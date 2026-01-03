#!/bin/bash
# Stop hook - intercepts exit and continues loop if active

set -uo pipefail

STATE_FILE=".claude/autoloop.local.md"

# Exit early if no state file
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# Parse YAML frontmatter
parse_yaml_value() {
  local key="$1"
  sed -n '/^---$/,/^---$/p' "$STATE_FILE" | grep "^${key}:" | sed "s/^${key}: *//" | sed 's/^"\(.*\)"$/\1/'
}

ACTIVE=$(parse_yaml_value "active")
ITERATION=$(parse_yaml_value "iteration")
MAX_ITERATIONS=$(parse_yaml_value "max_iterations")
COMPLETION_PROMISE=$(parse_yaml_value "completion_promise")

# Extract prompt (content after frontmatter)
PROMPT=$(sed -n '/^---$/,/^---$/d; p' "$STATE_FILE" | sed '/^$/d')

# Exit if not active
if [[ "$ACTIVE" != "true" ]]; then
  exit 0
fi

# Check for completion promise in transcript
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  if [[ -n "${CLAUDE_TRANSCRIPT:-}" ]]; then
    if echo "$CLAUDE_TRANSCRIPT" | grep -q "<promise>.*${COMPLETION_PROMISE}.*</promise>"; then
      rm -f "$STATE_FILE"
      echo ""
      echo "AUTOLOOP COMPLETE - Promise fulfilled after $ITERATION iteration(s)"
      exit 0
    fi
  fi
fi

# Check iteration limit
NEXT_ITERATION=$((ITERATION + 1))
if [[ "$MAX_ITERATIONS" -gt 0 ]] && [[ "$NEXT_ITERATION" -gt "$MAX_ITERATIONS" ]]; then
  rm -f "$STATE_FILE"
  echo ""
  echo "AUTOLOOP STOPPED - Max iterations ($MAX_ITERATIONS) reached"
  exit 0
fi

# Update state file with new iteration
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  COMPLETION_PROMISE_YAML="\"$COMPLETION_PROMISE\""
else
  COMPLETION_PROMISE_YAML="null"
fi

STARTED_AT=$(parse_yaml_value "started_at")

cat > "$STATE_FILE" <<EOF
---
active: true
iteration: $NEXT_ITERATION
max_iterations: $MAX_ITERATIONS
completion_promise: $COMPLETION_PROMISE_YAML
started_at: "$STARTED_AT"
---

$PROMPT
EOF

# Output continuation message
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "AUTOLOOP ITERATION $NEXT_ITERATION$(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo "/$MAX_ITERATIONS"; fi)"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Continue working on the task. Previous work is preserved."
echo ""
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  echo "To complete: <promise>$COMPLETION_PROMISE</promise>"
  echo ""
fi
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "$PROMPT"

# Block exit
exit 1
