# overline-TC Chezmoi Changelog

## 2026-08-21T21:26:29+08:00 - Initialize management scope

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `.`
- Summary: Added a dedicated marker and changelog for Overline source, tools, and deployed widgets.
- Important records:
  - Generated deployment assets require reference and stale-hash review before management.
  - Required helper binaries remain paired with source and build instructions.
- Portability: Existing ignore rules limit `.glzr` configuration to Windows targets; host paths still require templating review.
- Chezmoi: Added and managed as `dot_chezmanga/CHANGELOG.md`.
- Verification: `chezmoi source-path` resolved the target, scoped apply created it, and scoped diff was empty.

## 2026-08-21T21:40:51+08:00 - Make widget helpers portable

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `custom-src/RightButtons.tsx`, `custom-src/main/App.tsx`, `custom-src/main/workspaceDock.tsx`, `widgets/main/dist/index.html`, `widgets/main/dist/assets/main-BmnlOnvA.js`, `zpack.json`
- Summary: Made helper and refresh commands resolve from the installed widget pack instead of a specific user profile, while retaining the current workspace dock deployment.
- Important records:
  - Sleep and window-icon helpers now use pack-relative executable paths with an explicit working directory.
  - GlazeWM work-area refresh now derives its script path from the widget runtime path.
  - Existing unreferenced hash assets were retained because deployment cleanup is outside this functional change.
- Portability: Removed user-profile absolute path assumptions from authored configuration and the deployed bundle.
- Chezmoi: Updated managed source and deployment assets within the Overline scope.
- Verification: The bundle passed `node --check`; JSON, HTML asset references, personal-path scans, LF line endings, and scoped chezmoi state were validated.

## 2026-08-21T22:08:23+08:00 - Fix workspace application icons

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: windows/x64
- Scope: `custom-src/main/workspaceDock.tsx`, `widgets/main/dist/assets/main-BmnlOnvA.js`, `zpack.json`
- Summary: Restored workspace application icons by launching the pack-relative icon helper through `cmd.exe` from the widget pack directory.
- Important records:
  - Zebar does not reliably resolve a relative executable against `shellExec`'s working directory on Windows.
  - The `cmd.exe` privilege only permits the fixed helper command and the existing restricted process-name character set.
  - The deployed bundle was patched in place because this managed pack does not include the upstream monorepo dependencies needed to rebuild it.
- Portability: The helper remains pack-relative and contains no user-profile or machine-specific path.
- Chezmoi: Updated existing managed source, deployment asset, privilege configuration, and changelog.
- Verification: The `cmd.exe` helper path returned a Discord PNG, unsafe shell characters failed the privilege regex, the bundle passed `node --check`, `zpack.json` parsed successfully, scoped apply completed, and the rendered files and LF line endings were validated.

## 2026-08-26T13:03:50+08:00 - Investigate top-bar spacing

- Status: Partial
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `zpack.json`
- Summary: Restored the main widget's original edge reservation and normal z-order after alternative spacing approaches proved less usable.
- Important records:
  - Zebar remained visible after resume even when Windows lost its appbar working-area reservation.
  - Zebar again owns the Windows working-area reservation through `dockToEdge`.
  - Normal z-order keeps the bar from overlaying maximized application content.
- Portability: The setting is machine-neutral and remains paired with the managed 36px bar geometry and 2px margins.
- Chezmoi: Updated the existing managed widget pack configuration and applied it to the current machine.
- Verification: The rendered widget uses normal z-order with edge docking enabled, and all three monitors immediately reported a 40px top reservation after one Zebar restart; resume remains unresolved.

## 2026-08-29T20:22:57+08:00 - Rename pack and relocate workspace dock

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `custom-src/main`, `widgets/main/dist`, `zpack.json`, `../settings.json`
- Summary: Renamed the widget pack to `overline-TC` and moved the workspace application dock beside the workspace numbers with a collapsed-by-default, right-expanding toggle.
- Important records:
  - All six widget definitions remain because each has an active entry point or launcher.
  - The main widget was rebuilt from the upstream workspace with the managed custom sources overlaid.
  - Stale hash assets from earlier builds were removed; the main deployment now contains only the nine assets referenced by the current three HTML entry points.
  - The dock now opens on a normal click, stores its state under `overline-TC.workspaceDock.expanded`, and no longer exposes a compact four-icon mode or Shift-click behavior.
- Portability: Runtime paths remain pack-relative, and the pack contains no user-profile-specific paths.
- Chezmoi: Renamed the managed source directory, updated the startup pack, applied the new target, and removed the obsolete target directory.
- Verification: The full pnpm workspace build passed; the deployed bundle passed `node --check`; all six widget entry points resolved; scoped chezmoi status was clean; LF line endings were confirmed; and Zebar restarted successfully without adding an error log entry.

