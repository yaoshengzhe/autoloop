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
# Find the line number of the closing --- of YAML frontmatter (second occurrence)
FRONTMATTER_END=$(awk '/^---$/ { count++; if (count == 2) { print NR; exit } }' "$STATE_FILE")
# Get everything after the frontmatter, preserving internal --- separators
# Trim leading blank lines to prevent accumulation across iterations
PROMPT=$(tail -n +$((FRONTMATTER_END + 1)) "$STATE_FILE" | sed '/./,$!d')

# Exit if not active
if [[ "$ACTIVE" != "true" ]]; then
  exit 0
fi

# Check for completion promise in transcript
# Use grep -F for fixed string matching to prevent regex injection
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  if [[ -n "${CLAUDE_TRANSCRIPT:-}" ]]; then
    if echo "$CLAUDE_TRANSCRIPT" | grep -qF "<promise>${COMPLETION_PROMISE}</promise>"; then
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

# Calculate elapsed time for progress log
STARTED_AT=$(parse_yaml_value "started_at")
ELAPSED_STR="unknown"
if [[ -n "$STARTED_AT" ]]; then
  START_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$STARTED_AT" "+%s" 2>/dev/null || date -d "$STARTED_AT" "+%s" 2>/dev/null || echo "0")
  if [[ "$START_EPOCH" != "0" ]]; then
    NOW_EPOCH=$(date "+%s")
    ELAPSED=$((NOW_EPOCH - START_EPOCH))
    ELAPSED_MIN=$((ELAPSED / 60))
    ELAPSED_SEC=$((ELAPSED % 60))
    ELAPSED_STR="${ELAPSED_MIN}m ${ELAPSED_SEC}s"
  fi
fi

# Output continuation message with progress log
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "AUTOLOOP - Iteration $NEXT_ITERATION$(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo " of $MAX_ITERATIONS"; fi)"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Progress:"
echo "  • Iteration:     $ITERATION → $NEXT_ITERATION"
echo "  • Elapsed time:  $ELAPSED_STR"
echo "  • Status:        Active - continuing work"
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
