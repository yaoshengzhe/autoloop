# /autoloop

Start an autonomous iterative loop that continues until completion criteria are met.

**IMPORTANT**: If the script output below shows `[AUTOLOOP_HELP_SHOWN]`, just display the help message to the user without reading any files or taking other actions.

---

```bash
# Show help if no arguments provided
if [ -z "$ARGUMENTS" ] || [ "$ARGUMENTS" = "-h" ] || [ "$ARGUMENTS" = "--help" ]; then
  echo "[AUTOLOOP_HELP_SHOWN]"
  cat <<'HELP'
Autoloop - Autonomous iterative loop for Claude Code

USAGE:
  /autoloop <task> [OPTIONS]

OPTIONS:
  --max-iterations <n>        Maximum iterations before auto-stop (default: unlimited)
  --completion-promise <text> Promise phrase that signals completion
  -h, --help                  Show this help message

DESCRIPTION:
  Starts an autonomous loop that keeps working until completion. The stop hook
  prevents exit and feeds the prompt back, allowing iterative improvement.

  To signal completion, output: <promise>YOUR_PHRASE</promise>

EXAMPLES:
  /autoloop Build a REST API --completion-promise 'DONE' --max-iterations 20
  /autoloop Fix the auth bug --max-iterations 10
  /autoloop "Refactor cache layer" --completion-promise 'ALL TESTS PASS'

COMMON PROMPT FILE:
  Create .claude/autoloop-prompt.md with common instructions that apply to all loops.
  This content is automatically prepended to every loop prompt.

STOPPING THE LOOP:
  - Reaching --max-iterations limit
  - Outputting <promise>COMPLETION_TEXT</promise>
  - Running /autoloop:cancel-autoloop

OTHER COMMANDS:
  /autoloop:autoloop-status   Check current loop progress
  /autoloop:cancel-autoloop   Stop the active loop
HELP
  exit 0
fi

"$PLUGIN_DIR/scripts/setup-loop.sh" $ARGUMENTS

if [ -f .claude/autoloop.local.md ]; then
  PROMISE=$(sed -n '/^---$/,/^---$/p' .claude/autoloop.local.md | grep '^completion_promise:' | sed 's/completion_promise: *//' | sed 's/^"\(.*\)"$/\1/')
  if [ -n "$PROMISE" ] && [ "$PROMISE" != "null" ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "AUTOLOOP - Quality-Gated Completion Protocol"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "COMPLETION PROMISE: $PROMISE"
    echo ""
    echo "Before outputting <promise>$PROMISE</promise>, you MUST:"
    echo ""
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│  MANDATORY VERIFICATION CHECKLIST                       │"
    echo "├─────────────────────────────────────────────────────────┤"
    echo "│  □ 1. RUN TESTS   - Execute test suite, all must pass   │"
    echo "│  □ 2. RUN BUILD   - Build/compile succeeds without error│"
    echo "│  □ 3. RUN LINT    - No lint errors (warnings OK)        │"
    echo "│  □ 4. VERIFY TASK - Re-read original task requirements  │"
    echo "│  □ 5. SELF-REVIEW - Review changes for completeness     │"
    echo "└─────────────────────────────────────────────────────────┘"
    echo ""
    echo "COMPLETION FORMAT (all fields required):"
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│  <completion-report>                                    │"
    echo "│    <tests>PASS/FAIL/SKIP - [evidence]</tests>           │"
    echo "│    <build>PASS/FAIL/SKIP - [evidence]</build>           │"
    echo "│    <lint>PASS/FAIL/SKIP - [evidence]</lint>             │"
    echo "│    <task-checklist>                                     │"
    echo "│      - [x] requirement 1                                │"
    echo "│      - [x] requirement 2                                │"
    echo "│    </task-checklist>                                    │"
    echo "│    <summary>Brief description of work done</summary>    │"
    echo "│  </completion-report>                                   │"
    echo "│  <promise>$PROMISE</promise>                            │"
    echo "└─────────────────────────────────────────────────────────┘"
    echo ""
    echo "CRITICAL RULES:"
    echo "  • SKIP is only valid if project has no tests/build/lint"
    echo "  • FAIL in any check = continue working, DO NOT complete"
    echo "  • Provide ACTUAL command output as evidence"
    echo "  • Task checklist must cover ALL original requirements"
    echo "  • Promise without completion-report will be REJECTED"
    echo ""
    echo "The loop continues until ALL checks pass."
    echo "═══════════════════════════════════════════════════════════"
  fi
fi
```
