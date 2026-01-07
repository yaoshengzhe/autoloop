# /autoloop-help

Autoloop lets Claude Code work autonomously until your task is complete.

## Commands

| Command | Purpose |
|---------|---------|
| `/autoloop:autoloop <task> [options]` | Start autonomous loop |
| `/autoloop:cancel-autoloop` | Stop the loop |
| `/autoloop:autoloop-status` | Check progress |

## Usage

```bash
/autoloop:autoloop <task> --max-iterations <n>
```

When done, output `<complete/>` to trigger independent verification.

## How It Works

1. You describe the task
2. Claude works on it iteratively
3. When Claude outputs `<complete/>`, an **independent verification agent** checks the work
4. The verifier has NO access to the conversation - only the task and actual code
5. Loop continues until verification passes

## Example

```bash
/autoloop:autoloop "Build password reset with tests" --max-iterations 15
```

## Tips

- **Be specific** - List deliverables clearly
- **Set limits** - Use `--max-iterations` for safety
- **Trust the verifier** - It runs actual tests/build/lint independently
