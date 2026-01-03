/**
 * Loop state management - platform agnostic
 * Handles iteration tracking, completion promises, and state persistence
 */

export class LoopState {
  constructor(options = {}) {
    this.prompt = options.prompt || '';
    this.completionPromise = options.completionPromise || null;
    this.maxIterations = options.maxIterations || null;
    this.currentIteration = options.currentIteration || 0;
    this.startTime = options.startTime || Date.now();
    this.active = options.active ?? true;
  }

  /**
   * Increment iteration and check if loop should continue
   * @returns {boolean} true if loop should continue
   */
  nextIteration() {
    this.currentIteration++;
    if (this.maxIterations && this.currentIteration >= this.maxIterations) {
      return false;
    }
    return this.active;
  }

  /**
   * Check if output contains the completion promise
   * @param {string} output - The output to check
   * @returns {boolean} true if promise is found
   */
  checkCompletion(output) {
    if (!this.completionPromise) return false;
    const promisePattern = new RegExp(`<promise>\\s*${this.escapeRegex(this.completionPromise)}\\s*</promise>`, 'i');
    return promisePattern.test(output);
  }

  /**
   * Escape special regex characters
   * @param {string} str
   * @returns {string}
   */
  escapeRegex(str) {
    return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  /**
   * Deactivate the loop
   */
  cancel() {
    this.active = false;
  }

  /**
   * Serialize state to plain object
   * @returns {object}
   */
  toJSON() {
    return {
      prompt: this.prompt,
      completionPromise: this.completionPromise,
      maxIterations: this.maxIterations,
      currentIteration: this.currentIteration,
      startTime: this.startTime,
      active: this.active
    };
  }

  /**
   * Create LoopState from serialized data
   * @param {object} data
   * @returns {LoopState}
   */
  static fromJSON(data) {
    return new LoopState(data);
  }
}
