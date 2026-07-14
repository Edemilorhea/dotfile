import { tool } from "@opencode-ai/plugin/tool"
import { createLocuClient } from "./client"
import { resolveLocuToken } from "./config"

const MAX_LIMIT = 100

export const tasks = tool({
  description: "List all matching Locu tasks. Read-only; requires LOCU_PAT in the environment or a .env file.",
  args: {
    done: tool.schema.boolean().optional().describe("Filter by completion state"),
    limit: tool.schema.number().int().min(1).max(MAX_LIMIT).optional().describe("Tasks requested per API page"),
    projectId: tool.schema.string().optional().describe("Optional Locu project ID"),
    section: tool.schema.enum(["today", "sooner", "later"]).optional().describe("Optional task section"),
  },
  async execute(args) {
    return executeRead(async () => (await client()).listAllTasks({ ...args, includePlainText: true }))
  },
})

export const sessions = tool({
  description: "List Locu work sessions for an ISO 8601 range. Read-only; requires LOCU_PAT in the environment or a .env file.",
  args: {
    startAfter: tool.schema.string().datetime().describe("Inclusive worklog range start as ISO 8601 datetime"),
    startBefore: tool.schema.string().datetime().describe("Exclusive worklog range end as ISO 8601 datetime"),
    limit: tool.schema.number().int().min(1).max(MAX_LIMIT).optional().describe("Sessions requested per API page"),
    includeActivities: tool.schema.boolean().optional().describe("Include task and meeting activities"),
  },
  async execute(args) {
    return executeRead(async () => (await client()).listAllSessions({
      ...args,
      includeActivities: args.includeActivities ?? true,
    }))
  },
})

export const timer = tool({
  description: "Get current Locu timer status. Read-only; requires LOCU_PAT in the environment or a .env file.",
  args: {},
  async execute() {
    return executeRead(async () => (await client()).getTimer())
  },
})

async function client() {
  return createLocuClient({ token: await resolveLocuToken() })
}

async function executeRead(operation: () => Promise<unknown>): Promise<string> {
  try {
    return JSON.stringify(await operation(), null, 2)
  } catch (error) {
    return `Error: ${error instanceof Error ? error.message : "Locu request failed."}`
  }
}
