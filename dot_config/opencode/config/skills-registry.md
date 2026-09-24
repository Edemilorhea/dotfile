# Skills Registry

## Purpose

This registry records where workflow assets are installed and whether OpenCode exposes them through skill scanning, profiles, or explicit commands.

## Inventory Status

| Root | Current role | Ownership status |
| --- | --- | --- |
| `~/.agents/skills` | The only global skill root. OpenCode and Codex both scan it. | chezmoi-managed local and vendored skills, plus `opencode-assets` installs declared in `external-assets.json` |
| `~/.config/opencode/config/assets/fable` | Command-only Fable payloads; not skill-scanned | chezmoi-managed local package |
| `~/.config/opencode/skills` | Retired 2026-09-25; keep empty | Its skills moved to `~/.agents/skills` |
| `~/.claude/skills` | Retired 2026-09-25; Claude Code is no longer used | Junctions removed |

`~/.agents/skills/.manifest.json` identifies bundled third-party ownership for several external skills. `config/external-assets.json` is the schema v4 catalog used by `opencode-assets`; project selections live in `.opencode/assets.json` and resolved ownership is recorded in `.opencode/assets.lock.json`.

## Ownership Policy

Self-maintained global skills belong under chezmoi source `dot_agents/skills/`. All other portable self-maintained skills, third-party skills, and optional project skills are managed through `config/assets` plus `external-assets.json`. The `core` profile is installed globally by default during initialization; projects select all other profiles through `.opencode/assets.json`.

## Exposure Values

| Value | Meaning |
| --- | --- |
| `global` | Available in every profile; invoke only when its trigger applies. |
| `profile` | Exposed only by its owning framework profile. |
| `project` | Enable from a project-local OpenCode configuration. |
| `explicit` | Installed but invoked only by an explicit command or skill request. |
| `quarantine` | Do not expose until duplicate and provenance decisions are completed. |

Every globally installed skill that the user may need directly stays advertised, because the user should not have to remember skill names. Only a sub-component that another skill loads by ID sets `metadata.opencode/autoinvoke: false`; OpenCode then omits it from the model's list but still loads it. Today that applies to the four `implementation-understanding-*-contract` skills and to `feature-flow-explainer` and `vibe-coding-tutor`, which `implementation-understanding-tutor` loads as evidence specialists. The user invokes `implementation-understanding-tutor` and `change-understanding-review` directly.

## Core Workflow Pack

| Assets | Pack | Target exposure | Owner |
| --- | --- | --- | --- |
| `fable-method`, `fable-loop`, `fable-judge` command payloads | `fable` | `explicit` through `/selfmade/fable`, `/selfmade/fable-method`, `/selfmade/fable-loop`, or `/selfmade/fable-judge`; never skill-scanned | chezmoi-managed local package |
| `linear-workflow` | `core-workflow` | `global` | chezmoi-managed local skill |
| `feature-flow-explainer` | `learning-code` | `explicit`; evidence specialist for `implementation-understanding-tutor` | chezmoi-managed local skill |

After explicit command entry, the Fable pack is the sole orchestration authority. The hidden `FableAgent` reads the command-only payloads from `config/assets/fable`; it does not load them with the `skill` tool. All three payloads remain installed together, while each command reads only the method, loop, judge, and nested references required by that invocation.

## Development and Repository Packs

| Skills | Pack | Target exposure | Owner / provenance |
| --- | --- | --- | --- |
| `find-docs` | `dev-foundation` | `global` | official `upstash/context7` skill; installed through `skills@1.5.21` from pinned revision `8276a7c`; authentication remains runtime-only |
| `research` | `dev-foundation` | `global` | unmodified Matt Pocock skill installed through `skills@1.5.21` from pinned `mattpocock/skills` revision `2ab9580`; root agents must bound scope and prevent recursive delegation |
| `change-understanding-review` | `dev-foundation` | `global` | chezmoi-managed local skill |
| `init` | `core` | `global` | zencoderai-derived template deployed by `opencode-assets` to `~/.agents/skills/init` |
| `implementation-understanding-tutor`, `implementation-understanding-report-contract`, `implementation-understanding-code-teach-contract`, `implementation-understanding-mechanism-contract`, `implementation-understanding-quality-contract` | `learning-code` | `global` as one indivisible orchestrator pack | chezmoi-managed templates deployed by `opencode-assets`; contract skills are invoked only by the tutor orchestrator |
| `vibe-coding-tutor` | `learning-code` | `explicit`; required by the tutor's Code Teach contract | chezmoi-managed; upstream `tortoiseknightma/vibe-coding-tutor` with pinned provenance recorded locally |
| `teach` | `learning-code` | `explicit` | Optional `learning` profile; pinned `mattpocock/skills` source in `external-assets.json` |

