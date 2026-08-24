# OpenCode Chezmoi Changelog

## 2026-08-21T21:26:29+08:00 - Initialize management scope

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `.`
- Summary: Added a dedicated marker and changelog for OpenCode configuration and managed extensions.
- Important records:
  - The nearest ancestor marker owns future records; nested markers take precedence.
  - Secrets, runtime state, caches, and generated dependency directories remain excluded.
- Portability: Marker metadata contains no host-specific paths; the machine name is audit metadata only.
- Chezmoi: Added and managed as `dot_chezmanga/CHANGELOG.md`.
- Verification: `chezmoi source-path` resolved the target, scoped apply created it, and scoped diff was empty.

## 2026-08-21T21:40:51+08:00 - Add selective chezmoi management workflow

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `AGENTS.md.tmpl`, `skills/chezmoi-management/SKILL.md`
- Summary: Added a dedicated workflow for detecting marked scopes, selecting appropriate files, preserving portability, and recording functional changes.
- Important records:
  - OpenCode now checks target `.chezmanga/` and source `dot_chezmanga/` ancestors before changing configuration, themes, scripts, or deployment assets.
  - The workflow defaults to scoped operations and does not treat every descendant of a marker as automatically approved for management.
- Portability: The workflow prefers relative paths, environment variables, and chezmoi templates or data over machine-specific absolute paths.
- Chezmoi: Updated the source template and added the skill under the OpenCode-managed scope.
- Verification: Source and runtime files matched after scoped apply; skill frontmatter, LF line endings, and scoped chezmoi diff were validated.

## 2026-08-21T22:02:53+08:00 - Reduce routine task overhead

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `AGENTS.md.tmpl`, `skills/chezmoi-management/SKILL.md`
- Summary: Limited routine validation and line-ending checks to the smallest relevant scope and added a fast path for ordinary edits to existing managed files.
- Important records:
  - Code and behavior validation now runs once after the task's final edit instead of after every intermediate edit.
  - Routine managed-file edits no longer require Git status, repository-wide diff, candidate inventory, secret scanning, or portability analysis.
  - The full workflow remains required for new files, generated or binary assets, sensitive or machine-specific content, conflicts, audits, and commit or push requests.
- Portability: No platform behavior changed; the lighter workflow still preserves scoped source-to-target synchronization.
- Chezmoi: Updated the managed OpenCode instructions and skill, then applied both exact targets.
- Verification: Runtime content matched source after scoped apply, scoped status was clean, and the two manually edited configuration files remained LF-only.
