#!/bin/bash
# Autoloop setup - initialize loop state with YAML frontmatter

set -euo pipefail

PROMPT_PARTS=()
MAX_ITERATIONS=0
COMMON_PROMPT_FILE=".claude/autoloop-prompt.md"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat <<'HELP_EOF'
Autoloop - Autonomous iterative loop for Claude Code

USAGE:
  /autoloop:autoloop [PROMPT...] [OPTIONS]

ARGUMENTS:
  PROMPT...    Task description (can be multiple words without quotes)

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
  /autoloop:autoloop Build a REST API --max-iterations 20
  /autoloop:autoloop Fix the auth bug --max-iterations 10
  /autoloop:autoloop Refactor the cache layer

COMMON PROMPT FILE:
  Create .claude/autoloop-prompt.md with common instructions that apply to all loops.
  This content is automatically prepended to every loop prompt.

STOPPING:
  - Reaching --max-iterations limit
  - Outputting <complete/> and passing verification
  - Running /autoloop:cancel-autoloop

MONITORING:
  head -10 .claude/autoloop.local.md
HELP_EOF
      exit 0
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --max-iterations requires a number" >&2
        echo "" >&2
        echo "Examples:" >&2
        echo "  --max-iterations 10" >&2
        echo "  --max-iterations 50" >&2
        exit 1
      fi
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-iterations must be a positive integer, got: $2" >&2
        exit 1
      fi
      # Validate reasonable upper bound (prevent resource exhaustion)
      if [[ "$2" -gt 10000 ]]; then
        echo "Error: --max-iterations cannot exceed 10000" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --completion-promise)
      # Deprecated - kept for backwards compatibility but ignored
      echo "Note: --completion-promise is deprecated. Using subagent verification instead." >&2
      shift 2
      ;;
    *)
      PROMPT_PARTS+=("$1")
      shift
      ;;
  esac
done

# Join prompt parts
PROMPT="${PROMPT_PARTS[*]:-}"

# Load common prompt file if exists (check both current directory and plugin directory)
COMMON_PROMPT=""
COMMON_PROMPT_SOURCE=""
if [[ -f "$COMMON_PROMPT_FILE" ]]; then
  COMMON_PROMPT=$(cat "$COMMON_PROMPT_FILE")
  COMMON_PROMPT_SOURCE="$COMMON_PROMPT_FILE"
elif [[ -n "${PLUGIN_DIR:-}" ]] && [[ -f "$PLUGIN_DIR/../../../.claude/autoloop-prompt.md" ]]; then
  # Fall back to repo root relative to plugin directory
  COMMON_PROMPT=$(cat "$PLUGIN_DIR/../../../.claude/autoloop-prompt.md")
  COMMON_PROMPT_SOURCE="$PLUGIN_DIR/../../../.claude/autoloop-prompt.md"
fi

# Validate prompt
if [[ -z "$PROMPT" ]]; then
  echo "Error: No prompt provided" >&2
  echo "" >&2
  echo "Examples:" >&2
  echo "  /autoloop:autoloop Build a REST API --completion-promise 'DONE'" >&2
  echo "  /autoloop:autoloop Fix bug in auth module --max-iterations 10" >&2
  echo "" >&2
  echo "For help: /autoloop:autoloop --help" >&2
  exit 1
fi

# Create state directory
mkdir -p .claude

# Create unique log file for this execution
LOG_TIMESTAMP=$(date -u +%Y%m%d-%H%M%S)
LOG_FILE=".claude/autoloop-${LOG_TIMESTAMP}.log"

# Combine common prompt with task prompt
FULL_PROMPT=""
if [[ -n "$COMMON_PROMPT" ]]; then
  FULL_PROMPT="$COMMON_PROMPT

---

$PROMPT"
else
  FULL_PROMPT="$PROMPT"
fi

# Get start time
START_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Create state file with YAML frontmatter
cat > .claude/autoloop.local.md <<EOF
---
active: true
iteration: 1
max_iterations: $MAX_ITERATIONS
started_at: "$START_TIME"
log_file: "$LOG_FILE"
---

$FULL_PROMPT
EOF

# Initialize log file
cat > "$LOG_FILE" <<EOF
# Autoloop Execution Log
Started: $START_TIME

## Configuration
- Max iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)
- Verification: Independent subagent
- Common prompt: $(if [[ -n "$COMMON_PROMPT" ]]; then echo "loaded from $COMMON_PROMPT_SOURCE"; else echo "not found"; fi)

## Prompt
\`\`\`
$FULL_PROMPT
\`\`\`

---

## Iteration 1
Started: $START_TIME

EOF

# Output setup message with working log
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "AUTOLOOP - Started"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Configuration:"
echo "  • Iteration:     1$(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo " of $MAX_ITERATIONS"; fi)"
echo "  • Max iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)"
echo "  • Verification:  Independent subagent (no conversation context)"
echo "  • Common prompt: $(if [[ -n "$COMMON_PROMPT" ]]; then echo "loaded from $COMMON_PROMPT_SOURCE"; else echo "not found (create .claude/autoloop-prompt.md)"; fi)"
echo "  • Log file:      $LOG_FILE"
echo ""
echo "To signal completion: output <complete/>"
echo ""
echo "An independent verification agent will check your work."
echo "The verifier has NO access to this conversation - only the task"
echo "description and actual code/files. It will run tests, build, lint"
echo "and verify all requirements are met."
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""

# Output the full prompt
echo "$FULL_PROMPT"
