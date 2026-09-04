# Skills Registry

## Purpose

This registry is the source of the skill-pack decision. It separates where a skill is installed from whether OpenCode should expose it by default. No skill is moved, disabled, or deleted by this document.

## Inventory Status

| Root | Current role | Ownership status |
| --- | --- | --- |
| `~/.config/opencode/skills` | OpenCode global auto-scan | chezmoi-managed local skills |
| `~/.agents/skills` | Cross-agent external auto-scan | mixed installer payloads; reproducible entries are declared in `external-assets.json` |
| `~/.claude/skills` | Claude compatibility auto-scan | installer-created junctions that mirror selected `.agents` skills |

`~/.agents/skills/.manifest.json` identifies bundled third-party ownership for several external skills. `config/external-assets.json` is the schema v4 catalog used by `opencode-assets`; project selections live in `.opencode/assets.json` and resolved ownership is recorded in `.opencode/assets.lock.json`.

## Ownership Policy

Only self-maintained assets that are OpenCode-specific and must be directly globally auto-scanned belong under `dot_config/opencode/...`. All other portable self-maintained skills, third-party skills, and optional project skills are managed through `config/assets` plus `external-assets.json`. The `core` profile is installed globally by default during initialization; projects select all other profiles through `.opencode/assets.json`.

## Exposure Values

| Value | Meaning |
| --- | --- |
| `global` | Available in every profile; invoke only when its trigger applies. |
| `profile` | Exposed only by its owning framework profile. |
| `project` | Enable from a project-local OpenCode configuration. |
| `explicit` | Installed but invoked only by an explicit command or skill request. |
| `quarantine` | Do not expose until duplicate and provenance decisions are completed. |

## Core Workflow Pack

| Skills | Pack | Target exposure | Owner |
| --- | --- | --- | --- |
| `fable-method`, `fable-loop`, `fable-judge` | `fable` | `global` as one indivisible pack | chezmoi-managed local package |
| `feature-flow-explainer`, `linear-workflow` | `core-workflow` | `global` | chezmoi-managed local skills |

The Fable pack is the sole orchestration authority. `fable-loop` and `fable-judge` need not trigger for ordinary work, but must always be available with `fable-method`.

## Development and Repository Packs

| Skills | Pack | Target exposure | Owner / provenance |
| --- | --- | --- | --- |
| `find-docs` | `dev-foundation` | `global` | official `upstash/context7` skill; installed through `skills@1.5.21` from pinned revision `8276a7c`; authentication remains runtime-only |
| `research` | `dev-foundation` | `global` | unmodified Matt Pocock skill installed through `skills@1.5.21` from pinned `mattpocock/skills` revision `2ab9580`; root agents must bound scope and prevent recursive delegation |
| `change-understanding-review` | `dev-foundation` | `global` | chezmoi-managed local skill |
| `init` | `core` | `global` | zencoderai-derived template deployed by `opencode-assets` to `~/.agents/skills/init` |
| `implementation-understanding-tutor`, `implementation-understanding-report-contract`, `implementation-understanding-code-teach-contract`, `implementation-understanding-mechanism-contract`, `implementation-understanding-quality-contract` | `learning-code` | `global` as one indivisible orchestrator pack | chezmoi-managed templates deployed by `opencode-assets`; contract skills are invoked only by the tutor orchestrator |
| `vibe-coding-tutor` | `learning-code` | `global` | chezmoi-managed; upstream `tortoiseknightma/vibe-coding-tutor` with pinned provenance recorded locally |
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

| Skills | Pack | Target exposure | Owner / provenance |
| --- | --- | --- | --- |
| `cross-review` | `review` | `explicit` | `.agents` manifest: `zencoderai/skills` |

`fable-judge` is intentionally excluded: it belongs only to the Core Fable pack.

## Browser, Documents, and Productivity Packs

| Skills | Pack | Target exposure | Owner / provenance |
| --- | --- | --- | --- |
| `agent-browser` | `browser` | `project` | `.agents` manifest: `vercel-labs/agent-browser` |
| `playwright` | `browser` | `project` | Runtime-only payload; exact-phrase and GitHub code searches found no verifiable public upstream as of 2026-08-09 |
| `document-processing` | `documents` | `project` | chezmoi-managed template deployed by `opencode-assets`; no longer globally scanned |
| `office-documents` | `documents` | `global` | chezmoi-managed thin integration for the global Office MCP |
| `copy-editing`, `copywriting` | `content` | `explicit` | chezmoi-managed; record upstream provenance before refresh |

## Design and Skill-Authoring Packs

| Skills | Pack | Target exposure | Owner / provenance |
| --- | --- | --- | --- |
| `frontend-design` | `design` | `project` | `.agents` manifest: `zencoderai/skills` |
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

### Optional Frameworks

| Profile | Package | Managed behavior |
| --- | --- | --- |
| `oh-my-opencode-slim` | `oh-my-opencode-slim@2.2.10` | Adds only the pinned plugin spec to project `.opencode/opencode.json`; the upstream global installer is not run. |
| `gsd` | `@opengsd/gsd-core@1.10.0` | Runs the pinned official OpenCode installer with the `standard` profile and an isolated HOME; deploys only its generated file manifest and safely merges its project permission/MCP entries. |
| `ponytail` | `@dietrichgebert/ponytail@4.9.0` | Adds only the pinned plugin spec to project `.opencode/opencode.json`. |

These profiles are project-only. `oh-my-opencode-slim` and `ponytail` may coexist; `gsd` remains mutually exclusive with both. Network credentials and framework-generated project planning data are never recorded in the asset catalog.

## Required Follow-up Evidence

1. Add upstream repository, revision, and content hash for every chezmoi-managed skill whose source is currently unknown.
2. Confirm the installer and source tree that produced the unmanifested `.agents/skills` and all `.claude/skills` entries.
3. Hash-compare duplicate names across external roots before choosing the canonical copy.
4. Only after those checks, implement profile rendering and disable the redundant auto-scan root.
