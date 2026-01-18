# Autoloop v3.0 for Claude Code

The Two-Agent Autonomous Coding System for Claude Code.

---

## Install

```bash
claude plugin marketplace add yaoshengzhe/autoloop && claude plugin install autoloop@autoloop
```

## Quick Start (v3.0)

```bash
# Step 1: Architect creates task breakdown
/autoloop:init Build a REST API with authentication

# Step 2: Engineer executes tasks with TDD
/autoloop:work
```

---

## Commands

| Command | Description |
|---------|-------------|
| `/autoloop:init <description>` | Architect: Create prd.json task list |
| `/autoloop:work [--max-iterations N]` | Engineer: Execute tasks one at a time |
| `/autoloop:autoloop <task>` | Legacy v2.0 single-agent mode |
| `/autoloop:cancel-autoloop` | Stop active loop |
| `/autoloop:autoloop-status` | Check progress |

---

## Two-Agent Pattern

### Architect (init)
Runs once to analyze your project:
- Scans directory structure
- Creates `prd.json` with task breakdown
- Creates `autoloop-progress.md` for context

### Engineer (work)
Runs in a loop, one task at a time:
- Loads compacted context (prd.json + git log)
- Enforces TDD for feature tasks (Red-Green cycle)
- Auto-commits successful tasks
- Git resets on max retries (safety net)

---

## TDD Enforcement

Feature tasks follow Red-Green cycle:

| Phase | Goal | Validation |
|-------|------|------------|
| RED | Write failing tests | Exit code != 0 |
| GREEN | Make tests pass | Exit code == 0 |

```json
{
  "id": "TASK-002",
  "type": "feature",
  "description": "Create game window",
  "validation_cmd": "pytest tests/test_window.py",
  "test_file": "tests/test_window.py"
}
```

---

## Git Safety Net

| Event | Action |
|-------|--------|
| Pre-task | Ensures clean working tree |
| Success | Auto-commit: `feat(TASK-ID): description` |
| Max retries | `git reset --hard` to clean state |

---

## Completion Signals

| Signal | When to Use |
|--------|-------------|
| `<task-complete/>` | Validation command passed |
| `<task-stuck reason="..."/>` | Need help, explain why |

---

## Thinking Blocks

The Engineer must use thinking blocks before actions:

```xml
<thinking>
1. Current state: RED phase for TASK-002
2. Need to write failing tests for game window
3. Will create tests/test_window.py
4. Tests should import pygame and fail
</thinking>
```

---

## Example Workflow

```bash
# 1. Initialize project
/autoloop:init Create a CLI todo app with add/remove/list and tests

# 2. Review generated prd.json

# 3. Start worker loop
/autoloop:work --max-iterations 20
```

The Architect creates:
```json
{
  "project_name": "CLI Todo App",
  "tasks": [
    {"id": "TASK-001", "type": "setup", "description": "Create project structure"},
    {"id": "TASK-002", "type": "feature", "description": "Add task function"},
    {"id": "TASK-003", "type": "feature", "description": "List tasks function"}
  ]
}
```

The Engineer executes each task with TDD enforcement.

---

## Common Prompt File

Create `.claude/autoloop-prompt.md` for shared instructions:

```markdown
# Project Rules
- Run tests after each change
- Keep commits focused
- Follow existing patterns
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| prd.json not found | Run `/autoloop:init` first |
| Task stuck | Check validation_cmd output |
| Max retries reached | Task marked failed, git reset applied |
| Loop won't stop | `/autoloop:cancel-autoloop` |
