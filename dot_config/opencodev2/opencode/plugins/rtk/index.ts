import { execFile } from "node:child_process"
import { delimiter, dirname, join } from "node:path"
import { homedir } from "node:os"
import { accessSync, constants } from "node:fs"
import { promisify } from "node:util"

// Local V2 port of the RTK (Rust Token Killer) OpenCode integration.
//
// Upstream `rtk init --global --opencode` only emits a V1 plugin
// (`@opencode-ai/plugin` + the `$` Bun shell helper + a `tool.execute.before`
// hook object). V2 loads such a plugin with no id and it does nothing, so this
// file reimplements the same thin delegation against the V2 plugin API. All
// rewrite intelligence still lives in the `rtk rewrite` Rust binary; this only
// forwards the command and takes the result.
//
// Two deliberate differences from upstream:
//   1. `shell.create.before` is used instead of `tool.execute.before`, because
//      the V2 event exposes `command` and `env` directly instead of an opaque
//      tool input bag.
//   2. The rtk directory is injected into the per-shell PATH instead of the
//      user PATH, so a rewritten `rtk git status` can actually run while the
//      machine PATH stays untouched.
//
// REMOVAL — when upstream ships a real V2 plugin, undo exactly three things:
//   1. delete this directory (plugins are auto-discovered, so nothing in
//      opencode.json references it)
//   2. delete the "rtk (local V2 shim)" block in opencode.json permission.bash
//   3. delete ~/.local/bin/rtk.exe if the upstream package installs its own
// Nothing else on this machine knows about RTK.

const REWRITE_TIMEOUT_MS = 5_000

const execFileAsync = promisify(execFile)

const isWindows = process.platform === "win32"
const BIN_NAME = isWindows ? "rtk.exe" : "rtk"

// Preferred over PATH lookup: the binary is installed outside the user PATH on
// purpose, so removing RTK never requires an environment-variable edit.
const INSTALL_PATH = join(homedir(), ".local", "bin", BIN_NAME)

const isExecutable = (path: string): boolean => {
  try {
    accessSync(path, constants.X_OK)
    return true
  } catch {
    return false
  }
}

const resolveBinary = (): string | undefined => {
  const override = process.env.RTK_BIN
  if (override && isExecutable(override)) return override
  if (isExecutable(INSTALL_PATH)) return INSTALL_PATH
  return undefined
}

const pathKeyOf = (env: Record<string, string | undefined>): string =>
  Object.keys(env).find((key) => key.toLowerCase() === "path") ?? "PATH"

const withBinaryOnPath = (env: Record<string, string | undefined>, binary: string): void => {
  const directory = dirname(binary)
  const key = pathKeyOf(env)
  const current = env[key] ?? process.env.PATH ?? ""
  const present = current
    .split(delimiter)
    .some((entry) => entry.replace(/[\\/]+$/, "").toLowerCase() === directory.replace(/[\\/]+$/, "").toLowerCase())
  if (!present) env[key] = current ? `${directory}${delimiter}${current}` : directory
}

// `rtk rewrite` exits 3 when it rewrote the command and 1 when it passed it
// through, so the decision is made on stdout rather than on the exit code.
const rewrite = async (binary: string, command: string, cwd: string): Promise<string | undefined> => {
  try {
    const { stdout } = await execFileAsync(binary, ["rewrite", command], {
      cwd,
      timeout: REWRITE_TIMEOUT_MS,
      windowsHide: true,
      encoding: "utf8",
    })
    const rewritten = stdout.trim()
    return rewritten && rewritten !== command ? rewritten : undefined
  } catch (error: any) {
    const rewritten = typeof error?.stdout === "string" ? error.stdout.trim() : ""
    return rewritten && rewritten !== command ? rewritten : undefined
  }
}

export default {
  id: "selfmade.rtk",
  async setup(ctx: any) {
    const binary = resolveBinary()
    if (!binary) return

    const registration = await ctx.shell.hook("create.before", async (event: any) => {
      const command: string = event.command ?? ""
      if (!command.trim()) return
      if (process.env.RTK_DISABLED === "1") return
      if (/^\s*rtk(\.exe)?\s/i.test(command)) return

      const rewritten = await rewrite(binary, command, event.cwd)
      if (!rewritten) return

      event.command = rewritten
      withBinaryOnPath(event.env, binary)
    })

    return async () => {
      await registration.dispose()
    }
  },
}
