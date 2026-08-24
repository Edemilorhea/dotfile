# GlazeWM Chezmoi Changelog

## 2026-08-21T21:26:29+08:00 - Initialize management scope

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `.`
- Summary: Added a dedicated marker and changelog for GlazeWM configuration and helper scripts.
- Important records:
  - The nearest ancestor marker owns future records; nested markers take precedence.
  - The marker requires evaluation and does not automatically approve every descendant.
- Portability: Existing ignore rules limit `.glzr` configuration to Windows targets.
- Chezmoi: Added and managed as `dot_chezmanga/CHANGELOG.md`.
- Verification: `chezmoi source-path` resolved the target, scoped apply created it, and scoped diff was empty.

## 2026-08-22T14:33:16+08:00 - Make window cycling portable

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `config.yaml`
- Summary: Replaced the hard-coded user profile in the Alt+bracket window-cycling commands with the current chezmoi home directory.
- Important records:
  - The rendered path remains quoted so Windows home directories containing spaces are supported.
  - The helper still requires `node.exe`, `glazewm`, and `wscript.exe` to be available through `PATH`.
- Portability: The template normalizes `.chezmoi.homeDir` to Windows backslashes for each target machine.
- Chezmoi: Renamed the source to `config.yaml.tmpl` and kept the rendered target at `config.yaml`.
- Verification: The template rendered the current home directory correctly; scoped apply and synchronization checks completed successfully.

## 2026-08-24T18:59:20+08:00 - Add work-area refresh shortcut

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: windows/x64
- Scope: `config.yaml`
- Summary: Extended `Alt+Shift+W` to refresh the Windows work area before redrawing GlazeWM windows.
- Important records:
  - The existing redraw shortcut was reused to avoid adding another key combination.
  - The helper runs hidden through `wscript.exe` and does not restart GlazeWM.
- Portability: The template renders the helper path from `.chezmoi.homeDir` with Windows path separators.
- Chezmoi: Updated the existing managed `config.yaml.tmpl` source and applied the rendered target.
- Verification: GlazeWM reloaded the configuration successfully, and the background refresh helper exited successfully against the running instance.
