#!/bin/bash
# Setup autoloop - parse arguments and initialize loop state

set -e

PROMPT=""
COMPLETION_PROMISE=""
MAX_ITERATIONS=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --completion-promise)
      COMPLETION_PROMISE="$2"
      shift 2
      ;;
    --max-iterations)
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    *)
      if [ -z "$PROMPT" ]; then
        PROMPT="$1"
      else
        PROMPT="$PROMPT $1"
      fi
      shift
      ;;
  esac
done

# Validate prompt
if [ -z "$PROMPT" ]; then
  echo "Error: No prompt provided"
  echo "Usage: /autoloop \"<prompt>\" --completion-promise \"<text>\" [--max-iterations <n>]"
  exit 1
fi

# Ensure .claude directory exists
mkdir -p .claude

# Create state file
STATE_FILE=".claude/autoloop.state.json"
LOCAL_MD=".claude/autoloop.local.md"

cat > "$STATE_FILE" << EOF
{
  "prompt": $(echo "$PROMPT" | jq -Rs .),
  "completionPromise": $(echo "$COMPLETION_PROMISE" | jq -Rs . | sed 's/^""$/null/' | sed 's/^"\\n"$/null/'),
  "maxIterations": ${MAX_ITERATIONS:-null},
  "currentIteration": 0,
  "startTime": $(date +%s)000,
  "active": true
}
EOF

# Create human-readable local.md
cat > "$LOCAL_MD" << EOF
# Autoloop State

active: true
iteration: 0${MAX_ITERATIONS:+/$MAX_ITERATIONS}
completion_promise: ${COMPLETION_PROMISE:+"$COMPLETION_PROMISE"}${COMPLETION_PROMISE:-null}
started: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Prompt

$PROMPT
EOF

echo "Autoloop initialized successfully"
echo "Iteration: 0${MAX_ITERATIONS:+/$MAX_ITERATIONS}"
