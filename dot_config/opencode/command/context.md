---
description: Manage project or global context with explicit storage boundaries
tags: [context, knowledge-management]
dependencies:
  - subagent:context-organizer
  - subagent:contextscout
---

# Context Manager

## Root Resolution

Resolve the roots once before every operation. Keep them separate:

1. `{local_root}` = `{project_root}/.opencode/context/` when running in a repository.
2. `{global_root}` = `C:/Users/tc_tseng/.config/opencode/context/`.
3. `{core_root}` = `{local_root}/core/` only when `{local_root}/core/navigation.md` exists; otherwise use `{global_root}/core/` when `{global_root}/core/navigation.md` exists.
4. `{target_root}` = `{global_root}` with `--global`; otherwise `{local_root}` when running in a repository.

The absence of `{local_root}/core/` is valid for a global OAC installation. Never resolve all context to one root: core standards may come from global while project intelligence comes from local.

Outside a repository without `--global`, do not write and do not guess a project root. Ask the user to select a project directory or rerun with `--global`.

Project context contains architecture, patterns, decisions, and project-specific errors. It should be committed with the project. Global context contains reusable personal standards and defaults. A project context overrides global context.

Do not write project knowledge into `{core_root}`. Core is read-only operating guidance; generated project knowledge belongs under `{target_root}`.

## Safety Rules

- Keep generated context files below 200 lines and organize them by function.
- Preview writes and require approval before replacing, archiving, or deleting files.
- Load the required operation guide before delegating or writing.
- For validation failures, stop, report the failure, and request approval before attempting a repair.

## Operations

### `/context`

Scan the current workspace for summaries and suggest the appropriate operation. This is read-only.

### `/context harvest [path]`

Extract durable project knowledge from summaries or `.tmp/` files. Write it to the resolved target root. Show files proposed for cleanup and require approval before cleanup.

### `/context compact {file}`

Minimize an existing context file to MVI format under `{target_root}` without changing its meaning.

### `/context extract from {source}`

Extract useful knowledge from documentation, code, or a URL into the resolved target root.

### `/context organize {category}`

Restructure a category under the resolved target root into `concepts/`, `examples/`, `guides/`, `lookup/`, and `errors/` as appropriate.

### `/context update for {topic}`

Update context in the resolved target root when an API, dependency, or project pattern changes.

### `/context error for {error}`

Record a recurring, verified error and its resolution in the resolved target root.

### `/context create {category}`

Create a context category in the resolved target root after showing the intended files.

### `/context map [category]` and `/context validate`

Read-only operations. Inspect `{target_root}`. Load governing standards from `{core_root}`, but do not require `{target_root}/core/` to exist.

For `validate`:

- Validate files and navigation links that actually exist under `{target_root}`.
- A project with only `project-intelligence/` is valid; start from its category navigation when no root `navigation.md` exists.
- Report a missing `{core_root}` separately as an installation problem. Never report missing `{target_root}/core/context-system/` when global core fallback resolved successfully.

### `/context migrate`

Move only `project-intelligence/` from:

```text
C:/Users/tc_tseng/.config/opencode/context/project-intelligence/
```

to:

```text
{project_root}/.opencode/context/project-intelligence/
```

Require a repository. Preview differences, request approval before overwriting local files, and request separate approval before removing the global source.

## Delegation

- `harvest`, `compact`, `extract`, `organize`, `update`, `error`, `create`, and `migrate` → ContextOrganizer.
- `map` and `validate` → ContextScout.

Pass the operation, `{project_root}`, `{local_root}`, `{global_root}`, `{core_root}`, `{target_root}`, and safety rules to the subagent. Resolved roots are authoritative: the subagent must not recompute them or infer a global write target from a global installation.

## Lazy Loading

Load operation guides relative to `{core_root}/context-system/`:

| Operation | Required guides |
|---|---|
| `harvest` | `operations/harvest.md`, `standards/mvi.md`, `guides/workflows.md` |
| `compact` | `guides/compact.md`, `standards/mvi.md` |
| `extract` | `operations/extract.md`, `standards/mvi.md`, `guides/compact.md`, `guides/workflows.md` |
| `organize` | `operations/organize.md`, `standards/structure.md`, `guides/workflows.md` |
| `update` | `operations/update.md`, `guides/workflows.md`, `standards/mvi.md` |
| `error` | `operations/error.md`, `standards/templates.md`, `guides/workflows.md` |
| `create` | `guides/creation.md`, `standards/structure.md`, `standards/templates.md` |
| `migrate` | `standards/mvi.md` |

## Examples

```bash
/context harvest
# In a repository: writes to {project_root}/.opencode/context/

/context extract from docs/auth.md
# In a repository: writes to {project_root}/.opencode/context/

/context harvest --global
# Writes to C:/Users/tc_tseng/.config/opencode/context/

/context migrate
# Copies global project-intelligence to the current project's .opencode/context/
```

## Success Criteria

- Target root was resolved before writing.
- Core and target roots were resolved independently.
- Project output is never written globally without `--global`.
- Global core instructions remain unchanged by project operations.
- Cleanup and overwrite actions were explicitly approved.
- `navigation.md` was updated when context files changed.
