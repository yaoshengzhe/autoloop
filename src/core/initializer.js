/**
 * Initializer (Architect) - Two-Agent Pattern
 *
 * Runs once at the start of a project to:
 * 1. Scan the directory structure
 * 2. Create prd.json (task list)
 * 3. Create autoloop-progress.md (context log)
 * 4. Initialize git if missing
 */

import { PRD, PRDManager, TaskType, TaskStatus } from './prd.js';
import { execSync, spawn } from 'child_process';
import { existsSync, readFileSync, writeFileSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';

const PROGRESS_FILE = 'autoloop-progress.md';
const AGENTS_FILE = 'AGENTS.md';
const PRD_FILE = 'prd.json';

/**
 * Initializer class - the Architect agent
 */
export class Initializer {
  constructor(options = {}) {
    this.workingDir = options.workingDir || process.cwd();
    this.prdManager = new PRDManager(join(this.workingDir, PRD_FILE));
  }

  /**
   * Run the initialization process
   * @param {string} prompt - High-level project description
   * @returns {Promise<{prd: PRD, directoryScan: string}>}
   */
  async initialize(prompt) {
    // 1. Ensure git is initialized
    this.ensureGit();

    // 2. Scan directory structure
    const directoryScan = this.scanDirectory();

    // 3. Load AGENTS.md if exists (learnings/lessons)
    const agentsMd = this.loadAgentsMd();

    // 4. Create initial PRD structure
    const prd = new PRD({
      project_name: this.extractProjectName(prompt),
      description: prompt,
      context: {
        agents_md: agentsMd,
        progress_summary: ''
      }
    });

    // 5. Create progress log file
    this.initializeProgressLog(prompt);

    // 6. Save initial PRD
    await this.prdManager.save(prd);

    return {
      prd,
      directoryScan,
      agentsMd
    };
  }

  /**
   * Ensure git is initialized in the working directory
   */
  ensureGit() {
    const gitDir = join(this.workingDir, '.git');
    if (!existsSync(gitDir)) {
      try {
        execSync('git init', { cwd: this.workingDir, stdio: 'pipe' });
        execSync('git add -A', { cwd: this.workingDir, stdio: 'pipe' });
        execSync('git commit -m "Initial commit (autoloop init)" --allow-empty', {
          cwd: this.workingDir,
          stdio: 'pipe'
        });
      } catch (err) {
        // Git might already be configured at a parent level
        console.warn('Git initialization warning:', err.message);
      }
    }
  }

  /**
   * Scan directory structure
   * @returns {string} Directory listing
   */
  scanDirectory() {
    try {
      // Use ls -R but limit depth to avoid huge outputs
      const output = execSync(
        'find . -maxdepth 4 -type f -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/venv/*" -not -path "*/__pycache__/*" | head -200',
        { cwd: this.workingDir, encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] }
      );
      return output.trim();
    } catch (err) {
      // Fallback to basic ls
      try {
        return execSync('ls -la', { cwd: this.workingDir, encoding: 'utf8' });
      } catch {
        return 'Unable to scan directory';
      }
    }
  }

  /**
   * Load AGENTS.md file if it exists
   * @returns {string|null}
   */
  loadAgentsMd() {
    const agentsPath = join(this.workingDir, AGENTS_FILE);
    if (existsSync(agentsPath)) {
      return readFileSync(agentsPath, 'utf8');
    }
    return null;
  }

  /**
   * Extract a project name from the prompt
   * @param {string} prompt
   * @returns {string}
   */
  extractProjectName(prompt) {
    // Try to extract a meaningful name from the prompt
    const words = prompt.split(/\s+/).slice(0, 5);
    return words.join(' ').replace(/[^a-zA-Z0-9\s]/g, '').trim() || 'Untitled Project';
  }

  /**
   * Initialize the progress log file
   * @param {string} prompt
   */
  initializeProgressLog(prompt) {
    const progressPath = join(this.workingDir, PROGRESS_FILE);
    const timestamp = new Date().toISOString();

    const content = `# Autoloop Progress Log

## Project
${prompt}

## Timeline

### ${timestamp} - Project Initialized
- Created prd.json
- Scanned directory structure
- Ready for worker loop

---

## Completed Tasks

(Tasks will be logged here as they complete)

---

## Learnings & Notes

(Important insights discovered during development)

`;

    writeFileSync(progressPath, content, 'utf8');
  }

  /**
   * Check if project is already initialized
   * @returns {Promise<boolean>}
   */
  async isInitialized() {
    return await this.prdManager.exists();
  }
}

/**
 * Generate initialization prompt for Claude
 * This prompt is used to have Claude create the task breakdown
 */
export function generateInitPrompt(prompt, directoryScan, agentsMd) {
  return `You are the INITIALIZER agent in a two-agent autonomous coding system.

Your ONLY job is to analyze the project request and create a structured task list (prd.json).

## Project Request
${prompt}

## Current Directory Structure
\`\`\`
${directoryScan}
\`\`\`

${agentsMd ? `## AGENTS.md (Learnings from previous work)
\`\`\`
${agentsMd}
\`\`\`
` : ''}

## Your Task

Create a detailed prd.json with tasks broken down into actionable items.

### Rules for Task Breakdown

1. **Feature tasks** require TDD (Test-Driven Development):
   - First write failing tests (RED phase)
   - Then implement to make tests pass (GREEN phase)

2. **Setup tasks** are one-shot (no TDD):
   - Environment setup, dependencies, configuration

3. Each task needs a \`validation_cmd\` that proves it works

4. Tasks should be small and focused (15-30 min of work each)

5. Dependencies should flow naturally (setup → features → polish)

### Output Format

Output ONLY valid JSON in this exact format:

\`\`\`json
{
  "project_name": "...",
  "description": "...",
  "tasks": [
    {
      "id": "TASK-001",
      "type": "setup",
      "description": "Initialize project structure and dependencies",
      "validation_cmd": "command to verify task is complete"
    },
    {
      "id": "TASK-002",
      "type": "feature",
      "description": "Implement feature X",
      "validation_cmd": "pytest tests/test_feature_x.py",
      "test_file": "tests/test_feature_x.py"
    }
  ]
}
\`\`\`

Task types: setup, feature, test, bugfix, refactor, docs

Now analyze the project and create the prd.json:`;
}

/**
 * Parse Claude's response to extract PRD JSON
 */
export function parseInitResponse(response) {
  // Try to extract JSON from response
  const jsonMatch = response.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (jsonMatch) {
    try {
      return JSON.parse(jsonMatch[1].trim());
    } catch (err) {
      throw new Error(`Failed to parse PRD JSON: ${err.message}`);
    }
  }

  // Try parsing the whole response as JSON
  try {
    return JSON.parse(response.trim());
  } catch (err) {
    throw new Error('Could not find valid JSON in response');
  }
}
