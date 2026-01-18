# /autoloop

Start an autonomous iterative loop that continues until completion criteria are met.

**IMPORTANT**: If the script output below shows `[AUTOLOOP_HELP_SHOWN]`, just display the help message to the user without reading any files or taking other actions.

---

```bash
# Show help if no arguments provided
if [ -z "$ARGUMENTS" ] || [ "$ARGUMENTS" = "-h" ] || [ "$ARGUMENTS" = "--help" ]; then
  echo "[AUTOLOOP_HELP_SHOWN]"
  cat <<'HELP'
Autoloop v3.0 - Autonomous Coding Loop

Two modes available:

  v3.0 TWO-AGENT PATTERN (Recommended):
    /autoloop:init <description>  - Architect: Create prd.json task breakdown
    /autoloop:work                - Engineer: Execute tasks with TDD

  v2.0 SINGLE-AGENT (Legacy):
    /autoloop <task>              - Single loop with subagent verification

═══════════════════════════════════════════════════════════

v3.0 WORKFLOW:

  1. Initialize project:
     /autoloop:init Build a snake game in Python

  2. Review prd.json (created by init)

  3. Start worker loop:
     /autoloop:work

  Features:
    • TDD Enforcement (Red-Green cycle)
    • Git-based safety net (auto-commit, reset on failure)
    • Context compaction (prd.json + progress.md + git log)
    • <thinking> blocks required before actions

═══════════════════════════════════════════════════════════

v2.0 USAGE:
  /autoloop <task> [OPTIONS]

OPTIONS:
  --max-iterations <n>  Maximum iterations (default: unlimited)
  -h, --help            Show this help message

EXAMPLES:
  /autoloop Build a REST API --max-iterations 20
  /autoloop Fix the auth bug --max-iterations 10

STOPPING:
  - <complete/> and passing verification
  - /autoloop:cancel-autoloop

OTHER COMMANDS:
  /autoloop:autoloop-status   Check loop progress
  /autoloop:cancel-autoloop   Stop active loop
HELP
  exit 0
fi

"$PLUGIN_DIR/scripts/setup-loop.sh" $ARGUMENTS

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "AUTOLOOP v2.0 - Independent Verification System"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "TIP: Try v3.0 for TDD and better context management:"
echo "     /autoloop:init <description>  then  /autoloop:work"
echo ""
echo "───────────────────────────────────────────────────────────"
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
