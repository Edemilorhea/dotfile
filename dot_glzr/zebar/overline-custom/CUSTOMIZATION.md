# Overline Custom

This pack is based on `mushfikurr.overline-zebar` 1.0.5.

## Custom behavior

The power button opens a menu with three Windows actions:

- Shutdown after one minute: `shutdown /s /t 60`
- Sleep: `tools/SleepHelper.exe`, which shows a five-second countdown and then
  uses `Win+X`, `U`, `S` to select Sleep from the native Windows power menu.
- Hibernate: `shutdown /h`

The workspace window button and `Alt+Shift+G` open a centered selector on the
current monitor. It only shows windows from that monitor's displayed workspace,
sorts minimized windows first, and restores a minimized window before focusing
it. Use arrow keys or `J`/`K` to select, `Enter` to open, and `Escape` to close.
The selector closes its Zebar widget after a window is activated so it does not
remain as a stale window. It disables the selector binding mode before changing
focus, which prevents another monitor or workspace from reopening the selector.
The top bar also shows a clickable `PAUSED` indicator while GlazeWM window
management is paused. A black status label immediately to the left of the
workspace numbers shows the focused managed window's current state (`TILING`,
`FLOATING`, `FULLSCREEN`, or `MINIMIZED`). It queries GlazeWM over its local IPC
WebSocket so state changes appear without requiring a focus change.

When the main widget starts or reloads, it waits for Zebar to register its
Windows AppBar and then runs `~/.glzr/glazewm/refresh-work-area.ps1`. The helper
sends GlazeWM the Windows work-area-change message that makes it read the new
monitor geometry and redraw existing windows. A short named mutex prevents the
per-monitor widgets from running overlapping refreshes. It refreshes during
registration and once more after all monitor widgets have had time to settle.
The checked-in `dist/index.html` contains the runtime backport;
`custom-src/main/App.tsx` is the source for future builds.

Editable custom source files are preserved under `custom-src`:

- `RightButtons.tsx`: Windows power menu.
- `main/App.tsx`: Opens the selector for the focused monitor when the GlazeWM
  `window-switcher` binding mode activates.
- `main/leftButtons.tsx`: Adds the clickable selector button.
- `main/windowStateIndicator.tsx`: Shows the live focused-window state.
- `main/openWindowSwitcher.ts`: Places the selector on the bar's monitor.
- `main/window-switcher.tsx`, `main/window-switcher.html`, and
  `main/vite.config.ts`: Selector UI and multi-page build entry.

The runtime bundle is built into `widgets/main/dist`.

Hibernate requires Windows hibernation to be enabled.

## Restore on another computer

Requirements:

- Install GlazeWM and Zebar before you apply the chezmoi repository.
- Use Zebar 3.3.1 or a compatible version.
- Commit and push this pack, `zebar/settings.json`, and the GlazeWM config to
  the chezmoi repository.

Restore the configuration:

1. Initialize and apply the chezmoi repository:

   ```powershell
   chezmoi init --apply <repository-url>
   ```

2. Restart GlazeWM to load `~/.glzr/glazewm/config.yaml`.
3. Start Zebar with its saved startup configuration:

   ```powershell
   zebar startup
   ```

The saved `zebar/settings.json` starts the `overline-custom` pack with the
`main` widget and the `default` preset. The compiled files under
`widgets/main/dist` are included, so the other computer does not need Node.js
or pnpm to use the pack.
