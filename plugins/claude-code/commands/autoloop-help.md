# /autoloop-help

Autoloop is an autonomous iterative loop framework for Claude Code.

## Commands

| Command | Description |
|---------|-------------|
| `/autoloop "<prompt>" [options]` | Start an iterative loop |
| `/cancel-autoloop` | Cancel the active loop |
| `/autoloop-help` | Show this help |

## Options for /autoloop

- `--completion-promise "<text>"` - Text that signals task completion
- `--max-iterations <n>` - Maximum iterations (safety limit)

## How It Works

Autoloop creates a self-reinforcing development cycle:

1. **Start**: Your prompt initializes the loop
2. **Work**: Claude works on the task, making commits
3. **Stop Intercept**: When Claude tries to exit, the hook re-feeds the prompt
4. **Iteration**: Claude sees previous work and continues improving
5. **Complete**: Output `<promise>TEXT</promise>` when truly done

## Best Practices

### Clear Completion Criteria
```
/autoloop "Build a todo API with:
- CRUD endpoints
- Input validation
- Tests with >80% coverage

When complete: <promise>ALL TESTS PASS</promise>" --max-iterations 15
```

### Safety Limits
Always set `--max-iterations` to prevent runaway loops.

### Incremental Goals
Break complex tasks into phases with checkpoints.

## Example Session

```
/autoloop "Implement user auth with JWT. Run tests after each change.
When all tests pass: <promise>AUTH COMPLETE</promise>" --max-iterations 20

# Iteration 1: Implement basic structure
# Iteration 2: Add token generation
# Iteration 3: Fix test failures
# Iteration 4: <promise>AUTH COMPLETE</promise>
# Loop exits
```
