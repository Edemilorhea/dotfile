# Tool and Command Lifecycle

Use these rules before running shell commands, test tools, scripts, or CLI programs. The goal is to prevent a command from occupying the tool session indefinitely and blocking all later work.

## Preflight

1. Classify the command before execution:
   - **Finite:** completes and exits without user action.
   - **Interactive:** can prompt for input, credentials, confirmation, an editor, a pager, or a REPL.
   - **Persistent:** serves, watches, follows, polls, or waits until interrupted.
2. Confirm lifecycle behavior from existing project scripts, tool help, official documentation, or source. Do not start a possibly persistent command merely to discover whether it exits.
3. Prefer a finite, non-interactive mode. Supply explicit flags, input, target scope, and output options when supported.
4. Set a realistic tool timeout for every command. A timeout is a safety boundary, not evidence of success.
5. If lifecycle behavior remains uncertain, run the smallest harmless probe in isolation with a short timeout. State the uncertainty and do not treat forced termination as a passing result.

## Execution Rules

- Never start a REPL, interactive shell, editor, pager, TUI, watch mode, development server, log follower, or confirmation prompt in a foreground tool call.
- Avoid commands that wait for stdin. Use a non-interactive flag or provide complete input explicitly.
- Disable optional watch, debug, prompt, pager, and color modes when they can affect completion or machine-readable output.
- For a required persistent process, start it only through a background process mechanism that survives the launching call. Record its PID or another reliable process identity, observe readiness, and stop only that process when finished.
- Do not assume that appending `&`, creating a job, or hitting the tool timeout safely detaches or cleans up a child process. Use a platform-appropriate process API and verify the resulting process state.
- Before starting a service, check whether the required service or port is already active. Do not create duplicates.
- Stop only processes started for the current task. Do not terminate unrelated user or agent processes.
- Treat timeout, cancellation, forced termination, or incomplete output as `BLOCKED` or `FAIL`, never `PASS`.

## Tests and Validation

- Use one-shot test commands. Disable watch mode explicitly when a runner supports it, for example `--watch=false`, `--run`, or the runner's equivalent.
- Do not enable interactive debugging such as `--pdb`, `--inspect-brk`, breakpoint waiting, or rerun-on-keypress modes.
- Bound test scope and duration when practical. Prefer the closest relevant test before a larger suite.
- When testing code that reads stdin or runs a loop, provide controlled input and enforce a test-level timeout in addition to the command timeout.
- A test process must exit with a meaningful status. Captured output without process completion is not a completed validation.

## PowerShell

- Prefer `pwsh -NoLogo -NoProfile -NonInteractive -Command <command>` for isolated automation.
- Do not use `Read-Host`, `Pause`, `Out-GridView`, `Enter-PSSession`, an interactive `pwsh` process, or commands that open an editor or credential UI.
- Avoid foreground `Wait-Job`, `Receive-Job -Wait`, `Wait-Process`, and unbounded polling unless completion is guaranteed and bounded.
- For a required background process, use `Start-Process -PassThru` with explicit arguments and save the returned PID. Verify readiness and later stop that PID only.
- Use `-Confirm:$false` only when the requested operation is already approved and is not destructive or irreversible. It does not replace required user confirmation.

## Python

- Use finite entry points such as `python -c`, `python -m pytest`, or a specific script that has a defined exit condition.
- Do not run `python` without a script or module because it opens the REPL.
- Do not run persistent modules such as `python -m http.server`, application development servers, notebook servers, or file watchers in the foreground.
- Avoid `input()`, `breakpoint()`, `pdb`, `pytest --pdb`, and debugger wait modes in automation.
- Use unbuffered output (`python -u` or `PYTHONUNBUFFERED=1`) when timely logs are needed to observe readiness or diagnose a timeout.

## Nushell

- Prefer `nu -n -c '<command>'` for isolated, non-interactive execution. Use `--no-config-file` where supported by the installed version when startup configuration must be excluded.
- Do not run `nu` without `-c` or a script because it opens an interactive shell.
- Avoid `input`, interactive selectors, unbounded `loop` blocks, log followers, and watch commands unless input or termination is explicitly controlled.
- Bound streams before collecting them. Do not collect an infinite or externally open-ended stream.

## chezmoi

- Commands such as `chezmoi status`, `chezmoi diff`, `chezmoi managed`, and `chezmoi source-path` are normally finite.
- Treat `chezmoi edit`, `chezmoi cd`, merge tools, password-manager integrations, and commands that invoke an editor, shell, pager, or credential prompt as interactive unless configured otherwise.
- Before `chezmoi apply`, inspect the affected scope for `run_` scripts and external integrations. A script, package manager, password manager, or installer can prompt or remain active even when chezmoi itself is non-interactive.
- Prefer a scoped `chezmoi diff` and, when suitable, `chezmoi apply --dry-run --verbose` before applying. A dry run does not prove that apply-time scripts will terminate.
- Apply only the intended managed targets. Report prompts, timeouts, and script failures instead of bypassing them.

## If a Command Does Not Exit

1. Let the configured timeout stop the tool call if direct interruption is unavailable.
2. Check whether a child process remains active.
3. Terminate only the verified process created by the current task.
4. Capture available output and report where execution stopped.
5. Choose a finite alternative or correct background-process workflow before retrying.
