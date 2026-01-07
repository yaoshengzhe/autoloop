# /autoloop-status

Check the status of the current autoloop.

## Usage

```
/autoloop:autoloop-status
```

Displays:
- Current iteration number
- Max iterations (if set)
- Elapsed time
- Active status
- Verification method

---

```bash
STATE_FILE=".claude/autoloop.local.md"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "No active autoloop"
  exit 0
fi

# Parse YAML frontmatter
parse_yaml_value() {
  local key="$1"
  sed -n '/^---$/,/^---$/p' "$STATE_FILE" | grep "^${key}:" | sed "s/^${key}: *//" | sed 's/^"\(.*\)"$/\1/'
}

ACTIVE=$(parse_yaml_value "active")
ITERATION=$(parse_yaml_value "iteration")
MAX_ITERATIONS=$(parse_yaml_value "max_iterations")
STARTED_AT=$(parse_yaml_value "started_at")

# Calculate elapsed time
if [[ -n "$STARTED_AT" ]]; then
  START_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$STARTED_AT" "+%s" 2>/dev/null || date -d "$STARTED_AT" "+%s" 2>/dev/null || echo "0")
  NOW_EPOCH=$(date "+%s")
  ELAPSED=$((NOW_EPOCH - START_EPOCH))
  ELAPSED_MIN=$((ELAPSED / 60))
  ELAPSED_SEC=$((ELAPSED % 60))
  ELAPSED_STR="${ELAPSED_MIN}m ${ELAPSED_SEC}s"
else
  ELAPSED_STR="unknown"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "AUTOLOOP STATUS"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Active:       $ACTIVE"
echo "Iteration:    $ITERATION$(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo "/$MAX_ITERATIONS"; fi)"
echo "Elapsed:      $ELAPSED_STR"
echo "Verification: Independent subagent"
echo ""
echo "To complete: output <complete/>"
echo ""
echo "═══════════════════════════════════════════════════════════"
```
