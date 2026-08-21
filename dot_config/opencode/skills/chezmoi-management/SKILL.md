---
name: chezmoi-management
description: Use whenever the user says a file, folder, app configuration, theme, script, or generated asset should be managed by chezmoi, mentions `.chezmanga`, asks whether chezmoi correctly tracks a customization, or modifies anything inside a directory tree marked by `.chezmanga/`. Inspect managed state, select only appropriate files, handle machine and OS differences, update the chezmoi source safely, and record every functional change in `.chezmanga/CHANGELOG.md`.
---

# Chezmoi Management

Treat chezmoi as the source of truth for marked configuration projects. A
`.chezmanga/` directory is a management marker: its parent directory and
descendants must be evaluated for chezmoi management. It does not mean that
every file is safe or useful to manage.

## Trigger And Scope

Use this workflow when either condition is true:

- The user explicitly asks to put something under chezmoi management.
- The current directory, a requested path, or a changed file has a
  `.chezmanga/` directory in its nearest ancestor chain.

For each requested or changed path, walk upward to the filesystem root and use
the nearest `.chezmanga/` marker. Its parent is the management root. Do not let
a marker claim sibling directories outside that root.

If no marker exists:

- An explicit request to manage a clearly identified folder authorizes creating
  `<root>/.chezmanga/` and its changelog.
- Otherwise, explain that no marker was found and ask before creating one. Do
  not infer a management root when multiple folders are plausible.

The marker may first be found in the target state or its chezmoi source-state
counterpart. In source state, recognize chezmoi's encoded `dot_chezmanga/` name
as the target `.chezmanga/` marker; account for other source attributes instead
of comparing source names literally. Once the mapping is known, treat both
paths as the same management scope. Keep `.chezmanga/` and its changelog
managed so the intent and history travel to other machines.

## Required Workflow

### 1. Inspect Before Editing

1. Read the nearest project instructions and line-ending rules.
2. Locate the management root and `.chezmanga/` marker.
3. Run `chezmoi source-path` to find the source directory.
4. For each relevant target, run `chezmoi source-path <target>`:
   - A returned source path means the target is already managed.
   - A `not managed` result means it needs an explicit initial-add decision.
5. Inspect scoped `chezmoi diff <target>` output and Git status in the source
   repository. Preserve unrelated or concurrent changes.
6. Inventory relevant files, including hidden files, generated output, ignored
   files, symlinks, binaries, and files that may contain secrets.

Do not use an unscoped `chezmoi re-add`, `chezmoi add`, or `chezmoi apply` for
this workflow. Broad commands can capture private or unrelated home-directory
state.

### 2. Classify What To Manage

Classify every candidate before adding it.

| Classification | Default decision |
|---|---|
| User-authored configuration, theme source, scripts, keybindings, or required documentation | Manage |
| `.chezmanga/` metadata and changelog | Manage |
| Reproducible machine-neutral templates needed to build or deploy the customization | Manage |
| Required runtime artifact when the consuming app cannot build it locally | Manage, but keep its source/build instructions when available |
| OS- or machine-specific configuration | Manage conditionally with templates or ignore rules |
| Cache, log, session state, lock state, crash dump, temporary file, editor backup | Exclude |
| Dependency directory such as `node_modules`, package cache, or downloaded SDK | Exclude |
| Secret, credential, token, private key, browser profile, or authentication state | Exclude unless the user explicitly requests an approved encrypted/password-manager design |
| Build artifact that is reproducible and not consumed directly | Exclude |
| Generated deployment artifact already intentionally tracked and required by the runtime | Manage only after checking references and stale hashes |
| Host-specific absolute path or username embedded in shared content | Replace or template before managing |

Do not decide only from file extensions. Verify how the application builds,
loads, and deploys the file. For hash-named assets, check which files current
entry points reference and exclude stale build output unless the project has a
documented reason to retain it.

### 3. Design For Multiple Machines

Before writing source state, inspect `chezmoi data` and distinguish:

- Portable values shared by all machines.
- OS-specific values using `.chezmoi.os`.
- Architecture-specific values using `.chezmoi.arch`.
- Machine-specific values using `.chezmoi.hostname` only when the difference is
  genuinely tied to one host.
