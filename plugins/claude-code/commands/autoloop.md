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
  --max-iterations <n>  Maximum iterations before auto-stop (default: unlimited)
  -h, --help            Show this help message

DESCRIPTION:
  Starts an autonomous loop that keeps working until completion. Uses
  independent subagent verification for rigorous quality control.

  To signal completion, output: <complete/>

  An independent verification agent (with NO access to the conversation)
  will then check tests, build, lint, and task requirements.

EXAMPLES:
  /autoloop Build a REST API --max-iterations 20
  /autoloop Fix the auth bug --max-iterations 10
  /autoloop "Refactor cache layer"

COMMON PROMPT FILE:
  Create .claude/autoloop-prompt.md with common instructions that apply to all loops.
  This content is automatically prepended to every loop prompt.

STOPPING THE LOOP:
  - Reaching --max-iterations limit
  - Outputting <complete/> and passing verification
  - Running /autoloop:cancel-autoloop

OTHER COMMANDS:
  /autoloop:autoloop-status   Check current loop progress
  /autoloop:cancel-autoloop   Stop the active loop
HELP
  exit 0
fi

"$PLUGIN_DIR/scripts/setup-loop.sh" $ARGUMENTS

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "AUTOLOOP - Independent Verification System"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "When you believe the task is complete, output: <complete/>"
echo ""
echo "An independent verification agent will then:"
echo ""
echo "┌─────────────────────────────────────────────────────────┐"
echo "│  INDEPENDENT VERIFICATION (runs automatically)          │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│  1. RUN TESTS   - Execute test suite, all must pass     │"
echo "│  2. RUN BUILD   - Build/compile succeeds without error  │"
echo "│  3. RUN LINT    - No lint errors (warnings OK)          │"
echo "│  4. CHECK REQS  - Verify ALL task requirements are met  │"
echo "└─────────────────────────────────────────────────────────┘"
echo ""
echo "KEY POINTS:"
echo "  • The verifier has NO access to this conversation"
echo "  • It only sees the task description and actual files/code"
echo "  • It runs ACTUAL commands (not self-reported claims)"
echo "  • If verification fails, you'll see specific feedback"
echo ""
echo "The loop continues until the independent verifier approves."
echo "═══════════════════════════════════════════════════════════"
```
