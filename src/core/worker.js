/**
 * Worker (Engineer) - Two-Agent Pattern
 *
 * Runs in a loop, consuming one task from prd.json at a time.
 * Uses Git-based context and safety net.
 * Enforces TDD (Red-Green cycle) for feature tasks.
 */

import { PRD, PRDManager, Task, TaskStatus, TaskType, TDDPhase } from './prd.js';
import { execSync, spawnSync } from 'child_process';
import { existsSync, readFileSync, writeFileSync, appendFileSync } from 'fs';
import { join } from 'path';

const PROGRESS_FILE = 'autoloop-progress.md';
const AGENTS_FILE = 'AGENTS.md';
const PRD_FILE = 'prd.json';
const MAX_RETRIES = 3;

/**
 * Git operations helper
 */
export class GitHelper {
  constructor(workingDir = process.cwd()) {
    this.workingDir = workingDir;
  }

  /**
   * Execute git command
   */
  exec(cmd, options = {}) {
    try {
      return execSync(`git ${cmd}`, {
        cwd: this.workingDir,
        encoding: 'utf8',
        stdio: options.stdio || ['pipe', 'pipe', 'pipe'],
        ...options
      }).trim();
    } catch (err) {
      if (options.throwOnError !== false) {
        throw err;
      }
      return null;
    }
  }

  /**
   * Check if working tree is clean
   */
  isClean() {
    const status = this.exec('status --porcelain');
    return status === '';
  }

  /**
   * Get recent commit log
   */
  getRecentLog(count = 5) {
    try {
      return this.exec(`log -n ${count} --oneline`);
    } catch {
      return 'No commits yet';
    }
  }

  /**
   * Get recent changes summary
   */
  getDiffStat(commits = 5) {
    try {
      return this.exec(`diff HEAD~${commits}..HEAD --stat`, { throwOnError: false }) || 'No changes';
    } catch {
      return 'No changes to compare';
    }
  }

  /**
   * Stage all changes
   */
  stageAll() {
    this.exec('add -A');
  }

  /**
   * Create commit
   */
  commit(message) {
    this.stageAll();
    const result = this.exec(`commit -m "${message.replace(/"/g, '\\"')}"`, { throwOnError: false });
    if (result) {
      // Get the commit SHA
      return this.exec('rev-parse HEAD');
    }
    return null;
  }

  /**
   * Hard reset to last commit (discard all changes)
   */
  resetHard() {
    this.exec('reset --hard HEAD');
    this.exec('clean -fd'); // Remove untracked files too
  }

  /**
   * Stash changes
   */
  stash() {
    return this.exec('stash push -m "autoloop-safety-stash"', { throwOnError: false });
  }

  /**
   * Pop stash
   */
  stashPop() {
    return this.exec('stash pop', { throwOnError: false });
  }
}

/**
 * Worker class - the Engineer agent
 */
export class Worker {
  constructor(options = {}) {
    this.workingDir = options.workingDir || process.cwd();
    this.prdManager = new PRDManager(join(this.workingDir, PRD_FILE));
    this.git = new GitHelper(this.workingDir);
    this.maxRetries = options.maxRetries || MAX_RETRIES;
  }

  /**
   * Load context for the worker
   * This is the "context compaction" strategy from Anthropic
   */
  async loadContext() {
    const prd = await this.prdManager.load();
    if (!prd) {
      return null;
    }

    const context = {
      prd,
      currentTask: prd.getNextTask(),
      progressSummary: this.loadProgressLog(),
      gitLog: this.git.getRecentLog(5),
      gitDiffStat: this.git.getDiffStat(5),
      agentsMd: this.loadAgentsMd(),
      isGitClean: this.git.isClean()
    };

    return context;
  }

  /**
   * Load progress log summary
   */
  loadProgressLog() {
    const progressPath = join(this.workingDir, PROGRESS_FILE);
    if (existsSync(progressPath)) {
      const content = readFileSync(progressPath, 'utf8');
      // Return last 50 lines to keep context small
      const lines = content.split('\n');
      return lines.slice(-50).join('\n');
    }
    return '';
  }

