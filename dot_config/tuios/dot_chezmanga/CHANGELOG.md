# TUIOS Configuration Changelog

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
