# Skills Registry

## Purpose

This registry is the source of the skill-pack decision. It separates where a skill is installed from whether OpenCode should expose it by default. No skill is moved, disabled, or deleted by this document.

## Inventory Status

| Root | Skills | Current role | Ownership status |
| --- | ---: | --- | --- |
| `~/.config/opencode/skills` | 47 | OpenCode global auto-scan | chezmoi-managed; upstream provenance is incomplete for most entries |
| `~/.agents/skills` | 94 | External auto-scan | mixed: 9 entries have a managed manifest; the rest require installer ownership confirmation |
| `~/.claude/skills` | 83 | External auto-scan | unmanaged duplicate candidate; provenance must be confirmed before cleanup |

`~/.agents/skills/.manifest.json` identifies bundled or pinned third-party ownership for `plan`, `research`, `skill-creator`, `agent-browser`, `init`, `cross-review`, `zen-review`, `zen-comprehensive-review`, and `frontend-design`. `config/external-skills.json` pins `to-spec` and `to-tickets` from `mattpocock/skills` and the Product on Purpose PM catalog from `product-on-purpose/pm-skills`.

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

The Fable pack is the sole orchestration authority. `fable-loop` and `fable-judge` need not trigger for ordinary work, but must always be available with `fable-method`.

## Development and Repository Packs

| Skills | Pack | Target exposure | Owner / provenance |
| --- | --- | --- | --- |
| `context7`, `change-understanding-review` | `dev-foundation` | `global` | chezmoi-managed; record upstream provenance before any refresh |
| `plan`, `research`, `init` | `repo-development` | `project` | `.agents` manifest: bundled / zencoderai |
| `understand`, `understand-chat`, `understand-dashboard`, `understand-diff`, `understand-domain`, `understand-explain`, `understand-knowledge`, `understand-onboard` | `repo-understanding` | `project` | external; currently `.agents` only; provenance unrecorded |
| `task-management` | `oac-task-management` | `profile` (`oac`) | chezmoi-managed OAC-derived asset |
| `vibe-coding-tutor`, `teach` | `learning-code` | `explicit` | `vibe-coding-tutor` is chezmoi-managed; `teach` is external with provenance to record |

## Review Pack

| Skills | Pack | Target exposure | Owner / provenance |
| --- | --- | --- | --- |
| `code-review`, `comprehensive-review`, `cross-review`, `zen-review`, `zen-comprehensive-review` | `review` | `explicit` | `cross-review` is zencoderai; Zen entries are bundled; remaining origins require confirmation |

`fable-judge` is intentionally excluded: it belongs only to the Core Fable pack.

## Browser, Documents, and Productivity Packs

| Skills | Pack | Target exposure | Owner / provenance |
| --- | --- | --- | --- |
| `browser-automation`, `agent-browser`, `playwright` | `browser` | `project` | `agent-browser` is vercel-labs; others need provenance records |
| `document-processing`, `office-documents` | `documents` | `project` | chezmoi-managed; record upstream provenance before refresh |
| `linear-workflow` | `productivity` | `project` | chezmoi-managed; record upstream provenance before refresh |
| `copy-editing`, `copywriting` | `content` | `explicit` | chezmoi-managed; record upstream provenance before refresh |

## Design and Skill-Authoring Packs

| Skills | Pack | Target exposure | Owner / provenance |
| --- | --- | --- | --- |
| `frontend-design`, `interactive-diagram`, `utility-mermaid-diagrams`, `utility-slideshow-creator` | `design` | `project` | `frontend-design` is zencoderai; other origins require confirmation |
| `find-skills`, `skill-creator`, `utility-pm-skill-builder`, `utility-pm-skill-iterate`, `utility-pm-skill-validate`, `utility-pm-skill-auditor`, `utility-pm-workflow-builder`, `utility-pm-workflow-orchestrator`, `utility-update-pm-skills` | `skill-governance` | `explicit` | `skill-creator` is anthropics; PM utilities are Product on Purpose candidates |

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

## Duplicate and Cleanup Decision

The 83 `.claude/skills` entries substantially overlap with `.agents/skills`. Until a canonical external root is selected, all duplicate external entries are `quarantine`: they remain on disk but must not be treated as an approved default exposure.

Before any cleanup, verify each duplicate by content hash and preserve the installer manifest or lock record. The target state is one canonical external root plus reproducible installer metadata; no deletion occurs during classification.

## Required Follow-up Evidence

1. Add upstream repository, revision, and content hash for every chezmoi-managed skill whose source is currently unknown.
2. Confirm the installer and source tree that produced the unmanifested `.agents/skills` and all `.claude/skills` entries.
3. Hash-compare duplicate names across external roots before choosing the canonical copy.
4. Only after those checks, implement profile rendering and disable the redundant auto-scan root.
