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

## 2026-11-05T02:12:43+08:00 - Restore OpenCode image paste through psmux

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: Windows X64
- Scope: `config.ghostty`
- Summary: Ctrl+V still pastes clipboard text, then sends a raw Ctrl+V (`chain=text:\x16`) so psmux's root `C-v` binding can forward it to OpenCode when the clipboard holds an image.
- Important records:
  - `ctrl+v=paste_from_clipboard` consumed the key. noctty 1.3.135 sends an empty bracketed paste for an image-only clipboard; psmux drops an empty paste, and its `C-v` binding never fired, so OpenCode never read the image.
  - Removing the binding was rejected: the user prefers Ctrl+V over Ctrl+Shift+V for text.
  - psmux keeps text single: its `C-v` binding forwards only in OpenCode panes and only when `Get-Clipboard -Raw` is empty.
  - Outside psmux, OpenCode receives both the text paste and Ctrl+V, so text may paste twice there.
- Portability: Platform-neutral keybind; no paths.
- Chezmoi: Updated the managed source and applied only the noctty targets.
- Verification: Scoped apply and status only. Pasting in noctty was not performed by the agent.
