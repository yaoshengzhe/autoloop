#!/bin/bash
# Cancel the active autoloop

set -uo pipefail

STATE_FILE=".claude/autoloop.local.md"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "No active autoloop found"
  exit 0
fi

# Parse iteration from YAML frontmatter
ITERATION=$(sed -n '/^---$/,/^---$/p' "$STATE_FILE" | grep '^iteration:' | sed 's/iteration: *//')
ACTIVE=$(sed -n '/^---$/,/^---$/p' "$STATE_FILE" | grep '^active:' | sed 's/active: *//')

if [[ "$ACTIVE" != "true" ]]; then
  echo "Autoloop is not active"
  rm -f "$STATE_FILE"
  exit 0
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