## Code Understanding Pack

| Asset | Kind | Target exposure | Owner / provenance |
| --- | --- | --- | --- |
| `graphify` | Skill | `project` | Optional `understand` profile; pinned `Graphify-Labs/graphify` revision `91f4d12` installed through `skills@1.5.21` |
| `serena` | MCP, not a skill | `project` | Optional `understand` profile; pinned `oraios/serena` revision `43ae021`; requires `uv` and is merged into project `mcp.serena` by the Asset Manager |
| `understand`, `understand-chat`, `understand-dashboard`, `understand-diff`, `understand-domain`, `understand-explain`, `understand-knowledge`, `understand-onboard` | Skill and command bundle | `project` | Understand Anything local junction; upstream provenance remains unrecorded |

Use Graphify first to build `GRAPH_REPORT.md` and query repository relationships. Use Serena next for symbol-level definitions, references, implementations, and focused edits. Use Understand Anything for guided explanation, onboarding, and its optional dashboard. Archify remains in the separate `design` profile for producing architecture diagrams; it is not the repository-analysis execution path.

## External Research Systems

| Asset | Exposure | Owner / provenance | Managed behavior |
| --- | --- | --- | --- |
| `ResearchCurator` | `global` | Local methodology adaptation of Stanford OVAL STORM and Co-STORM, reviewed at revision `fb951af` | `research-curator-storm` copies one read-only OpenCode agent through the `core` profile. It does not install `knowledge-storm`, Python dependencies, credentials, or a research service. |

`ResearchCurator` prepares multi-perspective evidence and learning outlines. It is not a publication engine and must not claim to execute the upstream STORM runtime. Focused primary-source technical research remains the responsibility of the `research` skill; simple questions remain with the active primary agent.

## Communication Clarity Pack

| Skills | Pack | Target exposure | Owner / provenance |
| --- | --- | --- | --- |
| `iso-24495-plain-language`, `asd-ste100`, `eli5-explainer` | `communication-clarity` | `global` | chezmoi-managed local skills based on the named public communication frameworks; they do not claim formal compliance |
| `wait-what` | `communication-clarity` | `global` | chezmoi-managed adaptation of Matt Pocock's `wait-what` recovery prompt |

These skills are complementary. ISO 24495 governs information design, ASD-STE100 supplies sentence-level discipline, ELI5 builds intuition, and `wait-what` repairs a failed explanation. Global routing must select the smallest useful subset rather than applying the full pack to every answer.

## Review Pack

Code review runs through `/selfmade/review`, `/selfmade/adv-review`, and the `jev-review` skill. `cross-review` was removed on 2026-09-25 because the user does not review with a separately named model.

`fable-judge` is intentionally excluded: it is a command-only payload in the Core Fable pack, not a review skill.

## Browser, Documents, and Productivity Packs

| Skills | Pack | Target exposure | Owner / provenance |
| --- | --- | --- | --- |
| `agent-browser` | `browser` | `global`; `change-verification` also loads it for exploration | `.agents` manifest: `vercel-labs/agent-browser` |
| `playwright` | `browser` | `global`; `change-verification` loads it for precise assertions | Runtime-only payload; exact-phrase and GitHub code searches found no verifiable public upstream as of 2026-08-09. Its `node_modules/playwright-core/lib/tools/skills/` folder was deleted on 2026-09-25 because V2 discovered three nested `SKILL.md` files there; `npm install` can restore it. |
| `document-processing` | `documents` | `project` | chezmoi-managed template deployed by `opencode-assets`; no longer globally scanned |
| `office-documents` | `documents` | `global` | chezmoi-managed thin integration for the global Office MCP |
| `copy-editing`, `copywriting` | `content` | `project` | chezmoi-managed template under `config/assets/skills`, deployed by `opencode-assets` profile `content`; no longer globally scanned (moved 2026-09-18 after zero global use in three months) |

