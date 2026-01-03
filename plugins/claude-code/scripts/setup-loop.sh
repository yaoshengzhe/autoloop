#!/bin/bash
# Autoloop setup - initialize loop state with YAML frontmatter

set -euo pipefail

PROMPT_PARTS=()
MAX_ITERATIONS=0
COMPLETION_PROMISE="null"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat <<'HELP_EOF'
Autoloop - Autonomous iterative loop for Claude Code

USAGE:
  /autoloop [PROMPT...] [OPTIONS]

ARGUMENTS:
  PROMPT...    Task description (can be multiple words without quotes)

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
  /autoloop --completion-promise 'ALL TESTS PASS' Refactor the cache layer

STOPPING:
  - Reaching --max-iterations limit
  - Outputting <promise>COMPLETION_TEXT</promise>
  - Running /cancel-autoloop

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
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --completion-promise)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --completion-promise requires text" >&2
        echo "" >&2
        echo "Examples:" >&2
        echo "  --completion-promise 'DONE'" >&2
        echo "  --completion-promise 'ALL TESTS PASS'" >&2
        exit 1
      fi
      COMPLETION_PROMISE="$2"
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

# Validate prompt
if [[ -z "$PROMPT" ]]; then
  echo "Error: No prompt provided" >&2
  echo "" >&2
  echo "Examples:" >&2
  echo "  /autoloop Build a REST API --completion-promise 'DONE'" >&2
  echo "  /autoloop Fix bug in auth module --max-iterations 10" >&2
  echo "" >&2
  echo "For help: /autoloop --help" >&2
  exit 1
fi

# Create state directory
mkdir -p .claude

# Quote completion promise for YAML
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  COMPLETION_PROMISE_YAML="\"$COMPLETION_PROMISE\""
else
  COMPLETION_PROMISE_YAML="null"
fi

# Create state file with YAML frontmatter
cat > .claude/autoloop.local.md <<EOF
---
active: true
iteration: 1
max_iterations: $MAX_ITERATIONS
completion_promise: $COMPLETION_PROMISE_YAML
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
---

$PROMPT
EOF

# Output setup message
cat <<EOF

Autoloop activated!

Iteration: 1
Max iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)
Completion promise: $(if [[ "$COMPLETION_PROMISE" != "null" ]]; then echo "$COMPLETION_PROMISE"; else echo "none"; fi)

The stop hook will feed this prompt back when you try to exit.
Your previous work persists in files and git history.

EOF

# Output the prompt
echo "$PROMPT"
