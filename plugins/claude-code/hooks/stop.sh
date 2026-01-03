#!/bin/bash
# Stop hook - intercepts session exit and continues the loop if active

STATE_FILE=".claude/autoloop.state.json"

# Exit early if no state file
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Read state
STATE=$(cat "$STATE_FILE")
ACTIVE=$(echo "$STATE" | jq -r '.active')
PROMPT=$(echo "$STATE" | jq -r '.prompt')
COMPLETION_PROMISE=$(echo "$STATE" | jq -r '.completionPromise // empty')
MAX_ITERATIONS=$(echo "$STATE" | jq -r '.maxIterations // empty')
CURRENT_ITERATION=$(echo "$STATE" | jq -r '.currentIteration')

# Exit if not active
if [ "$ACTIVE" != "true" ]; then
  exit 0
fi

# Check for completion promise in transcript (passed via stdin or env)
if [ -n "$COMPLETION_PROMISE" ] && [ -n "$CLAUDE_TRANSCRIPT" ]; then
  if echo "$CLAUDE_TRANSCRIPT" | grep -q "<promise>.*$COMPLETION_PROMISE.*</promise>"; then
    # Promise found - allow exit and clean up
    rm -f "$STATE_FILE" ".claude/autoloop.local.md"
    echo "═══════════════════════════════════════════════════════════"
    echo "AUTOLOOP COMPLETE"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Promise fulfilled after $CURRENT_ITERATION iteration(s)"
    echo "═══════════════════════════════════════════════════════════"
    exit 0
  fi
fi

# Check iteration limit
NEXT_ITERATION=$((CURRENT_ITERATION + 1))
if [ -n "$MAX_ITERATIONS" ] && [ "$NEXT_ITERATION" -ge "$MAX_ITERATIONS" ]; then
  # Max iterations reached - allow exit and clean up
  rm -f "$STATE_FILE" ".claude/autoloop.local.md"
  echo "═══════════════════════════════════════════════════════════"
  echo "AUTOLOOP STOPPED - Max iterations reached"
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  echo "Completed $MAX_ITERATIONS iteration(s)"
  echo "═══════════════════════════════════════════════════════════"
  exit 0
fi

# Update iteration count
jq ".currentIteration = $NEXT_ITERATION" "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"

# Update local.md
cat > ".claude/autoloop.local.md" << EOF
# Autoloop State

active: true
iteration: $NEXT_ITERATION${MAX_ITERATIONS:+/$MAX_ITERATIONS}
completion_promise: ${COMPLETION_PROMISE:+"$COMPLETION_PROMISE"}${COMPLETION_PROMISE:-null}
started: $(echo "$STATE" | jq -r '.startTime' | xargs -I {} date -r $(({}/1000)) -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")

## Prompt

$PROMPT
EOF

# Block exit and output continuation message
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "AUTOLOOP ITERATION $NEXT_ITERATION${MAX_ITERATIONS:+/$MAX_ITERATIONS}"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Continue working on the task. Your previous work is preserved."
echo ""
if [ -n "$COMPLETION_PROMISE" ]; then
  echo "To complete: <promise>$COMPLETION_PROMISE</promise>"
  echo ""
fi
echo "═══════════════════════════════════════════════════════════"

# Output the prompt for Claude to continue
echo ""
echo "## Task"
echo ""
echo "$PROMPT"

# Block the exit by returning non-zero (Claude Code convention)
exit 1
