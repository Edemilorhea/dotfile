# psmux Chezmoi Changelog

## 2026-08-21T21:26:29+08:00 - Initialize management scope

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `.`
- Summary: Added a dedicated marker and changelog for psmux configuration.
- Important records:
  - The nearest ancestor marker owns future records; nested markers take precedence.
  - Runtime keys, ports, sessions, logs, and backups remain excluded.
- Portability: psmux remains Windows-specific through existing chezmoi ignore rules.
- Chezmoi: Added and managed as `dot_chezmanga/CHANGELOG.md`.
- Verification: `chezmoi source-path` resolved the target, scoped apply created it, and scoped diff was empty.

## 2026-08-27T10:54:29+08:00 - Restore OpenCode alias

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `psmux.conf`
- Summary: Added `oc` to the psmux-resurrect process whitelist so saved OpenCode panes can restart the recorded command.
- Important records:
  - psmux-resurrect records the OpenCode process as `oc`, while process matching uses the exact command basename.
  - Restoration starts a new `oc` process in the saved pane directory; it does not guarantee restoration of the previous OpenCode conversation.
- Portability: The command alias is machine-neutral within the existing Windows-specific psmux scope.
- Chezmoi: Updated the already managed `psmux.conf` source and applied only that target.
- Verification: Scoped diff showed only the whitelist addition; scoped apply succeeded; reloading psmux and reading `@resurrect-processes` returned `dotnet opencode oc ssh wsl nvim yarn`.
