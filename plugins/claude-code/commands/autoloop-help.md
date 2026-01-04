# /autoloop-help

Autoloop lets Claude Code work autonomously until your task is complete.

## Commands

| Command | Purpose |
|---------|---------|
| `/autoloop <task> [options]` | Start autonomous loop |
| `/cancel-autoloop` | Stop the loop |
| `/autoloop-status` | Check progress |

## Usage

```bash
/autoloop <task> --completion-promise '<signal>' --max-iterations <n>
```

When done, output `<promise>SIGNAL</promise>` to complete the loop.

## Example

```bash
/autoloop "Build password reset with tests. Run tests after each change.
<promise>DONE</promise>" --max-iterations 15
```

## Tips

- **Be specific** — List deliverables clearly
- **Verify work** — Include test/validation steps
- **Set limits** — Use `--max-iterations` for safety
- **Use phases** — Break large tasks into milestones
