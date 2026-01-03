# Autoloop for Claude Code

Transform Claude Code into an autonomous coding agent that works until your task is complete.

## Installation

```bash
# From GitHub
claude plugin install https://github.com/yaoshengzhe/autoloop/tree/main/plugins/claude-code

# From local clone
claude plugin install ./plugins/claude-code

# Verify
/autoloop --help
```

## Update / Uninstall

```bash
# Update to latest
claude plugin install https://github.com/yaoshengzhe/autoloop/tree/main/plugins/claude-code --force

# Remove
claude plugin uninstall autoloop
```

## Getting Started

### Your First Autonomous Loop

Start a simple loop to see how it works:

```bash
/autoloop Create a hello world Python script with tests --completion-promise 'DONE' --max-iterations 5
```

Claude will:
1. Create the script
2. Write tests
3. Run tests and fix any issues
4. Output `<promise>DONE</promise>` when complete

## Commands Reference

### /autoloop

Starts an autonomous loop with your task.

```bash
/autoloop <your task description> [options]
```

**Options:**

| Option | Description | Example |
|--------|-------------|---------|
| `--completion-promise` | Text that signals completion | `--completion-promise 'DONE'` |
| `--max-iterations` | Maximum loop iterations | `--max-iterations 20` |
| `--help` | Show usage information | `/autoloop --help` |

### /cancel-autoloop

Stops the current loop immediately.

```bash
/cancel-autoloop
```

Use this when you need to change direction or take manual control.

### /autoloop-status

Displays the current loop state including iteration count and elapsed time.

```bash
/autoloop-status
```

## Writing Effective Prompts

The key to successful autonomous loops is clear, specific prompts with verifiable completion criteria.

### Good Example

```bash
/autoloop "Build a user authentication module with:
- Login and logout endpoints
- Password hashing with bcrypt
- JWT token generation
- Unit tests for all functions

Run tests after each change. When all tests pass and coverage exceeds 80 percent: <promise>AUTH COMPLETE</promise>" --max-iterations 20
```

This prompt works because it:
- Lists specific deliverables
- Includes a verification step (run tests)
- Defines measurable completion criteria

### Poor Example

```bash
/autoloop "Make the code better" --max-iterations 10
```

This prompt fails because "better" is subjective and has no clear endpoint.

## Common Patterns

### Test-Driven Development

```bash
/autoloop "Implement the ShoppingCart class using TDD:
1. Write a failing test for add_item
2. Implement add_item to pass the test
3. Write a failing test for remove_item
4. Implement remove_item to pass the test
5. Continue for calculate_total and clear

Run pytest after each implementation. <promise>ALL TESTS GREEN</promise>" --max-iterations 15
```

### Incremental Feature Building

```bash
/autoloop "Build a markdown blog engine:

Phase 1: Parse markdown files from /posts directory
Phase 2: Generate HTML pages in /public directory
Phase 3: Create an index page listing all posts
Phase 4: Add syntax highlighting for code blocks

Commit after each phase. <promise>BLOG ENGINE COMPLETE</promise>" --max-iterations 25
```

### Bug Investigation and Fix

```bash
/autoloop "Fix the memory leak in the WebSocket handler:

1. Add logging to track connection lifecycle
2. Identify where connections are not being cleaned up
3. Implement proper cleanup on disconnect
4. Verify with a load test running 100 connections

<promise>MEMORY LEAK FIXED</promise>" --max-iterations 12
```

## How It Works

Loop state is stored in `.claude/autoloop.local.md` using YAML frontmatter:

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

The stop hook intercepts session exits, updates the iteration count, and re-displays your prompt so Claude can continue working.

## Troubleshooting

**Loop exits immediately**
Your completion promise might be appearing in your prompt. Rephrase to avoid triggering early completion.

**Loop runs forever**
Add `--max-iterations` as a safety limit. Review your completion criteria for clarity.

**Agent seems stuck**
Run `/autoloop-status` to check progress. Consider `/cancel-autoloop` and restarting with a more specific prompt.
