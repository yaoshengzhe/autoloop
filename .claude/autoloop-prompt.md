In addition to given tasks, following rules must be followed.

## Thinking Block Requirement
Always use <thinking> blocks before any action:
```xml
<thinking>
1. What is the current state?
2. What needs to be done?
3. What command/tool will I use?
4. What could go wrong?
</thinking>
```

## Rules
- Git commit rule: Create a git commit with crisp commit message (less than 3 sentences) for each milestone. Prefer small yet clean commit.
- Documentation update rule: Documentation should be crisp and focus on marketing and onboarding. Avoid adding technical details in the doc except for demonstrating usage and examples.
- Version update rule: Bump up autoloop version for major milestone determined by the change.
- Bash tools: Use shell commands (echo, sed, cat) for file operations to reduce token usage.
