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
/autoloop:autoloop Build a REST API with tests --max-iterations 15
```

The agent iterates on your task, committing progress along the way. When complete, an **independent verification agent** confirms all tests pass before exiting.

---

## Why Autoloop?

Traditional AI assistants need constant hand-holding. Prompt, wait, review, prompt again.

**Autoloop breaks this cycle:**

> **Autonomous** — Define your goal and let it work
>
> **Self-correcting** — Each iteration builds on the last
>
> **Independently verified** — A separate agent verifies completion (no self-reporting)
>
> **Safe** — Max iterations prevent runaway loops
>
> **Transparent** — All work preserved in files and git

---

## Independent Verification

When Claude claims completion with `<complete/>`, an independent verification agent takes over:

| What it does | Why it matters |
|--------------|----------------|
| **Runs actual tests** | Not self-reported — actually executes test commands |
| **Checks build** | Verifies compilation/build succeeds |
| **Runs lint** | Confirms no lint errors |
| **Validates requirements** | Checks each task requirement against actual code |

The verifier has **no access to the conversation** — only the task description and actual files. This eliminates self-reporting bias.

---

## Example

```bash
/autoloop:autoloop "Build user authentication:
- Login/logout endpoints
- JWT tokens
- Unit tests with 80% coverage

Run tests after each change." --max-iterations 20
```

When done, output `<complete/>` to trigger verification.

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
| `--max-iterations <n>` | Safety limit (default: unlimited) |

---

## Tips

| | |
|---|---|
| **Be specific** | Clear goals help the verifier check requirements |
| **Set limits** | Always use `--max-iterations` |
| **Include tests** | The verifier actually runs them |
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
