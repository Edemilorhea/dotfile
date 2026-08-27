# Overline Custom Chezmoi Changelog

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
