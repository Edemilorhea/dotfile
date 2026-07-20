<!-- Context: workflows/delegation | Priority: high | Version: 3.1 | Updated: 2026-02-05 -->
# Delegation Context Template

## Quick Reference

**Process**: Classify → Load supplied context → Discover only gaps → Delegate with inline or shared context → Validate → Cleanup

**Location**: `.tmp/sessions/{YYYY-MM-DD}-{task-slug}/context.md`

**Key Principle**: The orchestrator supplies bounded context. Downstream agents consume it without re-discovery; missing information is requested explicitly. ContextScout is only for unknown standards/convention context, not source-code impact analysis.

**Subagent Type Names**: Use the exact frontmatter `name` values when invoking the task tool: `ContextScout`, `ExternalScout`, `TaskManager`, `CoderAgent`, `CodeReviewer`, `TestEngineer`, `BuildAgent`, `DocWriter`. Avoid historical aliases such as `Task Manager`, `Coder Agent`, `Reviewer`, `Build Agent`, or `Documentation`.

**Approval Boundary**: `ContextScout` and `ExternalScout` are read-only discovery agents and may run before approval. File-mutating agents such as `CoderAgent`, `TestEngineer`, and `DocWriter` require user approval unless the user has already explicitly requested implementation.

---

## When to Create a Session

Only create a session when:
- User has **approved** the proposed approach (never before)
- TaskManager or multiple downstream agents need persistent shared context across batches/handoffs
- Inline context would be duplicated or lose decisions/state between agents

For direct execution or a single bounded specialist/CoderAgent task: pass inline context and skip session creation, regardless of file count.

---

## The Flow

```
Stage 1: CLASSIFY   → Decide direct vs single specialist vs orchestration
Stage 2: CONTEXT    → Use supplied paths; discover only missing standards
Stage 3: APPROVE    → Only when authorization is absent or risk/scope changed
Stage 4: DELEGATE   → Pass inline context, or init context.md only for shared state
Stage 5: VALIDATE   → Targeted checks, then one integrated full validation
Stage 6: CLEANUP    → Ask user, then delete session artifacts if any
```

---

## Template Structure

**Location**: `.tmp/sessions/{YYYY-MM-DD}-{task-slug}/context.md`

```markdown
# Task Context: {Task Name}

Session ID: {YYYY-MM-DD}-{task-slug}
Created: {ISO timestamp}
Status: in_progress

## Current Request
{What user asked for — verbatim or close paraphrase}

## Context Files (Standards to Follow)
Paths ContextScout discovered. Downstream agents load these for coding standards.
- /c/Users/tc_tseng/.config/opencode/context/core/standards/code-quality.md
- {other paths}

## Reference Files (Source Material)
Project files relevant to the task — NOT standards.
- {e.g. package.json}
- {e.g. src/existing-module.ts}

## External Context Fetched
Live docs fetched via ExternalScout. Read-only cache.
- `.tmp/external-context/{package}/{topic}.md` — {description}

## Components
- {Component 1} — {what it does}
- {Component 2} — {what it does}

## Constraints
{Technical constraints, preferences, version requirements}

## Exit Criteria
- [ ] {specific completion condition}

## Progress
- [ ] Session initialized
- [ ] Tasks created (if using TaskManager)
- [ ] Implementation complete
```

---

## Delegation Process

**Step 1-3: Classify, Context, Approve**
- Use supplied context first; call ContextScout only for missing standards paths
- Call ExternalScout only for uncertain current APIs actively used, changed, or diagnosed
- Ask for approval only when not already supplied or when risk/scope materially changes

**Step 4: Choose Delegation Form**
- Single bounded specialist: send requirements, standards paths, references, constraints, and verification inline; do not create a session or call TaskManager.
- Shared-state orchestration: create `.tmp/sessions/{YYYY-MM-DD}-{task-slug}/context.md`, then call TaskManager.

**Step 5: Delegate Shared Orchestration**
```javascript
task(
  subagent_type="TaskManager",
  description="{brief}",
  prompt="Load context from .tmp/sessions/{session-id}/context.md
          {specific instructions}"
)
```

**Step 6: Cleanup (only if a session was created)**
- Ask user: "Task complete. Clean up session files?"
- If approved: Delete session directory

---

## Semantic Rules for Task JSONs

| Field | Contains | Example |
|-------|----------|---------|
| `context_files` | **Standards only** | `/c/Users/tc_tseng/.config/opencode/context/core/standards/code-quality.md` |
| `reference_files` | **Source material only** | `src/auth/service.ts` |
| `external_context` | **External docs only** (read-only) | `.tmp/external-context/drizzle/schemas.md` |

**Never mix them.** Standards vs source material vs external docs.

---

## What Downstream Agents Expect

| Agent | Reads | Does |
|-------|-------|------|
| **TaskManager** | `context.md` (full) | Extracts files, creates subtask JSONs |
| **CoderAgent** | subtask JSON | Loads standards, references source, implements |
| **TestEngineer** | session path | Writes tests against same standards |
| **CodeReviewer** | session path | Reviews against applied standards |

Downstream agents must not repeat discovery already completed by the caller. If supplied context is insufficient and discovering more would expand the bounded scope, return `## Missing Information` and stop.

---

## Review Delegation Boundary

- Only the calling primary agent routes a review. `TaskManager` may plan large-review slices but never dispatches them.
- Each slice must provide the diff/files, standards, evidence, focus, and suggested terminal reviewer.
- `CodeReviewer` and `dotnet-code-reviewer` review only their supplied slice. They do not run `ContextScout`, `TaskManager`, `explore`, or another reviewer.
- A specialist with insufficient evidence returns `## Missing Information` to its caller; it does not broaden the review scope.

---

## Related

- `task-delegation-specialists.md` - When to delegate to which specialist
- `task-delegation-caching.md` - Context caching for repeated patterns
- `../context-system/standards/mvi.md` - MVI principle
