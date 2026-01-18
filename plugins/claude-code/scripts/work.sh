#!/bin/bash
# Autoloop v3.0 - Worker (Engineer) Agent
# Consumes tasks from prd.json one at a time

set -euo pipefail

PRD_FILE="prd.json"
PROGRESS_FILE="autoloop-progress.md"
AGENTS_FILE="AGENTS.md"
STATE_FILE=".claude/autoloop-worker.state"
MAX_ITERATIONS=0

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat <<'HELP_EOF'
Autoloop v3.0 - Worker Loop (Engineer Mode)

USAGE:
  /autoloop:work [OPTIONS]

OPTIONS:
  --max-iterations <n>  Maximum iterations before auto-stop (default: unlimited)
  -h, --help            Show this help message

DESCRIPTION:
  The Worker (Engineer) agent runs in a loop, consuming tasks from prd.json.

  Context Strategy (Token Efficient):
  - Loads prd.json (current task)
  - Reads autoloop-progress.md (what previous workers did)
  - Gets git log -n 5 (recent code changes)
  - Loads AGENTS.md (learnings/lessons)

PREREQUISITES:
  Run /autoloop:init first to create prd.json

TDD WORKFLOW:
  Feature tasks have two phases:
  1. RED: Write tests that FAIL (exit code != 0)
  2. GREEN: Write code to make tests PASS (exit code == 0)

SAFETY NET:
  - Pre-task: Ensures working tree is clean
  - Success: Auto-commits with "feat: [TASK-ID]"
  - Failure: git reset --hard after max retries

SIGNALS:
  <task-complete/>     - Current task validation passed
  <task-stuck reason="..."/>  - Need help, provide reason

EXAMPLES:
  /autoloop:work                      # Run until all tasks complete
  /autoloop:work --max-iterations 10  # Stop after 10 iterations
HELP_EOF
      exit 0
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --max-iterations requires a number" >&2
        exit 1
      fi
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-iterations must be a positive integer" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Check prerequisites
if [[ ! -f "$PRD_FILE" ]]; then
  echo "Error: prd.json not found!" >&2
  echo "" >&2
  echo "Run /autoloop:init first to create the project task list." >&2
  echo "" >&2
  echo "Example:" >&2
  echo "  /autoloop:init Build a REST API with authentication" >&2
  exit 1
fi

# Create state directory
mkdir -p .claude

# Load PRD
PRD_CONTENT=$(cat "$PRD_FILE")

# Parse PRD using python for reliable JSON handling
parse_prd() {
  python3 -c "
import json
import sys

prd = json.load(sys.stdin)

# Find current/next task
current_task = None
for task in prd.get('tasks', []):
    status = task.get('status', 'pending')
    if status in ['test_creation', 'implementation']:
        current_task = task
        break
    elif status == 'pending' and current_task is None:
        current_task = task

if current_task is None:
    # Check if all complete
    all_done = all(t.get('status') in ['completed', 'failed', 'skipped'] for t in prd.get('tasks', []))
    if all_done:
        print('ALL_COMPLETE')
    else:
        print('NO_TASKS')
    sys.exit(0)

# Output task details
print('TASK_FOUND')
print(json.dumps(current_task))
print(prd.get('project_name', 'Unknown'))

# Calculate progress
total = len(prd.get('tasks', []))
completed = len([t for t in prd.get('tasks', []) if t.get('status') == 'completed'])
print(f'{completed}/{total}')
" <<< "$PRD_CONTENT"
}

# Get task info
TASK_INFO=$(parse_prd)
TASK_STATUS=$(echo "$TASK_INFO" | head -1)

if [[ "$TASK_STATUS" == "ALL_COMPLETE" ]]; then
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "AUTOLOOP v3.0 - ALL TASKS COMPLETE!"
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  echo "All tasks in prd.json have been completed."
  echo ""
  echo "Review the results:"
  echo "  - prd.json: Final task statuses"
  echo "  - autoloop-progress.md: Development timeline"
  echo "  - git log: Commit history"
  echo ""
  exit 0
fi

