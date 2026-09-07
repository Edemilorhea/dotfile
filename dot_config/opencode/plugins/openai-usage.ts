import { homedir } from "node:os"
import { join } from "node:path"

export const id = "openai-usage-windows"

export default {
  id,
  server: async (...args: unknown[]) => {
    const originalDataHome = process.env.XDG_DATA_HOME

    if (process.platform === "win32" && !originalDataHome) {
      process.env.XDG_DATA_HOME = join(homedir(), ".local", "share")
    }

    try {
      const plugin = await import("@a-r-m-i-n/opencode-openai-usage")
      return await plugin.default.server(...args)
    } finally {
      if (originalDataHome === undefined) {
        delete process.env.XDG_DATA_HOME
      } else {
        process.env.XDG_DATA_HOME = originalDataHome
      }
    }
  },
}
