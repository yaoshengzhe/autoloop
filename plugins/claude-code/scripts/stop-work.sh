#!/bin/bash
# Autoloop v3.0 - Worker Stop Hook
# Handles task completion, TDD phase advancement, auto-commits, and loop continuation

set -uo pipefail

PRD_FILE="prd.json"
PROGRESS_FILE="autoloop-progress.md"
STATE_FILE=".claude/autoloop-worker.state"

# Exit early if no state file (not in worker mode)
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# Parse state file
parse_state_value() {
  local key="$1"
  grep "^${key}:" "$STATE_FILE" | sed "s/^${key}: *//" | sed 's/^"\(.*\)"$/\1/'
}

TASK_ID=$(parse_state_value "task_id")
LOG_FILE=$(parse_state_value "log_file")
MAX_ITERATIONS=$(parse_state_value "max_iterations")
ITERATION=$(parse_state_value "iteration")

# Helper function to append to log file
log_append() {
  if [[ -n "$LOG_FILE" ]] && [[ -f "$LOG_FILE" ]]; then
    echo "$1" >> "$LOG_FILE"
  fi
}

# Helper function to append to progress file
progress_append() {
  if [[ -f "$PROGRESS_FILE" ]]; then
    echo "" >> "$PROGRESS_FILE"
    echo "### $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$PROGRESS_FILE"
    echo "$1" >> "$PROGRESS_FILE"
  fi
}

# Log transcript for this iteration
if [[ -n "${CLAUDE_TRANSCRIPT:-}" ]]; then
  log_append "### Transcript"
  log_append ""
  log_append "\`\`\`"
  log_append "$CLAUDE_TRANSCRIPT"
  log_append "\`\`\`"
  log_append ""
fi

# Check for completion/stuck signals
TASK_COMPLETE=false
TASK_STUCK=false
STUCK_REASON=""

if [[ -n "${CLAUDE_TRANSCRIPT:-}" ]]; then
  if echo "$CLAUDE_TRANSCRIPT" | grep -qF "<task-complete/>"; then
    TASK_COMPLETE=true
  fi
  if echo "$CLAUDE_TRANSCRIPT" | grep -qE "<task-stuck"; then
    TASK_STUCK=true
    STUCK_REASON=$(echo "$CLAUDE_TRANSCRIPT" | grep -oE 'reason="[^"]*"' | head -1 | sed 's/reason="\(.*\)"/\1/')
  fi
fi

# Load and parse PRD
if [[ ! -f "$PRD_FILE" ]]; then
  echo "Error: prd.json not found" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Use python for reliable JSON handling
