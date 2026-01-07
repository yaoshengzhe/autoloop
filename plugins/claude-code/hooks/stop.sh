#!/bin/bash
# Stop hook - intercepts exit and continues loop if active
# Uses independent subagent verification for quality control

set -uo pipefail

STATE_FILE=".claude/autoloop.local.md"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_SCRIPT="$SCRIPT_DIR/../scripts/verify-completion.sh"

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
LOG_FILE=$(parse_yaml_value "log_file")

# Helper function to append to log file
log_append() {
  if [[ -n "$LOG_FILE" ]] && [[ -f "$LOG_FILE" ]]; then
    echo "$1" >> "$LOG_FILE"
  fi
}

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

# Log transcript for this iteration
if [[ -n "${CLAUDE_TRANSCRIPT:-}" ]]; then
  log_append "### Transcript"
  log_append ""
  log_append "\`\`\`"
  log_append "$CLAUDE_TRANSCRIPT"
  log_append "\`\`\`"
  log_append ""
fi

# Check if Claude claimed completion with <complete/> tag
# This is a simple signal - actual verification is done by subagent
CLAIMED_COMPLETE=false
if [[ -n "${CLAUDE_TRANSCRIPT:-}" ]]; then
  if echo "$CLAUDE_TRANSCRIPT" | grep -qF "<complete/>"; then
    CLAIMED_COMPLETE=true
  fi
fi

# If completion claimed, run independent subagent verification
if [[ "$CLAIMED_COMPLETE" == "true" ]]; then
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "AUTOLOOP - Completion Claimed"
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  echo "Running independent verification agent..."
  echo "(This agent has no context of our conversation)"
  echo ""

  log_append "### Independent Verification"
  log_append "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  log_append ""

  # Run verification script
  if [[ -x "$VERIFY_SCRIPT" ]]; then
    VERIFY_OUTPUT=$("$VERIFY_SCRIPT" 2>&1)
    VERIFY_EXIT=$?

    log_append "\`\`\`"
    log_append "$VERIFY_OUTPUT"
    log_append "\`\`\`"
    log_append ""

    echo "$VERIFY_OUTPUT"

    if [[ $VERIFY_EXIT -eq 0 ]]; then
      # Verification passed
      log_append "---"
      log_append ""
      log_append "## Completion"
      log_append "Ended: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
      log_append "Status: SUCCESS - Independent verification passed"
      log_append "Total iterations: $ITERATION"
      log_append ""

      rm -f "$STATE_FILE"
      echo ""
      echo "═══════════════════════════════════════════════════════════"
      echo "AUTOLOOP COMPLETE - Verified by independent agent"
      echo "═══════════════════════════════════════════════════════════"
      echo ""
      echo "  ✓ Independent verification PASSED"
      echo "  ✓ Completed after $ITERATION iteration(s)"
      echo ""
      echo "═══════════════════════════════════════════════════════════"
      exit 0
    else
      # Verification failed
      log_append "### Verification Failed"
      log_append "Continue working to address issues."
      log_append ""

      echo ""
      echo "═══════════════════════════════════════════════════════════"
      echo "AUTOLOOP - Verification FAILED"
      echo "═══════════════════════════════════════════════════════════"
      echo ""
      echo "The independent verifier found issues."
      echo "Review the verification output above and continue working."
      echo ""
      echo "═══════════════════════════════════════════════════════════"
      # Continue loop - don't exit 0
    fi
  else
    echo "ERROR: Verification script not found or not executable"
    echo "Path: $VERIFY_SCRIPT"
    log_append "ERROR: Verification script not found"
    # Continue loop on error
  fi
fi

# Check iteration limit
NEXT_ITERATION=$((ITERATION + 1))
if [[ "$MAX_ITERATIONS" -gt 0 ]] && [[ "$NEXT_ITERATION" -gt "$MAX_ITERATIONS" ]]; then
  # Log max iterations reached
  log_append "---"
  log_append ""
  log_append "## Completion"
  log_append "Ended: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  log_append "Status: STOPPED - Max iterations ($MAX_ITERATIONS) reached"
  log_append "Total iterations: $ITERATION"
  log_append ""
  rm -f "$STATE_FILE"
  echo ""
  echo "AUTOLOOP STOPPED - Max iterations ($MAX_ITERATIONS) reached"
  exit 0
fi

# Update state file with new iteration
STARTED_AT=$(parse_yaml_value "started_at")

cat > "$STATE_FILE" <<EOF
---
active: true
iteration: $NEXT_ITERATION
max_iterations: $MAX_ITERATIONS
started_at: "$STARTED_AT"
log_file: "$LOG_FILE"
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

# Log next iteration header
log_append "---"
log_append ""
log_append "## Iteration $NEXT_ITERATION"
log_append "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
log_append "Elapsed: $ELAPSED_STR"
log_append ""

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
echo "───────────────────────────────────────────────────────────"
echo "TO SIGNAL COMPLETION:"
echo ""
echo "When you believe the task is complete, output: <complete/>"
echo ""
echo "An independent verification agent will then:"
echo "  • Run tests, build, and lint"
echo "  • Check all task requirements are met"
echo "  • Approve or reject with specific feedback"
echo ""
echo "Note: The verifier has NO access to our conversation."
echo "It only sees the task description and actual code/files."
echo "───────────────────────────────────────────────────────────"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "$PROMPT"

# Block exit
exit 1
