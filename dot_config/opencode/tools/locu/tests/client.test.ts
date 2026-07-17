import { expect, test } from "bun:test"
import { createLocuClient, createLocuUrl, LocuApiError } from "../client"

test("createLocuUrl serializes defined query values", () => {
  const url = createLocuUrl("/sessions", {
    includeActivities: true,
    limit: 50,
    cursor: undefined,
  })

  expect(url.toString()).toBe("https://api.locu.app/api/v1/sessions?includeActivities=true&limit=50")
})

test("listSessions sends bearer authentication and validates the page", async () => {
  let callCount = 0
  const fetchFn = async (input: RequestInfo | URL, init?: RequestInit) => {
    callCount += 1
    expect(String(input)).toBe(callCount === 1
      ? "https://api.locu.app/api/v1/sessions?includeActivities=true"
      : "https://api.locu.app/api/v1/sessions?includeActivities=true&cursor=next-page")
    expect(init?.headers).toEqual({ Authorization: "Bearer test-token" })
    return Response.json(callCount === 1
      ? {
          data: [{
            id: "session-1",
            isManual: false,
            createdAt: "2026-07-14T01:00:00.000Z",
            finishedAt: "2026-07-14T02:00:00.000Z",
            activities: [],
          }],
          nextCursor: "next-page",
          hasMore: true,
        }
      : {
          data: [{
            id: "session-2",
            isManual: true,
            createdAt: "2026-07-14T03:00:00.000Z",
            finishedAt: "2026-07-14T04:00:00.000Z",
            activities: [],
          }],
          nextCursor: null,
          hasMore: false,
        })
  }
  const client = createLocuClient({ fetchFn: fetchFn as typeof fetch, token: "test-token" })

  const result = await client.listAllSessions({ includeActivities: true })

  expect(result.data.map((session) => session.id)).toEqual(["session-1", "session-2"])
})

test("listAllTasks follows pagination cursors and validates tasks", async () => {
  let callCount = 0
  const fetchFn = async (input: RequestInfo | URL) => {
    callCount += 1
    expect(String(input)).toBe(callCount === 1
      ? "https://api.locu.app/api/v1/tasks?includePlainText=true"
      : "https://api.locu.app/api/v1/tasks?includePlainText=true&cursor=next-task-page")

    return Response.json(callCount === 1
      ? {
          data: [{ id: "task-1", name: "First task", type: "locu", done: null }],
          nextCursor: "next-task-page",
          hasMore: true,
        }
      : {
          data: [{ id: "task-2", name: "Second task", type: "linear", done: "completed" }],
          nextCursor: null,
          hasMore: false,
        })
  }
  const client = createLocuClient({ fetchFn: fetchFn as typeof fetch, token: "test-token" })

  const result = await client.listAllTasks({ includePlainText: true })

  expect(result.data.map((task) => task.id)).toEqual(["task-1", "task-2"])
  expect(callCount).toBe(2)
})

test("listTasks rejects task payloads without required worklog fields", async () => {
  const fetchFn = async () => Response.json({
    data: [{ id: "task-without-name" }],
    nextCursor: null,
    hasMore: false,
  })
  const client = createLocuClient({ fetchFn: fetchFn as typeof fetch, token: "test-token" })

  expect(client.listTasks()).rejects.toThrow("Locu returned an invalid task response.")
})

test("listTasks rejects legacy boolean completion values", async () => {
  const fetchFn = async () => Response.json({
    data: [{ id: "task-1", name: "First task", type: "locu", done: false }],
    nextCursor: null,
    hasMore: false,
  })
  const client = createLocuClient({ fetchFn: fetchFn as typeof fetch, token: "test-token" })

  expect(client.listTasks()).rejects.toThrow("Locu returned an invalid task response.")
})

test("listSessions rejects session payloads without required worklog fields", async () => {
  const fetchFn = async () => Response.json({
    data: [{ id: "session-without-times" }],
    nextCursor: null,
    hasMore: false,
  })
  const client = createLocuClient({ fetchFn: fetchFn as typeof fetch, token: "test-token" })

  expect(client.listSessions({ includeActivities: true })).rejects.toThrow(
    "Locu returned an invalid session response.",
  )
})

test("getTimer returns a safe API error without exposing the bearer token", async () => {
  const fetchFn = async () => Response.json({ message: "Token rejected" }, { status: 401 })
  const client = createLocuClient({ fetchFn: fetchFn as typeof fetch, token: "secret-token" })

  try {
    await client.getTimer()
    throw new Error("Expected getTimer to reject")
  } catch (error) {
    expect(error).toBeInstanceOf(LocuApiError)
    expect((error as LocuApiError).status).toBe(401)
    expect((error as Error).message).toBe("Token rejected")
    expect((error as Error).message).not.toContain("secret-token")
  }
})
