import { join } from "node:path"
import { createLocuClient, type LocuClient } from "./core/client"
import { resolveLocuToken } from "./core/config"

// V2 port of the retired v1 custom tool (tools/locu.ts). V2 removed file-based
// custom tools, so the same three tools are registered through the plugin tool
// registry instead. `core/` holds the client, config, and their tests.
//
// The default export is a plain object rather than `Plugin.define(...)` because
// OpenCode does not resolve `@opencode/plugin` for a local plugin directory and
// `define` is only `(plugin) => plugin`. OpenCode validates the exported shape,
// so this keeps the plugin free of any installed dependency.
//
// Two v1 tool-context fields have no v2 equivalent:
//   context.directory -> ctx.location.directory, resolved once during setup
//   context.abort     -> a plugin-lifetime AbortController, aborted on unload
// The client keeps its own 10s per-request timeout either way.

const MAX_LIMIT = 100

const LIMIT_PROPERTY = {
  type: "integer",
  minimum: 1,
  maximum: MAX_LIMIT,
} as const

interface ToolResult {
  content: string
}

export default {
  id: "selfmade.locu",
  async setup(ctx: any) {
    const lifetime = new AbortController()
    const directory: string = ctx.location.directory

    const client = async (): Promise<LocuClient> =>
      createLocuClient({
        signal: lifetime.signal,
        token: await resolveLocuToken({ searchPaths: [join(directory, ".env")] }),
      })

    const read = async (operation: (locu: LocuClient) => Promise<unknown>): Promise<ToolResult> => {
      try {
        return { content: JSON.stringify(await operation(await client()), null, 2) }
      } catch (error) {
        return { content: `Error: ${error instanceof Error ? error.message : "Locu request failed."}` }
      }
    }

    const registration = await ctx.tool.transform((editor: any) => {
      editor.namespace({
        name: "locu",
        description: "Read-only access to Locu tasks, work sessions, and the running timer.",
      })

      editor.add({
        name: "tasks",
        description:
          "List all matching Locu tasks. Read-only; requires LOCU_PAT in the environment or a .env file.",
        options: { namespace: "locu" },
        input: {
          type: "object",
          properties: {
            done: { type: "boolean", description: "Filter by completion state" },
            limit: { ...LIMIT_PROPERTY, description: "Tasks requested per API page" },
            projectId: { type: "string", description: "Optional Locu project ID" },
            section: {
              type: "string",
              enum: ["today", "sooner", "later"],
              description: "Optional task section",
            },
          },
          additionalProperties: false,
        },
        execute: (input: Record<string, unknown>) =>
          read((locu) => locu.listAllTasks({ ...input, includePlainText: true })),
      })

      editor.add({
        name: "sessions",
        description:
          "List Locu work sessions for an ISO 8601 range. Read-only; requires LOCU_PAT in the environment or a .env file.",
        options: { namespace: "locu" },
        input: {
          type: "object",
          properties: {
            startAfter: {
              type: "string",
              format: "date-time",
              description: "Inclusive worklog range start as ISO 8601 datetime",
            },
            startBefore: {
              type: "string",
              format: "date-time",
              description: "Exclusive worklog range end as ISO 8601 datetime",
            },
            limit: { ...LIMIT_PROPERTY, description: "Sessions requested per API page" },
            includeActivities: {
              type: "boolean",
              description: "Include task and meeting activities",
            },
          },
          required: ["startAfter", "startBefore"],
          additionalProperties: false,
        },
        execute: (input: Record<string, unknown>) =>
          read((locu) =>
            locu.listAllSessions({ ...input, includeActivities: input.includeActivities ?? true }),
          ),
      })

      editor.add({
        name: "timer",
        description:
          "Get current Locu timer status. Read-only; requires LOCU_PAT in the environment or a .env file.",
        options: { namespace: "locu" },
        input: { type: "object", properties: {}, additionalProperties: false },
        execute: () => read((locu) => locu.getTimer()),
      })
    })

    return async () => {
      lifetime.abort()
      await registration.dispose()
    }
  },
}
