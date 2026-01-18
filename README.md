<h1 align="center">Autoloop v3.0</h1>

<p align="center">
<strong>The Two-Agent Autonomous Coding System</strong>
</p>

<p align="center">
Walk away from your keyboard. Return to working, tested code.
</p>

---

## Install

```bash
claude plugin marketplace remove autoloop 2>/dev/null; claude plugin marketplace add yaoshengzhe/autoloop && claude plugin install autoloop@autoloop
```

## Quick Start (v3.0)

```bash
# Step 1: Initialize project (Architect creates task breakdown)
/autoloop:init Build a snake game in Python with tests

# Step 2: Start worker loop (Engineer executes tasks)
/autoloop:work
```

The **Architect** analyzes your project and creates a structured task list. The **Engineer** executes tasks one at a time with TDD enforcement.

---

## Why v3.0?

| Feature | v2.0 | v3.0 |
|---------|------|------|
| **Agent Pattern** | Single agent | Two agents (Architect + Engineer) |
| **Context** | Full conversation | Compacted (prd.json + git log) |
| **Testing** | Optional | TDD enforced (Red-Green cycle) |
| **Safety Net** | None | Git auto-commit, reset on failure |
| **Verification** | Subagent | Per-task validation commands |

---

## The Two-Agent Pattern

### Architect (Initializer)
Runs **once** to create the project plan:
- Scans directory structure
- Creates `prd.json` (task list)
- Creates `autoloop-progress.md` (context log)
- Initializes git if needed

### Engineer (Worker)
Runs **in a loop**, one task at a time:
- Loads context: `prd.json` + `progress.md` + `git log`
- Enforces TDD for feature tasks
- Auto-commits on success
- Git resets on max retries

---

## TDD Workflow

Feature tasks follow the Red-Green cycle:

```
1. RED Phase   → Write tests that FAIL
2. GREEN Phase → Write code to make tests PASS
3. Auto-commit → Changes saved with task ID
```

Each task has a `validation_cmd` that must pass:
```json
{
  "id": "TASK-002",
  "type": "feature",
  "description": "Create game window",
  "validation_cmd": "pytest tests/test_window.py"
}
```

---

## Git Safety Net

| When | What Happens |
|------|--------------|
| **Pre-task** | Ensures clean working tree |
| **Success** | Auto-commits: `feat(TASK-002): description` |
| **Failure** | After max retries: `git reset --hard` |

Your code is always safe. Failed experiments are automatically cleaned up.

---

## Commands

| Command | Purpose |
|---------|---------|
| `/autoloop:init <description>` | Create project plan (Architect) |
| `/autoloop:work [--max-iterations N]` | Execute tasks (Engineer) |
| `/autoloop:autoloop <task>` | Legacy single-agent mode |
| `/autoloop:cancel-autoloop` | Stop active loop |
| `/autoloop:autoloop-status` | Check progress |

---

## Example

```bash
# Initialize
/autoloop:init Create a CLI todo app with:
- Add/remove/list tasks
- Save to JSON file
- Unit tests

# Review prd.json, then start working
/autoloop:work --max-iterations 30
```

The Engineer uses `<thinking>` blocks before each action:

```xml
<thinking>
1. Current task: Write tests for add_task function
2. Need to create tests/test_todo.py
3. Tests should fail (RED phase)
</thinking>
```

---

## Completion Signals

| Signal | Meaning |
|--------|---------|
| `<task-complete/>` | Task validation passed |
| `<task-stuck reason="..."/>` | Need help |

---

## Tips

| | |
|---|---|
| **Use TDD tasks** | Features get automatic Red-Green enforcement |
| **Set max iterations** | Safety limit prevents runaway loops |
| **Check prd.json** | Review task breakdown before starting |
| **Trust git** | Failed tasks reset automatically |

---

## Plugin Management

```bash
# Update
claude plugin marketplace remove autoloop 2>/dev/null; claude plugin marketplace add yaoshengzhe/autoloop && claude plugin install autoloop@autoloop

# Uninstall
claude plugin uninstall autoloop && claude plugin marketplace remove autoloop
```

---

<p align="center">
<sub>MIT License</sub>
</p>
