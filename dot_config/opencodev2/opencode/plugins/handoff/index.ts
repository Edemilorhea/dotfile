// V2 port of the v1 plugin `opencode-handoff` (npm 0.5.0, @opencode-ai/plugin).
// Upstream has no v2 build, so the same `/handoff` flow is reimplemented here
// against `@opencode/plugin`.
//
// One behaviour cannot be ported. V1 called `client.tui.appendPrompt` to drop
// the generated prompt into the new session's input box as an editable draft.
// V2 has no server API for that: `tui.prompt.append` exists in the protocol and
// the CLI listens for it, but nothing on the server can publish it and the CLI
// plugin context exposes no prompt writer. The handoff text is therefore
// attached to the new session with `session.synthetic`, which adds it as
// context without starting a turn. The next session starts by reading it.
//
// For the same reason the v1 `@file` preloading is gone: synthetic text is not
// scanned for attachments. Files are listed as a reading list instead.
//
// The default export is a plain object rather than `Plugin.define(...)` because
// OpenCode does not resolve `@opencode/plugin` for a local plugin directory and
// `define` is only `(plugin) => plugin`. OpenCode validates the exported shape.

const HANDOFF_COMMAND = `GOAL: You are creating a handoff message to continue work in a new session.

<context>
When an AI assistant starts a fresh session, it spends significant time exploring the codebase - grepping, reading files, searching - before it can begin actual work. This "file archaeology" is wasteful when the previous session already discovered what matters.

A good handoff frontloads everything the next session needs so it can start implementing immediately.
</context>

<instructions>
Analyze this conversation and extract what matters for continuing the work.

1. Identify all relevant files the next session should read first

   Include files that will be edited, dependencies being touched, relevant tests, configs, and key reference docs. Be generous - the cost of an extra file is low; missing a critical one means another archaeology dig. Target 8-15 files, up to 20 for complex work.

   These files are listed for the next session to read. They are not preloaded into its context.

2. Draft the context and goal description

   Describe what we're working on and provide whatever context helps continue the work. Structure it based on what fits the conversation - could be tasks, findings, a simple paragraph, or detailed steps.

   Preserve: decisions, constraints, user preferences, technical patterns.

   Exclude: conversation back-and-forth, dead ends, meta-commentary.

The user controls what context matters. If they mentioned something to preserve, include it - trust their judgment about their workflow.
</instructions>

<user_input>
This is what the next session should focus on. Use it to shape your handoff's direction - don't investigate or search, just incorporate the intent into your context and goals.

If empty, capture a natural continuation of the current conversation's direction.

USER: $ARGUMENTS
</user_input>

---

After generating the handoff message, IMMEDIATELY call handoff_session with your prompt, a short title, and the files:
\`handoff_session(prompt="...", title="...", files=["src/foo.ts", "src/bar.ts", ...])\``

const MAX_TRANSCRIPT_MESSAGES = 500
const DEFAULT_TRANSCRIPT_MESSAGES = 100

interface ToolResult {
  content: string
}

function normalizeFiles(value: unknown): string[] {
  if (!Array.isArray(value)) return []
  return value
    .filter((entry): entry is string => typeof entry === "string" && entry.trim().length > 0)
    .map((entry) => entry.trim().replace(/^@/, ""))
}

function formatTranscript(messages: any[], truncated: boolean): string {
  const lines: string[] = []

  for (const message of messages) {
    if (message?.type === "user") {
      lines.push("## User", String(message.text ?? ""))
      for (const file of message.files ?? []) {
        lines.push(`[Attached: ${file?.uri ?? "file"}]`)
      }
      lines.push("")
      continue
    }

    if (message?.type === "synthetic") {
      lines.push("## Synthetic", String(message.text ?? ""), "")
      continue
    }

    if (message?.type === "assistant") {
      lines.push("## Assistant")
      for (const part of message.content ?? []) {
        if (part?.type === "text") lines.push(String(part.text ?? ""))
        if (part?.type === "tool") lines.push(`[Tool: ${part.name}] ${part.state?.status ?? "unknown"}`)
      }
      lines.push("")
    }
  }

  const body = lines.join("\n").trim()
  return truncated
    ? `${body}\n\n(Showing the ${messages.length} most recent messages. Raise 'limit' to see more.)`
    : `${body}\n\n(End of session - ${messages.length} messages.)`
}

