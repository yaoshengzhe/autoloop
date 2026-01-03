# /autoloop

Start an autonomous iterative loop that continues until completion criteria are met.

## Usage

```
/autoloop "<prompt>" --completion-promise "<text>" [--max-iterations <n>]
```

## Options

- `--completion-promise "<text>"` - Exact text that signals completion (required for automatic stop)
- `--max-iterations <n>` - Maximum iterations before stopping (default: unlimited)

## How It Works

1. Execute your prompt
2. When you try to exit, the stop hook intercepts and re-feeds the prompt
3. Each iteration sees your previous work in files and git history
4. Loop ends when you output `<promise>TEXT</promise>` or reach max iterations

## Example

```
/autoloop "Build a REST API with tests. When all tests pass: <promise>COMPLETE</promise>" --max-iterations 10
```

---

```bash
"$PLUGIN_DIR/scripts/setup-loop.sh" $ARGUMENTS

if [ -f .claude/autoloop.local.md ]; then
  PROMISE=$(grep '^completion_promise:' .claude/autoloop.local.md | sed 's/completion_promise: *//' | sed 's/^"\(.*\)"$/\1/')
  if [ -n "$PROMISE" ] && [ "$PROMISE" != "null" ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "AUTOLOOP STARTED"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "To complete this loop, output this EXACT text:"
    echo "  <promise>$PROMISE</promise>"
    echo ""
    echo "Requirements:"
    echo "  ✓ The statement MUST be completely TRUE"
    echo "  ✓ Do NOT output false promises to exit early"
    echo "═══════════════════════════════════════════════════════════"
  fi
fi
```
