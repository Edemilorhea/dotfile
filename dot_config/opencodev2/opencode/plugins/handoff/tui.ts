// CLI half of the handoff plugin. The server half cannot move the user to the
// session it creates, so this listens for the `session.created` event that
// carries the `handoff` metadata flag set by the handoff_session tool and
// navigates there. It replaces the v1 `tui.executeCommand("session_new")` step.
//
// Kept dependency-free for the same reason as index.ts: a local plugin
// directory should not rely on `@opencode/plugin` resolving.

export default {
  id: "selfmade.handoff.cli",
  setup(ctx: any) {
    const here = (ctx.location ?? ctx.data.location.default())?.directory

    return ctx.data.on("session.created", (event: any) => {
      if (event?.data?.metadata?.handoff !== true) return

      const there = event.location?.directory ?? event.data?.location?.directory
      if (here && there && here !== there) return

      const sessionID = event.data.sessionID
      if (typeof sessionID !== "string") return

      ctx.ui.router.navigate({ type: "session", sessionID })
      ctx.ui.toast.show({
        title: "Handoff ready",
        message: "Review the handoff context, then send a message to start.",
        variant: "success",
        duration: 5000,
      })
    })
  },
}
