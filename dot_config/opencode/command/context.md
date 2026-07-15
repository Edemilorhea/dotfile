---
description: Manage project or global context with explicit storage boundaries
tags: [context, knowledge-management]
dependencies:
  - subagent:context-organizer
  - subagent:contextscout
---

# Context Manager

## Storage Policy

Load operation instructions from `C:/Users/tc_tseng/.config/opencode/context/core/context-system/`.

Use this target resolver before every operation that writes context:

1. `--global` → `C:/Users/tc_tseng/.config/opencode/context/`.
2. In a repository without `--global` → `{project_root}/.opencode/context/`.
3. Outside a repository without `--global` → do not write; ask the user to either select a project directory or rerun with `--global`.

Project context contains architecture, patterns, decisions, and project-specific errors. It should be committed with the project. Global context contains reusable personal standards and defaults. A project context overrides global context.

Do not write project knowledge into the global core standards directory. The global `core/context-system/` directory contains only the command's operating instructions.

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

Read-only operations. Inspect the resolved project root when in a repository; otherwise inspect the global root only when explicitly requested with `--global`.

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

- `harvest`, `extract`, `organize`, `update`, `error`, `create`, and `migrate` → ContextOrganizer.
- `map` and `validate` → ContextScout.

Pass the resolved target root, the global operation-instruction path, and the safety rules to the subagent. Do not let a subagent infer a global write target from a global OpenCode installation.

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
- Project output is never written globally without `--global`.
- Global core instructions remain unchanged by project operations.
- Cleanup and overwrite actions were explicitly approved.
- `navigation.md` was updated when context files changed.