## Design and Skill-Authoring Packs

| Skills | Pack | Target exposure | Owner / provenance |
| --- | --- | --- | --- |
| `frontend-design` | `design` | `global` | `.agents` manifest: `zencoderai/skills` |
| `interactive-diagram` | `design` | `explicit` | Optional `design` profile; pinned `LizardLiang/interactive-diagram` source in `external-assets.json` |
| `diagram-design` | `design` | `explicit` | Optional `design` profile; pinned `cathrynlavery/diagram-design` source in `external-assets.json` |
| `archify` | `design` | `explicit` | Optional `design` profile; pinned `tt-a1i/archify` source in `external-assets.json` |
| `find-skills` | `skill-governance` | `global` | Pinned `vercel-labs/skills` source in `external-assets.json` |
| `skill-creator`, `utility-pm-skill-builder`, `utility-pm-skill-iterate`, `utility-pm-skill-validate`, `utility-pm-skill-auditor`, `utility-pm-workflow-builder`, `utility-pm-workflow-orchestrator`, `utility-update-pm-skills` | `skill-governance` | `explicit` | `skill-creator` is anthropics; PM utilities are Product on Purpose candidates |

## Product Management Pack

All skills in this table belong to the pinned `product-on-purpose/pm-skills` catalog unless later provenance verification disproves it. They are useful as a coherent catalogue but are not general development defaults.

| Group | Skills | Target exposure |
| --- | --- | --- |
| Foundation | `foundation-build-risk-review`, `foundation-lean-canvas`, `foundation-meeting-agenda`, `foundation-meeting-brief`, `foundation-meeting-recap`, `foundation-meeting-synthesize`, `foundation-okr-writer`, `foundation-persona`, `foundation-prioritized-action-plan`, `foundation-stakeholder-briefings`, `foundation-stakeholder-update` | `project` |
| Discovery | `discover-competitive-analysis`, `discover-interview-synthesis`, `discover-journey-map`, `discover-market-sizing`, `discover-stakeholder-summary` | `project` |
| Definition | `define-hypothesis`, `define-jtbd-canvas`, `define-opportunity-tree`, `define-prioritization-framework`, `define-problem-statement` | `project` |
| Delivery | `deliver-acceptance-criteria`, `deliver-edge-cases`, `deliver-launch-checklist`, `deliver-prd`, `deliver-release-notes`, `deliver-user-stories` | `project` |
| Development | `develop-adr`, `develop-design-rationale`, `develop-solution-brief`, `develop-spike-summary` | `project` |
| Measurement | `measure-dashboard-requirements`, `measure-experiment-design`, `measure-experiment-results`, `measure-instrumentation-spec`, `measure-okr-grader`, `measure-survey-analysis` | `project` |
| Iteration | `iterate-lessons-log`, `iterate-pivot-decision`, `iterate-refinement-notes`, `iterate-retrospective` | `project` |
| Design sprints | `tool-design-sprint-brief`, `tool-design-sprint-map-and-target`, `tool-design-sprint-sketch`, `tool-design-sprint-decide-and-storyboard`, `tool-design-sprint-prototype-plan`, `tool-design-sprint-test-and-score`, `tool-design-sprint-readiness` | `explicit` |
| Foundation sprints | `tool-foundation-sprint-brief`, `tool-foundation-sprint-basics`, `tool-foundation-sprint-differentiation`, `tool-foundation-sprint-approach-options`, `tool-foundation-sprint-magic-lenses`, `tool-foundation-sprint-founding-hypothesis`, `tool-foundation-sprint-readiness` | `explicit` |
| Utilities | `tool-note-and-vote`, `utility-pm-changelog-curator`, `utility-pm-critic`, `utility-pm-release-conductor`, `to-spec`, `to-tickets` | `explicit` |

