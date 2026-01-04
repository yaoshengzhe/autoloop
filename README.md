# Autoloop

**Let your AI agent work autonomously until the job is done.**

Walk away from your keyboard. Return to working code.

## Quick Start

```bash
# Install (one-time)
claude plugin marketplace add yaoshengzhe/autoloop
claude plugin install autoloop@autoloop
```

```bash
# Run
/autoloop:autoloop Build a REST API with tests --completion-promise 'DONE' --max-iterations 15
```

The agent iterates on your task, committing progress along the way. When complete, it outputs `<promise>DONE</promise>` and exits.

## Why Autoloop?

Traditional AI assistants need constant hand-holding. Prompt, wait, review, prompt again.

Autoloop breaks this cycle:

- **Autonomous execution** — Define your goal and let it work
- **Self-correcting** — Each iteration builds on the last
- **Safe** — Max iterations prevent runaway loops
- **Transparent** — All work preserved in files and git

## Example

```bash
/autoloop:autoloop "Build user authentication:
- Login/logout endpoints
- JWT tokens
- Unit tests with 80% coverage

Run tests after each change.
<promise>AUTH COMPLETE</promise>" --max-iterations 20
```

## Commands

| Command | Purpose |
|---------|---------|
| `/autoloop:autoloop <task> [options]` | Start autonomous loop |
| `/autoloop:cancel-autoloop` | Stop the loop |
| `/autoloop:autoloop-status` | Check progress |

## Options

- `--completion-promise <text>` — Text that signals completion
- `--max-iterations <n>` — Safety limit (default: unlimited)

## Tips

1. **Be specific** — Clear goals prevent endless loops
2. **Set limits** — Always use `--max-iterations`
3. **Verify work** — Include test steps in your prompt
4. **Use commits** — Ask for commits at milestones

## Plugin Management

```bash
claude plugin install autoloop@autoloop --force  # Update
claude plugin uninstall autoloop                  # Remove
```

## License

MIT
