# Project Discovery

Derive runtime and test commands from repository evidence. Do not assume that a familiar framework uses its default commands or ports.

## Evidence order

1. Nearest `AGENTS.md` and repository documentation
2. Existing CI workflows and task-runner configuration
3. Package or project manifests
4. Existing E2E configuration and tests
5. Container, compose, launch-profile, and environment example files
6. Running processes and listening development servers

## Common evidence locations

- JavaScript and TypeScript: `package.json`, workspace manifests, lockfiles, `playwright.config.*`, `vite.config.*`, `next.config.*`
- .NET: solution and project files, launch profiles, test projects, `appsettings*.json`
- Python: `pyproject.toml`, `tox.ini`, `pytest.ini`, framework entry points
- Java and Kotlin: Gradle or Maven files, application profiles, test source sets
- Containers: compose files, Dockerfiles, dev-container configuration
- CI: GitHub Actions, GitLab CI, Azure Pipelines, or repository-specific workflows

Prefer a command already used by CI or repository documentation. Inspect scripts before running unfamiliar commands with side effects.

## Runtime checklist

Determine:

- Which services are required for the affected path
- Whether they are already running
- Which ports and base URLs are actually in use
- How readiness is observed
- Whether migrations, seed data, emulators, queues, or external dependencies are required
- Whether the available database and accounts are safe for mutation

Do not start duplicate services when the repository or environment already provides them. If multiple plausible frontend servers are running, ask which target belongs to the current project unless repository evidence disambiguates it.

## Authentication and data

- Prefer existing test fixtures, seeded accounts, storage state, or documented local auth bypasses.
- Ask the user to perform interactive login or provide an approved credential mechanism when necessary.
- Do not read or modify `.env`, credential stores, tokens, or secret files.
- Use unique, recognizable test records and clean them up only when deletion is safe and expected.
- Never perform destructive verification against production or shared data without explicit authorization.

## Existing Playwright setup

If `playwright.config.*` or project E2E tests exist, inspect:

- `testDir`, projects, devices, and base URL
- `webServer` startup behavior
- Authentication setup and storage state
- Fixtures and page objects
- Locator and assertion conventions
- Trace, screenshot, video, and reporter settings
- CI command and required environment

Use this setup for permanent or existing regression tests. Do not create a parallel temporary convention inside the repository.
