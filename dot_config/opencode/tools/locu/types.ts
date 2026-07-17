export type JsonObject = Record<string, unknown>

export interface LocuPage<T = unknown> {
  data: T[]
  nextCursor: string | null
  hasMore: boolean
}

export interface LocuTask extends JsonObject {
  id: string
  name: string
  type: "jira" | "linear" | "locu"
  done: "completed" | "canceled" | null
}

export interface LocuSession extends JsonObject {
  id: string
  isManual: boolean
  createdAt: string
  finishedAt: string
  activities?: unknown[]
}

export interface LocuTimer {
  state: "IDLE" | "ACTIVE" | "PAUSED"
  duration?: number
  currentTaskId?: string
  startedAt?: string
}

export function isJsonObject(value: unknown): value is JsonObject {
  return typeof value === "object" && value !== null && !Array.isArray(value)
}

export function parseLocuPage(value: unknown): LocuPage {
  if (!isJsonObject(value) || !Array.isArray(value.data)) {
    throw new Error("Locu returned an invalid paginated response.")
  }

  if (value.nextCursor !== null && typeof value.nextCursor !== "string") {
    throw new Error("Locu returned an invalid pagination cursor.")
  }

  if (typeof value.hasMore !== "boolean") {
    throw new Error("Locu returned an invalid pagination flag.")
  }

  return {
    data: value.data,
    nextCursor: value.nextCursor,
    hasMore: value.hasMore,
  }
}

export function parseLocuTaskPage(value: unknown): LocuPage<LocuTask> {
  const page = parseLocuPage(value)

  if (!page.data.every(isLocuTask)) {
    throw new Error("Locu returned an invalid task response.")
  }

  return { ...page, data: page.data }
}

export function parseLocuSessionPage(value: unknown): LocuPage<LocuSession> {
  const page = parseLocuPage(value)

  if (!page.data.every(isLocuSession)) {
    throw new Error("Locu returned an invalid session response.")
  }

  return { ...page, data: page.data }
}

export function parseLocuTimer(value: unknown): LocuTimer {
  if (!isJsonObject(value) || !isTimerState(value.state)) {
    throw new Error("Locu returned an invalid timer response.")
  }

  return {
    state: value.state,
    duration: optionalNumber(value.duration),
    currentTaskId: optionalString(value.currentTaskId),
    startedAt: optionalString(value.startedAt),
  }
}

function isTimerState(value: unknown): value is LocuTimer["state"] {
  return value === "IDLE" || value === "ACTIVE" || value === "PAUSED"
}

function isLocuTask(value: unknown): value is LocuTask {
  return isJsonObject(value)
    && typeof value.id === "string"
    && typeof value.name === "string"
    && (value.type === "jira" || value.type === "linear" || value.type === "locu")
    && isTaskCompletionState(value.done)
}

function isTaskCompletionState(value: unknown): value is LocuTask["done"] {
  return value === "completed" || value === "canceled" || value === null
}

function isLocuSession(value: unknown): value is LocuSession {
  return isJsonObject(value)
    && typeof value.id === "string"
    && typeof value.isManual === "boolean"
    && typeof value.createdAt === "string"
    && typeof value.finishedAt === "string"
    && (value.activities === undefined || Array.isArray(value.activities))
}

function optionalNumber(value: unknown): number | undefined {
  return typeof value === "number" ? value : undefined
}

function optionalString(value: unknown): string | undefined {
  return typeof value === "string" ? value : undefined
}
