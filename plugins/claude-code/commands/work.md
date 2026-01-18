# /work

Start the Worker (Engineer) loop to consume tasks from prd.json.

**IMPORTANT**: If the script output below shows `[WORK_HELP_SHOWN]`, just display the help message to the user without reading any files or taking other actions.

---

```bash
# Show help if requested
if [ "$ARGUMENTS" = "-h" ] || [ "$ARGUMENTS" = "--help" ]; then
  echo "[WORK_HELP_SHOWN]"
  cat <<'HELP'
Autoloop v3.0 - Worker Loop (Engineer Mode)

USAGE:
  /autoloop:work [OPTIONS]

OPTIONS:
  --max-iterations <n>  Maximum iterations before auto-stop (default: unlimited)
  -h, --help            Show this help message

DESCRIPTION:
  The Worker (Engineer) agent runs in a loop, consuming tasks from prd.json.

  Context Strategy (Token Efficient):
  - Loads prd.json (current task)
  - Reads autoloop-progress.md (what previous workers did)
  - Gets git log -n 5 (recent code changes)
  - Loads AGENTS.md (learnings/lessons)

PREREQUISITES:
  Run /autoloop:init first to create prd.json

TDD WORKFLOW:
  Feature tasks have two phases:
  1. RED: Write tests that FAIL (exit code != 0)
  2. GREEN: Write code to make tests PASS (exit code == 0)

SAFETY NET:
  - Pre-task: Ensures working tree is clean
  - Success: Auto-commits with "feat: [TASK-ID]"
  - Failure: git reset --hard after max retries

SIGNALS:
  <task-complete/>           - Task validation passed
  <task-stuck reason="..."/> - Need help

EXAMPLES:
  /autoloop:work                      # Run until all tasks complete
  /autoloop:work --max-iterations 10  # Stop after 10 iterations
HELP
  exit 0
fi

"$PLUGIN_DIR/scripts/work.sh" $ARGUMENTS
```
