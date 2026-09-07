import { homedir } from "node:os"
import { join } from "node:path"

export const id = "openai-usage-tui-windows"

export default {
  id,
  tui: async (...args: unknown[]) => {
    const originalDataHome = process.env.XDG_DATA_HOME

    if (process.platform === "win32" && !originalDataHome) {
      process.env.XDG_DATA_HOME = join(homedir(), ".local", "share")
    }

    try {
      const plugin = await import("@a-r-m-i-n/opencode-openai-usage/tui")
      return await plugin.default.tui(...args)
    } finally {
      if (originalDataHome === undefined) {
        delete process.env.XDG_DATA_HOME
      } else {
        process.env.XDG_DATA_HOME = originalDataHome
      }
    }
  },
}
