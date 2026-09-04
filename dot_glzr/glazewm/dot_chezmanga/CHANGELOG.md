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

## 2026-08-26T13:03:50+08:00 - Restore Zebar space after resume

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `refresh-work-area.ps1`
- Summary: Extended the existing refresh shortcut to re-register each Zebar main widget as a 40px Windows AppBar before GlazeWM refreshes its monitor work areas.
- Important records:
  - After resume, Zebar remained visible but Windows reported no top-edge reservation on any monitor.
  - The helper reuses the existing Zebar window handles and does not start, stop, or cover Zebar with an always-on-top window.
  - The AppBar registration remains owned by the Zebar windows after the one-shot helper exits; no persistent helper process is required.
- Portability: The helper discovers monitors from the active Zebar windows; the 40px reservation matches the managed 36px bar with 2px margins.
- Chezmoi: Updated the existing managed refresh helper and retained the original Zebar dock and GlazeWM gap configuration.
- Verification: A reversible runtime test removed and restored all three AppBar registrations, kept the Zebar PID unchanged, and preserved a 40px top work area for at least 15 seconds; a physical sleep/resume cycle was not performed.

## 2026-08-26T20:04:48+08:00 - Restore mixed-DPI work areas

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `refresh-work-area.ps1`
- Summary: Removed the helper's external AppBar registration so Zebar exclusively manages its native dock reservation on each monitor.
- Important records:
  - The helper mixed system-DPI monitor coordinates with Per-Monitor-aware Zebar windows, which expanded the 150% portrait monitor reservation to 186 physical pixels.
  - Restarting Zebar removed the malformed AppBar state and restored native DPI-scaled reservations without changing the GlazeWM refresh behavior.
- Portability: The helper no longer calculates monitor geometry or assumes a fixed physical AppBar height across mixed-DPI displays.
- Chezmoi: Restored the managed refresh helper to its notification-only implementation and applied it to the current machine.
- Verification: PowerShell parsing passed; the helper exited successfully; GlazeWM reported 60px and 49px native top reservations on the 150% and 125% monitors; source and target remained synchronized with LF line endings.

## 2026-08-27T10:15:15+08:00 - Add full GlazeWM restart

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `config.yaml`, `restart-glazewm.ps1`, `restart-glazewm.vbs`
- Summary: Replaced the `Alt+Shift+W` notification refresh with a hidden, coordinated restart of GlazeWM and Zebar so Windows can rebuild each docked work area.
- Important records:
  - A named mutex prevents overlapping restarts when the shortcut is pressed repeatedly.
  - The helper records the original GlazeWM, watcher, and Zebar processes, requests `wm-exit`, and force-stops only matching original process instances if graceful shutdown times out.
  - Restart success requires Zebar to be running and every GlazeWM monitor to report a top work-area reservation; failures are appended to `%LOCALAPPDATA%\glazewm\restart.log`.
  - The notification-only `refresh-work-area` helpers remain managed but are no longer bound to a shortcut.
- Portability: The config template renders the home directory for the launcher, while the launcher resolves the target script through `%USERPROFILE%`; runtime commands still require `glazewm`, `pwsh.exe`, and `wscript.exe` on `PATH`.
- Chezmoi: Added and applied both restart helpers, updated the existing config template, and kept all changes scoped to the GlazeWM management root.
- Verification: PowerShell parsing passed; GlazeWM accepted `wm-reload-config`; one launcher run replaced the GlazeWM, watcher, and both Zebar PIDs and reported a 40px top reservation on all three monitors; scoped chezmoi status and diff were clean; source and target helper hashes matched with LF line endings. A physical sleep/resume scenario was not run.

## 2026-08-27T14:19:57+08:00 - Hide Zebar shutdown console

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `config.yaml`, `stop-zebar.vbs`, `restart-glazewm.ps1`
- Summary: Replaced the direct Zebar `taskkill.exe` shutdown command with a hidden WScript launcher so full restart and normal GlazeWM exit do not flash a console window.
- Important records:
  - `wscript.exe //B` starts the launcher without a console or interactive alerts.
  - `WScript.Shell.Run` uses window style `0` and waits for the hidden `taskkill.exe` process to finish.
  - Restart readiness now requires the post-restart monitor count to match the pre-restart count before checking every top work-area reservation.
