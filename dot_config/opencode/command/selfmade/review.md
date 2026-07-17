---
description: Review an explicit diff or file scope without recursive reviewer delegation
agent: OpenAgent
subtask: false
---

# Code Review

Review scope: `$ARGUMENTS`.

1. Load the review and delegation standards. Establish the review scope before delegating:
   - With arguments, review only the supplied files, globs, diff range, or explicit focus.
   - Without arguments, review only the current repository's committed diff plus working-tree changes. Do not review the whole repository or adjacent modules by default.
2. OpenAgent is the routing owner. It passes the scoped diff/files, standards, evidence, and focus to exactly one terminal specialist for a small review:
   - `.NET`-only scope → `dotnet-code-reviewer`
   - Any other single-language scope → `CodeReviewer`
3. For a large or mixed review, OpenAgent may ask `TaskManager` to produce bounded review slices. TaskManager plans only; OpenAgent dispatches each slice to the appropriate terminal reviewer.
4. A terminal reviewer must not invoke ContextScout, TaskManager, explore, another reviewer, or any other subagent. If the supplied evidence is insufficient, it returns `## Missing Information` to OpenAgent.

Report only concrete findings inside the supplied scope. Prioritize correctness and security, then maintainability and performance. Include file/line evidence and avoid speculative repository-wide recommendations.

Usage examples:
- `/review` - Review the current committed and working-tree diff only
- `/review @src/components/Button.tsx` - Review one explicit file
- `/review HEAD~1..HEAD` - Review one explicit commit range
