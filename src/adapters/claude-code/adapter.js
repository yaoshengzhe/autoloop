/**
 * Claude Code adapter
 * Handles state persistence using .claude directory and local markdown files
 */

import { readFile, writeFile, unlink, mkdir } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { existsSync } from 'node:fs';

const STATE_FILE = '.claude/autoloop.state.json';
const LOCAL_MD_FILE = '.claude/autoloop.local.md';

export class ClaudeCodeAdapter {
  constructor(workingDir = process.cwd()) {
    this.workingDir = workingDir;
    this.stateFile = join(workingDir, STATE_FILE);
    this.localMdFile = join(workingDir, LOCAL_MD_FILE);
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
   * Read loop state from file
   * @returns {Promise<object|null>}
   */
  async readState() {
    try {
      const content = await readFile(this.stateFile, 'utf-8');
      return JSON.parse(content);
    } catch (err) {
      if (err.code === 'ENOENT') {
        return null;
      }
      throw err;
    }
  }

  /**
   * Write loop state to file
   * Also writes a human-readable .local.md file for hooks
   * @param {LoopState} state
   */
  async writeState(state) {
    await this.ensureDir();
    const data = state.toJSON ? state.toJSON() : state;

    // Write JSON state
    await writeFile(this.stateFile, JSON.stringify(data, null, 2), 'utf-8');

    // Write human-readable markdown for hooks
    const md = this.generateLocalMd(data);
    await writeFile(this.localMdFile, md, 'utf-8');
  }

  /**
   * Generate human-readable local.md content
   * @param {object} data
   * @returns {string}
   */
  generateLocalMd(data) {
    const lines = [
      '# Autoloop State',
      '',
      `active: ${data.active}`,
      `iteration: ${data.currentIteration}${data.maxIterations ? '/' + data.maxIterations : ''}`,
      `completion_promise: ${data.completionPromise ? '"' + data.completionPromise + '"' : 'null'}`,
      `started: ${new Date(data.startTime).toISOString()}`,
      '',
      '## Prompt',
      '',
      data.prompt || '(no prompt)',
      ''
    ];
    return lines.join('\n');
  }

  /**
   * Clear state files
   */
  async clearState() {
    try {
      await unlink(this.stateFile);
    } catch (err) {
      if (err.code !== 'ENOENT') throw err;
    }
    try {
      await unlink(this.localMdFile);
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
