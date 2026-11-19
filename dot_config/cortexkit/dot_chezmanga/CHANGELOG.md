# Cortexkit Chezmoi Changelog

## 2026-10-05T21:45:05+08:00 - Manage Magic Context config

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `magic-context.jsonc`
- Summary: Put the Magic Context plugin config under chezmoi. Historian and dreamer both use `omniroute/claude-sonnet`.
- Important records:
  - The plugin itself is installed through opencode-assets; this scope only holds its user config.
  - The file contains no secrets or machine-specific paths.
- Portability: Portable; the model ID depends only on the OmniRoute provider being configured.
- Chezmoi: Added `magic-context.jsonc` and `.chezmanga/` as a new management root.
- Verification: Scoped `chezmoi status` is clean after apply; source uses LF.

## 2026-11-19T17:05:16+08:00 - Fold at 250k tokens instead of the percentage default

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `magic-context.jsonc`
- Summary: Added `execute_threshold_tokens.default = 250000`. Magic Context now folds when the context passes 250k tokens, for every model.
- Important records:
  - Evidence: session `ses_e0d9a7541ffeV2Qr7ViIINYp9a` (a Code-Mentor guide of 19 files) folded 18 times in 22 minutes. The detected limit was 168k with provenance `unknown`, the fold came at about 109k, and the fixed prefix took 46k. About 63k was left for work that needed about 82k.
  - The real limits are declared in `opencode.json` in the same change (see the opencode changelog). With an 872k limit the default 65% would fold at about 480k, so the absolute value keeps the cost per step bounded.
  - The plugin clamps a token threshold above 90% of the context limit. 250k is below that for an 872k model.
- Portability: Portable. The value is absolute and does not depend on the machine.
- Chezmoi: Updated the managed source and applied only `magic-context.jsonc` and this changelog.
- Verification: Scoped apply and `chezmoi status` only. No session was run after an OpenCode restart to confirm the new limit and threshold in `session_meta`.
