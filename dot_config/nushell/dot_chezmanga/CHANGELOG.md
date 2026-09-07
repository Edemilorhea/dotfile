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

## 2026-08-27T00:18:27+08:00 - Remove rejected welcome artwork

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `config.nu`
- Summary: Removed the manually generated ASCII artwork and restored the concise ASCII-only welcome line.
- Important records:
  - The artwork did not match the supplied frog image closely enough and was rejected.
  - The welcome line remains emoji-free, preserving the verified Rio startup fix.
- Portability: The welcome output uses portable ASCII text and contains no machine-specific path.
- Chezmoi: Updated the managed `config.nu` source and applied only that target.
- Verification: Source and runtime configuration match; Nushell loads the rendered configuration without error.

## 2026-08-29T14:07:18+08:00 - Improve completion selection contrast

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `modules/interface.nu`
- Summary: Replaced the reversed completion selection style with fixed light text on a dark blue-gray background so selected paths remain readable.
- Important records:
  - Reverse video used each completion item's foreground color as its background, which made light-green directory entries difficult to read.
  - Both `selected_text` and `selected_match_text` use foreground `#eff1f5`, background `#3b4652`, and bold text so the matched prefix and remaining value have one consistent selection style.
- Portability: The menu style uses Nushell-supported color records and contains no machine-specific values.
- Chezmoi: Updated the managed source and applied only the interface module and changelog targets.
- Verification: Nushell loaded the applied module and reported the expected completion selection style without configuration errors.

## 2026-09-03T15:38:02+08:00 - Add machine-local Pre connection functions

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `local.nu`
- Summary: Added machine-local functions for opening the fixed Pre Azure Web App tunnel and connecting to it over SSH.
- Important records:
  - `local.nu` remains unmanaged and machine-local; neither it nor its values were added to chezmoi.
  - The functions use the fixed resource group `Vital-ESG-Pre-Group` and app `esgyun-pre`, default to local port 22022, and contain no password, token, or other secret.
- Chezmoi: Updated and applied only this managed changelog target; `config.nu` and `local.nu.example` remain unchanged.
- Verification: Isolated Nushell sourcing confirmed `az-pre-tunnel` and `az-pre-ssh` exist without invoking either external command; scoped chezmoi checks confirmed changelog synchronization and that `local.nu` remains unmanaged.

## 2026-09-04T16:46:03+08:00 - Move command input to a new prompt line

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `modules/prompt.nu`, `themes/M365Princess.omp.json`
- Summary: Added a managed M365Princess theme variant that starts command input on a second line with a `❯` prompt marker.
- Important records:
  - The managed theme is preferred over Scoop's bundled theme so package updates cannot overwrite the customization.
  - The bundled theme remains the fallback when the managed theme is unavailable.
- Portability: The prompt resolves the theme relative to Nushell's default configuration directory and contains no machine-specific paths.
- Chezmoi: Added the theme and updated the already managed prompt module, then applied only those targets and this changelog.
- Verification: Oh My Posh and an isolated Nushell prompt render both produced the expected newline and second-line `❯` marker; scoped status was clean for the prompt module and theme.

## 2026-09-07T00:48:22+08:00 - Add isolated OpenCode exit tests

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: windows/x64
- Scope: `diagnostics/launch-opencode-exit-test.ps1`
- Summary: Added a launcher for fresh Rio and Nushell sessions that isolates configuration components involved in the OpenCode normal-exit crash.
- Important records:
  - Every profile starts Nushell with `--no-config-file --no-history`, then explicitly loads only the selected environment, Atuin, prompt, interface, or full configuration components.
  - The launcher must be started from Windows Run for reliable isolation from an existing Nushell process.
- Portability: The launcher is Windows-specific, resolves Rio and Nushell from `PATH`, and derives configuration paths from the current home directory.
- Chezmoi: Added the diagnostic launcher under the existing managed Nushell scope and applied only that directory and this changelog.
- Verification: PowerShell parsing passed; isolated Atuin, prompt, and full Nushell profiles loaded successfully; Rio CLI options were confirmed with `rio --help`.

## 2026-09-07T10:15:08+08:00 - Fix exit-test command construction

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: windows/x64
- Scope: `diagnostics/launch-opencode-exit-test.ps1`
- Summary: Keep source commands in an array so single-component profiles do not concatenate source and print into invalid Nushell syntax.
- Important records: Added a finite `-Check` mode using the same command text as the interactive launcher, displayed OpenCode resolution, and fixed the working directory to the user home. Earlier manual results require reconfirmation; the conhost crash is not yet fixed.
- Portability: Uses the current home directory and PATH; launcher remains Windows-specific.
- Chezmoi: Updated source first and applied only the launcher and changelog.
- Verification: Reproduced the old extra_positional parser error. All nine corrected profiles passed through the launcher check mode and resolved the same OpenCode executable in the agent environment. Interactive exit verification remains pending.

## 2026-09-07T10:30:01+08:00 - Add separate-console OpenCode workaround

- Status: Partial
- Machine: DESKTOP-3JHKCAP
- Platform: windows/x64
- Scope: `modules/commands.nu`
- Summary: Added opt-in `oc-window` to start OpenCode in a new Rio window with CMD, keeping the current working directory and leaving `oc` unchanged.
- Important records: This creates a new ConPTY rather than nesting CMD inside Nushell's existing console. CMD stays open after OpenCode exits. No claim of an upstream crash fix; user exit verification remains pending.
- Portability: Windows-only command using PATH resolution and the current Nushell working directory; no fixed machine paths.
- Chezmoi: Updated source first and applied only commands.nu and this changelog.
- Verification: Nushell successfully loaded the module and found oc-window. The first inspection command used the wrong metadata column (signature); the corrected signatures query passed. Interactive launch and exit remain unverified.

## 2026-09-07T19:37:54+08:00 - Disable OpenTUI alternate screen on Windows

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: windows/x64
- Scope: `env.nu`, `modules/commands.nu`
- Summary: Set `OTUI_USE_ALTERNATE_SCREEN=false` for Windows Nushell sessions so OpenCode uses the same-pane exit path that passed interactive testing.
- Important records:
  - The environment setting covers direct `opencode`, the `oc` alias, and `ocRider` without replacing their existing definitions.
  - Removed the rejected `oc-window` workaround because opening another terminal conflicts with pane-based workflows.
  - No `ocrr` command exists in the managed or deployed Nushell configuration, so no undefined alias was added.
- Portability: The workaround is restricted to Windows; other platforms retain OpenTUI's default alternate-screen behavior.
- Chezmoi: Updated the managed source first and applied only `env.nu`, `modules/commands.nu`, and this changelog.
- Verification: Isolated Nushell loading reported the environment value as `false`, retained `ocRider`, removed `oc-window`, and confirmed `oc` still expands to `opencode`. The user had already observed a successful same-pane `/exit`; the persistent setting requires one final test in a newly started Nushell session.

## 2026-09-07T19:43:07+08:00 - Retire temporary exit-test launcher

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: windows/x64
- Scope: `diagnostics/launch-opencode-exit-test.ps1`
- Summary: Removed the temporary profile launcher after direct same-pane testing identified the alternate-screen workaround.
- Important records: The launcher was diagnostic support only and is not required by the persistent OpenTUI setting.
- Portability: No diagnostic script remains to deploy on other machines.
- Chezmoi: Removed the temporary source and deployed target before committing the final fix.
- Verification: The source repository no longer contains an untracked Nushell diagnostics directory.
