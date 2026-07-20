import type { Plugin } from "@opencode-ai/plugin"
import { existsSync, readFileSync, realpathSync } from "node:fs"
import {
  dirname,
  extname,
  isAbsolute,
  join,
  relative,
  resolve,
  sep,
} from "node:path"

export type FormatterName = "prettier" | "biome" | "dprint"

export interface FormatterSelection {
  formatter: FormatterName
  cwd: string
}

interface FormatterPolicy {
  formatter: FormatterName
  extensions?: string[]
}

interface ToolAfterInput {
  tool: string
  args: Record<string, unknown>
}

export type FormatterRunner = (
  selection: FormatterSelection,
  filePath: string,
) => Promise<void>

const EDIT_TOOLS = new Set(["edit", "write", "apply_patch"])

export const DEFAULT_EXTENSIONS = [
  ".cjs",
  ".cs",
  ".css",
  ".html",
  ".js",
  ".json",
  ".jsx",
  ".md",
  ".mjs",
  ".scss",
  ".toml",
  ".ts",
  ".tsx",
  ".yaml",
  ".yml",
] as const

const CONFIG_FILES: Record<FormatterName, readonly string[]> = {
  prettier: [
    ".prettierrc",
    ".prettierrc.json",
    ".prettierrc.yaml",
    ".prettierrc.yml",
    ".prettierrc.js",
    ".prettierrc.cjs",
    ".prettierrc.mjs",
    ".prettierrc.ts",
    "prettier.config.js",
    "prettier.config.cjs",
    "prettier.config.mjs",
    "prettier.config.ts",
  ],
  biome: ["biome.json", "biome.jsonc"],
  dprint: ["dprint.json", "dprint.jsonc"],
}

const PACKAGE_NAMES: Record<FormatterName, readonly string[]> = {
  prettier: ["prettier"],
  biome: ["@biomejs/biome"],
  dprint: ["dprint"],
}

function normalizeExtensions(extensions: readonly string[]): Set<string> {
  return new Set(
    extensions.map((extension) => {
      const normalized = extension.trim().toLowerCase()
      return normalized.startsWith(".") ? normalized : `.${normalized}`
    }),
  )
}

function ancestorDirectories(start: string, boundary: string): string[] {
  const normalizedStart = resolve(start)
  const normalizedBoundary = resolve(boundary)
  const relativePath = relative(normalizedBoundary, normalizedStart)

  if (
    relativePath === ".." ||
    relativePath.startsWith(`..${sep}`) ||
    isAbsolute(relativePath)
  ) {
    throw new Error(
      `Mandatory formatter refused a file outside the project directory: ${normalizedStart}`,
    )
  }

  const directories: string[] = []
  let current = normalizedStart

  while (true) {
    directories.push(current)
    if (relative(normalizedBoundary, current) === "") break

    const parent = dirname(current)
    if (parent === current) {
      throw new Error(`Failed to reach project boundary: ${normalizedBoundary}`)
    }
    current = parent
  }

  return directories
}

function readPolicy(directory: string): FormatterPolicy | undefined {
  const policyPath = join(directory, ".opencode", "mandatory-format.json")
  if (!existsSync(policyPath)) return undefined

  const policy = JSON.parse(readFileSync(policyPath, "utf8")) as FormatterPolicy
  if (!(["prettier", "biome", "dprint"] as const).includes(policy.formatter)) {
    throw new Error(`Invalid formatter in ${policyPath}`)
  }

  if (
    policy.extensions !== undefined &&
    (!Array.isArray(policy.extensions) ||
      policy.extensions.some((extension) => typeof extension !== "string"))
  ) {
    throw new Error(`Invalid extensions in ${policyPath}`)
  }

  return policy
}

function packageDependencies(directory: string): Set<string> {
  const packagePath = join(directory, "package.json")
  if (!existsSync(packagePath)) return new Set()

  const packageJson = JSON.parse(readFileSync(packagePath, "utf8")) as Record<
    string,
    unknown
  >
  const dependencyFields = [
    "dependencies",
    "devDependencies",
    "optionalDependencies",
    "peerDependencies",
  ]
  const dependencies = new Set<string>()

  for (const field of dependencyFields) {
    const values = packageJson[field]
    if (!values || typeof values !== "object" || Array.isArray(values)) continue
    for (const dependency of Object.keys(values)) dependencies.add(dependency)
  }

  return dependencies
}

function detectFormatters(directory: string): FormatterName[] {
  const dependencies = packageDependencies(directory)

  return (["prettier", "biome", "dprint"] as const).filter((formatter) => {
    const hasConfig = CONFIG_FILES[formatter].some((name) =>
      existsSync(join(directory, name)),
    )
    const hasDependency = PACKAGE_NAMES[formatter].some((name) =>
      dependencies.has(name),
    )
    return hasConfig || hasDependency
  })
}

