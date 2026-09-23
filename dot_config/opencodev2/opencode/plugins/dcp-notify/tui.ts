// Shows a toast when DCP compresses the context.
//
// DCP 3.2.0 declares `pruneNotificationType` and `compress.showCompression`,
// but its V2 lane routes both the chat and the toast path through
// `lib/v2/index.ts report()`, which only writes a debug log ("V2 report
// (display pending)"). Nothing reaches the UI, so compression looks like it
// never happens. This plugin rebuilds the notification from the events the
// `compress` tool already emits, without touching DCP itself.
//
// Remove this whole directory once DCP implements V2 notification display.

const COMPRESS_TOOL = "compress"
const MAX_TRACKED_CALLS = 32
const MESSAGE_LIMIT = 240

interface Pending {
  topic?: string
}

function collapse(text: string): string {
  return text.replace(/\s+/g, " ").trim()
}

function truncate(text: string): string {
  return text.length > MESSAGE_LIMIT ? `${text.slice(0, MESSAGE_LIMIT - 1)}\u2026` : text
}

function resultText(content: unknown): string {
  if (!Array.isArray(content)) return ""
  return collapse(
    content
      .filter((part: any) => part?.type === "text" && typeof part.text === "string")
      .map((part: any) => part.text)
      .join(" "),
  )
}

export default {
  id: "selfmade.dcp-notify.cli",
  setup(ctx: any) {
    const pending = new Map<string, Pending>()

    const track = (id: unknown) => {
      if (typeof id !== "string") return
      if (pending.size >= MAX_TRACKED_CALLS) {
        const oldest = pending.keys().next()
        if (!oldest.done) pending.delete(oldest.value)
      }
      pending.set(id, {})
    }

    const take = (id: unknown): Pending | undefined => {
      if (typeof id !== "string") return undefined
      const entry = pending.get(id)
      if (entry) pending.delete(id)
      return entry
    }

    const stopStarted = ctx.data.on("session.tool.input.started", (event: any) => {
      if (event?.data?.name !== COMPRESS_TOOL) return
      track(event.data.id)
    })

    const stopCalled = ctx.data.on("session.tool.called", (event: any) => {
      const entry = typeof event?.data?.id === "string" ? pending.get(event.data.id) : undefined
      if (!entry) return
      const topic = event.data.input?.topic
      if (typeof topic === "string" && topic.trim().length > 0) entry.topic = topic.trim()
    })

    const stopSuccess = ctx.data.on("session.tool.success", (event: any) => {
      const entry = take(event?.data?.id)
      if (!entry) return

      const lines = []
      if (entry.topic) lines.push(`\u2192 Topic: ${entry.topic}`)
      const result = resultText(event.data.content)
      if (result) lines.push(`\u2192 ${result}`)

      ctx.ui.toast.show({
        title: "DCP: context compressed",
        message: truncate(lines.join("\n")) || "Compression finished.",
        variant: "info",
        duration: 6000,
      })
    })

    const stopFailed = ctx.data.on("session.tool.failed", (event: any) => {
      const entry = take(event?.data?.id)
      if (!entry) return

      ctx.ui.toast.show({
        title: "DCP: compression failed",
        message: truncate(collapse(String(event.data.error?.message ?? "compress tool failed"))),
        variant: "error",
        duration: 6000,
      })
    })

    return () => {
      stopStarted()
      stopCalled()
      stopSuccess()
      stopFailed()
      pending.clear()
    }
  },
}
