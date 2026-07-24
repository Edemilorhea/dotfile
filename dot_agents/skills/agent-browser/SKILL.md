---
name: agent-browser
description: Browser automation CLI for explicit website or desktop-app interaction, or when authenticated, dynamic, or JavaScript-only content requires it. Do not trigger merely because a public URL is supplied or the user requests a summary, comparison, or research; use a read-only fetch tool for those tasks.
allowed-tools: Bash(agent-browser:*), Bash(npx agent-browser:*)
hidden: true
---

# agent-browser

Fast browser automation CLI for AI agents. Chrome/Chromium via CDP with
accessibility-tree snapshots and compact `@eN` element refs.

## Usage Boundary

Use this skill only when the user explicitly requests browser interaction
(open, click, fill, log in, screenshot, automate, scrape, test, or operate a
desktop app), or when authenticated, dynamic, or JavaScript-only content
cannot be obtained with a read-only fetch tool.

Do not start a browser only because the user provides a public URL or asks to
read, summarize, compare, or research public content. Prefer a read-only fetch
tool for those requests.

Before browser automation, state the intended action. Use a visible browser
only when the user asks to see it or needs to interact with it. After running
the browser, return the requested result in the same response; do not leave a
browser operation unexplained.

Install: `npm i -g agent-browser && agent-browser install`

## Start here

This file is a discovery stub, not the usage guide. Before running any
`agent-browser` command, load the actual workflow content from the CLI:

```bash
agent-browser skills get core             # start here — workflows, common patterns, troubleshooting
agent-browser skills get core --full      # include full command reference and templates
```

The CLI serves skill content that always matches the installed version,
so instructions never go stale. The content in this stub cannot change
between releases, which is why it just points at `skills get core`.

## Specialized skills

Load a specialized skill when the task falls outside browser web pages:

```bash
agent-browser skills get electron          # Electron desktop apps (VS Code, Slack, Discord, Figma, ...)
agent-browser skills get slack             # Slack workspace automation
agent-browser skills get dogfood           # Exploratory testing / QA / bug hunts
agent-browser skills get derive-client     # Record a HAR and derive a standalone API client
agent-browser skills get vercel-sandbox    # agent-browser inside Vercel Sandbox microVMs
agent-browser skills get agentcore         # AWS Bedrock AgentCore cloud browsers
```

Run `agent-browser skills list` to see everything available on the
installed version.

## Why agent-browser

- Fast native Rust CLI, not a Node.js wrapper
- Works with any AI agent (Cursor, Claude Code, Codex, Continue, Windsurf, etc.)
- Chrome/Chromium via CDP with no Playwright or Puppeteer dependency
- Accessibility-tree snapshots with element refs for reliable interaction
- Sessions, authentication vault, state persistence, video recording
- Specialized skills for Electron apps, Slack, exploratory testing, cloud providers

## Observability Dashboard

The dashboard runs independently of browser sessions on port `4848`. Use it
only when the task needs browser-session observability.