export default {
  id: "selfmade.handoff",
  async setup(ctx: any) {
    const commands = await ctx.command.transform((editor: any) => {
      editor.add({
        name: "handoff",
        description: "Create a focused handoff prompt for a new session",
        execute: async (invocation: any) => {
          const argument = String(invocation.prompt?.text ?? "").trim()
          await ctx.session.prompt({
            sessionID: invocation.sessionID,
            text: HANDOFF_COMMAND.replace("$ARGUMENTS", argument),
            delivery: invocation.delivery,
          })
        },
      })
    })

    const tools = await ctx.tool.transform((editor: any) => {
      editor.add({
        name: "handoff_session",
        description:
          "Create a new session carrying the handoff prompt as context. Call this immediately after generating a handoff message.",
        options: { codemode: false },
        input: {
          type: "object",
          properties: {
            prompt: { type: "string", description: "The generated handoff prompt" },
            title: { type: "string", description: "Short title for the new session" },
            files: {
              type: "array",
              items: { type: "string" },
              description: "Paths the next session should read first",
            },
          },
          required: ["prompt"],
          additionalProperties: false,
        },
        execute: async (input: Record<string, unknown>, context: any): Promise<ToolResult> => {
          const files = normalizeFiles(input.files)
          const title =
            typeof input.title === "string" && input.title.trim().length > 0
              ? input.title.trim()
              : "Handoff"

          const sections = [
            `Continuing work from session ${context.sessionID}. Call read_session with that ID when this summary is missing something.`,
          ]
          if (files.length > 0) {
            sections.push(
              `Read these files first:\n${files.map((file) => `- ${file}`).join("\n")}`,
            )
          }
          sections.push(String(input.prompt ?? "").trim())

          const source = await ctx.session.get({ sessionID: context.sessionID })
          const session = await ctx.session.create({
            title,
            location: source?.location?.directory
              ? { directory: source.location.directory }
              : undefined,
            metadata: { handoff: true, handoffSource: context.sessionID },
          })

          await ctx.session.synthetic({
            sessionID: session.id,
            text: sections.join("\n\n"),
            description: "Handoff context",
          })

          return {
            content: [
              `Created session ${session.id} ("${title}") with the handoff as context.`,
              "The CLI switches to it automatically. Send any message there to start the work.",
            ].join("\n"),
          }
        },
      })

      editor.add({
        name: "read_session",
        description:
          "Read the conversation transcript of a previous session. Use it when the handoff summary is missing something.",
        options: { codemode: false },
        input: {
          type: "object",
          properties: {
            sessionID: { type: "string", description: "Full session ID, for example ses_01jxyz..." },
            limit: {
              type: "integer",
              minimum: 1,
              maximum: MAX_TRANSCRIPT_MESSAGES,
              description: `Most recent messages to read (default ${DEFAULT_TRANSCRIPT_MESSAGES})`,
            },
          },
          required: ["sessionID"],
          additionalProperties: false,
        },
        execute: async (input: Record<string, unknown>): Promise<ToolResult> => {
          const sessionID = String(input.sessionID ?? "")
          const requested = typeof input.limit === "number" ? input.limit : DEFAULT_TRANSCRIPT_MESSAGES
          const limit = Math.min(Math.max(Math.trunc(requested), 1), MAX_TRANSCRIPT_MESSAGES)

          try {
            const messages = await ctx.session.context({ sessionID })
            if (!Array.isArray(messages) || messages.length === 0) {
              return { content: "Session has no messages or does not exist." }
            }
            const truncated = messages.length > limit
            return { content: formatTranscript(messages.slice(-limit), truncated) }
          } catch (error) {
            return {
              content: `Could not read session ${sessionID}: ${
                error instanceof Error ? error.message : "unknown error"
              }`,
            }
          }
        },
      })
    })

    return async () => {
      await tools.dispose()
      await commands.dispose()
    }
  },
}
