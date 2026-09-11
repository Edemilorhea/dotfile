import { readFile } from "node:fs/promises"

const packageName = "@a-r-m-i-n/opencode-openai-usage"

// Keep the pinned upstream implementation; extend its data and rendering in memory.
export function patchUsageSource(source, kind) {
  const replace = (before, after) => {
    if (source.split(before).length !== 2) {
      throw new Error(`OpenAI usage ${kind} patch no longer matches upstream 0.1.5`)
    }
    source = source.replace(before, () => after)
  }
  if (kind === "shared") {
    replace("  primary: null,", "  additional: [],\n  primary: null,")
    replace("    primary: normalizeWindow(rateLimits.primary", "    additional: normalizeAdditional(data.additional_rate_limits),\n    primary: normalizeWindow(rateLimits.primary")
    replace("    primary: normalizeStoredWindow(input.primary),", "    additional: normalizeAdditional(input.additional, true),\n    primary: normalizeStoredWindow(input.primary),")
    replace('  hasUsageDetails = appendWindowLines(lines, "Primary", state.primary)', '  lines.push("General quota");\n  hasUsageDetails = appendWindowLines(lines, "Primary", state.primary)')
    replace("  if (state.rateLimitReachedType) {", `  for (const group of state.additional ?? []) {
    lines.push("", group.name);
    hasUsageDetails = appendWindowLines(lines, "Primary", group.primary) || hasUsageDetails;
    hasUsageDetails = appendWindowLines(lines, "Secondary", group.secondary) || hasUsageDetails;
  }
  if (state.rateLimitReachedType) {`)
    source += `
function normalizeAdditional(value, stored = false) {
  if (!Array.isArray(value)) return [];
  return value.flatMap((item) => {
    if (!isRecord(item)) return [];
    const rawName = stored ? item.name : item.limit_name ?? item.metered_feature;
    if (typeof rawName !== "string" || !rawName.trim()) return [];
    const limits = stored ? item : item.rate_limit;
    if (!isRecord(limits)) return [];
    const readWindow = (window) => {
      if (window == null) return null;
      try { return stored ? normalizeStoredWindow(window) : normalizeWindow(window, "additional"); }
      catch { return null; }
    };
    const primary = readWindow(limits.primary ?? limits.primary_window);
    const secondary = readWindow(limits.secondary ?? limits.secondary_window);
    if (!primary && !secondary) return [];
    return [{ name: rawName.replace(/[\\x00-\\x1f\\x7f-\\x9f]/g, " ").trim().slice(0, 100), primary, secondary }];
  });
}
`
  } else if (kind === "tui") {
    replace("      if (currentState.error && !currentState.primary && !currentState.secondary) {", "      if (currentState.error && !currentState.primary && !currentState.secondary && !currentState.additional?.length) {")
    replace("      if (!currentState.primary && !currentState.secondary) {", "      if (!currentState.primary && !currentState.secondary && !currentState.additional?.length) {")
    replace("        _$insert(_el$14, () => renderSidebarWindow(currentState.primary), null);", `        const heading = (label) => {
          const text = _$createElement("text");
          _$insert(text, label);
          return text;
        };
        _$insert(_el$14, () => currentState.error ? heading("Status: stale (refresh failed)") : null, null);
        _$insert(_el$14, heading("General quota"), null);
        _$insert(_el$14, () => renderSidebarWindow(currentState.primary), null);`)
    replace("        _$insert(_el$14, () => renderSidebarWindow(currentState.secondary), null);", `        _$insert(_el$14, () => renderSidebarWindow(currentState.secondary), null);
        _$insert(_el$14, () => (currentState.additional ?? []).map((group) => {
          const box = _$createElement("box");
          _$setProp(box, "flexDirection", "column");
          _$insert(box, heading(group.name), null);
          _$insert(box, renderSidebarWindow(group.primary), null);
          _$insert(box, renderSidebarWindow(group.secondary), null);
          return box;
        }), null);`)
  } else {
    throw new Error(`Unknown OpenAI usage patch kind: ${kind}`)
  }
  return source
}

export async function loadUsagePlugin(entry) {
  if (entry !== "server" && entry !== "tui") throw new Error("Unknown usage entry")
  const entryUrl = import.meta.resolve(packageName + (entry === "tui" ? "/tui" : ""))
  const manifest = JSON.parse(await readFile(new URL("../package.json", entryUrl), "utf8"))
  if (manifest.version !== "0.1.5") throw new Error("OpenAI usage groups require upstream 0.1.5")
  let source = await readFile(new URL(entryUrl), "utf8")
  const chunk = source.match(/from "(\.\/chunk-[^"]+\.js)";/)?.[1]
  if (!chunk) throw new Error("OpenAI usage shared module not found")
  const shared = patchUsageSource(await readFile(new URL(chunk, entryUrl), "utf8"), "shared")
  const dataUrl = (code) => `data:text/javascript;base64,${Buffer.from(code).toString("base64")}`
  const sharedUrl = dataUrl(shared)
  const runtimeImports = new Map()
  if (entry === "tui") {
    source = patchUsageSource(source, "tui")
    const { runtimeModuleIdForSpecifier } = await import("@opentui/core/runtime-plugin")
    for (const specifier of ["@opentui/core", "@opentui/solid", "solid-js", "solid-js/store"]) {
      runtimeImports.set(specifier, runtimeModuleIdForSpecifier(specifier))
    }
  }
  // Data URLs bypass host source rewriting. Use host runtime IDs for TUI singletons.
  // Resolve other imports absolutely and retain upstream's manifest location.
  source = source.replaceAll("import.meta.url", JSON.stringify(entryUrl))
  source = source.replace(/from "([^"]+)"/g, (_, specifier) =>
    `from ${JSON.stringify(specifier === chunk ? sharedUrl : runtimeImports.get(specifier) ?? import.meta.resolve(specifier))}`)
  return import(dataUrl(source))
}
