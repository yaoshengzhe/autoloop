# /autoloop-help

Autoloop lets Claude Code work autonomously on your tasks until they are complete.

## Quick Reference

| Command | What It Does |
|---------|--------------|
| `/autoloop <task> [options]` | Start working on a task autonomously |
| `/cancel-autoloop` | Stop the current loop |
| `/autoloop-status` | Check progress and elapsed time |
| `/autoloop-help` | Show this guide |

## Starting a Loop

```bash
/autoloop <task description> --completion-promise '<done signal>' --max-iterations <limit>
```

**Required:** A clear task description

**Recommended Options:**
- `--completion-promise` - The text that signals your task is complete
- `--max-iterations` - Safety limit to prevent endless loops

## The Completion Promise

When your task is done, output the promise text in XML tags:

```
<promise>DONE</promise>
```

The promise should only be output when the statement is genuinely true. This ensures the agent works until real completion, not just to exit the loop.

## Example: Building a Feature

```bash
/autoloop "Create a password reset feature with:
- Reset request endpoint that sends email
- Token validation endpoint
- Password update endpoint
- Unit tests for each endpoint

Run tests after each change. <promise>PASSWORD RESET COMPLETE</promise>" --max-iterations 20
```

The agent will iterate through building each endpoint, writing tests, running them, and fixing any failures until everything works.

## Example: Fixing a Bug

```bash
/autoloop "Debug and fix the cart total calculation:
1. Add logging to trace the calculation
2. Identify where the discount is applied incorrectly
3. Fix the calculation logic
4. Add a test case for the edge case
5. Verify the fix

<promise>BUG FIXED</promise>" --max-iterations 10
```

## Tips for Success

**Be specific.** List exactly what needs to be built or fixed.

**Include verification.** Ask the agent to run tests or validate its work.

**Set iteration limits.** Start with 10-20 iterations for most tasks.

**Use phases for large tasks.** Break complex work into clear milestones.

## What Happens in Each Iteration

1. Claude works on your task
2. Claude attempts to finish the session
3. The stop hook intercepts and checks for completion
4. If not complete, the prompt is re-displayed
5. Claude sees its previous work and continues

All changes are preserved in files and git history, so you can review progress at any time.
