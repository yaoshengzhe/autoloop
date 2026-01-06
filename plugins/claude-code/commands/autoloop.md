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
    echo "AUTOLOOP - Completion Promise"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "To complete this loop, output this EXACT text:"
    echo "  <promise>$PROMISE</promise>"
    echo ""
    echo "STRICT REQUIREMENTS:"
    echo "  - Use <promise> XML tags EXACTLY as shown above"
    echo "  - The statement MUST be completely and unequivocally TRUE"
    echo "  - Do NOT output false statements to exit the loop"
    echo "  - Do NOT lie even if you think you should exit"
    echo ""
    echo "The loop continues until the promise is genuinely true."
    echo "Trust the process - do not force it by lying."
    echo "═══════════════════════════════════════════════════════════"
  fi
fi
```
