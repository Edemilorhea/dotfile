# PowerShell Chezmoi Changelog

## 2026-08-21T21:26:29+08:00 - Initialize management scope

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `.`
- Summary: Added a dedicated marker and changelog for the PowerShell profile.
- Important records:
  - The nearest ancestor marker owns future records; nested markers take precedence.
  - The source remains readonly through the existing chezmoi source attribute.
- Portability: Existing ignore rules apply this profile only when PowerShell synchronization is enabled on Windows.
- Chezmoi: Added and managed as `dot_chezmanga/CHANGELOG.md`.
- Verification: `chezmoi source-path` resolved the target, scoped apply created it, and scoped diff was empty.