function findPolicy(
  directories: readonly string[],
): (FormatterSelection & { extensions?: string[] }) | undefined {
  for (const directory of directories) {
    const policy = readPolicy(directory)
    if (policy) return { ...policy, cwd: directory }
  }

  return undefined
}

function resolveDetectedFormatter(
  directories: readonly string[],
  filePath: string,
): FormatterSelection {
  for (const directory of directories) {
    const detected = detectFormatters(directory)
    if (detected.length === 1) return { formatter: detected[0], cwd: directory }
    if (detected.length > 1) {
      throw new Error(
        `Multiple formatters detected in ${directory}: ${detected.join(", ")}. ` +
          "Create .opencode/mandatory-format.json to select one.",
      )
    }
  }

  throw new Error(
    `No Prettier, Biome, or dprint configuration was found for ${filePath}`,
  )
}

export function collectModifiedFiles(
  tool: string,
  args: Record<string, unknown>,
): string[] {
  if (!EDIT_TOOLS.has(tool)) return []

  const files = new Set<string>()
  const directPath = args.filePath ?? args.path
  if (typeof directPath === "string" && directPath.trim()) {
    files.add(directPath.trim())
  }

  if (tool === "apply_patch" && typeof args.patchText === "string") {
    const pathPattern = /^\*\*\* (?:Add File|Update File|Move to): (.+)$/gm
    for (const match of args.patchText.matchAll(pathPattern)) {
      files.add(match[1].trim())
    }
  }

  return [...files]
}

export function shouldFormatFile(
  filePath: string,
  extensions: readonly string[] = DEFAULT_EXTENSIONS,
): boolean {
  return normalizeExtensions(extensions).has(extname(filePath).toLowerCase())
}

export function resolveFormatter(
  filePath: string,
  projectDirectory: string,
): FormatterSelection & { extensions?: string[] } {
  const directories = ancestorDirectories(dirname(resolve(filePath)), projectDirectory)
  return findPolicy(directories) ?? resolveDetectedFormatter(directories, filePath)
}

export function createFormatAfterHook(
  projectDirectory: string,
  runFormatter: FormatterRunner,
): (input: ToolAfterInput) => Promise<void> {
  return async (input) => {
    const modifiedFiles = collectModifiedFiles(input.tool, input.args)
    const canonicalProjectDirectory = realpathSync.native(projectDirectory)
    const seen = new Set<string>()

    for (const modifiedFile of modifiedFiles) {
      const filePath = isAbsolute(modifiedFile)
        ? resolve(modifiedFile)
        : resolve(projectDirectory, modifiedFile)
      if (!existsSync(filePath)) continue

      const canonicalFilePath = realpathSync.native(filePath)
      const relativePath = relative(canonicalProjectDirectory, canonicalFilePath)
      if (
        relativePath === ".." ||
        relativePath.startsWith(`..${sep}`) ||
        isAbsolute(relativePath)
      ) {
        throw new Error(
          `Mandatory formatter refused a file outside the project directory: ${canonicalFilePath}`,
        )
      }

      const deduplicationKey =
        process.platform === "win32" ? canonicalFilePath.toLowerCase() : canonicalFilePath
      if (seen.has(deduplicationKey)) continue
      seen.add(deduplicationKey)

      const directories = ancestorDirectories(
        dirname(canonicalFilePath),
        canonicalProjectDirectory,
      )
      const policy = findPolicy(directories)
      if (!policy && !shouldFormatFile(canonicalFilePath)) continue

      const selection =
        policy ?? resolveDetectedFormatter(directories, canonicalFilePath)
      if (!shouldFormatFile(filePath, selection.extensions)) continue
      await runFormatter(selection, canonicalFilePath)
    }
  }
}

export const MandatoryFormat: Plugin = async ({ directory, $ }) => {
  const runFormatter: FormatterRunner = async (selection, filePath) => {
    try {
      if (selection.formatter === "prettier") {
        await $`npx --no-install prettier --write ${filePath}`.cwd(selection.cwd)
      } else if (selection.formatter === "biome") {
        await $`npx --no-install biome format --write ${filePath}`.cwd(selection.cwd)
      } else {
        await $`npx --no-install dprint fmt ${filePath}`.cwd(selection.cwd)
      }
    } catch (error) {
      const cause = error instanceof Error ? error.message : String(error)
      throw new Error(
        `Mandatory ${selection.formatter} formatting failed for ${filePath}: ${cause}`,
      )
    }
  }

  return {
    "tool.execute.after": createFormatAfterHook(directory, runFormatter),
  }
}
