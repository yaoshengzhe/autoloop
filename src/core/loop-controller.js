/**
 * Loop controller - orchestrates loop execution
 * Platform-agnostic interface for loop management
 */

import { LoopState } from './loop-state.js';

export class LoopController {
  /**
   * @param {object} adapter - Platform adapter with read/write state methods
   */
  constructor(adapter) {
    this.adapter = adapter;
    this.state = null;
  }

  /**
   * Initialize a new loop
   * @param {object} options - Loop configuration
   * @returns {Promise<LoopState>}
   */
  async start(options) {
    this.state = new LoopState({
      prompt: options.prompt,
      completionPromise: options.completionPromise,
      maxIterations: options.maxIterations,
      currentIteration: 0,
      startTime: Date.now(),
      active: true
    });

    await this.adapter.writeState(this.state);
    return this.state;
  }

  /**
   * Load existing loop state
   * @returns {Promise<LoopState|null>}
   */
  async load() {
    const data = await this.adapter.readState();
    if (data) {
      this.state = LoopState.fromJSON(data);
      return this.state;
    }
    return null;
  }

  /**
   * Process a loop iteration
   * Called by the stop hook to determine if loop should continue
   * @param {string} output - Agent output from this iteration
   * @returns {Promise<{continue: boolean, reason: string}>}
   */
  async processIteration(output) {
    if (!this.state) {
      await this.load();
    }

    if (!this.state || !this.state.active) {
      return { continue: false, reason: 'no_active_loop' };
    }

    // Check for completion promise
    if (this.state.checkCompletion(output)) {
      this.state.cancel();
      await this.adapter.writeState(this.state);
      await this.adapter.clearState();
      return { continue: false, reason: 'promise_fulfilled' };
    }

    // Check iteration limit
    const shouldContinue = this.state.nextIteration();
    await this.adapter.writeState(this.state);

    if (!shouldContinue) {
      await this.adapter.clearState();
      return { continue: false, reason: 'max_iterations_reached' };
    }

    return { continue: true, reason: 'iteration_complete' };
  }

  /**
   * Cancel the current loop
   * @returns {Promise<boolean>} true if loop was cancelled
   */
  async cancel() {
    if (!this.state) {
      await this.load();
    }

    if (this.state && this.state.active) {
      this.state.cancel();
      await this.adapter.writeState(this.state);
      await this.adapter.clearState();
      return true;
    }
    return false;
  }

  /**
   * Get current loop status
   * @returns {Promise<object|null>}
   */
  async getStatus() {
    if (!this.state) {
      await this.load();
    }
    return this.state ? this.state.toJSON() : null;
  }
}
