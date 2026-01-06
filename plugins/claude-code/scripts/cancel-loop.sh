#!/bin/bash
# Cancel the active autoloop

set -uo pipefail

STATE_FILE=".claude/autoloop.local.md"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "No active autoloop found"
  exit 0
fi

# Parse YAML frontmatter values
ITERATION=$(sed -n '/^---$/,/^---$/p' "$STATE_FILE" | grep '^iteration:' | sed 's/iteration: *//')
ACTIVE=$(sed -n '/^---$/,/^---$/p' "$STATE_FILE" | grep '^active:' | sed 's/active: *//')
LOG_FILE=$(sed -n '/^---$/,/^---$/p' "$STATE_FILE" | grep '^log_file:' | sed 's/log_file: *//' | sed 's/^"\(.*\)"$/\1/')

if [[ "$ACTIVE" != "true" ]]; then
  echo "Autoloop is not active"
  rm -f "$STATE_FILE"
  exit 0
fi

# Log cancellation
if [[ -n "$LOG_FILE" ]] && [[ -f "$LOG_FILE" ]]; then
  echo "---" >> "$LOG_FILE"
  echo "" >> "$LOG_FILE"
  echo "## Completion" >> "$LOG_FILE"
  echo "Ended: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOG_FILE"
  echo "Status: CANCELLED by user" >> "$LOG_FILE"
  echo "Total iterations: $ITERATION" >> "$LOG_FILE"
  echo "" >> "$LOG_FILE"
fi

# Remove state file
rm -f "$STATE_FILE"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "AUTOLOOP CANCELLED"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Completed $ITERATION iteration(s) before cancellation"
echo "═══════════════════════════════════════════════════════════"