- Portability: The config template renders the launcher path from `.chezmoi.homeDir`; Windows Script Host and `taskkill.exe` are standard Windows components.
- Chezmoi: Added and applied `stop-zebar.vbs`, updated the managed config and restart helper, and kept the change scoped to the GlazeWM management root.
- Verification: GlazeWM accepted the updated config; PowerShell parsing passed; a hidden launcher run replaced the GlazeWM and both Zebar PIDs, preserved the current 1-to-1 monitor count, and restored a 49px top reservation. Visual absence of a transient window requires user observation.

## 2026-09-01T13:59:28+08:00 - Remove VBScript launchers

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `config.yaml`, `cycle-workspace-window.js`, `restart-glazewm.ps1`, removed `*.vbs` launchers
- Summary: Replaced all GlazeWM WScript launchers with native `shell-exec --hide-window` commands so normal shutdown, window cycling, and full restart no longer depend on deprecated VBScript.
- Important records:
  - GlazeWM 3.10.1 implements `--hide-window` with `ShellExecuteExW` and `SW_HIDE`; PowerShell also keeps `-WindowStyle Hidden` as a second safeguard.
  - The notification-only `refresh-work-area.ps1` remains managed, but its unused VBS launcher was removed.
  - A scoped chezmoi destroy dry-run unexpectedly activated the configured Git auto-commit and auto-push behavior, publishing commit `851f42d`; no rollback was attempted because the commit also contained unrelated existing changes.
- Portability: Script paths continue to render from `.chezmoi.homeDir`; runtime commands require `node.exe`, `pwsh.exe`, and `taskkill.exe` on `PATH`, but no longer require Windows Script Host.
- Chezmoi: Updated and applied the existing config template, then removed the four obsolete VBS files from both source and target state.
- Verification: The rendered config has clean scoped status and diff; Node and PowerShell parsing passed; required executables resolve through `PATH`; source and target config use LF without mixed endings. GlazeWM was not running, so live config reload and visual window-hiding behavior were not tested.

## 2026-09-03T13:31:52+08:00 - Emphasize the focused window

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `config.yaml`
- Summary: Changed the focused-window border to bright amber and dimmed non-focused windows to 90% opacity.
- Important records:
  - Non-focused custom borders are disabled so the amber focused border has stronger contrast.
  - The focused window remains fully opaque; only non-focused managed windows receive transparency.
- Portability: The effects use GlazeWM configuration only; custom border colors require Windows 11.
- Chezmoi: Updated the existing managed `config.yaml.tmpl` source and applied the rendered target.
- Verification: GlazeWM 3.10.1 accepted `wm-reload-config`; the rendered values match the source; scoped chezmoi status is clean; the source template uses LF without mixed endings.

## 2026-09-03T13:44:25+08:00 - Reduce inactive-window transparency

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `config.yaml`
- Summary: Increased non-focused window opacity from 90% to 95% for a subtler dimming effect.
- Important records:
  - The bright amber focused-window border and all other visual settings remain unchanged.
- Portability: The effect uses GlazeWM configuration only and has no machine-specific paths.
- Chezmoi: Updated the existing managed `config.yaml.tmpl` source and applied the rendered target.
- Verification: GlazeWM 3.10.1 accepted `wm-reload-config`; the rendered opacity matches the source; scoped chezmoi status is clean; the source template uses LF without mixed endings.

## 2026-09-04T13:39:08+08:00 - Restore opaque inactive windows

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `config.yaml`
- Summary: Set non-focused windows to an explicit 100% opacity so screen sharing always shows fully opaque content.
- Important records:
  - The bright amber focused-window border and all other visual settings remain unchanged.
  - Disabling the effect did not clear opacity already applied to existing windows, so the effect remains enabled with a 100% value.
- Portability: The effect uses GlazeWM configuration only and has no machine-specific paths.
- Chezmoi: Updated the existing managed `config.yaml.tmpl` source and applied the rendered target.
- Verification: Scoped apply completed; GlazeWM 3.10.1 accepted `wm-reload-config` and `wm-redraw`; source and target values match; scoped chezmoi status is clean; manually edited source files use LF without mixed endings.