  /**
   * Load AGENTS.md learnings
   */
  loadAgentsMd() {
    const agentsPath = join(this.workingDir, AGENTS_FILE);
    if (existsSync(agentsPath)) {
      return readFileSync(agentsPath, 'utf8');
    }
    return null;
  }

  /**
   * Append to progress log
   */
  appendToProgressLog(entry) {
    const progressPath = join(this.workingDir, PROGRESS_FILE);
    const timestamp = new Date().toISOString();
    appendFileSync(progressPath, `\n### ${timestamp}\n${entry}\n`, 'utf8');
  }

  /**
   * Ensure working tree is clean before starting task
   */
  ensureCleanWorkingTree() {
    if (!this.git.isClean()) {
      // Stash any uncommitted changes
      this.git.stash();
      this.appendToProgressLog('- Stashed uncommitted changes before starting task');
    }
  }

  /**
   * Run validation command for a task
   * @returns {{success: boolean, output: string, exitCode: number}}
   */
  runValidation(task) {
    if (!task.validation_cmd) {
      return { success: true, output: 'No validation command', exitCode: 0 };
    }

    try {
      const output = execSync(task.validation_cmd, {
        cwd: this.workingDir,
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'pipe'],
        timeout: 120000 // 2 minute timeout
      });
      return { success: true, output, exitCode: 0 };
    } catch (err) {
      return {
        success: false,
        output: err.stderr || err.stdout || err.message,
        exitCode: err.status || 1
      };
    }
  }

  /**
   * Verify TDD phase
   * RED phase: tests MUST fail (exitCode != 0)
   * GREEN phase: tests MUST pass (exitCode == 0)
   */
  verifyTDDPhase(task, validationResult) {
    if (!task.requiresTDD()) {
      return validationResult.success;
    }

    if (task.tdd_phase === TDDPhase.RED) {
      // In RED phase, tests should FAIL
      return !validationResult.success;
    } else if (task.tdd_phase === TDDPhase.GREEN) {
      // In GREEN phase, tests should PASS
      return validationResult.success;
    }

    return validationResult.success;
  }

  /**
   * Handle successful task completion
   */
  async handleTaskSuccess(task, prd) {
    // Auto-commit the changes
    const commitMessage = `feat(${task.id}): ${task.description.slice(0, 50)}`;
    const commitSha = this.git.commit(commitMessage);

    if (commitSha) {
      task.commit_sha = commitSha;
    }

    // Advance task phase
    const prevStatus = task.status;
    task.advancePhase();

    // Log progress
    if (task.status === TaskStatus.COMPLETED) {
      this.appendToProgressLog(`- ✅ Completed ${task.id}: ${task.description}\n  Commit: ${commitSha || 'N/A'}`);
    } else {
      this.appendToProgressLog(`- 🔄 ${task.id}: Advanced from ${prevStatus} to ${task.status}`);
    }

    // Save updated PRD
    await this.prdManager.save(prd);

    return task;
  }

  /**
   * Handle task failure
   */
  async handleTaskFailure(task, prd, error) {
    task.recordFailure(error);

    if (task.isMaxAttemptsReached()) {
      // Reset to clean state
      this.git.resetHard();
      this.appendToProgressLog(`- ❌ FAILED ${task.id} after ${task.attempts} attempts: ${error}\n  Working tree reset to last commit`);
    } else {
      this.appendToProgressLog(`- ⚠️ Attempt ${task.attempts}/${task.max_attempts} failed for ${task.id}: ${error}`);
    }

    await this.prdManager.save(prd);
    return task;
  }

  /**
   * Get the current work status
   */
  async getStatus() {
    const prd = await this.prdManager.load();
    if (!prd) {
      return { initialized: false };
    }

    const progress = prd.getProgress();
    const currentTask = prd.getCurrentTask();
    const nextTask = prd.getNextTask();

    return {
      initialized: true,
      projectName: prd.project_name,
      progress,
      currentTask: currentTask ? currentTask.toJSON() : null,
      nextTask: nextTask ? nextTask.toJSON() : null,
      isComplete: prd.isComplete(),
      isGitClean: this.git.isClean()
    };
  }
}

