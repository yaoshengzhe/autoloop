# /init

Initialize a project with the Architect agent. Creates prd.json and autoloop-progress.md.

**IMPORTANT**: If the script output below shows `[INIT_HELP_SHOWN]`, just display the help message to the user without reading any files or taking other actions.

---

```bash
# Show help if no arguments provided
if [ -z "$ARGUMENTS" ] || [ "$ARGUMENTS" = "-h" ] || [ "$ARGUMENTS" = "--help" ]; then
  echo "[INIT_HELP_SHOWN]"
  cat <<'HELP'
Autoloop v3.0 - Initialize Project (Architect Mode)

USAGE:
  /autoloop:init <project description>

DESCRIPTION:
  The Initializer (Architect) agent runs ONCE at the start of a project to:

  1. Scan the directory structure
  2. Create prd.json (structured task list)
  3. Create autoloop-progress.md (context log)
  4. Initialize git if missing

  After initialization, use /autoloop:work to start the worker loop.

EXAMPLES:
  /autoloop:init Build a REST API with authentication
  /autoloop:init Create a snake game in Python
  /autoloop:init Refactor the codebase to use TypeScript

TDD WORKFLOW:
  Feature tasks are automatically broken into:
  - RED phase: Write failing tests first
  - GREEN phase: Implement to make tests pass
HELP
  exit 0
fi

"$PLUGIN_DIR/scripts/init.sh" $ARGUMENTS

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "NEXT STEPS"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "1. Review and create the prd.json file above"
echo "2. Once prd.json is ready, run: /autoloop:work"
echo ""
echo "═══════════════════════════════════════════════════════════"
```
