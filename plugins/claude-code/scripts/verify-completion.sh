#!/bin/bash
# verify-completion.sh - Spawn a subagent to independently verify work completion
#
# This script uses 'claude' CLI to spawn an independent verification agent.
# The verifier has NO access to the previous conversation context, ensuring
# unbiased evaluation of the actual work done.

set -uo pipefail

STATE_FILE=".claude/autoloop.local.md"
VERIFICATION_RESULT_FILE=".claude/verification-result.json"

# Parse task from state file
parse_yaml_value() {
  local key="$1"
  sed -n '/^---$/,/^---$/p' "$STATE_FILE" | grep "^${key}:" | sed "s/^${key}: *//" | sed 's/^"\(.*\)"$/\1/'
}

# Extract prompt (content after frontmatter) - this is the original task
FRONTMATTER_END=$(awk '/^---$/ { count++; if (count == 2) { print NR; exit } }' "$STATE_FILE")
ORIGINAL_TASK=$(tail -n +$((FRONTMATTER_END + 1)) "$STATE_FILE" | sed '/./,$!d')

# Get git diff to show what changed
GIT_DIFF=$(git diff HEAD~5..HEAD --stat 2>/dev/null || echo "No git history available")
GIT_DIFF_FULL=$(git diff HEAD~5..HEAD 2>/dev/null | head -500 || echo "")

# Create verification prompt
VERIFICATION_PROMPT=$(cat <<'VERIFY_EOF'
You are an independent verification agent. Your ONLY job is to verify whether the claimed work was actually completed correctly.

## CRITICAL RULES
1. You must ACTUALLY RUN commands to verify - do not trust any claims
2. Be skeptical - assume nothing works until you verify it yourself
3. Check the ACTUAL state of files and code, not what was claimed
4. Return a structured JSON verdict

## Original Task
The developer was asked to do this:
```
ORIGINAL_TASK_PLACEHOLDER
```

## Recent Changes (git diff --stat)
```
GIT_DIFF_PLACEHOLDER
```

## Your Verification Steps

1. **Check if tests exist and pass**
   - Look for test files (package.json scripts, pytest, go test, etc.)
   - Run the actual test command
   - Report: PASS (all pass), FAIL (failures), or SKIP (no tests)

2. **Check if build succeeds**
   - Look for build configuration (package.json, Makefile, Cargo.toml, etc.)
   - Run the actual build command
   - Report: PASS, FAIL, or SKIP

3. **Check if lint passes**
   - Look for lint configuration
   - Run the actual lint command
   - Report: PASS, FAIL, or SKIP

4. **Verify task requirements**
   - Parse the original task into specific requirements
   - Check each one against the actual code/files
   - List which requirements are met vs not met

5. **Final verdict**
   Return ONLY a JSON object (no other output):
   ```json
   {
     "tests": {"status": "PASS|FAIL|SKIP", "evidence": "actual output"},
     "build": {"status": "PASS|FAIL|SKIP", "evidence": "actual output"},
     "lint": {"status": "PASS|FAIL|SKIP", "evidence": "actual output"},
     "requirements": [
       {"requirement": "...", "met": true|false, "evidence": "..."}
     ],
     "verdict": "APPROVED|REJECTED",
     "reason": "Brief explanation"
   }
   ```

## IMPORTANT
- Actually RUN the commands, don't just look at files
- If a check fails, verdict MUST be REJECTED
- If requirements are not met, verdict MUST be REJECTED
- Output ONLY the JSON, nothing else
VERIFY_EOF
)

# Replace placeholders
VERIFICATION_PROMPT="${VERIFICATION_PROMPT//ORIGINAL_TASK_PLACEHOLDER/$ORIGINAL_TASK}"
VERIFICATION_PROMPT="${VERIFICATION_PROMPT//GIT_DIFF_PLACEHOLDER/$GIT_DIFF}"

# Run verification using claude CLI as a subagent
# The subagent runs in non-interactive mode with a fresh context
echo "Spawning independent verification agent..."
echo ""

# Use claude CLI to run verification
# --print flag for non-interactive output
VERIFICATION_OUTPUT=$(claude --print --model haiku "$VERIFICATION_PROMPT" 2>&1)
CLAUDE_EXIT_CODE=$?

if [[ $CLAUDE_EXIT_CODE -ne 0 ]]; then
  echo "ERROR: Verification agent failed to run"
  echo "$VERIFICATION_OUTPUT"
  # Default to rejection on error
  cat > "$VERIFICATION_RESULT_FILE" <<EOF
{
  "tests": {"status": "SKIP", "evidence": "Verification failed to run"},
  "build": {"status": "SKIP", "evidence": "Verification failed to run"},
  "lint": {"status": "SKIP", "evidence": "Verification failed to run"},
  "requirements": [],
  "verdict": "REJECTED",
  "reason": "Verification agent failed: $VERIFICATION_OUTPUT"
}
EOF
  exit 1
fi

# Extract JSON from output (in case there's extra text)
# Use python to reliably extract the JSON object
JSON_OUTPUT=$(python3 -c "
import re
import sys
text = sys.stdin.read()
# Find all JSON-like blocks
matches = re.findall(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', text, re.DOTALL)
if matches:
    # Get the last/most complete match
    for m in reversed(matches):
        if 'verdict' in m:
            print(m)
            sys.exit(0)
    # If no verdict found, print last match
    print(matches[-1])
else:
    sys.exit(1)
" <<< "$VERIFICATION_OUTPUT" 2>/dev/null)

if [[ -z "$JSON_OUTPUT" ]]; then
  echo "ERROR: Could not parse verification result"
  echo "Raw output:"
  echo "$VERIFICATION_OUTPUT"
  cat > "$VERIFICATION_RESULT_FILE" <<EOF
{
  "tests": {"status": "SKIP", "evidence": "Could not parse output"},
  "build": {"status": "SKIP", "evidence": "Could not parse output"},
  "lint": {"status": "SKIP", "evidence": "Could not parse output"},
  "requirements": [],
  "verdict": "REJECTED",
  "reason": "Could not parse verification output"
}
EOF
  exit 1
fi

# Save result
echo "$JSON_OUTPUT" > "$VERIFICATION_RESULT_FILE"

# Parse verdict
VERDICT=$(echo "$JSON_OUTPUT" | grep -o '"verdict"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/".*//')

echo "═══════════════════════════════════════════════════════════"
echo "VERIFICATION RESULT"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "$JSON_OUTPUT" | python3 -m json.tool 2>/dev/null || echo "$JSON_OUTPUT"
echo ""
echo "═══════════════════════════════════════════════════════════"

if [[ "$VERDICT" == "APPROVED" ]]; then
  echo "✓ Verification PASSED"
  exit 0
else
  echo "✗ Verification FAILED"
  exit 1
fi
