import { readFile } from "node:fs/promises"

export interface EnvLoaderConfig {
  searchPaths?: string[]
}

export async function resolveLocuToken(config: EnvLoaderConfig = {}): Promise<string> {
  const environmentToken = normalizeToken(process.env.LOCU_PAT)
  if (environmentToken) {
    return environmentToken
  }

  for (const path of config.searchPaths ?? []) {
    const content = await readOptionalFile(path)
    const fileToken = content === null ? null : parseEnvToken(content)
    if (fileToken) {
      return fileToken
    }
  }

  throw new Error("LOCU_PAT is not set. Add it to the environment or the project .env file.")
}

function parseEnvToken(content: string): string | null {
  for (const line of content.replace(/^\uFEFF/, "").split(/\r?\n/)) {
    const match = line.match(/^\s*(?:export\s+)?LOCU_PAT\s*=\s*(.*?)\s*$/)
    if (!match) {
      continue
    }

    return normalizeToken(unquote(match[1]))
  }

  return null
}

async function readOptionalFile(path: string): Promise<string | null> {
  try {
    return await readFile(path, "utf8")
  } catch (error) {
    if (isMissingFileError(error)) {
      return null
    }
    throw new Error(`Unable to read Locu environment file: ${path}`)
  }
}

function isMissingFileError(error: unknown): error is NodeJS.ErrnoException {
  return error instanceof Error && "code" in error && error.code === "ENOENT"
}

function normalizeToken(value: string | undefined | null): string | null {
  const token = value?.trim()
  return token ? token : null
}

function unquote(value: string): string {
  if (value.length >= 2) {
    const first = value[0]
    const last = value[value.length - 1]
    if ((first === '"' && last === '"') || (first === "'" && last === "'")) {
      return value.slice(1, -1)
    }
  }

  return value
}
