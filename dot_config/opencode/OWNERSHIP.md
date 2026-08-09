# OpenCode Ownership

## Status

This is a self-managed OpenCode configuration. `chezmoi` is the source of truth for files deployed under `~/.config/opencode`.

## Ownership Categories

| Category | Source of truth | Update policy |
| --- | --- | --- |
| Self-managed configuration | chezmoi source | Review and edit in chezmoi source first. |
| External dependencies | Pinned bootstrap metadata | Install reproducibly; never vendor generated dependency trees. |
| Runtime state and secrets | Local machine only | Never add to chezmoi. |

## Maintenance Rules

- Do not remove a `.chezmoiignore` rule until its replacement source path and validation are in place.
- `LOCU_PAT`, OAuth tokens, account files, caches, logs, `.tmp`, and `node_modules` remain local-only.
- A managed change must update its chezmoi source in the same atomic step.

## External Asset Policy

- `config/external-assets.json` declares reproducible third-party skills, marketplaces, and project-scoped assets.
- `run_onchange_after_install-opencode-external-assets.ps1.tmpl` is the only managed dispatcher for that inventory.
- Installer payloads, compatibility junctions, lock files, and credentials remain runtime-only.
- Locally authored or materially modified assets stay in chezmoi; unmodified external payloads stay with their installer.
