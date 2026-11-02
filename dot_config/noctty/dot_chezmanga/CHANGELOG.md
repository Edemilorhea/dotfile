# noctty Configuration Changelog

## 2026-11-02T16:44:28+08:00 - Bring noctty config under chezmoi

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: Windows X64
- Scope: `config.ghostty`, `AppData/Local/noctty/config.ghostty` (symlink), `.chezmanga/CHANGELOG.md`
- Summary: noctty reads `%LOCALAPPDATA%/noctty/config.ghostty`. The existing file moved to `~/.config/noctty/config.ghostty`, and a chezmoi-managed symlink now points the noctty path at it.
- Important records:
  - Symlink target is relative (`../../../.config/noctty/config.ghostty`), following the `tuios` convention.
  - Runtime state in `%LOCALAPPDATA%/noctty` (`crash/`, `shell-integration/`, `*-state.json`, `jump-list-recents.json`, `startup-attempts.json`, `*.lock`) is not managed.
  - Original file backed up to `%TEMP%/opencode/noctty-config.ghostty.bak`.
- Portability: noctty is Windows-only; `.config/noctty/**` is ignored on non-Windows in `.chezmoiignore.tmpl`, and `AppData/**` already is. Config has no absolute paths.
- Chezmoi: Added `dot_config/noctty/config.ghostty`, `AppData/Local/noctty/symlink_config.ghostty`, and this changelog; applied with scoped `chezmoi apply`.
- Verification: Scoped `chezmoi status` clean; the noctty path resolves to the symlink. Reload in noctty not verified.
