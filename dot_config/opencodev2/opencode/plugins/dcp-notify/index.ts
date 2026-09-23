// Server half of the DCP compression notifier. It registers nothing; it exists
// so the directory is discovered as a plugin package and its `tui.ts` half is
// loaded. See tui.ts for why the plugin is needed.
//
// Remove this whole directory once DCP displays its own V2 notifications.

export default {
  id: "selfmade.dcp-notify",
  setup() {},
}