update_prd() {
  local action="$1"
  local reason="${2:-}"

  python3 << PYTHON_EOF
import json
import subprocess
from datetime import datetime

with open('$PRD_FILE', 'r') as f:
    prd = json.load(f)

# Find current task
current_task = None
task_index = -1
for i, task in enumerate(prd.get('tasks', [])):
    if task.get('id') == '$TASK_ID':
        current_task = task
        task_index = i
        break

if current_task is None:
    print("TASK_NOT_FOUND")
    exit(1)

action = '$action'
reason = '$reason'

task_type = current_task.get('type', '')
status = current_task.get('status', 'pending')
tdd_phase = current_task.get('tdd_phase')
validation_cmd = current_task.get('validation_cmd', '')
attempts = current_task.get('attempts', 0)
max_attempts = current_task.get('max_attempts', 3)

# Determine if task requires TDD
requires_tdd = task_type in ['feature', 'bugfix']

if action == 'complete':
    # Run validation
    validation_passed = True
    validation_output = ""
    if validation_cmd:
        try:
            result = subprocess.run(validation_cmd, shell=True, capture_output=True, text=True, timeout=120)
            validation_output = result.stdout + result.stderr
            validation_passed = (result.returncode == 0)
        except Exception as e:
            validation_output = str(e)
            validation_passed = False

    # TDD phase verification
    if requires_tdd and status in ['pending', 'test_creation']:
        # RED phase: tests should FAIL
        if tdd_phase == 'red' or status == 'test_creation':
            if not validation_passed:
                # Tests fail as expected - advance to GREEN
                current_task['status'] = 'implementation'
                current_task['tdd_phase'] = 'green'
                print("PHASE_ADVANCED:red_to_green")
            else:
                # Tests pass but should fail - stay in RED
                current_task['attempts'] = attempts + 1
                if 'error_log' not in current_task:
                    current_task['error_log'] = []
                current_task['error_log'].append({
                    'attempt': current_task['attempts'],
                    'timestamp': datetime.utcnow().isoformat() + 'Z',
                    'error': 'RED phase: Tests should FAIL but they passed'
                })
                print("RED_PHASE_FAILED:tests_should_fail")
    elif requires_tdd and status == 'implementation':
        # GREEN phase: tests should PASS
        if tdd_phase == 'green' or status == 'implementation':
            if validation_passed:
                # Tests pass - task complete!
                current_task['status'] = 'completed'
                current_task['completed_at'] = datetime.utcnow().isoformat() + 'Z'

                # Auto-commit
                try:
                    subprocess.run(['git', 'add', '-A'], check=True, capture_output=True)
                    commit_msg = f"feat({current_task['id']}): {current_task['description'][:50]}"
                    result = subprocess.run(['git', 'commit', '-m', commit_msg], capture_output=True, text=True)
                    if result.returncode == 0:
                        sha = subprocess.run(['git', 'rev-parse', 'HEAD'], capture_output=True, text=True)
                        current_task['commit_sha'] = sha.stdout.strip()
                except Exception as e:
                    pass

                print(f"TASK_COMPLETED:{current_task.get('commit_sha', 'no-commit')}")
            else:
                # Tests fail - retry
                current_task['attempts'] = attempts + 1
                if 'error_log' not in current_task:
                    current_task['error_log'] = []
                current_task['error_log'].append({
                    'attempt': current_task['attempts'],
                    'timestamp': datetime.utcnow().isoformat() + 'Z',
                    'error': validation_output[:500]
                })
                print(f"GREEN_PHASE_FAILED:{current_task['attempts']}/{max_attempts}")
    else:
        # Non-TDD task
        if validation_passed:
            current_task['status'] = 'completed'
            current_task['completed_at'] = datetime.utcnow().isoformat() + 'Z'

            # Auto-commit
            try:
                subprocess.run(['git', 'add', '-A'], check=True, capture_output=True)
                task_type_prefix = current_task.get('type', 'feat')
                if task_type_prefix == 'setup':
                    task_type_prefix = 'chore'
                commit_msg = f"{task_type_prefix}({current_task['id']}): {current_task['description'][:50]}"
                result = subprocess.run(['git', 'commit', '-m', commit_msg], capture_output=True, text=True)
                if result.returncode == 0:
                    sha = subprocess.run(['git', 'rev-parse', 'HEAD'], capture_output=True, text=True)
                    current_task['commit_sha'] = sha.stdout.strip()
            except Exception as e:
                pass

            print(f"TASK_COMPLETED:{current_task.get('commit_sha', 'no-commit')}")
        else:
            current_task['attempts'] = attempts + 1
            if 'error_log' not in current_task:
                current_task['error_log'] = []
            current_task['error_log'].append({
                'attempt': current_task['attempts'],
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'error': validation_output[:500]
            })
            print(f"VALIDATION_FAILED:{current_task['attempts']}/{max_attempts}")

elif action == 'stuck':
    current_task['attempts'] = attempts + 1
    if 'error_log' not in current_task:
        current_task['error_log'] = []
    current_task['error_log'].append({
        'attempt': current_task['attempts'],
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'error': f'Task stuck: {reason}'
    })
    print(f"TASK_STUCK:{current_task['attempts']}/{max_attempts}")

# Check if max attempts reached
if current_task.get('attempts', 0) >= max_attempts and current_task.get('status') not in ['completed', 'failed']:
    current_task['status'] = 'failed'
    # Git reset on failure
    try:
        subprocess.run(['git', 'reset', '--hard', 'HEAD'], check=True, capture_output=True)
        subprocess.run(['git', 'clean', '-fd'], check=True, capture_output=True)
    except:
        pass
    print("MAX_ATTEMPTS_REACHED:git_reset")

# Update PRD
prd['tasks'][task_index] = current_task
prd['updated_at'] = datetime.utcnow().isoformat() + 'Z'

with open('$PRD_FILE', 'w') as f:
    json.dump(prd, f, indent=2)

PYTHON_EOF
}