- User-configurable values that belong in `.chezmoi.toml.tmpl` data instead of
  application files.

Prefer these techniques in order:

1. Application-native relative paths and environment variables.
2. Chezmoi templates such as `.chezmoi.homeDir`, `.chezmoi.os`, and configured
   data values.
3. Conditional source content or `.chezmoiignore.tmpl` for platform-specific
   files.
4. Hostname conditionals as a narrow last resort.

Do not copy `C:\Users\<name>`, `/home/<name>`, `/Users/<name>`, drive letters,
or machine-specific installation directories into shared files without a
verified portability decision. Keep Windows and Unix path syntax valid for the
application that consumes the rendered target; a template is not permission to
mix path conventions blindly.

### 4. Update Source State Safely

Use the smallest applicable path set.

- Existing managed path: edit its source-state file first, then apply that
  specific target.
- New unmanaged target: inspect it first, then run `chezmoi add <target>` for
  approved individual files by default. Add a directory recursively only after
  inventorying every descendant and confirming that exclusions prevent caches,
  dependencies, secrets, and stale build output from being captured. Review the
  resulting source paths before continuing.
- Target contains machine-specific literals: convert the source file to a
  `.tmpl` or use an appropriate conditional design before considering it done.
- Files requiring source attributes: use standard chezmoi names such as
  `dot_`, `private_`, `executable_`, and `.tmpl`; verify the rendered target
  name and mode.

Never overwrite unrelated target edits. If source and target both changed in
conflicting ways, stop and ask which version is authoritative. Do not commit or
push the chezmoi repository unless the user explicitly requests it.

### 5. Record Every Functional Change

Maintain `<management-root>/.chezmanga/CHANGELOG.md`. Create it when the marker
is initialized. Append one entry for each user-visible functional modification,
including partial modifications that remain on disk. Do not create noisy entries
for read-only inspection or formatting-only operations unless formatting was the
requested result.

Use this format:

```markdown
## YYYY-MM-DDTHH:mm:ss+HH:MM - <topic>

- Status: Completed | Partial
- Machine: <computer name or hostname>
- Platform: <OS and architecture>
- Scope: <relative paths or component>
- Summary: <what behavior changed>
- Important records:
  - <design decision, migration note, dependency, generated-artifact decision,
    or machine-specific constraint>
- Portability: <how paths and machine differences are handled>
- Chezmoi: <added, updated, templated, conditionally ignored, or already managed>
- Verification: <commands or observations and their results>
```

Use an ISO-style local timestamp with numeric UTC offset. Obtain the machine
name from the environment or a finite hostname command. Do not put secrets,
tokens, private values, or unnecessarily sensitive machine details in the log.
Use paths relative to the management root when possible.

Write the changelog entry after implementation and verification so it records
observed results. If work stops with modified files, append a `Partial` entry
that states what remains incomplete. The changelog update is part of the same
chezmoi-managed change and must be included in scoped diff and apply checks.

### 6. Verify End To End

For every touched scope:

1. Verify each intended target resolves with `chezmoi source-path <target>`.
2. Run scoped `chezmoi diff <target>` and inspect unexpected deletions,
   permission changes, secret material, stale generated files, and hard-coded
   machine paths.
3. Apply only the scoped targets with `chezmoi apply <target>` when application
   to the current machine is part of the request.
4. Read or run the rendered target and perform the closest relevant functional
   check.
5. Verify touched text files use the selected line ending without mixed CRLF
   and LF.
6. Re-check Git status in the chezmoi source and separate this work from
   unrelated changes.
7. Confirm `.chezmanga/CHANGELOG.md` describes the completed or partial result.

## Completion Report

Report:

- Marker and management root used.
- Files added, updated, templated, conditionally excluded, or deliberately left
  unmanaged, grouped by reason.
- Portability decisions and remaining machine-specific assumptions.
- Changelog entry created.
- Verification results and any blocked checks.
- Whether commit, push, or application to another machine still requires a
  separate explicit request.

Do not claim that a file is managed merely because it exists in the chezmoi Git
repository. Confirm the target-to-source mapping and rendered behavior.
