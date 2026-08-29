# PowerShell Chezmoi Changelog

## 2026-08-21T21:26:29+08:00 - Initialize management scope

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `.`
- Summary: Added a dedicated marker and changelog for the PowerShell profile.
- Important records:
  - The nearest ancestor marker owns future records; nested markers take precedence.
  - The source remains readonly through the existing chezmoi source attribute.
- Portability: Existing ignore rules apply this profile only when PowerShell synchronization is enabled on Windows.
- Chezmoi: Added and managed as `dot_chezmanga/CHANGELOG.md`.
- Verification: `chezmoi source-path` resolved the target, scoped apply created it, and scoped diff was empty.

## 2026-08-29T02:34:20+08:00 - Report foreground commands to psmux

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `Microsoft.PowerShell_profile.ps1`
- Summary: Added PowerShell shell integration so psmux can distinguish the PowerShell prompt from a foreground OpenCode process.
- Important records:
  - The Enter handler reports the submitted command through `WEZTERM_PROG` before PSReadLine accepts it.
  - The prompt wrapper sends `OSC 133;A` after rendering the existing Oh My Posh and zoxide prompt, which clears the completed command without replacing the prompt.
  - The integration is enabled only in interactive ConsoleHost sessions that have a `TMUX` environment variable.
- Portability: The integration is confined to the existing Windows PowerShell profile and uses terminal OSC sequences already understood by psmux.
- Chezmoi: Updated the managed source first and applied only the PowerShell profile target.
- Verification: The PowerShell parser accepted the profile; an isolated psmux session reported `pwsh` at the prompt, `opencode` while a test command ran, and `pwsh` again after it completed; the user confirmed image paste in `psmux -> pwsh -> opencode`.
