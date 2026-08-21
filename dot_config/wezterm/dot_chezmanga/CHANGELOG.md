# WezTerm Chezmoi Changelog

## 2026-08-21T21:26:29+08:00 - Initialize management scope

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `.`
- Summary: Added a dedicated marker and changelog for WezTerm configuration.
- Important records:
  - The nearest ancestor marker owns future records; nested markers take precedence.
  - `wezterm_local.lua` remains machine-local and excluded from synchronization.
- Portability: Shared configuration uses the cross-platform `.config/wezterm` location.
- Chezmoi: Added and managed as `dot_chezmanga/CHANGELOG.md`.
- Verification: `chezmoi source-path` resolved the target, scoped apply created it, and scoped diff was empty.
