# Autoloop

Autonomous iterative loop framework for AI agents. Keeps working on a task until completion criteria are met.

## Overview

Autoloop creates a self-reinforcing development cycle where an AI agent iteratively improves on a task. When the agent tries to exit, a stop hook intercepts and feeds the same prompt back, allowing the agent to see its previous work and continue improving.

## Architecture

```
autoloop/
├── src/
│   ├── core/                 # Platform-agnostic loop logic
│   │   ├── loop-state.js     # State management
│   │   └── loop-controller.js # Loop orchestration
│   └── adapters/
│       └── claude-code/      # Claude Code adapter
└── plugins/
    └── claude-code/          # Claude Code plugin
        ├── commands/         # /autoloop, /cancel-autoloop
        └── hooks/            # Stop hook for loop persistence
```

The core is platform-agnostic. Adapters handle platform-specific state persistence. Plugins provide the user interface.

## Installation

### Claude Code Plugin

```bash
# From the plugin directory
claude plugin install ./plugins/claude-code
```

## Usage

```bash
# Start a loop with completion promise
/autoloop Build a REST API --completion-promise 'DONE' --max-iterations 20

# Cancel active loop
/cancel-autoloop

# Show help
/autoloop --help
```

## How It Works

1. **Start**: `/autoloop` initializes state and displays the prompt
2. **Work**: Agent works on the task, making changes and commits
3. **Stop Intercept**: When agent tries to exit, hook re-feeds the prompt
4. **Iteration**: Agent sees previous work in files/git and continues
5. **Complete**: Agent outputs `<promise>TEXT</promise>` when done

## Completion Promise

To exit the loop, output the exact promise text in XML tags:

```
<promise>DONE</promise>
```

The promise must be **true** - the loop is designed to continue until genuine completion.

## Options

| Option | Description |
|--------|-------------|
| `--completion-promise <text>` | Text that signals task completion |
| `--max-iterations <n>` | Maximum iterations before auto-stop |
| `-h, --help` | Show usage information |

## Extending

To add support for other AI agents:

1. Create an adapter in `src/adapters/<agent-name>/`
2. Implement `readState()`, `writeState()`, `clearState()`
3. Create a plugin in `plugins/<agent-name>/` with commands and hooks

## License

MIT
