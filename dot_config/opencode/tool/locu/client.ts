import {
  parseLocuSessionPage,
  parseLocuTaskPage,
  parseLocuTimer,
  type LocuPage,
  type LocuSession,
  type LocuTask,
  type LocuTimer,
} from "./types"

export const LOCU_API_BASE_URL = "https://api.locu.app/api/v1"

type QueryValue = boolean | number | string | undefined
type FetchFunction = typeof fetch

export interface LocuClient {
  listTasks(query?: Record<string, QueryValue>): Promise<LocuPage<LocuTask>>
  listAllTasks(query?: Record<string, QueryValue>, maxPages?: number): Promise<LocuPage<LocuTask>>
  listSessions(query?: Record<string, QueryValue>): Promise<LocuPage<LocuSession>>
  listAllSessions(query?: Record<string, QueryValue>, maxPages?: number): Promise<LocuPage<LocuSession>>
  getTimer(): Promise<LocuTimer>
}

export interface LocuClientOptions {
  fetchFn?: FetchFunction
  token: string
  timeoutMs?: number
}

export class LocuApiError extends Error {
  constructor(
    public readonly status: number,
    message: string,
  ) {
    super(message)
    this.name = "LocuApiError"
  }
}

export function createLocuClient(options: LocuClientOptions): LocuClient {
  const request = createRequest(options)

  return {
    listTasks: async (query = {}) => parseLocuTaskPage(await request("/tasks", query)),
    listAllTasks: async (query = {}, maxPages = 20) => collectPages(
      async (cursor) => parseLocuTaskPage(await request("/tasks", { ...query, cursor })),
      maxPages,
    ),
    listSessions: async (query = {}) => parseLocuSessionPage(await request("/sessions", query)),
    listAllSessions: async (query = {}, maxPages = 20) => collectPages(
      async (cursor) => parseLocuSessionPage(await request("/sessions", { ...query, cursor })),
      maxPages,
    ),
    getTimer: async () => parseLocuTimer(await request("/timer")),
  }
}

export function createLocuUrl(path: string, query: Record<string, QueryValue> = {}): URL {
  const url = new URL(`${LOCU_API_BASE_URL}${path}`)

  for (const [name, value] of Object.entries(query)) {
    if (value !== undefined) {
      url.searchParams.set(name, String(value))
    }
  }

  return url
}

export async function collectPages<T>(
  fetchPage: (cursor: string | undefined) => Promise<LocuPage<T>>,
  maxPages: number,
): Promise<LocuPage<T>> {
  if (!Number.isInteger(maxPages) || maxPages < 1) {
    throw new Error("maxPages must be a positive integer.")
  }

  const data: T[] = []
  const seenCursors = new Set<string>()
  let cursor: string | undefined

  for (let pageNumber = 0; pageNumber < maxPages; pageNumber += 1) {
    const page = await fetchPage(cursor)
    data.push(...page.data)

    if (!page.hasMore || page.nextCursor === null) {
      return { data, nextCursor: page.nextCursor, hasMore: false }
    }

    if (seenCursors.has(page.nextCursor)) {
      throw new Error("Locu returned a repeated pagination cursor.")
    }

    seenCursors.add(page.nextCursor)
    cursor = page.nextCursor
  }

  throw new Error(`Locu pagination exceeded the ${maxPages}-page safety limit.`)
}

function createRequest(options: LocuClientOptions) {
  const fetchFn = options.fetchFn ?? fetch
  const timeoutMs = options.timeoutMs ?? 10_000

  return async (path: string, query?: Record<string, QueryValue>): Promise<unknown> => {
    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), timeoutMs)

    try {
      const response = await fetchFn(createLocuUrl(path, query), {
        headers: { Authorization: `Bearer ${options.token}` },
        signal: controller.signal,
      })

      if (!response.ok) {
        throw new LocuApiError(response.status, await readErrorMessage(response))
      }

      return await response.json()
    } catch (error) {
      if (error instanceof LocuApiError) {
        throw error
      }

      const message = error instanceof Error && error.name === "AbortError"
        ? "Locu request timed out."
        : "Locu request failed."
      throw new Error(message)
    } finally {
      clearTimeout(timeout)
    }
  }
}

async function readErrorMessage(response: Response): Promise<string> {
  const fallback = `Locu API request failed with status ${response.status}.`

  try {
    const value: unknown = await response.json()
    if (isErrorEnvelope(value)) {
      return value.message
    }
  } catch {
    return fallback
  }

  return fallback
}

function isErrorEnvelope(value: unknown): value is { message: string } {
  return typeof value === "object"
    && value !== null
    && "message" in value
    && typeof value.message === "string"
}