## 2026-09-06T18:19:56+08:00 - Stabilize window switcher focus

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `custom-src/main/window-switcher.tsx`, `widgets/main/dist/assets/window-switcher-r93y_ofB.js`
- Summary: Added a delayed focus retry after the selector opens so it retains keyboard focus after GlazeWM finishes managing and floating the new window.
- Important records:
  - The existing immediate focus request remains in place; the second request runs once after 100 ms and is cancelled if the component unmounts first.
  - The deployed bundle was patched in place because this managed pack does not include the upstream monorepo dependencies needed to rebuild it.
- Portability: The change uses Zebar's existing Tauri window API and has no machine-specific path.
- Chezmoi: Updated the managed source and deployed runtime bundle, then applied both to the current machine.
- Verification: The deployed bundle passed `node --check`; a live GlazeWM query reported the selector as shown, floating, and focused.

## 2026-09-21T10:40:37+08:00 - Drop the dead work-area refresh call

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `custom-src/main/App.tsx`, `widgets/main/dist/assets/main-w_IRe7zy.js`, `CUSTOMIZATION.md`
- Summary: Removed the startup effect that asked GlazeWM to run `~/.glzr/glazewm/refresh-work-area.vbs`, along with the three path constants that fed it.
- Important records:
  - The VBS launcher was deleted on 2026-09-01, so every bar instance scheduled up to three `shell-exec -- wscript.exe` calls against a missing file, each guarded by a 1500 ms timeout and a 1000 ms retry.
  - The effect could not have worked even with the launcher present: it only asked GlazeWM to re-read the Windows work area, while the actual defect is that Windows never reserved the space. `restart-glazewm.ps1` now re-issues `ABM_SETPOS` against Zebar's own bar windows instead.
  - The deployed bundle was patched in place because this managed pack does not include the upstream monorepo dependencies needed to rebuild it. The content hash in the file name no longer matches its content; `index.html` references the bundle by name, so this is consistent with the earlier backports.
  - `widgetPackPath` still exists independently in `RightButtons.tsx` and `workspaceDock.tsx`, which use it as a shell working directory. Only the `App.tsx` copy was removed.
- Portability: The change only deletes code and introduces no machine-specific path.
- Chezmoi: Updated the managed source, deployed runtime bundle, and documentation, then applied all three to the current machine.
- Verification: The patched bundle passed `node --check` and contains no remaining `refresh-work-area`, `wscript`, or `Oy`/`Vy`/`_y` references, while `Dy` (useAutoTiling) is intact. After a Zebar restart all three bars rendered at 1920x38 on their monitor origins and `errors.log` gained no new entry.

## 2026-09-30T09:42:30+08:00 - Update restart helper path

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `CUSTOMIZATION.md`
- Summary: Updated the documented path of `restart-glazewm.ps1` to `~/.glzr/glazewm/scripts/restart-glazewm.ps1` after the GlazeWM helper scripts moved into `scripts/`.
- Portability: The path uses `~` and contains no machine-specific value.
- Chezmoi: Updated the existing managed source and applied it.
- Verification: Scoped `chezmoi status` is clean; the source uses LF.

## 2026-11-18T17:12:00+08:00 - Stop maximized windows from covering the bar

- Status: Completed
- Machine: tc-tseng
- Platform: windows/x64
- Scope: `zpack.json`
- Summary: Raised the main widget's `dockToEdge.windowMargin` from 2px to 8px so the top reservation grows from 40px to 46px.
- Important records:
  - A maximized window's frame extends about 8px past the work area, so with only a 2px margin it covered the bottom 5-6px of the 36px bar.
  - Measured before the change: DataGrip window top at y=32 while the work area started at y=40.
- Portability: The setting is machine-neutral; the 8px frame extension is a Windows constant.
- Chezmoi: Updated the existing managed source and applied it.
- Verification: After a Zebar restart, DISPLAY8 and DISPLAY7 reported a 46px reservation and a pixel scan showed the bar ending at y=38 with the window content starting at y=39. DISPLAY6 lost its reservation after the restart (see the unresolved appbar registration failure above) and needs `Alt+Shift+W`.

## 2026-11-18T17:20:00+08:00 - Revert windowMargin to 2px

- Status: Completed
- Machine: tc-tseng
- Platform: windows/x64
- Scope: `zpack.json`
- Summary: Reverted `dockToEdge.windowMargin` from 8px back to 2px, undoing the previous entry.
- Important records:
  - The 8px margin raised the top reservation to 46px and pushed window content down to y=39, which the user reported as taking more space, not less.
  - The earlier diagnosis (maximized window frame covers the bar) was a guess about what the user meant by "too much distance" and was not confirmed.
- Portability: The setting is machine-neutral.
- Chezmoi: Updated the existing managed source and applied it.
- Verification: After a Zebar restart, DISPLAY8 and DISPLAY7 reported a 40px reservation and window content started at y=33 again. DISPLAY6 still reports 0 (appbar registration failure).

