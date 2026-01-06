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

# Check for completion promise in transcript with quality gate validation
# Use grep -F for fixed string matching to prevent regex injection
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  if [[ -n "${CLAUDE_TRANSCRIPT:-}" ]]; then
    if echo "$CLAUDE_TRANSCRIPT" | grep -qF "<promise>${COMPLETION_PROMISE}</promise>"; then
      # Quality gate: Check for completion report
      HAS_REPORT=false
      HAS_TESTS=false
      HAS_BUILD=false
      HAS_LINT=false
      HAS_CHECKLIST=false
      HAS_SUMMARY=false

      if echo "$CLAUDE_TRANSCRIPT" | grep -q "<completion-report>"; then
        HAS_REPORT=true
      fi
      if echo "$CLAUDE_TRANSCRIPT" | grep -qE "<tests>(PASS|SKIP)"; then
        HAS_TESTS=true
      fi
      if echo "$CLAUDE_TRANSCRIPT" | grep -qE "<build>(PASS|SKIP)"; then
        HAS_BUILD=true
      fi
      if echo "$CLAUDE_TRANSCRIPT" | grep -qE "<lint>(PASS|SKIP)"; then
        HAS_LINT=true
      fi
      if echo "$CLAUDE_TRANSCRIPT" | grep -q "<task-checklist>"; then
        HAS_CHECKLIST=true
      fi
      if echo "$CLAUDE_TRANSCRIPT" | grep -q "<summary>"; then
        HAS_SUMMARY=true
      fi

      # Check if any verification reported FAIL
      HAS_FAILURE=false
      if echo "$CLAUDE_TRANSCRIPT" | grep -qE "<tests>FAIL|<build>FAIL|<lint>FAIL"; then
        HAS_FAILURE=true
      fi

      # Validate completion report
      if [[ "$HAS_REPORT" == "true" ]] && [[ "$HAS_TESTS" == "true" ]] && \
         [[ "$HAS_BUILD" == "true" ]] && [[ "$HAS_LINT" == "true" ]] && \
         [[ "$HAS_CHECKLIST" == "true" ]] && [[ "$HAS_SUMMARY" == "true" ]] && \
         [[ "$HAS_FAILURE" == "false" ]]; then
        rm -f "$STATE_FILE"
        echo ""
        echo "═══════════════════════════════════════════════════════════"
        echo "AUTOLOOP COMPLETE - Quality gates passed"
        echo "═══════════════════════════════════════════════════════════"
        echo ""
        echo "  ✓ Completion report validated"
        echo "  ✓ All verification checks passed"
        echo "  ✓ Promise fulfilled after $ITERATION iteration(s)"
        echo ""
        echo "═══════════════════════════════════════════════════════════"
        exit 0
      else
        # Promise found but quality gates not met
        echo ""
        echo "═══════════════════════════════════════════════════════════"
        echo "AUTOLOOP - Completion REJECTED"
        echo "═══════════════════════════════════════════════════════════"
        echo ""
        echo "Promise was output but quality gates not satisfied:"
        echo ""
        if [[ "$HAS_REPORT" != "true" ]]; then
          echo "  ✗ Missing <completion-report> wrapper"
        fi
        if [[ "$HAS_TESTS" != "true" ]]; then
          echo "  ✗ Missing or failed <tests> verification"
        fi
        if [[ "$HAS_BUILD" != "true" ]]; then
          echo "  ✗ Missing or failed <build> verification"
        fi
        if [[ "$HAS_LINT" != "true" ]]; then
          echo "  ✗ Missing or failed <lint> verification"
        fi
        if [[ "$HAS_CHECKLIST" != "true" ]]; then
          echo "  ✗ Missing <task-checklist>"
        fi
        if [[ "$HAS_SUMMARY" != "true" ]]; then
          echo "  ✗ Missing <summary>"
        fi
        if [[ "$HAS_FAILURE" == "true" ]]; then
          echo "  ✗ One or more checks reported FAIL"
        fi
        echo ""
        echo "Continue working until ALL quality gates pass."
        echo "═══════════════════════════════════════════════════════════"
        # Continue the loop - don't exit 0
      fi
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
  echo "───────────────────────────────────────────────────────────"
  echo "COMPLETION REQUIREMENTS:"
  echo ""
  echo "Before claiming completion, you MUST:"
  echo "  1. Run tests (or confirm no tests exist)"
  echo "  2. Run build (or confirm no build step)"
  echo "  3. Run lint (or confirm no linter)"
  echo "  4. Verify ALL task requirements are met"
  echo "  5. Provide completion report with evidence"
  echo ""
  echo "Format:"
  echo "  <completion-report>"
  echo "    <tests>PASS/SKIP - [output]</tests>"
  echo "    <build>PASS/SKIP - [output]</build>"
  echo "    <lint>PASS/SKIP - [output]</lint>"
  echo "    <task-checklist>- [x] each requirement</task-checklist>"
  echo "    <summary>Work done</summary>"
  echo "  </completion-report>"
  echo "  <promise>$COMPLETION_PROMISE</promise>"
  echo "───────────────────────────────────────────────────────────"
  echo ""
fi
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "$PROMPT"

# Block exit
exit 1
