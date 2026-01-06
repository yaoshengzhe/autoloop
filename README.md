<h1 align="center">Autoloop</h1>

<p align="center">
<strong>Let your AI agent work autonomously until the job is done.</strong>
</p>

<p align="center">
Walk away from your keyboard. Return to working code.
</p>

---

## Install

```bash
claude plugin marketplace remove autoloop 2>/dev/null; claude plugin marketplace add yaoshengzhe/autoloop && claude plugin install autoloop@autoloop
```

Works for fresh installs and updates alike.

## Run

```bash
/autoloop:autoloop Build a REST API with tests --completion-promise 'DONE' --max-iterations 15
```

The agent iterates on your task, committing progress along the way. When complete, it outputs `<promise>DONE</promise>` and exits.

---

## Why Autoloop?

Traditional AI assistants need constant hand-holding. Prompt, wait, review, prompt again.

**Autoloop breaks this cycle:**

> **Autonomous** — Define your goal and let it work
>
> **Self-correcting** — Each iteration builds on the last
>
> **Safe** — Max iterations prevent runaway loops
>
> **Transparent** — All work preserved in files and git

---

## Example

```bash
/autoloop:autoloop "Build user authentication:
- Login/logout endpoints
- JWT tokens
- Unit tests with 80% coverage

Run tests after each change.
<promise>AUTH COMPLETE</promise>" --max-iterations 20
```

---

## Commands

| Command | Purpose |
|---------|---------|
| `/autoloop:autoloop <task> [options]` | Start autonomous loop |
| `/autoloop:cancel-autoloop` | Stop the loop |
| `/autoloop:autoloop-status` | Check progress |

### Options

| Option | Description |
|--------|-------------|
| `--completion-promise <text>` | Text that signals completion |
| `--max-iterations <n>` | Safety limit (default: unlimited) |

---

## Tips

| | |
|---|---|
| **Be specific** | Clear goals prevent endless loops |
| **Set limits** | Always use `--max-iterations` |
| **Verify work** | Include test steps in your prompt |
| **Use commits** | Ask for commits at milestones |

---

## Plugin Management

```bash
# Update (same as install command)
claude plugin marketplace remove autoloop 2>/dev/null; claude plugin marketplace add yaoshengzhe/autoloop && claude plugin install autoloop@autoloop

# Uninstall
claude plugin uninstall autoloop && claude plugin marketplace remove autoloop
```

---

<p align="center">
<sub>MIT License</sub>
</p>
