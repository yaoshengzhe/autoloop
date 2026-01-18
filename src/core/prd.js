/**
 * PRD (Project Requirements Document) management
 * Handles the structured task list for TDD-driven development
 */

export const TaskType = {
  SETUP: 'setup',
  FEATURE: 'feature',
  TEST: 'test',
  BUGFIX: 'bugfix',
  REFACTOR: 'refactor',
  DOCS: 'docs'
};

export const TaskStatus = {
  PENDING: 'pending',
  TEST_CREATION: 'test_creation', // Red phase - write failing tests
  IMPLEMENTATION: 'implementation', // Green phase - make tests pass
  COMPLETED: 'completed',
  FAILED: 'failed',
  SKIPPED: 'skipped'
};

export const TDDPhase = {
  RED: 'red',   // Tests must fail
  GREEN: 'green' // Tests must pass
};

/**
 * Represents a single task in the PRD
 */
export class Task {
  constructor(options = {}) {
    this.id = options.id || this.generateId();
    this.type = options.type || TaskType.FEATURE;
    this.description = options.description || '';
    this.status = options.status || TaskStatus.PENDING;
    this.validation_cmd = options.validation_cmd || null;
    this.test_file = options.test_file || null;
    this.tdd_phase = options.tdd_phase || null; // null for non-TDD tasks
    this.attempts = options.attempts || 0;
    this.max_attempts = options.max_attempts || 3;
    this.error_log = options.error_log || [];
    this.completed_at = options.completed_at || null;
    this.commit_sha = options.commit_sha || null;
  }

  generateId() {
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).substring(2, 6);
    return `TASK-${timestamp}-${random}`.toUpperCase();
  }

  /**
   * Check if task requires TDD workflow
   */
  requiresTDD() {
    return this.type === TaskType.FEATURE || this.type === TaskType.BUGFIX;
  }

  /**
   * Advance to next phase
   */
  advancePhase() {
    if (this.status === TaskStatus.PENDING) {
      if (this.requiresTDD()) {
        this.status = TaskStatus.TEST_CREATION;
        this.tdd_phase = TDDPhase.RED;
      } else {
        this.status = TaskStatus.IMPLEMENTATION;
      }
    } else if (this.status === TaskStatus.TEST_CREATION) {
      this.status = TaskStatus.IMPLEMENTATION;
      this.tdd_phase = TDDPhase.GREEN;
    } else if (this.status === TaskStatus.IMPLEMENTATION) {
      this.status = TaskStatus.COMPLETED;
      this.completed_at = new Date().toISOString();
    }
    return this.status;
  }

  /**
   * Record a failed attempt
   */
  recordFailure(error) {
    this.attempts++;
    this.error_log.push({
      attempt: this.attempts,
      timestamp: new Date().toISOString(),
      error: error
    });
    if (this.attempts >= this.max_attempts) {
      this.status = TaskStatus.FAILED;
    }
  }

  /**
   * Check if max attempts exceeded
   */
  isMaxAttemptsReached() {
    return this.attempts >= this.max_attempts;
  }

  toJSON() {
    return {
      id: this.id,
      type: this.type,
      description: this.description,
      status: this.status,
      validation_cmd: this.validation_cmd,
      test_file: this.test_file,
      tdd_phase: this.tdd_phase,
      attempts: this.attempts,
      max_attempts: this.max_attempts,
      error_log: this.error_log,
      completed_at: this.completed_at,
      commit_sha: this.commit_sha
    };
  }

  static fromJSON(data) {
    return new Task(data);
  }
}

/**
 * PRD - Project Requirements Document
 * Contains the structured task list
 */
export class PRD {
  constructor(options = {}) {
    this.project_name = options.project_name || 'Untitled Project';
    this.description = options.description || '';
    this.created_at = options.created_at || new Date().toISOString();
    this.updated_at = options.updated_at || new Date().toISOString();
    this.tasks = (options.tasks || []).map(t => t instanceof Task ? t : Task.fromJSON(t));
    this.context = options.context || {
      agents_md: null,
      progress_summary: ''
    };
  }

