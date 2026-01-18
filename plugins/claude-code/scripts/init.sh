#!/bin/bash
# Autoloop v3.0 - Initializer (Architect) Agent
# Creates prd.json and autoloop-progress.md for a project

set -euo pipefail

PROMPT_PARTS=()
PRD_FILE="prd.json"
PROGRESS_FILE="autoloop-progress.md"
AGENTS_FILE="AGENTS.md"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat <<'HELP_EOF'
Autoloop v3.0 - Initialize Project (Architect Mode)

USAGE:
  /autoloop:init [PROMPT...] [OPTIONS]

ARGUMENTS:
  PROMPT...    High-level project description

OPTIONS:
  -h, --help   Show this help message

DESCRIPTION:
  The Initializer (Architect) agent runs ONCE at the start of a project to:

  1. Scan the directory structure
  2. Create prd.json (structured task list)
  3. Create autoloop-progress.md (context log)
  4. Initialize git if missing

  After initialization, use /autoloop:work to start the worker loop.

WORKFLOW:
  1. /autoloop:init "Build a snake game in Python"
     -> Creates prd.json with task breakdown

  2. /autoloop:work
     -> Worker consumes tasks one at a time

EXAMPLES:
  /autoloop:init Build a REST API with authentication
  /autoloop:init "Create a CLI tool for data processing"
  /autoloop:init Refactor the existing codebase to use TypeScript

TDD WORKFLOW:
  Feature tasks are automatically broken into:
  - RED phase: Write failing tests first
  - GREEN phase: Implement to make tests pass
HELP_EOF
      exit 0
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
  echo "Usage: /autoloop:init <project description>" >&2
  echo "" >&2
  echo "Examples:" >&2
  echo "  /autoloop:init Build a snake game in Python" >&2
  echo "  /autoloop:init Create a REST API with user authentication" >&2
  echo "" >&2
  echo "For help: /autoloop:init --help" >&2
  exit 1
fi

# Check if already initialized
if [[ -f "$PRD_FILE" ]]; then
  echo "WARNING: prd.json already exists!" >&2
  echo "" >&2
  echo "Options:" >&2
  echo "  - Use /autoloop:work to continue working on existing tasks" >&2
  echo "  - Delete prd.json to start fresh" >&2
  echo "" >&2
  exit 1
fi

# Ensure git is initialized
if [[ ! -d ".git" ]]; then
  echo "Initializing git repository..."
  git init
  git add -A 2>/dev/null || true
  git commit -m "Initial commit (autoloop init)" --allow-empty 2>/dev/null || true
fi

# Ensure working tree is clean
if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
  echo "Stashing uncommitted changes..."
  git stash push -m "autoloop-init-stash" 2>/dev/null || true
fi

# Scan directory structure
echo "Scanning directory structure..."
DIR_SCAN=$(find . -maxdepth 4 -type f \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -not -path "*/venv/*" \
  -not -path "*/__pycache__/*" \
  -not -path "*/.venv/*" \
  -not -path "*/dist/*" \
  -not -path "*/build/*" \
  2>/dev/null | head -200 || ls -la)

# Load AGENTS.md if exists
AGENTS_MD=""
if [[ -f "$AGENTS_FILE" ]]; then
  AGENTS_MD=$(cat "$AGENTS_FILE")
fi

# Create initial progress file
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
cat > "$PROGRESS_FILE" <<EOF
# Autoloop Progress Log

## Project
$PROMPT

## Timeline

### $TIMESTAMP - Project Initialized
- Scanned directory structure
- Ready for task breakdown

---

## Completed Tasks

(Tasks will be logged here as they complete)

---

## Learnings & Notes

(Important insights discovered during development)

EOF

# Output initialization message
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "AUTOLOOP v3.0 - INITIALIZER (Architect Mode)"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Project: $PROMPT"
echo ""
echo "Files created:"
echo "  - autoloop-progress.md (context log)"
echo ""
echo "Directory scan complete ($(echo "$DIR_SCAN" | wc -l | tr -d ' ') files found)"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Now analyze this project and create a prd.json task breakdown."
echo ""
echo "┌─────────────────────────────────────────────────────────┐"
echo "│  YOUR TASK: Create prd.json                             │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│  1. Analyze the project request                         │"
echo "│  2. Break it into small, focused tasks                  │"
echo "│  3. Add validation commands for each task               │"
echo "│  4. Feature tasks get TDD (RED→GREEN phases)            │"
echo "└─────────────────────────────────────────────────────────┘"
echo ""
echo "<thinking> blocks are REQUIRED before any action."
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
cat <<INIT_PROMPT
You are the INITIALIZER agent in a two-agent autonomous coding system.

Your ONLY job is to analyze the project request and create a structured prd.json.

## Project Request
$PROMPT

## Current Directory Structure
\`\`\`
$DIR_SCAN
\`\`\`
$(if [[ -n "$AGENTS_MD" ]]; then
echo "
## AGENTS.md (Learnings from previous work)
\`\`\`
$AGENTS_MD
\`\`\`"
fi)

## CRITICAL: Use <thinking> Block

Before creating the task list, output your analysis:

<thinking>
1. What is being requested?
2. What files/structure already exists?
3. What are the logical task phases?
4. What validation commands will prove each task works?
</thinking>

## Task Breakdown Rules

1. **Feature tasks** require TDD (Test-Driven Development):
   - First write failing tests (RED phase)
   - Then implement to make tests pass (GREEN phase)

2. **Setup tasks** are one-shot (no TDD):
   - Environment setup, dependencies, configuration

3. Each task needs a \`validation_cmd\` that proves it works

4. Tasks should be small and focused (15-30 min of work each)

5. Dependencies should flow naturally (setup → features → polish)

## Output Format

After your <thinking> block, create the prd.json file with this structure:

\`\`\`json
{
  "project_name": "...",
  "description": "Full project description",
  "tasks": [
    {
      "id": "TASK-001",
      "type": "setup",
      "description": "Initialize project structure and dependencies",
      "validation_cmd": "command to verify task is complete"
    },
    {
      "id": "TASK-002",
      "type": "feature",
      "description": "Implement feature X",
      "validation_cmd": "pytest tests/test_feature_x.py",
      "test_file": "tests/test_feature_x.py"
    }
  ]
}
\`\`\`

Task types: setup, feature, test, bugfix, refactor, docs

Now analyze the project and create prd.json:
INIT_PROMPT
