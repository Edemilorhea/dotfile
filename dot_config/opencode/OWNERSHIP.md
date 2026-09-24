# OpenCode Ownership

## Status

Two sources deploy `~/.config/opencode`. chezmoi owns the base configuration. The private `opencode-assets` repository (GitHub `Edemilorhea/opencode-assets`) owns every installable asset. Its local path is written in `commands/selfmade/assets.md` on each machine.

## Ownership Categories

| Category | Source of truth | Update policy |
| --- | --- | --- |
| Base configuration: `opencode.json` except `plugins` and `mcp`, `cli.json`, `dcp.jsonc`, `AGENTS.md`, `docs/tool-command-lifecycle.md`, `env.example` | chezmoi source | Edit in chezmoi source first, then `chezmoi apply`. |
| OpenCode binary, user `PATH`, and the Claude Code version override | chezmoi `run_onchange_after_setup-opencode.ps1.tmpl` | Bump the version in that script. |
| Agents, commands, local plugins, `~/.agents/skills`, Fable payloads, `opencode-mem.jsonc`, `plugins` and `mcp` in `opencode.json`, MCP server clones, the `rtk` binary | `opencode-assets` repository | Edit the repository, commit, then run `/selfmade/assets apply -Scope global`. |
| Runtime state and secrets | Local machine only | Never add to chezmoi or to `opencode-assets`. |

## Maintenance Rules

- `modify_opencode.json` rewrites every key except `plugins` and `mcp`, which it copies from the current file. Do not put plugins or MCP servers in it.
- Each machine records its global selection in `config/assets.json` and the installed result in `config/assets.lock.json`. Both are runtime files.
- `LOCU_PAT`, `JEV_API_KEY`, OAuth tokens, account files, caches, logs, `.tmp`, and `node_modules` remain local-only.
- A managed change must update its source of truth in the same atomic step.

## New Machine

1. Run `chezmoi init --apply` for the base configuration and the OpenCode binary.
2. Clone `Edemilorhea/opencode-assets` and run `./opencode-assets.ps1 apply -Scope global -Profiles core` (add `integrations` when the machine needs MCP servers and tool integrations).
