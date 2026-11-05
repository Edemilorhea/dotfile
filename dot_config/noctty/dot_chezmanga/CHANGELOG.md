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

## 2026-11-05T10:40:19+08:00 - Keep text paste compacted in OpenCode through psmux

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `config.ghostty`
- Summary: Reversed the Ctrl+V chain to send Ctrl+V first (`text:\x16`) and then paste the clipboard, so psmux paste detection wraps text as one bracketed paste.
- Important records:
  - With paste first and Ctrl+V after, the trailing Ctrl+V landed inside psmux's paste staging window and flushed the pending characters as keystrokes. Newlines became Enter, so OpenCode submitted the text and did not compact it into `[Pasted ~N lines]`. This cause is inferred from psmux docs and discussion #859, not from an input log.
  - psmux treats a Ctrl+V press followed by characters as a paste; a Ctrl+V press with no characters runs the root `C-v` binding, which forwards Ctrl+V to OpenCode only when the clipboard has no text.
- Portability: Platform-neutral keybind; no paths.
- Chezmoi: Updated the managed source and applied only the noctty targets.
- Verification: Scoped apply and status only. Pasting text and an image in noctty was not performed by the agent.

## 2026-11-05T14:33:48+08:00 - Let the shell receive Shift+Home/End

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `config.ghostty`
- Summary: Unbound the default `shift+home=scroll_to_top` and `shift+end=scroll_to_bottom`, so nu.exe (reedline) receives Shift+Home/End and can select to line start or end.
- Important records:
  - Root cause: noctty consumed Shift+Home/End as scroll actions, confirmed with `noctty +list-keybinds`.
  - Shift+Home/End no longer scroll the terminal to top or bottom.
- Portability: Platform-neutral keybind; no paths.
- Chezmoi: Updated the managed source and applied only the noctty targets.
- Verification: `noctty +list-keybinds` check only. Selecting text in noctty was not performed by the agent.
