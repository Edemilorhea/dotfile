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
