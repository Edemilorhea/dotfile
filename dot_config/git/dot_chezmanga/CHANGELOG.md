# Git Chezmoi Changelog

## 2026-08-21T21:26:29+08:00 - Initialize management scope

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `.`
- Summary: Added a dedicated marker and changelog for Git configuration.
- Important records:
  - The nearest ancestor marker owns future records; nested markers take precedence.
  - Credentials and authentication helpers require separate security review.
- Portability: Marker metadata contains no host-specific paths; the machine name is audit metadata only.
- Chezmoi: Added and managed as `dot_chezmanga/CHANGELOG.md`.
- Verification: `chezmoi source-path` resolved the target, scoped apply created it, and scoped diff was empty.

## 2026-10-13T14:10:47+08:00 - Ignore AGENTS.local.md globally

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `ignore`
- Summary: Added `AGENTS.local.md` to the global gitignore so personal per-project agent rules are never committed.
- Important records:
  - The OpenCode plugin `selfmade.agents-local` (opencode-assets) loads these files.
- Portability: Pattern only; no machine-specific paths.
- Chezmoi: Already managed; updated `dot_config/git/ignore`.
- Verification: Scoped apply; `git check-ignore` result reported in task.