# Handle completion signal
if [[ "$TASK_COMPLETE" == "true" ]]; then
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "AUTOLOOP - Task Completion Claimed"
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  echo "Running validation..."

  RESULT=$(update_prd "complete")

  log_append "### Task Completion"
  log_append "Result: $RESULT"
  log_append ""

  if [[ "$RESULT" == TASK_COMPLETED:* ]]; then
    COMMIT_SHA=$(echo "$RESULT" | cut -d: -f2)
    echo ""
    echo "✅ Task $TASK_ID completed successfully!"
    echo "   Commit: $COMMIT_SHA"
    echo ""
    progress_append "- ✅ Completed $TASK_ID"

    # Check if all tasks done
    ALL_DONE=$(python3 -c "
import json
with open('$PRD_FILE') as f:
    prd = json.load(f)
all_done = all(t.get('status') in ['completed', 'failed', 'skipped'] for t in prd.get('tasks', []))
print('true' if all_done else 'false')
")

    if [[ "$ALL_DONE" == "true" ]]; then
      echo "═══════════════════════════════════════════════════════════"
      echo "🎉 ALL TASKS COMPLETE!"
      echo "═══════════════════════════════════════════════════════════"
      rm -f "$STATE_FILE"
      log_append "## Completion"
      log_append "All tasks completed!"
      exit 0
    fi

    # Continue to next task
    rm -f "$STATE_FILE"
    echo ""
    echo "Moving to next task..."
    echo "Run /autoloop:work to continue"
    exit 0

  elif [[ "$RESULT" == PHASE_ADVANCED:* ]]; then
    echo ""
    echo "🔄 TDD Phase Advanced: RED → GREEN"
    echo "   Tests are failing as expected."
    echo "   Now implement the code to make them pass."
    echo ""
    progress_append "- 🔄 $TASK_ID: Advanced from RED to GREEN phase"

  elif [[ "$RESULT" == RED_PHASE_FAILED:* ]]; then
    echo ""
    echo "⚠️ RED Phase: Tests should FAIL but they passed!"
    echo "   Write tests that verify the expected behavior."
    echo "   Tests must fail before implementation."
    echo ""

  elif [[ "$RESULT" == GREEN_PHASE_FAILED:* ]]; then
    ATTEMPT_INFO=$(echo "$RESULT" | cut -d: -f2)
    echo ""
    echo "⚠️ GREEN Phase: Tests still failing"
    echo "   Attempts: $ATTEMPT_INFO"
    echo "   Review the test output and fix the implementation."
    echo ""

  elif [[ "$RESULT" == VALIDATION_FAILED:* ]]; then
    ATTEMPT_INFO=$(echo "$RESULT" | cut -d: -f2)
    echo ""
    echo "⚠️ Validation Failed"
    echo "   Attempts: $ATTEMPT_INFO"
    echo "   Review the output and try again."
    echo ""

  elif [[ "$RESULT" == MAX_ATTEMPTS_REACHED:* ]]; then
    echo ""
    echo "❌ MAX ATTEMPTS REACHED - Task Failed"
    echo "   Working tree has been reset to last commit."
    echo "   The task has been marked as failed."
    echo ""
    progress_append "- ❌ FAILED $TASK_ID after max attempts (git reset performed)"
    rm -f "$STATE_FILE"
    exit 0
  fi
fi

# Handle stuck signal
if [[ "$TASK_STUCK" == "true" ]]; then
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "AUTOLOOP - Task Stuck"
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  echo "Reason: $STUCK_REASON"

  RESULT=$(update_prd "stuck" "$STUCK_REASON")

  log_append "### Task Stuck"
  log_append "Reason: $STUCK_REASON"
  log_append "Result: $RESULT"
  log_append ""

  if [[ "$RESULT" == MAX_ATTEMPTS_REACHED:* ]]; then
    echo ""
    echo "❌ MAX ATTEMPTS REACHED - Task Failed"
    echo "   Working tree has been reset."
    echo ""
    progress_append "- ❌ FAILED $TASK_ID: $STUCK_REASON"
    rm -f "$STATE_FILE"
    exit 0
  fi

  echo ""
  echo "Attempt recorded. Continue working on the task."
  echo ""
fi

# Check iteration limit
NEXT_ITERATION=$((ITERATION + 1))
if [[ "$MAX_ITERATIONS" -gt 0 ]] && [[ "$NEXT_ITERATION" -gt "$MAX_ITERATIONS" ]]; then
  log_append "## Stopped"
  log_append "Max iterations ($MAX_ITERATIONS) reached"
  rm -f "$STATE_FILE"
  echo ""
  echo "AUTOLOOP STOPPED - Max iterations ($MAX_ITERATIONS) reached"
  exit 0
fi

# Update state file for next iteration
STARTED_AT=$(parse_state_value "started_at")
cat > "$STATE_FILE" <<EOF
task_id: "$TASK_ID"
started_at: "$STARTED_AT"
log_file: "$LOG_FILE"
max_iterations: $MAX_ITERATIONS
iteration: $NEXT_ITERATION
EOF

log_append "---"
log_append ""
log_append "## Iteration $NEXT_ITERATION"
log_append ""

# Continue loop
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "AUTOLOOP - Iteration $NEXT_ITERATION"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Continue working on task $TASK_ID"
echo ""
echo "Remember:"
echo "  - Use <thinking> blocks before actions"
echo "  - Run validation: Check your validation command"
echo "  - Signal completion: <task-complete/>"
echo ""
echo "═══════════════════════════════════════════════════════════"

# Block exit to continue loop
exit 1
