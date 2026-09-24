# Agent Skills Chezmoi Changelog

## 2026-08-21T21:26:29+08:00 - Initialize management scope

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `.`
- Summary: Added a dedicated marker and changelog for agent skill configuration.
- Important records:
  - The nearest ancestor marker owns future records; nested markers take precedence.
  - The marker requires evaluation and does not automatically approve every descendant.
- Portability: Marker metadata contains no host-specific paths; the machine name is audit metadata only.
- Chezmoi: Added and managed as `dot_chezmanga/CHANGELOG.md`.
- Verification: `chezmoi source-path` resolved the target, scoped apply created it, and scoped diff was empty.

## 2026-09-25T02:05:11+08:00 - Make ~/.agents/skills the only global skill root

- Status: Completed
- Machine: TC-TSENG
- Platform: Microsoft Windows 10.0.26200 / AMD64
- Scope: `skills/{change-understanding-review,change-verification,chezmoi-management,feature-flow-explainer,jev-review,linear-workflow,office-documents,typesafe-ai,vibe-coding-tutor}`
- Summary: Moved the nine chezmoi-managed skills here from `~/.config/opencode/skills`. OpenCode and Codex now read every global skill from this root.
- Important records:
  - Removed the vendored `cross-review` skill and its manifest entry; the user does not review with a separately named model.
  - Every skill here stays advertised except sub-components of `implementation-understanding-tutor`: its four contracts, plus `feature-flow-explainer` and `vibe-coding-tutor` (`metadata.opencode/autoinvoke: false`). The user invokes the tutor and `change-understanding-review` directly. A brief trial that hid six standalone skills was reverted, so the vendored files still match `skills/.manifest.json`.
  - Deleted seven orphan `skills/source-command-*` skills; they were not chezmoi-managed.
  - `skills/playwright` stays and stays advertised: `change-verification` loads it, and its `run.js` needs the local `node_modules`. It is an unmanaged runtime payload. Deleted only `node_modules/playwright-core/lib/tools/skills/` (16 files), which leaked `playwright-cli`, `playwright-component-testing`, and `playwright-trace` as extra skills; `npm install` can restore that folder.
- Portability: No machine-specific paths.
- Chezmoi: Source moved from `dot_config/opencode/skills/` to `dot_agents/skills/` with `git mv`.
- Verification: Scoped `chezmoi apply` exited 0 and created the nine skill directories; frontmatter edits contain no CR bytes.