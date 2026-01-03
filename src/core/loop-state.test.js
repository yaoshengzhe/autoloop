import { describe, it } from 'node:test';
import assert from 'node:assert';
import { LoopState } from './loop-state.js';

describe('LoopState', () => {
  describe('constructor', () => {
    it('should initialize with default values', () => {
      const state = new LoopState();
      assert.strictEqual(state.prompt, '');
      assert.strictEqual(state.completionPromise, null);
      assert.strictEqual(state.maxIterations, null);
      assert.strictEqual(state.currentIteration, 0);
      assert.strictEqual(state.active, true);
    });

    it('should accept options', () => {
      const state = new LoopState({
        prompt: 'Build an API',
        completionPromise: 'DONE',
        maxIterations: 10,
        currentIteration: 5
      });
      assert.strictEqual(state.prompt, 'Build an API');
      assert.strictEqual(state.completionPromise, 'DONE');
      assert.strictEqual(state.maxIterations, 10);
      assert.strictEqual(state.currentIteration, 5);
    });
  });

  describe('nextIteration', () => {
    it('should increment iteration count', () => {
      const state = new LoopState();
      state.nextIteration();
      assert.strictEqual(state.currentIteration, 1);
    });

    it('should return true when under max iterations', () => {
      const state = new LoopState({ maxIterations: 10 });
      assert.strictEqual(state.nextIteration(), true);
    });

    it('should return false when reaching max iterations', () => {
      const state = new LoopState({ maxIterations: 2, currentIteration: 1 });
      assert.strictEqual(state.nextIteration(), false);
    });

    it('should return false when inactive', () => {
      const state = new LoopState();
      state.cancel();
      assert.strictEqual(state.nextIteration(), false);
    });
  });

  describe('checkCompletion', () => {
    it('should return false when no promise set', () => {
      const state = new LoopState();
      assert.strictEqual(state.checkCompletion('<promise>DONE</promise>'), false);
    });

    it('should detect promise in output', () => {
      const state = new LoopState({ completionPromise: 'DONE' });
      assert.strictEqual(state.checkCompletion('Task complete <promise>DONE</promise>'), true);
    });

    it('should be case insensitive', () => {
      const state = new LoopState({ completionPromise: 'DONE' });
      assert.strictEqual(state.checkCompletion('<PROMISE>DONE</PROMISE>'), true);
    });

    it('should handle whitespace in promise tags', () => {
      const state = new LoopState({ completionPromise: 'DONE' });
      assert.strictEqual(state.checkCompletion('<promise> DONE </promise>'), true);
    });

    it('should escape regex special characters', () => {
      const state = new LoopState({ completionPromise: 'tests.pass()' });
      assert.strictEqual(state.checkCompletion('<promise>tests.pass()</promise>'), true);
    });
  });

  describe('cancel', () => {
    it('should set active to false', () => {
      const state = new LoopState();
      state.cancel();
      assert.strictEqual(state.active, false);
    });
  });

  describe('serialization', () => {
    it('should serialize to JSON', () => {
      const state = new LoopState({
        prompt: 'Test',
        completionPromise: 'DONE',
        maxIterations: 5
      });
      const json = state.toJSON();
      assert.strictEqual(json.prompt, 'Test');
      assert.strictEqual(json.completionPromise, 'DONE');
      assert.strictEqual(json.maxIterations, 5);
    });

    it('should deserialize from JSON', () => {
      const data = {
        prompt: 'Test',
        completionPromise: 'DONE',
        maxIterations: 5,
        currentIteration: 2,
        active: true
      };
      const state = LoopState.fromJSON(data);
      assert.strictEqual(state.prompt, 'Test');
      assert.strictEqual(state.currentIteration, 2);
    });
  });
});
