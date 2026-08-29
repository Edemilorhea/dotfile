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

## 2026-08-28T20:01:11+08:00 - Prevent duplicate Ctrl+V paste

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `psmux.conf`
- Summary: Made the two Ctrl+V handling modes explicit and enabled psmux-owned paste detection without forwarding the same key to the child application.
- Important records:
  - Mode A keeps `paste-detection on` and removes the root `C-v` binding; this is the active default.
  - Mode B remains documented but commented out; it disables paste detection and forwards `C-v` to the child application.
  - Enabling paste detection and forwarding `C-v` at the same time caused PSReadLine and psmux to paste the clipboard independently.
- Portability: The modes use psmux-native options and remain inside the existing Windows-specific psmux scope.
- Chezmoi: Updated the managed source first and applied only `.config/psmux/psmux.conf`.
- Verification: Reloaded the running server without ending sessions; `paste-detection` reported `on`; the root key table had no `C-v` binding; Rio → psmux → nu → pwsh pasted `Write-Output PSMUX_PASTE_MODE_A_7319` exactly once with one Ctrl+V press.

## 2026-08-28T22:34:00+08:00 - Preserve OpenCode image paste

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `psmux.conf`
- Summary: Switched the default Ctrl+V handling to child-owned mode so OpenCode can inspect clipboard images directly.
- Important records:
  - Mode B disables psmux paste detection and forwards one `C-v` key to the active child application.
  - Mode A only transfers clipboard text and prevents OpenCode from handling image clipboard data.
  - Mode A remains documented as a commented alternative for text-only workflows.
- Portability: The modes use psmux-native options and remain inside the existing Windows-specific psmux scope.
- Chezmoi: Updated the managed source first and applied only `.config/psmux/psmux.conf`.
- Verification: Reloaded the running server without ending sessions; `paste-detection` reported `off`; the root key table contained one `C-v` forwarding binding; pwsh pasted `Write-Output PSMUX_MODE_B_9284` exactly once; OpenCode successfully pasted an image from the clipboard.

## 2026-08-29T02:34:20+08:00 - Route Ctrl+V by foreground application

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `psmux.conf`
- Summary: Enabled psmux-owned text paste globally and conditionally forwarded the same Ctrl+V to OpenCode so it can read image clipboard data.
- Important records:
  - `paste-detection on` provides one text paste path for Nushell, PowerShell, and OpenCode.
  - The root binding forwards literal `C-v` only when `pane_current_command` is `oc`, `opencode`, or `opencode.exe`.
  - PowerShell shell integration is required so nested PowerShell panes do not retain Nushell's stale `WEZTERM_PROG=pwsh` value.
  - Removed clipboard helper experiments because external psmux clients could route to the wrong server and raw multiline paste could execute input prematurely.
- Portability: The final binding uses psmux-native formats and commands inside the existing Windows-specific psmux scope.
- Chezmoi: Updated the managed source first, applied only the psmux configuration, and reloaded every existing psmux session without terminating it.
- Verification: Nushell and PowerShell accepted multiline text once; OpenCode accepted text and images when launched from Nushell and PowerShell; all existing sessions reported `paste-detection on` with the conditional root binding.
