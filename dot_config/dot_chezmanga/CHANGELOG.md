# Config Root Chezmoi Changelog

## 2026-08-21T21:26:29+08:00 - Initialize root management scope

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: root-level files and shared structure only
- Summary: Added a fallback marker for root-level `.config` files such as `starship.toml`.
- Important records:
  - Child applications use their own nested markers and changelogs.
  - This changelog must not duplicate records owned by a nearer child marker.
- Portability: Marker metadata contains no host-specific paths; the machine name is audit metadata only.
- Chezmoi: Added and managed as `dot_chezmanga/CHANGELOG.md`.
- Verification: `chezmoi source-path` resolved the target, scoped apply created it, and scoped diff was empty.
