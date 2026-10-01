# GlazeWM scripts

Helper scripts for `../config.yaml`. Paths in the config are rendered from
`config.yaml.tmpl` and point at this folder.

| Script | Used by | Purpose |
|---|---|---|
| `cycle-workspace-window.js` | `Alt+[` / `Alt+]` | Focus the previous or next window in the focused workspace. |
| `cycle-workspace-window.config.json` | `cycle-workspace-window.js` | `scope` (`same-state` or `workspace`) and `minimizedPolicy` (`exclude`, `fullscreen-only`, or `include`). |
| `restart-glazewm.ps1` | `Alt+Shift+W` | Re-seat Zebar's dock reservation in place; fall back to a full GlazeWM and Zebar restart. Failures go to `%LOCALAPPDATA%\glazewm\restart.log`. |
| `inspect-window.ps1` | Manual | Print the focused window's properties and a `window_rules` snippet. |

Run the manual tool from PowerShell, then focus the target window within the delay:

```powershell
pwsh -NoProfile -File ~/.glzr/glazewm/scripts/inspect-window.ps1 -DelaySeconds 3
```

Zebar's own helper executables (`SleepHelper.exe`, `WindowIconHelper.exe`) stay
in `../../zebar/overline-TC/tools` because the widget resolves them relative to
its pack.
