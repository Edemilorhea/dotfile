import { homedir } from "node:os"
import { join } from "node:path"
import { loadUsagePlugin } from "../lib/openai-usage-groups.mjs"

export const id = "openai-usage-tui-windows"

export default {
  id,
  tui: async (...args: unknown[]) => {
    const originalDataHome = process.env.XDG_DATA_HOME

    if (process.platform === "win32" && !originalDataHome) {
      process.env.XDG_DATA_HOME = join(homedir(), ".local", "share")
    }

    try {
      const plugin = await loadUsagePlugin("tui")
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
