# Autoloop for Claude Code

Turn Claude Code into an autonomous agent that iterates until your task is complete.

## Installation

```bash
claude plugin marketplace add yaoshengzhe/autoloop
claude plugin install autoloop@autoloop
```

## Quick Start

```bash
/autoloop Create a Python CLI with tests --completion-promise 'DONE' --max-iterations 5
```

Claude will work autonomously, iterating until it can truthfully output `<promise>DONE</promise>`.

## Commands

| Command | Description |
|---------|-------------|
| `/autoloop <task> [options]` | Start autonomous loop |
| `/cancel-autoloop` | Stop immediately |
| `/autoloop-status` | Check progress |

**Options:** `--completion-promise <text>` · `--max-iterations <n>` · `--help`

## Common Prompt File

Create `.claude/autoloop-prompt.md` with instructions that apply to all loops:

```markdown
# Common Instructions
- Run tests after each change
- Keep commits small and focused
- Follow existing code style
```

This content is automatically prepended to every `/autoloop` prompt.

## Example Patterns

**TDD Loop:**
```bash
/autoloop "Implement ShoppingCart with TDD. Run pytest after each change.
<promise>ALL TESTS GREEN</promise>" --max-iterations 15
```

**Feature Build:**
```bash
/autoloop "Build a markdown blog engine with index page.
Commit after each milestone. <promise>COMPLETE</promise>" --max-iterations 20
```

**Bug Fix:**
```bash
/autoloop "Fix the memory leak in WebSocket handler.
Verify with load test. <promise>FIXED</promise>" --max-iterations 10
```

## Writing Good Prompts

✅ **Good:** Specific deliverables + verification steps + clear completion signal

```bash
/autoloop "Build auth module with login/logout, JWT, and tests.
Run tests after each change. <promise>AUTH COMPLETE</promise>" --max-iterations 20
```

❌ **Bad:** Vague goals with no endpoint

```bash
/autoloop "Make the code better" --max-iterations 10
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Loop exits immediately | Completion promise in your prompt; rephrase it |
| Loop runs forever | Add `--max-iterations`; clarify completion criteria |
| Agent stuck | Run `/autoloop-status`, then `/cancel-autoloop` if needed |
