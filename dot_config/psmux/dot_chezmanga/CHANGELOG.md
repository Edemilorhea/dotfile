# psmux Chezmoi Changelog

## 2026-08-21T21:26:29+08:00 - Initialize management scope

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `.`
- Summary: Added a dedicated marker and changelog for psmux configuration.
- Important records:
  - The nearest ancestor marker owns future records; nested markers take precedence.
  - Runtime keys, ports, sessions, logs, and backups remain excluded.
- Portability: psmux remains Windows-specific through existing chezmoi ignore rules.
- Chezmoi: Added and managed as `dot_chezmanga/CHANGELOG.md`.
- Verification: `chezmoi source-path` resolved the target, scoped apply created it, and scoped diff was empty.
