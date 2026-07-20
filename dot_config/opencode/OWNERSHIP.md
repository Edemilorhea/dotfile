# OpenCode Ownership and Provenance

## Status

This configuration is migrating to a self-managed chezmoi setup. `chezmoi` is the intended source of truth; OpenAgentsControl (OAC) is no longer an update source.

## Ownership Categories

| Category | Source of truth | Update policy |
| --- | --- | --- |
| Self-managed configuration | chezmoi source | Review and edit in chezmoi source first. |
| Vendored OAC assets | chezmoi source with a pinned provenance record | Update only by an explicit vendor refresh. |
| External dependencies | Pinned bootstrap metadata | Install reproducibly; never vendor generated dependency trees. |
| Runtime state and secrets | Local machine only | Never add to chezmoi. |

## Migration Rules

- Do not run OAC `install.sh` or `update.sh` against this configuration.
- Existing OAC-derived runtime files have unknown exact provenance until they are inventoried and captured as a vendor snapshot.
- Do not remove a `.chezmoiignore` rule until its replacement source path and validation are in place.
- `LOCU_PAT`, OAuth tokens, account files, caches, logs, `.tmp`, and `node_modules` remain local-only.
- A managed change must update its chezmoi source in the same atomic step.

## Current Migration Batches

1. Establish this ownership baseline.
2. Capture self-managed Locu tools and tests.
3. Capture selected OAC assets as a fixed vendor snapshot.
4. Pin external dependency bootstrap metadata.
5. Validate reconstruction without relying on OAC installation output.

## Provenance Record

The OAC source repository is `https://github.com/darrenhinde/OpenAgentsControl`. Treat its runtime archive only as a review baseline until the matching full archive is captured in chezmoi. Local behaviour must be promoted into normal chezmoi-managed paths, never changed in place under `vendor/`.

## Fixed Vendor Candidate

The runtime review baseline is pinned to `ef3836efd659e451b6dbb8eee7d3213ba39f5aec` and SHA-256 `5228974504b810f90ae22e8d4d7b2f970bb007dec855dcd04b1cf8ea93818a6e`. It is deployed under `.config/opencode/vendor/openagentscontrol`, not into active OpenCode paths. Its files must be hash-compared and explicitly promoted before any active OAC-derived asset is replaced. The chezmoi provenance record is `vendor/openagentscontrol/PROVENANCE.md`; complete archive capture remains a separate migration batch.
