/**
 * Autoloop TypeScript type definitions
 */

export interface LoopStateOptions {
  prompt?: string;
  completionPromise?: string | null;
  maxIterations?: number | null;
  currentIteration?: number;
  startTime?: number;
  active?: boolean;
}

export interface LoopStateData {
  prompt: string;
  completionPromise: string | null;
  maxIterations: number | null;
  currentIteration: number;
  startTime: number;
  active: boolean;
}

export declare class LoopState {
  prompt: string;
  completionPromise: string | null;
  maxIterations: number | null;
  currentIteration: number;
  startTime: number;
  active: boolean;

  constructor(options?: LoopStateOptions);
  nextIteration(): boolean;
  checkCompletion(output: string): boolean;
  cancel(): void;
  toJSON(): LoopStateData;
  static fromJSON(data: LoopStateData): LoopState;
}

export interface IterationResult {
  continue: boolean;
  reason: 'no_active_loop' | 'promise_fulfilled' | 'max_iterations_reached' | 'iteration_complete';
}

export interface Adapter {
  readState(): Promise<LoopStateData | null>;
  writeState(state: LoopState | LoopStateData): Promise<void>;
  clearState(): Promise<void>;
}

export declare class LoopController {
  constructor(adapter: Adapter);
  start(options: LoopStateOptions): Promise<LoopState>;
  load(): Promise<LoopState | null>;
  processIteration(output: string): Promise<IterationResult>;
  cancel(): Promise<boolean>;
  getStatus(): Promise<LoopStateData | null>;
}

export declare class ClaudeCodeAdapter implements Adapter {
  constructor(workingDir?: string);
  readState(): Promise<LoopStateData | null>;
  writeState(state: LoopState | LoopStateData): Promise<void>;
  clearState(): Promise<void>;
  isLoopActive(): Promise<boolean>;
}
