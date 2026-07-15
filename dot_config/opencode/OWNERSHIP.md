# OpenCode Ownership and Provenance

## Source of Truth

Chezmoi is the source of truth for this configuration. Do not run OpenAgentsControl (OAC) `install.sh` or `update.sh` against the active configuration.

## Ownership Boundaries

| Category | Owner | Update policy |
| --- | --- | --- |
| Active configuration, commands, agents, plugins | This chezmoi repository | Review and edit here first. |
| OAC vendor baseline | `vendor/openagentscontrol/` | Refresh only through an explicit, reviewed import. |
| Secrets, caches, state, `.tmp`, dependency trees | Local machine | Never commit. |

## Upstream Integration

1. Do not track every upstream `main` commit.
2. Select a release or reviewed commit when it fixes a relevant issue, includes security work, or is needed for a requested feature.
3. Compare the new vendor candidate with the pinned vendor baseline and this repository's active configuration.
4. Classify each change as Adopt, Adapt, or Reject.
5. Apply approved behaviour only to active chezmoi-managed files.
6. Validate, update provenance, and commit both the vendor record and active changes together.

The vendor directory is reference-only and must never be auto-loaded by OpenCode. Local customisations never belong in imported vendor files.
