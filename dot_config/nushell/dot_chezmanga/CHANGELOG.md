# Nushell Chezmoi Changelog

## 2026-08-21T21:26:29+08:00 - Initialize management scope

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `.`
- Summary: Added a dedicated marker and changelog for Nushell configuration.
- Important records:
  - The nearest ancestor marker owns future records; nested markers take precedence.
  - Local machine overrides remain represented by example files rather than synchronized private values.
- Portability: Marker metadata contains no host-specific paths; the machine name is audit metadata only.
- Chezmoi: Added and managed as `dot_chezmanga/CHANGELOG.md`.
- Verification: `chezmoi source-path` resolved the target, scoped apply created it, and scoped diff was empty.

## 2026-08-25T09:56:29+08:00 - Report running commands to psmux

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `modules/interface.nu`
- Summary: Added a Nushell pre-execution hook that reports the complete running command through psmux's OSC shell-integration channel.
- Important records:
  - The hook appends to the existing hook list so Atuin and other integrations remain active.
  - psmux remains unchanged; `pane_current_command` continues to be the command source for session persistence.
- Portability: The hook uses Nushell built-ins and the terminal OSC protocol without machine-specific paths.
- Chezmoi: Updated the already managed `modules/interface.nu` source and applied only that target.
- Verification: A new isolated Nushell pane ran `sleep 20sec`; `psmux list-panes` reported `pane_current_command` as `sleep 20sec`, and the temporary session was removed.

## 2026-08-26T14:03:52+08:00 - Disable stale vendor transient prompt

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `modules/prompt.nu`
- Summary: Disabled the Oh My Posh transient prompt left by vendor autoload so the managed prompt remains the sole prompt implementation.
- Important records:
  - The generated vendor prompt inferred `CMD_DURATION_MS` as an integer but received a string from Nushell 0.114.1, causing `nu::shell::type_mismatch` after commands.
  - The generated vendor file remains unmanaged; the managed user autoload overrides its prompt behavior after vendor integrations load.
- Portability: The fix uses a Nushell prompt environment variable and contains no machine-specific path.
- Chezmoi: Updated the already managed `modules/prompt.nu` source and applied only that target.
- Verification: Isolated interactive sessions verified both standard and OpenCode prompts, confirmed the transient prompt was unset, and completed five consecutive standard-prompt commands including a 1.2-second command without the type mismatch error. Sixteen bounded Oh My Posh primary calls also completed in 210-372 ms without timeout or stderr.

## 2026-08-26T20:25:36+08:00 - Remove slow Rio emoji fallback

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `config.nu`
- Summary: Replaced the welcome banner's emoji labels with ASCII art and text so Rio does not block while discovering the Windows emoji fallback font.
- Important records:
  - Rio TRACE showed a 5.32-second gap immediately before Sugarloaf registered Segoe UI Emoji for U+1F550 from the welcome banner.
  - Oh My Posh remains enabled with the M365Princess theme; temporary theme and multiline-indicator diagnostics were reverted.
- Portability: The welcome banner now uses only portable ASCII characters and contains no machine-specific path.
- Chezmoi: Updated the managed `config.nu` source and applied only the Nushell configuration targets.
- Verification: Nushell loaded the rendered configuration without error, scoped chezmoi status was clean, and a user-launched Rio session with Nushell became interactive without the previous five-second delay.
