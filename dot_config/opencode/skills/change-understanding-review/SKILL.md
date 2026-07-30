---
name: change-understanding-review
description: Use whenever the user asks what changed, wants to understand completed implementation, asks to 查看修改、了解 code、回顧實作、這次改了什麼, or needs a diff explained by requirement or business intent with actual code ranges and clear Added, Modified, and Removed labels. Produces an evidence-based change walkthrough, not a correctness/security code review and not a general project tutorial.
---

# Change Understanding Review

Explain a completed change so the user can connect the original need to the actual code. Focus on what changed, why the change exists, how behavior now flows, and which code was added, modified, or removed.

This is a comprehension workflow. It does not approve code, score quality, or search broadly for defects unless the user separately asks for a conventional code review.

## Routing Boundaries

Use this skill when the primary question is one of these:

- What changed in this implementation?
- Which requirement, feature, or business rule does each change support?
- What code was added versus modified?
- How does the behavior differ before and after?
- Which files, symbols, and line ranges implement the change?

Use a conventional code-review workflow instead when the primary request is correctness, security, performance, maintainability, approval, or defect detection.

Use `vibe-coding-tutor` instead when the user wants a broad project tutorial, architecture lesson, extension exercises, or onboarding walkthrough rather than a bounded change explanation.

If the request contains both comprehension and correctness review, keep them as two explicit parts. Complete the change-understanding report first; do not mix severity findings into the change map.

## Evidence Rules

Base every code-specific claim on available evidence:

1. Prefer the diff, commit, range, pull request, or files named by the user.
2. If no scope is named and the current directory is a Git repository, inspect the working-tree and staged diffs.
3. Read enough surrounding code to identify symbols, callers, data flow, and behavioral context. Do not expand into an unrelated repository-wide review.
4. Recover the requirement or business intent from the user's request, linked issue, commit message, tests, names, and surrounding behavior.
5. Label intent as `Confirmed`, `Inferred`, or `Unknown`. Never present a plausible business explanation as confirmed fact.
6. Do not claim a test was executed unless execution evidence exists. Distinguish implemented behavior, test coverage, and verified runtime behavior.
7. Follow the host project's database-context rules whenever a change depends on schemas, SQL, or persisted data. Never invent table structures or data contracts.

Ask a clarifying question only when different baselines or scopes would materially change the report and no source is clearly preferred.

## Change Classification

Classify change units by semantic role, not merely by diff-line prefix:

- `[ADDED]`: A new file, symbol, field, branch, validation, integration, or externally observable behavior.
- `[MODIFIED]`: Existing logic, configuration, data flow, contract usage, or behavior was changed. A replacement hunk is normally one modified unit, not unrelated removal and addition units.
- `[REMOVED]`: Existing behavior, symbol, branch, configuration, or dependency was intentionally removed without a direct in-place replacement.
- `[CONTEXT]`: Unchanged surrounding code shown only to explain where a change fits. Do not count it as a change.

Group generated artifacts, lockfiles, snapshots, and formatting-only edits separately so they do not obscure behavior-bearing changes.

## Analysis Workflow

### 1. Establish the baseline and scope

State exactly what is being compared, such as:

- Working tree versus `HEAD`
- One commit versus its parent
- A supplied commit range
- A pasted before/after diff
- The implementation performed in the current conversation

Record any limitation that prevents recovering the original version.

### 2. Build a complete change inventory

List every changed file and behavior-bearing change unit. For each unit, capture:

- Classification
- Current `file:line-range`
- Old diff range when available
- Symbol or configuration key
- Requirement, feature, business rule, or technical necessity served
- Direct dependencies and downstream effect

The change map must be complete even when the detailed section uses bounded excerpts.

### 3. Reconstruct the behavior flow

Trace the smallest end-to-end path that explains the change:

`Need or trigger -> entry point -> decision or transformation -> state or dependency -> observable result`

Explain how the old flow behaved and what changed in the new flow. Separate user-visible behavior from internal enabling work.

### 4. Show actual code and range

Use real excerpts from the evidence, not pseudocode.

For `[MODIFIED]` units, keep `Before` and `After` adjacent:

````markdown
**Before — `path/to/file.ext:old-start-old-end`**
```language
actual old code
```

**After — `path/to/file.ext:new-start-new-end`**
```language
actual current code
```
````

Then explain the exact behavioral difference. Never insert unrelated explanation between `Before` and `After`.

For `[ADDED]` units, show an `Added code` block with the current range and explain where it connects to existing code.

For `[REMOVED]` units, show the removed code with its old range and explain what behavior disappeared or superseded it.

Keep excerpts bounded but sufficient to reveal inputs, conditions, transformations, and outputs. If a hunk is too large, show the behavior-bearing portion and cite the complete range in the change map.

### 5. Connect code to intent

For each change unit, explicitly answer:

1. What was changed?
2. Why was it necessary?
3. Which feature, business rule, requirement, or technical constraint does it support?
4. How does it participate in the end-to-end flow?
5. What would be missing or behave differently without it?

Do not use vague explanations such as "improves the code" or "supports the feature" without identifying the concrete behavior.

## Required Report Structure

Use this structure. Omit a subsection only when it is genuinely inapplicable, not to shorten the analysis.

```markdown
# Change Understanding Review: [scope]

## 1. What This Change Delivers

**Requirement or business need:** ...
**Resulting behavior:** ...
**Intent confidence:** Confirmed | Inferred | Unknown
**Compared baseline:** ...

## 2. Change Map

| Type | File and range | Symbol or area | Purpose | Intent evidence |
|------|----------------|----------------|---------|-----------------|
| [MODIFIED] | `path/file.ext:10-28` | `SymbolName` | ... | Confirmed: ... |

## 3. Behavior Flow

### Before
...

### After
...

### Functional Difference
...

## 4. Detailed Changes

### Change 1 — [behavior-oriented title]

**Type:** [ADDED] | [MODIFIED] | [REMOVED]
**Scope:** `path/file.ext:line-range`
**Supports:** [requirement, feature, business rule, or technical constraint]
**Why:** ...

[Actual code blocks appropriate to the classification]

**What is different:** ...
**Role in the flow:** ...
**Without this change:** ...

## 5. Added, Modified, and Removed Summary

### Added
- ...

### Modified
- ...

### Removed
- None | ...

## 6. Evidence, Validation, and Unknowns

**Evidence used:** ...
**Tests present:** ...
**Execution evidence:** Not run | [actual evidence]
**Unknown or inferred intent:** ...

## 7. Mental Model

[One concise paragraph connecting the requirement to the changed code path.]
```

## Scale the Detail Without Losing Coverage

- **Small change:** Explain every behavior-bearing hunk with actual code.
- **Medium change:** Keep the change map complete and show actual code for every semantic unit, consolidating tightly related hunks.
- **Large change:** Keep the full file/change inventory, then deep-dive into business-critical paths and summarize generated or repetitive changes separately.

Never hide omitted scope. State what was summarized and why.

## Output Quality Checks

Before returning the report, verify that:

- The compared baseline and scope are explicit.
- The report explains requirement or business intent, not only mechanics.
- Every changed file appears in the change map.
- Added, modified, and removed work are visibly distinct.
- Every modified unit keeps actual `Before` and `After` code adjacent.
- Code-specific claims include `file:line-range` evidence.
- The report distinguishes confirmed facts, inference, and unknowns.
- The report does not drift into conventional defect review or a generic project tutorial.
- No test or runtime verification is claimed without evidence.

Use Traditional Chinese for explanations. Preserve original code, identifiers, paths, commands, requirement names, and business terms as written.
