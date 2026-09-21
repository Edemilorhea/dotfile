# TUIOS Configuration Changelog

## 2026-09-21T10:53:09+08:00 - Dockbar and window chrome appearance

- Status: Completed
- Machine: TC-TSENG
- Platform: Windows X64
- Scope: `config.toml`, `.chezmanga/CHANGELOG.md`
- Summary: Enabled the dockbar clock, hid per-window minimize/maximize/close buttons, and moved window titles to the top border to approximate the psmux tokyonight status-line look.
- Important records:
  - Installed TUIOS is v0.7.0; the `[dock]` component table, settings page, and custom dock components exist only on newer main and were not used.
- Portability: No paths; options are documented `[appearance]` keys in v0.7.0.
- Chezmoi: Updated `dot_config/tuios/config.toml` and applied it; the Windows symlink from the previous entry carries the change.
- Verification: Scoped `chezmoi apply` and `chezmoi status` clean; source file LF-only. Rendered appearance not verified (requires launching the TUI).

## 2026-09-21T10:08:41+08:00 - Load config on Windows and release GlazeWM-owned Alt keys

- Status: Completed
- Machine: TC-TSENG
- Platform: Windows X64
- Scope: `config.toml`, `AppData/Local/tuios/config.toml` (symlink), `.chezmanga/CHANGELOG.md`
- Summary: TUIOS on Windows reads `%LOCALAPPDATA%/tuios/config.toml` (`tuios config path`), so the file under `~/.config/tuios` was never loaded and TUIOS ran with all defaults (Ctrl+B leader). Added a chezmoi-managed symlink from `%LOCALAPPDATA%/tuios/config.toml` to `~/.config/tuios/config.toml`. Released every TUIOS default that GlazeWM already intercepts at the OS level: `alt+1..9` / `alt+shift+1..9` (workspaces), `alt+h/j/k/l` (BSP preselect), and `alt+p` (terminal-mode previous window). Workspace switching now goes through `<leader> w 1-9`, matching the psmux prefix habit.
- Important records:
  - Symlink target is relative (`../../../.config/tuios/config.toml`), following the existing `symlink_dot_psmux.conf` convention.
  - The auto-generated default `%LOCALAPPDATA%/tuios/config.toml` was replaced by the symlink; it contained only TUIOS defaults.
  - `alt+n` (terminal-mode next window) and `alt+esc` (back to WM mode) are not bound in GlazeWM and were left as-is.
  - Installed TUIOS is a `go install` dev build; `tuios keybinds explain` is not available in it, and `tuios keybinds list` prints a stale "Ctrl+B is not configurable" note while only showing a subset of sections.
- Portability: `AppData/**` is already ignored on non-Windows by `.chezmoiignore.tmpl`; Linux/macOS keep reading `~/.config/tuios/config.toml` directly. No absolute paths added.
- Chezmoi: Updated `dot_config/tuios/config.toml`; added `AppData/Local/tuios/symlink_config.toml`; both applied with scoped `chezmoi apply`.
- Verification: `tuios config path` resolves to `%LOCALAPPDATA%/tuios/config.toml`, which is now a symlink to `~/.config/tuios/config.toml`. `tuios keybinds list-custom` went from "No custom keybindings configured" to 24 customized bindings (workspace, move-and-follow, preselect, snap). Scoped `chezmoi status` is clean; source `config.toml` is LF-only. Not verified: `leader_key = "alt+a"`, `nav_*` h/j/k/l, and `terminal_prev_window = []` do not appear in the CLI listings; confirm in-app with `tuios --show-keys`.

## 2026-09-03T13:36:29+08:00 - Add psmux-inspired configuration

- Status: Partial
- Machine: TC-TSENG
- Platform: Windows X64
- Scope: `config.toml`, `.chezmanga/CHANGELOG.md`
- Summary: Added a TUIOS v0.7-compatible configuration using Nushell, Tokyo Night, a top dockbar, 50,000 scrollback lines, shared borders, an Alt+A leader, and vim-style window navigation.
- Important records:
  - TUIOS defaults already provide leader bindings for new window, close, splits, copy mode, and fullscreen; psmux-only actions and non-equivalent resize bindings were not copied.
  - The h/l snap defaults were disabled to avoid conflicts with vim-style navigation.
  - TUIOS is not installed on this machine, so application-level validation was not available.
  - On Windows, TUIOS v0.7 resolves its config under `%LOCALAPPDATA%` when `XDG_CONFIG_HOME` is unset. Set `XDG_CONFIG_HOME` to `~/.config` when launching TUIOS to load this file.
- Portability: The configuration contains no absolute paths; `nu` must be available through `PATH` on each machine.
- Chezmoi: Added the TUIOS configuration and nested management marker to source state, then applied them to `~/.config/tuios`.
- Verification: Parsed the rendered file with Python `tomllib`, confirmed LF line endings, confirmed `nu.exe` is on `PATH`, and confirmed scoped `chezmoi status` is clean. Runtime validation was blocked because TUIOS is not installed.
