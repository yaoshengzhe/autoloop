import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert';
import { LoopController } from './loop-controller.js';

// Mock adapter for testing
class MockAdapter {
  constructor() {
    this.state = null;
  }

  async readState() {
    return this.state;
  }

  async writeState(state) {
    this.state = state.toJSON ? state.toJSON() : state;
  }

  async clearState() {
    this.state = null;
  }
}

describe('LoopController', () => {
  let adapter;
  let controller;

  beforeEach(() => {
    adapter = new MockAdapter();
    controller = new LoopController(adapter);
  });

  describe('start', () => {
    it('should initialize a new loop', async () => {
      const state = await controller.start({
        prompt: 'Build an API',
        completionPromise: 'DONE',
        maxIterations: 10
      });

      assert.strictEqual(state.prompt, 'Build an API');
      assert.strictEqual(state.completionPromise, 'DONE');
      assert.strictEqual(state.maxIterations, 10);
      assert.strictEqual(state.active, true);
    });

    it('should persist state to adapter', async () => {
      await controller.start({ prompt: 'Test' });
      assert.notStrictEqual(adapter.state, null);
      assert.strictEqual(adapter.state.prompt, 'Test');
    });
  });

  describe('load', () => {
    it('should load existing state', async () => {
      adapter.state = {
        prompt: 'Existing task',
        currentIteration: 3,
        active: true
      };

      const state = await controller.load();
      assert.strictEqual(state.prompt, 'Existing task');
      assert.strictEqual(state.currentIteration, 3);
    });

    it('should return null when no state exists', async () => {
      const state = await controller.load();
      assert.strictEqual(state, null);
    });
  });

  describe('processIteration', () => {
    it('should continue when no completion detected', async () => {
      await controller.start({
        prompt: 'Test',
        completionPromise: 'DONE'
      });

      const result = await controller.processIteration('Still working...');
      assert.strictEqual(result.continue, true);
      assert.strictEqual(result.reason, 'iteration_complete');
    });

    it('should stop when promise fulfilled', async () => {
      await controller.start({
        prompt: 'Test',
        completionPromise: 'DONE'
      });

      const result = await controller.processIteration('Finished! <promise>DONE</promise>');
      assert.strictEqual(result.continue, false);
      assert.strictEqual(result.reason, 'promise_fulfilled');
    });

    it('should stop when max iterations reached', async () => {
      await controller.start({
        prompt: 'Test',
        maxIterations: 2
      });

      await controller.processIteration('iteration 1');
      const result = await controller.processIteration('iteration 2');
      assert.strictEqual(result.continue, false);
      assert.strictEqual(result.reason, 'max_iterations_reached');
    });

    it('should return no_active_loop when no state', async () => {
      const result = await controller.processIteration('output');
      assert.strictEqual(result.continue, false);
      assert.strictEqual(result.reason, 'no_active_loop');
    });
  });

  describe('cancel', () => {
    it('should cancel active loop', async () => {
      await controller.start({ prompt: 'Test' });
      const cancelled = await controller.cancel();
      assert.strictEqual(cancelled, true);
    });

    it('should return false when no active loop', async () => {
      const cancelled = await controller.cancel();
      assert.strictEqual(cancelled, false);
    });
  });

  describe('getStatus', () => {
    it('should return current state', async () => {
      await controller.start({
        prompt: 'Test',
        maxIterations: 5
      });

      const status = await controller.getStatus();
      assert.strictEqual(status.prompt, 'Test');
      assert.strictEqual(status.maxIterations, 5);
    });

    it('should return null when no state', async () => {
      const status = await controller.getStatus();
      assert.strictEqual(status, null);
    });
  });
});
