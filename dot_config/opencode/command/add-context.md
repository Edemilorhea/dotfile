---
description: Create or update project intelligence with explicit local and global storage
tags: [context, onboarding, project-intelligence, wizard]
dependencies:
  - subagent:context-organizer
---

# Add Context

Create project intelligence from real project examples. Ask only for information needed to capture the project's stack, patterns, naming, standards, and security requirements.

## Storage Policy

Resolve `$CONTEXT_DIR` before scanning or writing:

1. `--global` → `C:/Users/tc_tseng/.config/opencode/context/project-intelligence/`.
2. In a repository without `--global` → `{project_root}/.opencode/context/project-intelligence/`.
3. Outside a repository without `--global` → stop and ask the user to select a project directory or rerun with `--global`.

Create the selected directory when it does not exist. Never substitute the global directory for a project-local target. Project intelligence is intended to be committed and shared with the project's team. Global intelligence is a personal fallback only.

## Workflow

1. Resolve `$CONTEXT_DIR` using the storage policy.
2. Check `.tmp/` for optional external context material; offer `/context harvest`, but do not clean anything automatically.
3. Inspect `$CONTEXT_DIR` for existing `technical-domain.md` and `navigation.md`.
4. Ask for or infer from the codebase:
   - Tech stack
   - API or component examples
   - Naming conventions
   - Code standards
   - Security requirements
5. Show a preview and request approval before writing.
6. Create or update `$CONTEXT_DIR/technical-domain.md` and `$CONTEXT_DIR/navigation.md`.
7. Validate the generated files, then report their exact location.

## File Requirements

- Each file is below 200 lines and scannable.
- Each file starts with HTML context frontmatter containing category, priority, version, and update date.
- `technical-domain.md` includes concise codebase references.
- Update `navigation.md` whenever a context file changes.
- Content changes increment the minor version; structural changes increment the major version.

## Existing Context

When files already exist, offer numbered choices:

1. Review and update existing patterns.
2. Add patterns while retaining existing content.
3. Replace patterns after showing a backup and replacement preview.
4. Cancel.

Require explicit approval before replacing or deleting existing files. Backups belong under the current project's `.tmp/backup/` unless the user explicitly selected `--global`.

## Usage

```bash
/add-context
# Saves to {project_root}/.opencode/context/project-intelligence/

/add-context --update
# Updates project intelligence in the same local directory

/add-context --tech-stack
# Updates only the stack information after preview

/add-context --global
# Saves to C:/Users/tc_tseng/.config/opencode/context/project-intelligence/
```

## Delegation

Delegate create and update work to ContextOrganizer. Pass `$CONTEXT_DIR`, the distinction between project and global context, and all file requirements. The subagent must not infer the target from the global installation path.

## Success Criteria

- The target is local by default when a repository is present.
- Global output happens only with `--global`.
- Project output is suitable for source control.
- The write preview was approved.
- `technical-domain.md` and `navigation.md` were validated and reported.