## 2026-11-19T09:30:00+08:00 - Make the main bar top-most

- Status: Partial
- Machine: tc-tseng
- Platform: windows/x64
- Scope: `zpack.json`
- Summary: Changed the main widget `zOrder` from `normal` to `top_most` so the invisible frame of a maximized window cannot cover the bar.
- Important records:
  - A maximized window's frame starts about 8px (scaled by DPI) above the visible edge, so it extends into the bar area. Windows decides this position; GlazeWM cannot change it because `maximize()` clamps the window back.
  - The 2026-08-26 entry moved the bar from top-most to normal because it covered maximized content while the work-area reservation was missing (`reserved=0`). That case still exists on DISPLAY6.
  - Side effect observed: a window GlazeWM treats as fullscreen (`y=0`) is drawn under the bar, so the bar covers its top 38px.
- Portability: The setting is machine-neutral.
- Chezmoi: Updated the existing managed source and applied it.
- Verification: After a Zebar restart all three bars report top-most. No window was maximized during the check, so the white strip fix is not yet confirmed.

## 2026-11-19T09:55:00+08:00 - Remove the 2px gap under the main bar

- Status: Partial
- Machine: tc-tseng
- Platform: windows/x64
- Scope: `zpack.json`
- Summary: Changed the main widget `dockToEdge.windowMargin` from `2px` to `0px`; `zOrder` stays `top_most`.
- Important records:
  - With `top_most` alone, DataGrip maximized on DISPLAY7 still showed `243,243,243` at y=615–616. The bar window ends at y=615 but the reservation was 40px, so a 2px band of DataGrip's invisible frame showed between the bar and the work area.
  - With `0px` the reservation equals the 38px bar height and the top-most bar covers the frame above the work area.
- Portability: The setting is machine-neutral.
- Chezmoi: Updated the existing managed source and applied it.
- Verification: After a Zebar restart DISPLAY8 and DISPLAY7 report `reserved=38` and the bar is the top window down to y=614 on DISPLAY7. DataGrip was not in front at the time, so the strip fix still needs a visual check.

## 2026-11-19T10:05:00+08:00 - Grow the main bar to fill the reserved area

- Status: Partial
- Machine: tc-tseng
- Platform: windows/x64
- Scope: `zpack.json`
- Summary: Changed the main widget preset `height` from `36px` to `38px`; `windowMargin` stays `0px` and `zOrder` stays `top_most`.
- Important records:
  - User confirmed DataGrip had no white strip with `0px`, but Zen's maximized title bar lost its top rows: the 38px reservation moved every maximized window up 2px against the 40px it had before.
  - The reservation is `offsetY + height + windowMargin`. With `2px + 38px + 2px` it became 42px, so `windowMargin` must stay `0px` to keep the original 40px.
  - With `2px + 38px + 0px` the reservation is 40px again and the bar window ends exactly at the work-area top, so no gap shows a maximized window's frame.
- Portability: The setting is machine-neutral.
- Chezmoi: Updated the existing managed source and applied it.
- Verification: After a Zebar restart DISPLAY8 and DISPLAY7 report `reserved=40`, each bar window spans y=0–40 relative to its monitor, and maximized Zen's visible top is at y=40 as before the margin change. DISPLAY6 still reports `reserved=0` from the separate AppBar registration failure.

## 2026-11-19T11:30:00+08:00 - Revert the main bar to its original geometry and z-order

- Status: Completed
- Machine: tc-tseng
- Platform: windows/x64
- Scope: `zpack.json`
- Summary: Restored the main widget to the committed values `zOrder: normal`, `height: 36px`, `dockToEdge.windowMargin: 2px`, undoing the three 2026-11-19 entries above.
- Important records:
  - Settings in use before this revert: `zOrder: top_most`, `offsetY: 2px`, `height: 38px`, `dockToEdge.windowMargin: 0px` (reservation 40px). With them DataGrip showed no light strip, but every maximized window lost its top rows to the bar.
  - Measured cause: a natively maximized window's top 8 rows (at 100% scale) sit above the work-area top and overlap the bar. With normal z-order those rows show the window: 8 rows for a stock WinForms window and Zen on DISPLAY8, and 7 rows for noctty on DISPLAY7. With `top_most` the bar covers them instead, so the maximized title bar shrinks from 31px to 23px.
  - Changing z-order only decides which side is covered. Removing the overlap needs a non-native maximize in GlazeWM, which is not implemented.
- Portability: The setting is machine-neutral.
- Chezmoi: Restored the managed source from git and applied it.
- Verification: The managed source matches git HEAD. After a Zebar restart all three bars are not top-most and span 38px from their monitor top. DISPLAY8 and DISPLAY7 report `reserved=40`; DISPLAY6 reports `reserved=0` from the separate AppBar registration issue.