if [[ "$TASK_STATUS" == "NO_TASKS" ]]; then
  echo "Error: No tasks found in prd.json" >&2
  exit 1
fi

# Parse current task
CURRENT_TASK=$(echo "$TASK_INFO" | sed -n '2p')
PROJECT_NAME=$(echo "$TASK_INFO" | sed -n '3p')
PROGRESS=$(echo "$TASK_INFO" | sed -n '4p')

# Extract task fields
TASK_ID=$(echo "$CURRENT_TASK" | python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))")
TASK_TYPE=$(echo "$CURRENT_TASK" | python3 -c "import json,sys; print(json.load(sys.stdin).get('type',''))")
TASK_DESC=$(echo "$CURRENT_TASK" | python3 -c "import json,sys; print(json.load(sys.stdin).get('description',''))")
TASK_STATUS=$(echo "$CURRENT_TASK" | python3 -c "import json,sys; print(json.load(sys.stdin).get('status','pending'))")
VALIDATION_CMD=$(echo "$CURRENT_TASK" | python3 -c "import json,sys; print(json.load(sys.stdin).get('validation_cmd',''))")
TEST_FILE=$(echo "$CURRENT_TASK" | python3 -c "import json,sys; print(json.load(sys.stdin).get('test_file',''))")
TDD_PHASE=$(echo "$CURRENT_TASK" | python3 -c "import json,sys; print(json.load(sys.stdin).get('tdd_phase',''))")
ATTEMPTS=$(echo "$CURRENT_TASK" | python3 -c "import json,sys; print(json.load(sys.stdin).get('attempts',0))")
MAX_ATTEMPTS=$(echo "$CURRENT_TASK" | python3 -c "import json,sys; print(json.load(sys.stdin).get('max_attempts',3))")

# Determine TDD phase for feature tasks
if [[ "$TASK_TYPE" == "feature" || "$TASK_TYPE" == "bugfix" ]]; then
  if [[ "$TASK_STATUS" == "pending" ]]; then
    TDD_PHASE="red"
    TASK_STATUS="test_creation"
  fi
fi

# Load context
GIT_LOG=$(git log -n 5 --oneline 2>/dev/null || echo "No commits yet")
GIT_DIFF_STAT=$(git diff HEAD~5..HEAD --stat 2>/dev/null || echo "No changes")
PROGRESS_SUMMARY=""
if [[ -f "$PROGRESS_FILE" ]]; then
  PROGRESS_SUMMARY=$(tail -50 "$PROGRESS_FILE")
fi
AGENTS_MD=""
if [[ -f "$AGENTS_FILE" ]]; then
  AGENTS_MD=$(cat "$AGENTS_FILE")
fi

# Check git status
GIT_CLEAN="true"
if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
  GIT_CLEAN="false"
fi

# Get start time and create log file
START_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOG_TIMESTAMP=$(date -u +%Y%m%d-%H%M%S)
LOG_FILE=".claude/autoloop-work-${LOG_TIMESTAMP}.log"

# Create state file
cat > "$STATE_FILE" <<EOF
task_id: "$TASK_ID"
started_at: "$START_TIME"
log_file: "$LOG_FILE"
max_iterations: $MAX_ITERATIONS
iteration: 1
EOF

# Initialize log file
cat > "$LOG_FILE" <<EOF
# Autoloop Worker Log
Started: $START_TIME
Task: $TASK_ID - $TASK_DESC

---

## Iteration 1

EOF

# TDD phase display
TDD_DISPLAY=""
if [[ "$TDD_PHASE" == "red" ]]; then
  TDD_DISPLAY="
┌─────────────────────────────────────────────────────────┐
│  TDD Phase: 🔴 RED - Write Failing Tests                 │
├─────────────────────────────────────────────────────────┤
│  Your goal: Tests must FAIL (exit code != 0)            │
│  Test file: ${TEST_FILE:-tests/test_*.py}                              │
│  DO NOT write implementation yet!                        │
└─────────────────────────────────────────────────────────┘"
elif [[ "$TDD_PHASE" == "green" ]]; then
  TDD_DISPLAY="
