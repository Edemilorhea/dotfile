# OpenAgentsControl Vendor Provenance

This directory is a review-only upstream baseline. It is never loaded by OpenCode and its installer scripts must never run against the active configuration.

## Pinned Baseline

- Repository: `https://github.com/darrenhinde/OpenAgentsControl`
- Version: `0.7.1`
- Commit: `ef3836efd659e451b6dbb8eee7d3213ba39f5aec`
- Archive SHA-256: `5228974504b810f90ae22e8d4d7b2f970bb007dec855dcd04b1cf8ea93818a6e`
- Import status: pending full archive capture; runtime reference currently exists at `~/.config/opencode/vendor/openagentscontrol/`.

## Refresh Procedure

1. Select a release or reviewed commit; never auto-follow `main`.
2. Import it as a new immutable candidate and record its commit, date, hashes, and file inventory.
3. Diff the candidate against this baseline and self-managed files.
4. Classify each change as Adopt, Adapt, or Reject.
5. Promote only approved changes into normal chezmoi-managed paths.
6. Validate and commit the vendor metadata and self-managed changes together.

Do not edit imported upstream files to carry local changes. Local behaviour belongs in normal chezmoi-managed files.
