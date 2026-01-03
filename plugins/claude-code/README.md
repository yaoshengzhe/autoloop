# Autoloop for Claude Code

A Claude Code plugin that enables autonomous iterative loops.

## Installation

```bash
claude plugin install ./plugins/claude-code
```

## Commands

### /autoloop

Start an iterative loop:

```bash
/autoloop Build a REST API --completion-promise 'DONE' --max-iterations 20
```

Options:
- `--completion-promise <text>` - Exit when this text is output in `<promise>` tags
- `--max-iterations <n>` - Maximum iterations (default: unlimited)
- `-h, --help` - Show help

### /cancel-autoloop

Cancel the active loop:

```bash
/cancel-autoloop
```

### /autoloop-help

Show detailed help and examples.

## State File

Loop state is stored in `.claude/autoloop.local.md` with YAML frontmatter:

```yaml
---
active: true
iteration: 3
max_iterations: 20
completion_promise: "DONE"
started_at: "2024-01-01T00:00:00Z"
---

Your task prompt here
```

## Stop Hook

The stop hook (`hooks/stop.sh`) intercepts session exit and:
1. Checks for completion promise in output
2. Checks iteration limit
3. Updates iteration count
4. Re-displays the prompt to continue

## Examples

### TDD Loop

```bash
/autoloop "Implement auth with TDD:
1. Write failing test
2. Implement feature
3. Run tests
4. Fix failures
5. Repeat until green

When all tests pass: <promise>TESTS PASS</promise>" --max-iterations 15
```

### Feature Development

```bash
/autoloop "Build user dashboard with:
- Profile display
- Activity feed
- Settings panel

Commit after each component.
<promise>DASHBOARD COMPLETE</promise>" --max-iterations 25
```