## Learning Pack

All of the following are a coherent but non-universal learning catalogue. They are chezmoi-managed and should be `explicit`, never global, until their upstream source is recorded.

| Group | Skills |
| --- | --- |
| Learning foundations | `00-learning-how-to-learn`, `00-tutor-persona` |
| K-12 | `01-k12-exam-systems`, `01-k12-humanities`, `01-k12-languages`, `01-k12-mathematics`, `01-k12-sciences` |
| University | `02-arts-design-tutor`, `02-business-economics-tutor`, `02-humanities-social-tutor`, `02-medical-health-tutor`, `02-music-arts`, `02-stem-tutor`, `02-university-guide` |
| Research | `03-academic-writing`, `03-data-analysis-stats`, `03-literature-review`, `03-research-methodology` |
| Career | `04-career-navigator`, `04-civil-service`, `04-consulting-career`, `04-finance-career`, `04-fullstack-webapp`, `04-interview-prep`, `04-tech-career` |
| Interpersonal | `05-communication-skills`, `05-cross-cultural`, `05-emotional-intelligence`, `05-negotiation-persuasion`, `05-social-intelligence` |
| Personal development | `06-creativity-innovation`, `06-critical-thinking`, `06-financial-literacy`, `06-health-wellness` |

## Asset Manager

`~/.config/opencode/scripts/opencode-assets.ps1` is the deterministic installer and ownership boundary. It supports `list`, `profiles`, `plan`, `apply`, `status`, `remove`, and `doctor` for global or project scope.

Project repositories may commit `.opencode/assets.json`; the generated `.opencode/assets.lock.json` records only manager-owned paths and pinned revisions. The manager never stores credentials and never runs a repository-provided installer.

### Runtime Targeting

V1 was retired on 2026-09-24. The catalog keeps the runtime dimension with one runtime, `v2`, which is also `defaultRuntimes`; `-Runtimes v2` is the only valid value.

| Behavior | Rule |
| --- | --- |
| Runtime root | `runtimes.v2.configRoot` (`~/.config/opencode`) resolves the `{configRoot}` token in target paths. `OPENCODE_ASSETS_V2_CONFIG_ROOT` overrides it per machine. |
| Plugin config | The spec is written under `plugins`. Hand-written `{ package, options }` entries are preserved. |
| Unsupported assets | `runtimes` and `runtimeBlocked` declare support. `list`, `plan`, `status`, and `doctor` report the blocked runtime and its reason; the TUI renders the item as `[-]` and cannot select it. `apply` refuses unless `-SkipUnsupported` is passed. |
| Lock | One global lock (`managerPaths.globalLock`) and one project lock. Each entry records the runtime IDs it serves. Older entries that list `v1` are harmless and are rewritten on the next apply. |

Runtime compatibility is a property of the payload, not of the config key. V2 reads normalized V1-shaped `mcp.<name>` and `permission.<key>` entries, but a V1 plugin implementation does not run in V2. The V1-only `gsd` (`@opengsd/gsd-core@1.10.0`) and `ponytail` (`@dietrichgebert/ponytail@4.9.0`) profiles were removed with V1; restore them from Git history if upstream ships a V2 `setup()` export.

### Optional Frameworks

| Profile | Package | Managed behavior |
| --- | --- | --- |
| `oh-my-opencode-slim` | `oh-my-opencode-slim@2.2.22` | Adds only the pinned plugin spec under `plugins` in project `.opencode/opencode.json` (V2 `setup()`, >=2.0.7); the upstream global installer is not run. |

This profile is project-only. Network credentials and framework-generated project planning data are never recorded in the asset catalog.

## Required Follow-up Evidence

1. Add upstream repository, revision, and content hash for every chezmoi-managed skill whose source is currently unknown.
2. Confirm the installer and source tree that produced the unmanifested `~/.agents/skills/playwright` payload.