  /**
   * Add a new task
   */
  addTask(taskOptions) {
    const task = new Task(taskOptions);
    this.tasks.push(task);
    this.updated_at = new Date().toISOString();
    return task;
  }

  /**
   * Get next pending task
   */
  getNextTask() {
    // First, look for tasks in test_creation or implementation phase
    const inProgress = this.tasks.find(t =>
      t.status === TaskStatus.TEST_CREATION ||
      t.status === TaskStatus.IMPLEMENTATION
    );
    if (inProgress) return inProgress;

    // Then, get next pending task
    return this.tasks.find(t => t.status === TaskStatus.PENDING);
  }

  /**
   * Get current task being worked on
   */
  getCurrentTask() {
    return this.tasks.find(t =>
      t.status === TaskStatus.TEST_CREATION ||
      t.status === TaskStatus.IMPLEMENTATION
    );
  }

  /**
   * Get all completed tasks
   */
  getCompletedTasks() {
    return this.tasks.filter(t => t.status === TaskStatus.COMPLETED);
  }

  /**
   * Get all failed tasks
   */
  getFailedTasks() {
    return this.tasks.filter(t => t.status === TaskStatus.FAILED);
  }

  /**
   * Get progress stats
   */
  getProgress() {
    const total = this.tasks.length;
    const completed = this.tasks.filter(t => t.status === TaskStatus.COMPLETED).length;
    const failed = this.tasks.filter(t => t.status === TaskStatus.FAILED).length;
    const pending = this.tasks.filter(t => t.status === TaskStatus.PENDING).length;
    const inProgress = this.tasks.filter(t =>
      t.status === TaskStatus.TEST_CREATION ||
      t.status === TaskStatus.IMPLEMENTATION
    ).length;

    return {
      total,
      completed,
      failed,
      pending,
      in_progress: inProgress,
      percentage: total > 0 ? Math.round((completed / total) * 100) : 0
    };
  }

  /**
   * Check if all tasks are done (completed or failed)
   */
  isComplete() {
    return this.tasks.every(t =>
      t.status === TaskStatus.COMPLETED ||
      t.status === TaskStatus.FAILED ||
      t.status === TaskStatus.SKIPPED
    );
  }

  /**
   * Mark a task as completed with commit SHA
   */
  completeTask(taskId, commitSha) {
    const task = this.tasks.find(t => t.id === taskId);
    if (task) {
      task.status = TaskStatus.COMPLETED;
      task.completed_at = new Date().toISOString();
      task.commit_sha = commitSha;
      this.updated_at = new Date().toISOString();
    }
    return task;
  }

  toJSON() {
    return {
      project_name: this.project_name,
      description: this.description,
      created_at: this.created_at,
      updated_at: this.updated_at,
      tasks: this.tasks.map(t => t.toJSON()),
      context: this.context
    };
  }

  static fromJSON(data) {
    return new PRD(data);
  }
}

/**
 * PRD File Manager - handles file I/O
 */
export class PRDManager {
  constructor(filePath = 'prd.json') {
    this.filePath = filePath;
  }

  /**
   * Load PRD from file
   */
  async load() {
    const fs = await import('fs/promises');
    try {
      const content = await fs.readFile(this.filePath, 'utf8');
      return PRD.fromJSON(JSON.parse(content));
    } catch (err) {
      if (err.code === 'ENOENT') {
        return null;
      }
      throw err;
    }
  }

  /**
   * Save PRD to file
   */
  async save(prd) {
    const fs = await import('fs/promises');
    const content = JSON.stringify(prd.toJSON(), null, 2);
    await fs.writeFile(this.filePath, content, 'utf8');
  }

  /**
   * Check if PRD file exists
   */
  async exists() {
    const fs = await import('fs/promises');
    try {
      await fs.access(this.filePath);
      return true;
    } catch {
      return false;
    }
  }
}
