---
description: Review an explicit diff or file scope without recursive reviewer delegation
agent: build
subtask: false
---

# Code Review

Review scope: `$ARGUMENTS`.

1. Apply the global review and delegation rules. Establish the review scope before inspecting findings:
   - With arguments, review only the supplied files, globs, diff range, or explicit focus.
   - Without arguments, review only the current repository's committed diff plus working-tree changes. Do not review the whole repository or adjacent modules by default.
2. Review the supplied diff/files directly. Look first for concrete correctness and security defects introduced by the change, then behavioral regressions, missing tests, maintainability, and performance risks.
3. For a large or mixed review, use the built-in `explore` subagent only to map bounded review slices; assess each slice under the same contract.
4. Do not recursively invoke another reviewer. If the supplied evidence is insufficient, return `## Missing Information` to the caller.

Report only concrete findings inside the supplied scope. Prioritize correctness and security, then maintainability and performance. Include file/line evidence and avoid speculative repository-wide recommendations.

Usage examples:
- `/review` - Review the current committed and working-tree diff only
- `/review @src/components/Button.tsx` - Review one explicit file
- `/review HEAD~1..HEAD` - Review one explicit commit range
