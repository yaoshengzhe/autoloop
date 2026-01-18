/**
 * Autoloop TypeScript type definitions
 */

// ============================================================================
// PRD (Project Requirements Document) Types
// ============================================================================

export type TaskType = 'setup' | 'feature' | 'test' | 'bugfix' | 'refactor' | 'docs';
export type TaskStatus = 'pending' | 'test_creation' | 'implementation' | 'completed' | 'failed' | 'skipped';
export type TDDPhase = 'red' | 'green';

export interface TaskErrorLog {
  attempt: number;
  timestamp: string;
  error: string;
}

export interface TaskData {
  id: string;
  type: TaskType;
  description: string;
  status: TaskStatus;
  validation_cmd: string | null;
  test_file: string | null;
  tdd_phase: TDDPhase | null;
  attempts: number;
  max_attempts: number;
  error_log: TaskErrorLog[];
  completed_at: string | null;
  commit_sha: string | null;
}

export interface PRDContext {
  agents_md: string | null;
  progress_summary: string;
}

export interface PRDData {
  project_name: string;
  description: string;
  created_at: string;
  updated_at: string;
  tasks: TaskData[];
  context: PRDContext;
}

export interface PRDProgress {
  total: number;
  completed: number;
  failed: number;
  pending: number;
  in_progress: number;
  percentage: number;
}

export declare class Task {
  id: string;
  type: TaskType;
  description: string;
  status: TaskStatus;
  validation_cmd: string | null;
  test_file: string | null;
  tdd_phase: TDDPhase | null;
  attempts: number;
  max_attempts: number;
  error_log: TaskErrorLog[];
  completed_at: string | null;
  commit_sha: string | null;

  constructor(options?: Partial<TaskData>);
  requiresTDD(): boolean;
  advancePhase(): TaskStatus;
  recordFailure(error: string): void;
  isMaxAttemptsReached(): boolean;
  toJSON(): TaskData;
  static fromJSON(data: TaskData): Task;
}

export declare class PRD {
  project_name: string;
  description: string;
  created_at: string;
  updated_at: string;
  tasks: Task[];
  context: PRDContext;

  constructor(options?: Partial<PRDData>);
  addTask(taskOptions: Partial<TaskData>): Task;
  getNextTask(): Task | undefined;
  getCurrentTask(): Task | undefined;
  getCompletedTasks(): Task[];
  getFailedTasks(): Task[];
  getProgress(): PRDProgress;
  isComplete(): boolean;
  completeTask(taskId: string, commitSha: string): Task | undefined;
  toJSON(): PRDData;
  static fromJSON(data: PRDData): PRD;
}

export declare class PRDManager {
  filePath: string;
  constructor(filePath?: string);
  load(): Promise<PRD | null>;
  save(prd: PRD): Promise<void>;
  exists(): Promise<boolean>;
}

// ============================================================================
// Loop State Types
// ============================================================================

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

// ============================================================================
// Two-Agent Pattern Types (v3.0)
// ============================================================================

// Initializer (Architect) Types
export interface InitializerOptions {
  workingDir?: string;
}

export interface InitializeResult {
  prd: PRD;
  directoryScan: string;
  agentsMd: string | null;
}

export declare class Initializer {
  workingDir: string;
  prdManager: PRDManager;

  constructor(options?: InitializerOptions);
  initialize(prompt: string): Promise<InitializeResult>;
  ensureGit(): void;
  scanDirectory(): string;
  loadAgentsMd(): string | null;
  extractProjectName(prompt: string): string;
  initializeProgressLog(prompt: string): void;
  isInitialized(): Promise<boolean>;
}

export declare function generateInitPrompt(
  prompt: string,
  directoryScan: string,
  agentsMd: string | null
): string;

export declare function parseInitResponse(response: string): PRDData;

// Worker (Engineer) Types
export interface WorkerOptions {
  workingDir?: string;
  maxRetries?: number;
}

export interface WorkerContext {
  prd: PRD;
  currentTask: Task | undefined;
  progressSummary: string;
  gitLog: string;
  gitDiffStat: string;
  agentsMd: string | null;
  isGitClean: boolean;
}

export interface ValidationResult {
  success: boolean;
  output: string;
  exitCode: number;
}

export interface WorkerStatus {
  initialized: boolean;
  projectName?: string;
  progress?: PRDProgress;
  currentTask?: TaskData | null;
  nextTask?: TaskData | null;
  isComplete?: boolean;
  isGitClean?: boolean;
}

export interface WorkerResponseParsed {
  complete: boolean;
  stuck: boolean;
  stuckReason: string | null;
  hasThinking: boolean;
  thinkingContent: string | null;
}

export declare class GitHelper {
  workingDir: string;

  constructor(workingDir?: string);
  exec(cmd: string, options?: { stdio?: string; throwOnError?: boolean }): string | null;
  isClean(): boolean;
  getRecentLog(count?: number): string;
  getDiffStat(commits?: number): string;
  stageAll(): void;
  commit(message: string): string | null;
  resetHard(): void;
  stash(): string | null;
  stashPop(): string | null;
}

export declare class Worker {
  workingDir: string;
  prdManager: PRDManager;
  git: GitHelper;
  maxRetries: number;

  constructor(options?: WorkerOptions);
  loadContext(): Promise<WorkerContext | null>;
  loadProgressLog(): string;
  loadAgentsMd(): string | null;
  appendToProgressLog(entry: string): void;
  ensureCleanWorkingTree(): void;
  runValidation(task: Task): ValidationResult;
  verifyTDDPhase(task: Task, validationResult: ValidationResult): boolean;
  handleTaskSuccess(task: Task, prd: PRD): Promise<Task>;
  handleTaskFailure(task: Task, prd: PRD, error: string): Promise<Task>;
  getStatus(): Promise<WorkerStatus>;
}

export declare function generateWorkerPrompt(context: WorkerContext): string | null;

export declare function parseWorkerResponse(response: string): WorkerResponseParsed;
