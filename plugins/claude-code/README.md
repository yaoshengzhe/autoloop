# Autoloop for Claude Code

Turn Claude Code into an autonomous agent that iterates until your task is complete.

---

## Install

```bash
claude plugin marketplace add yaoshengzhe/autoloop && claude plugin install autoloop@autoloop
```

## Quick Start

```bash
/autoloop:autoloop Create a Python CLI with tests --max-iterations 5
```

Claude works autonomously. When it outputs `<complete/>`, an independent verification agent confirms the work is actually done.

---

## Commands

| Command | Description |
|---------|-------------|
| `/autoloop:autoloop <task> [options]` | Start autonomous loop |
| `/autoloop:cancel-autoloop` | Stop immediately |
| `/autoloop:autoloop-status` | Check progress |

**Options:** `--max-iterations <n>` | `--help`

---

## How Verification Works

When Claude outputs `<complete/>`, a separate verification agent spawns:

1. **No conversation access** — Only sees task description and actual files
2. **Runs real commands** — Executes tests, build, lint (not self-reported)
3. **Checks requirements** — Validates each task requirement against code
4. **Returns verdict** — APPROVED (loop ends) or REJECTED (loop continues with feedback)

This eliminates self-reporting bias — the verifier has no knowledge of what Claude *said* it did, only what actually exists.

---

## Common Prompt File

Create `.claude/autoloop-prompt.md` with instructions that apply to all loops:

```markdown
# Common Instructions
- Run tests after each change
- Keep commits small and focused
- Follow existing code style
```

This content is automatically prepended to every `/autoloop:autoloop` prompt.

---

## Examples

**TDD Loop:**
```bash
/autoloop:autoloop "Implement ShoppingCart with TDD. Run pytest after each change." --max-iterations 15
```

**Feature Build:**
```bash
/autoloop:autoloop "Build a markdown blog engine with index page. Commit after each milestone." --max-iterations 20
```

**Bug Fix:**
```bash
/autoloop:autoloop "Fix the memory leak in WebSocket handler. Verify with load test." --max-iterations 10
```

---

## Writing Good Prompts

**Good:** Specific deliverables + verification steps

```bash
/autoloop:autoloop "Build auth module with login/logout, JWT, and tests. Run tests after each change." --max-iterations 20
```

**Bad:** Vague goals with no clear requirements

```bash
/autoloop:autoloop "Make the code better" --max-iterations 10
```

The verifier needs concrete requirements to check against.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Verification keeps failing | Check verifier output for specific issues |
| Loop runs forever | Add `--max-iterations`; make requirements clearer |
| Agent stuck | Run `/autoloop:autoloop-status`, then `/autoloop:cancel-autoloop` if needed |
