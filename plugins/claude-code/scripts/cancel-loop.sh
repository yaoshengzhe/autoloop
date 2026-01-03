#!/bin/bash
# Cancel the active autoloop

STATE_FILE=".claude/autoloop.state.json"
LOCAL_MD=".claude/autoloop.local.md"

if [ ! -f "$STATE_FILE" ]; then
  echo "No active autoloop found"
  exit 0
fi

# Check if already inactive
ACTIVE=$(jq -r '.active' "$STATE_FILE" 2>/dev/null || echo "false")
if [ "$ACTIVE" != "true" ]; then
  echo "Autoloop is not active"
  rm -f "$STATE_FILE" "$LOCAL_MD"
  exit 0
fi

# Get current iteration for summary
ITERATION=$(jq -r '.currentIteration' "$STATE_FILE" 2>/dev/null || echo "0")

# Remove state files
rm -f "$STATE_FILE" "$LOCAL_MD"

echo "═══════════════════════════════════════════════════════════"
echo "AUTOLOOP CANCELLED"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Completed $ITERATION iteration(s) before cancellation"
echo "═══════════════════════════════════════════════════════════"