┌─────────────────────────────────────────────────────────┐
│  TDD Phase: 🟢 GREEN - Make Tests Pass                   │
├─────────────────────────────────────────────────────────┤
│  Your goal: Tests must PASS (exit code == 0)            │
│  Implement minimum code to pass the tests               │
└─────────────────────────────────────────────────────────┘"
fi

# Output worker prompt
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "AUTOLOOP v3.0 - WORKER (Engineer Mode)"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Project: $PROJECT_NAME"
echo "Progress: $PROGRESS tasks completed"
echo ""
echo "───────────────────────────────────────────────────────────"
echo "CURRENT TASK"
echo "───────────────────────────────────────────────────────────"
echo "ID:          $TASK_ID"
echo "Type:        $TASK_TYPE"
echo "Status:      $TASK_STATUS"
echo "Description: $TASK_DESC"
echo "Validation:  $VALIDATION_CMD"
echo "Attempts:    $ATTEMPTS/$MAX_ATTEMPTS"
if [[ -n "$TDD_DISPLAY" ]]; then
  echo "$TDD_DISPLAY"
fi
echo ""
echo "───────────────────────────────────────────────────────────"
echo "CONTEXT"
echo "───────────────────────────────────────────────────────────"
echo "Git status:  $(if [[ "$GIT_CLEAN" == "true" ]]; then echo "✅ Clean"; else echo "⚠️ Uncommitted changes"; fi)"
echo "Log file:    $LOG_FILE"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
cat <<WORKER_PROMPT
You are the WORKER agent in a two-agent autonomous coding system.

## CRITICAL: <thinking> Block Required

Before ANY action, you MUST output a thinking block:

<thinking>
1. What is the current state?
2. What needs to be done?
3. What command will I use?
4. What could go wrong?
</thinking>

Then execute your planned action.

## Current Task

**ID**: $TASK_ID
**Type**: $TASK_TYPE
**Status**: $TASK_STATUS
**Description**: $TASK_DESC
**Validation**: \`$VALIDATION_CMD\`
**Attempts**: $ATTEMPTS/$MAX_ATTEMPTS
$(if [[ -n "$TEST_FILE" ]]; then echo "**Test File**: $TEST_FILE"; fi)
$(if [[ "$TDD_PHASE" == "red" ]]; then echo "
## TDD Phase: 🔴 RED (Write Failing Tests)

**Your goal**: Write tests that FAIL. The validation command must return exit code != 0.
- Create test file: ${TEST_FILE:-tests/test_*.py}
- Tests should cover the expected behavior
- DO NOT write implementation yet
"; elif [[ "$TDD_PHASE" == "green" ]]; then echo "
## TDD Phase: 🟢 GREEN (Make Tests Pass)

**Your goal**: Write implementation to make tests PASS. The validation command must return exit code == 0.
- Implement the minimum code to pass the tests
- Run: $VALIDATION_CMD
"; fi)

## Context

### Recent Git Log
\`\`\`
$GIT_LOG
\`\`\`

### Recent Changes
\`\`\`
$GIT_DIFF_STAT
\`\`\`

### Progress Summary
$PROGRESS_SUMMARY
$(if [[ -n "$AGENTS_MD" ]]; then echo "
### AGENTS.md (Learnings)
\`\`\`
$AGENTS_MD
\`\`\`"; fi)

### Git Status
$(if [[ "$GIT_CLEAN" == "true" ]]; then echo "✅ Working tree is clean"; else echo "⚠️ Working tree has uncommitted changes"; fi)

## Rules

1. **Always use <thinking> before actions**
2. **Use bash/shell commands for file operations** (echo, sed, cat)
3. **Validate your work** by running: \`$VALIDATION_CMD\`
4. **One task at a time** - focus only on the current task
5. **Git is your safety net** - changes are auto-committed on success

## When Done

When the validation command passes (or fails, for RED phase):
- Output: <task-complete/>

If you're stuck after multiple attempts:
- Output: <task-stuck reason="explanation"/>

Now work on the task. Start with <thinking>:
WORKER_PROMPT
