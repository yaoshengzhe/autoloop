# Autoloop

**Let your AI agent work autonomously until the job is done.**

Autoloop is a framework that transforms AI coding assistants into autonomous workers. Instead of stopping after each response, your agent continues iterating on a task until it meets your completion criteria. Walk away from your keyboard and return to working code.

## Why Autoloop?

Traditional AI coding assistants require constant supervision. You prompt, they respond, you review, you prompt again. This back-and-forth is time-consuming and breaks your flow.

Autoloop changes this dynamic:

- **Set it and forget it** - Define your task and completion criteria, then let the agent work independently
- **Self-correcting iterations** - The agent sees its previous work and fixes issues automatically
- **Built-in safety limits** - Maximum iteration counts prevent runaway loops
- **Full visibility** - All work is preserved in files and git history for your review

## Quick Start

### 1. Install

```bash
# Add the marketplace (one-time setup)
claude plugin marketplace add yaoshengzhe/autoloop

# Install the plugin
claude plugin install autoloop@yaoshengzhe-autoloop

# Or install from local clone
claude plugin install ./plugins/claude-code
```

### 2. Start Your First Loop

```bash
/autoloop Build a REST API with user authentication --completion-promise 'DONE' --max-iterations 15
```

### 3. Let It Work

The agent will iterate on the task, making commits and improvements. When finished, it outputs `<promise>DONE</promise>` and the loop ends.

## How It Works

1. You provide a task description and completion criteria
2. The agent works on the task and attempts to exit
3. A stop hook intercepts the exit and re-feeds your prompt
4. The agent sees its previous work in files and git history
5. It continues improving until the completion promise is genuinely true

Each iteration builds on the last. The agent reviews what it built, identifies gaps, and addresses them systematically.

## Use Cases

**Feature Development** - Describe a feature with acceptance criteria and let the agent build it end-to-end with tests.

**Test-Driven Development** - The agent writes tests, implements code, runs tests, and fixes failures in a continuous loop.

**Refactoring** - Point the agent at legacy code with specific improvement goals and let it work through the changes.

**Bug Fixes** - Describe the bug and expected behavior, then let the agent investigate, fix, and verify.

## Commands

| Command | Purpose |
|---------|---------|
| `/autoloop <task> [options]` | Start an autonomous loop |
| `/cancel-autoloop` | Stop the current loop |
| `/autoloop-status` | Check loop progress |
| `/autoloop --help` | View all options |

## Options

| Option | Description |
|--------|-------------|
| `--completion-promise <text>` | The exact text that signals task completion |
| `--max-iterations <n>` | Safety limit on iteration count |

## Best Practices

**Be specific about completion criteria.** Vague goals lead to endless loops. Define exactly what "done" looks like.

**Always set max-iterations.** This prevents runaway loops if the agent gets stuck. Start with 10-20 for most tasks.

**Include verification steps in your prompt.** Ask the agent to run tests or validate its work before claiming completion.

**Use git commits as checkpoints.** Instruct the agent to commit after each milestone so you can review progress.

## Plugin Management

```bash
# Add marketplace (one-time)
claude plugin marketplace add yaoshengzhe/autoloop

# Install
claude plugin install autoloop@yaoshengzhe-autoloop

# Update (reinstall latest)
claude plugin install autoloop@yaoshengzhe-autoloop --force

# Uninstall
claude plugin uninstall autoloop
```

## Architecture

Autoloop is designed for extensibility. The core logic is platform-agnostic, with adapters handling platform-specific integration.

```
autoloop/
├── src/
│   ├── core/           # Platform-agnostic loop logic
│   └── adapters/       # Platform-specific integrations
└── plugins/
    └── claude-code/    # Claude Code plugin
```

Adding support for other AI agents requires implementing an adapter and plugin for that platform.

## License

MIT
