# Zebar Chezmoi Changelog

## 2026-08-21T21:26:29+08:00 - Initialize parent management scope

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `settings.json`, `workspace-bar`, and shared Zebar structure
- Summary: Added a parent marker for Zebar settings and widgets outside `overline-custom`.
- Important records:
  - `overline-custom` uses its own nested marker and changelog.
  - This changelog must not duplicate records owned by the nearer Overline marker.
- Portability: Existing ignore rules limit `.glzr` configuration to Windows targets.
- Chezmoi: Added and managed as `dot_chezmanga/CHANGELOG.md`.
- Verification: `chezmoi source-path` resolved the target, scoped apply created it, and scoped diff was empty.