/**
 * Generate worker prompt for Claude
 * This includes context compaction and thinking block enforcement
 */
export function generateWorkerPrompt(context) {
  const { prd, currentTask, progressSummary, gitLog, agentsMd, isGitClean } = context;

  if (!currentTask) {
    return null; // No more tasks
  }

  const tddInstructions = currentTask.requiresTDD() ? `
## TDD Phase: ${currentTask.tdd_phase === TDDPhase.RED ? '🔴 RED (Write Failing Tests)' : '🟢 GREEN (Make Tests Pass)'}

${currentTask.tdd_phase === TDDPhase.RED ? `
**Your goal**: Write tests that FAIL. The validation command must return exit code != 0.
- Create test file: ${currentTask.test_file || 'tests/test_*.py'}
- Tests should cover the expected behavior
- DO NOT write implementation yet
` : `
**Your goal**: Write implementation to make tests PASS. The validation command must return exit code == 0.
- Implement the minimum code to pass the tests
- Run: ${currentTask.validation_cmd}
`}
` : '';

  return `You are the WORKER agent in a two-agent autonomous coding system.

## CRITICAL: Thinking Block Required
Before ANY action, you MUST output a thinking block:

<thinking>
1. What is the current state?
2. What needs to be done?
3. What command will I use?
4. What could go wrong?
</thinking>

Then execute your planned action.

## Current Task
**ID**: ${currentTask.id}
**Type**: ${currentTask.type}
**Status**: ${currentTask.status}
**Description**: ${currentTask.description}
**Validation**: \`${currentTask.validation_cmd || 'None'}\`
**Attempts**: ${currentTask.attempts}/${currentTask.max_attempts}
${tddInstructions}

## Context

### Recent Git Log
\`\`\`
${gitLog}
\`\`\`

### Progress Summary
${progressSummary || 'No progress yet'}

${agentsMd ? `### AGENTS.md (Learnings)
\`\`\`
${agentsMd}
\`\`\`
` : ''}

### Git Status
${isGitClean ? '✅ Working tree is clean' : '⚠️ Working tree has uncommitted changes'}

## Project Progress
${JSON.stringify(prd.getProgress(), null, 2)}

## Rules

1. **Always use <thinking> before actions**
2. **Use bash/shell commands for file operations** (sed, echo, cat)
3. **Validate your work** by running: \`${currentTask.validation_cmd}\`
4. **One task at a time** - focus only on the current task
5. **Git is your safety net** - changes are auto-committed on success

## When Done

When the validation command passes:
- Output: <task-complete/>

If you're stuck after multiple attempts:
- Output: <task-stuck reason="explanation"/>

Now work on the task. Start with <thinking>:`;
}

/**
 * Parse worker response for completion signals
 */
export function parseWorkerResponse(response) {
  const result = {
    complete: false,
    stuck: false,
    stuckReason: null,
    hasThinking: false,
    thinkingContent: null
  };

  // Check for thinking block
  const thinkingMatch = response.match(/<thinking>([\s\S]*?)<\/thinking>/);
  if (thinkingMatch) {
    result.hasThinking = true;
    result.thinkingContent = thinkingMatch[1].trim();
  }

  // Check for task-complete signal
  if (response.includes('<task-complete/>') || response.includes('<task-complete />')) {
    result.complete = true;
  }

  // Check for stuck signal
  const stuckMatch = response.match(/<task-stuck\s+reason="([^"]*)".*?\/>/);
  if (stuckMatch) {
    result.stuck = true;
    result.stuckReason = stuckMatch[1];
  }

  return result;
}
