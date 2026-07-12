---
description: Audit recent OpenCode configuration changes for safe chezmoi management.
agent: OpenAgent
subtask: true
---

# Chezmoi Configuration Audit

Arguments: `$ARGUMENTS`

Audit OpenCode configuration changes and report safe chezmoi actions. This command is **read-only**: never run `chezmoi add`, `chezmoi re-add`, `chezmoi apply`, `git add`, `git commit`, or `git push`.

## Modes

- No arguments: audit target files modified within the last 7 days.
- `<duration>`: audit a PowerShell-compatible duration such as `30d` or `14d`.
- `--full`: audit all relevant OpenCode configuration files, regardless of modification time.
- `--verbose`: include source-only and ignored historical entries; otherwise summarize them.

If arguments are invalid or combine unsupported modes, explain the valid forms and stop. Do not guess a duration.

## Safety Boundaries

Never read file contents from, list individual files within, or recommend managing these locations:

- `C:\Users\tc_tseng\.local\share\opencode\`
- `C:\Users\tc_tseng\.local\state\opencode\`
- `C:\Users\tc_tseng\.cache\opencode\`
- `.tmp\sessions\`
- account, auth, credential, token, secret, key, session, database, WAL, SHM, cache, log, history, snapshot, tool-output, lock, backup, or temporary files
- `antigravity-accounts.json`

Do not inspect OpenCode session messages, SQLite databases, tool output, account data, or secret-bearing files. Session activity may be summarized only as an unattributed timestamp when safely available; file and chezmoi evidence are authoritative.

## Authoritative Ownership Rules

Read `C:\Users\tc_tseng\.config\opencode\AGENTS.md` and `C:\Users\tc_tseng\.local\share\chezmoi\.chezmoiignore` before classifying files.

Classify target files under `C:\Users\tc_tseng\.config\opencode\` as follows:

1. **chezmoi-owned**: `AGENTS.md`, `WORKFLOW.md`, `CodeStyle.md`, `opencode.json`, `agent\selfmade\**`, `command\selfmade\**`, `agent\core\**`, `agent\subagents\code\**`, and `agent\subagents\core\**`.
2. **install.sh-owned**: `context\**`, OAC-provided skills, `plugins\**`, `tool\**`, and other OAC agents or commands excluded by `.chezmoiignore`.
3. **runtime or sensitive**: anything matching the safety boundaries or excluded by `.chezmoiignore` for runtime, account, backup, test-only, or machine-local reasons.
4. **ambiguous**: every other OpenCode configuration file, including files already in the chezmoi source but not explicitly owned by `AGENTS.md`.

Never recommend an action for install.sh-owned, runtime/sensitive, or ambiguous files. Explain the owner or uncertainty instead.

## Audit Procedure

1. Resolve the source directory with `chezmoi source-path`; expected source mapping is `dot_config\opencode\...`.
2. Collect read-only evidence with:
   - `chezmoi status`
   - `chezmoi diff`
   - `chezmoi managed`
   - `chezmoi ignored`
   - `chezmoi unmanaged`
   - `git -C <source-path> status --short`
   - `git -C <source-path> log --since=<period> --name-status` when auditing a duration
3. For recent mode, inspect only metadata for target files modified in the requested period. For full mode, inspect the target configuration inventory while respecting every safety boundary.
4. Compare each candidate with the source mapping, chezmoi managed/ignored state, `chezmoi status`, and `chezmoi diff`.
5. Use the following action rules for **chezmoi-owned** files only:
   - **RE-ADD candidate**: the target is already managed and differs from its source representation. Recommend `chezmoi re-add <target-path>`.
   - **ADD candidate**: the target exists, is unmanaged, is not ignored, and is chezmoi-owned. Recommend `chezmoi add <target-path>`.
   - **No action**: target and source are synchronized, source-only, ignored, or evidence is incomplete.

`mtime` is a discovery signal, not proof that a user intentionally changed a file. Prefer chezmoi status/diff and source Git history when they disagree.

## Required Report

Use this structure:

```markdown
# Chezmoi Audit Report

Mode: ...
Scope: ...
Source: ...

## Summary
- Re-add candidates: N
- Add candidates: N
- Excluded: N
- Ambiguous: N

## Safe Candidates
| Action | Target | Evidence | Reason |
| --- | --- | --- | --- |
| RE-ADD | ... | managed + diff | ... |
| ADD | ... | unmanaged + not ignored | ... |

## Excluded
| Path or category | Owner | Reason |
| --- | --- | --- |

## Ambiguous Ownership
| Target | Evidence | Why manual decision is required |
| --- | --- | --- |

## Next Step
Reply with the exact targets to apply, for example:
- `re-add <target-path>`
- `add <target-path>`

I will show the exact command and request confirmation before any write operation.
```

Do not create files, update `.chezmoiignore`, or imply that a candidate has been managed. Report command failures without retrying or attempting repairs.
