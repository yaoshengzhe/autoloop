/**
 * Claude Code adapter
 * Handles state persistence using YAML frontmatter in .claude/autoloop.local.md
 */

import { readFile, writeFile, unlink, mkdir } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { existsSync } from 'node:fs';

const STATE_FILE = '.claude/autoloop.local.md';

export class ClaudeCodeAdapter {
  constructor(workingDir = process.cwd()) {
    this.workingDir = workingDir;
    this.stateFile = join(workingDir, STATE_FILE);
  }

  /**
   * Ensure .claude directory exists
   */
  async ensureDir() {
    const dir = dirname(this.stateFile);
    if (!existsSync(dir)) {
      await mkdir(dir, { recursive: true });
    }
  }

  /**
   * Parse YAML frontmatter from markdown content
   * @param {string} content
   * @returns {object}
   */
  parseYamlFrontmatter(content) {
    const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);
    if (!frontmatterMatch) return null;

    const yaml = frontmatterMatch[1];
    const data = {};

    for (const line of yaml.split('\n')) {
      const match = line.match(/^(\w+):\s*(.*)$/);
      if (match) {
        let value = match[2].trim();
        // Remove quotes if present
        if (value.startsWith('"') && value.endsWith('"')) {
          value = value.slice(1, -1);
        }
        // Parse special values
        if (value === 'true') value = true;
        else if (value === 'false') value = false;
        else if (value === 'null') value = null;
        else if (/^\d+$/.test(value)) value = parseInt(value, 10);

        data[match[1]] = value;
      }
    }

    // Extract prompt (content after frontmatter)
    const promptMatch = content.match(/^---\n[\s\S]*?\n---\n\n?([\s\S]*)$/);
    if (promptMatch) {
      data.prompt = promptMatch[1].trim();
    }

    return data;
  }

  /**
   * Read loop state from file
   * @returns {Promise<object|null>}
   */
  async readState() {
    try {
      const content = await readFile(this.stateFile, 'utf-8');
      const data = this.parseYamlFrontmatter(content);
      if (!data) return null;

      // Map YAML keys to internal state format
      return {
        prompt: data.prompt || '',
        completionPromise: data.completion_promise,
        maxIterations: data.max_iterations || null,
        currentIteration: data.iteration || 0,
        startTime: data.started_at ? new Date(data.started_at).getTime() : Date.now(),
        active: data.active ?? false
      };
    } catch (err) {
      if (err.code === 'ENOENT') {
        return null;
      }
      throw err;
    }
  }

  /**
   * Write loop state to file with YAML frontmatter
   * @param {LoopState} state
   */
  async writeState(state) {
    await this.ensureDir();
    const data = state.toJSON ? state.toJSON() : state;

    const completionPromise = data.completionPromise
      ? `"${data.completionPromise}"`
      : 'null';

    const md = `---
active: ${data.active}
iteration: ${data.currentIteration}
max_iterations: ${data.maxIterations || 0}
completion_promise: ${completionPromise}
started_at: "${new Date(data.startTime).toISOString()}"
---

${data.prompt || ''}
`;

    await writeFile(this.stateFile, md, 'utf-8');
  }

  /**
   * Clear state file
   */
  async clearState() {
    try {
      await unlink(this.stateFile);
    } catch (err) {
      if (err.code !== 'ENOENT') throw err;
    }
  }

  /**
   * Check if a loop is currently active
   * @returns {Promise<boolean>}
   */
  async isLoopActive() {
    const state = await this.readState();
    return state?.active ?? false;
  }
}
