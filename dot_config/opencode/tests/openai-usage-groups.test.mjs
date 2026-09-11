import assert from "node:assert/strict"
import { readFile, mkdtemp, writeFile, rm } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { test } from "node:test"
import { patchUsageSource, loadUsagePlugin } from "../lib/openai-usage-groups.mjs"

const entryUrl = import.meta.resolve("@a-r-m-i-n/opencode-openai-usage")
const entry = await readFile(new URL(entryUrl), "utf8")
const chunk = entry.match(/from "(\.\/chunk-[^"]+\.js)";/)[1]
const source = await readFile(new URL(chunk, entryUrl), "utf8")
const patched = patchUsageSource(source, "shared")
const usage = await import(`data:text/javascript;base64,${Buffer.from(patched).toString("base64")}`)
const window = (seconds, used = 0) => ({ limit_window_seconds: seconds, used_percent: used, reset_at: 1900000000 })

test("additional quotas retain their identity through fetch, cache, summary and failures", async () => {
  const dir = await mkdtemp(join(tmpdir(), "openai-usage-test-"))
  const originalFetch = globalThis.fetch
  let payload = { rate_limit: { primary_window: window(604800, 9), secondary_window: null } }
  globalThis.fetch = async () => Response.json(payload)
  try {
    await writeFile(join(dir, "auth.json"), JSON.stringify({ openai: { type: "oauth", access: "test-only" } }))
    const general = await usage.buildUsageState(dir)
    assert.equal(general.primary.windowDurationMins, 10080)
    assert.equal(general.secondary, null)
    assert.deepEqual(general.additional, [])
    payload.additional_rate_limits = [
      { limit_name: "GPT-5.3-Codex-Spark", rate_limit: { primary_window: window(18000), secondary_window: window(604800) } },
      { limit_name: "gpt-reserve", rate_limit: { primary_window: window(604800) } },
      null, { limit_name: "broken", rate_limit: { primary_window: {} } },
    ]
    const grouped = await usage.buildUsageState(dir)
    assert.equal(grouped.additional.length, 2)
    assert.equal(grouped.additional[0].primary.windowDurationMins, 300)
    assert.equal(grouped.additional[0].secondary.windowDurationMins, 10080)
    assert.equal(grouped.secondary, null)
    await usage.writeUsageState(dir, grouped)
    assert.deepEqual(await usage.readUsageState(dir), grouped)
    const summary = usage.formatCommandSummary(grouped, "test", "0.1.5", "https://example.com")
    assert.match(summary, /General quota[\s\S]*7d:[\s\S]*GPT-5.3-Codex-Spark[\s\S]*5h:[\s\S]*7d:[\s\S]*gpt-reserve/)
    assert.equal(summary.slice(0, summary.indexOf("GPT-5.3-Codex-Spark")).includes("5h:"), false)
    assert.deepEqual(usage.buildFailureState(grouped, new Error("offline")).additional, grouped.additional)
    await usage.writeUsageState(dir, { ...general, additional: undefined })
    assert.deepEqual((await usage.readUsageState(dir)).additional, [])
    payload = { rate_limit: { primary_window: window(18000), secondary_window: window(604800) } }
    const both = await usage.buildUsageState(dir)
    assert.equal(both.primary.windowDurationMins, 300)
    assert.equal(both.secondary.windowDurationMins, 10080)
    assert.deepEqual(both.additional, [])
    await writeFile(join(dir, "auth.json"), "{}")
    assert.equal((await usage.buildUsageState(dir)).configured, false)
    assert.deepEqual((await usage.buildUsageState(dir)).additional, [])
  } finally {
    globalThis.fetch = originalFetch
    await rm(dir, { recursive: true, force: true })
  }
})

test("upstream drift fails explicitly and server loads without modifying dependencies", async () => {
  assert.throws(() => patchUsageSource("changed upstream", "shared"), /no longer matches/)
  assert.throws(() => patchUsageSource(source + source, "shared"), /no longer matches/)
  assert.equal(typeof (await loadUsagePlugin("server")).default.server, "function")
})

test("sidebar renders general and additional quota groups separately", async () => {
  const tuiSource = await readFile(new URL(import.meta.resolve("@a-r-m-i-n/opencode-openai-usage/tui")), "utf8")
  const tui = patchUsageSource(tuiSource, "tui")
  const start = tui.indexOf("    const renderSidebarBody = () => {")
  const end = tui.indexOf("    const renderSidebarContent =", start)
  const render = new Function("state", "renderSidebarWindow", "_$createElement", "_$setProp", "_$insert", "_$insertNode", "_$createTextNode", `${tui.slice(start, end)}; return renderSidebarBody();`)
  const create = (type) => ({ type, children: [] })
  const insert = (node, value) => { node.children.push(typeof value === "function" ? value() : value) }
  const draw = (state) => JSON.stringify(render(() => state, (w) => w ? `${w.windowDurationMins / 60}h` : null, create, (n, k, v) => { n[k] = v }, insert, insert, (text) => text))
  const state = { primary: { windowDurationMins: 10080 }, secondary: null, additional: [{ name: "Spark", primary: { windowDurationMins: 300 }, secondary: { windowDurationMins: 10080 } }] }
  assert.match(draw(state), /General quota.*168h.*Spark.*5h.*168h/)
  assert.match(draw({ ...state, error: "offline" }), /stale/)
  assert.doesNotMatch(draw({ ...state, additional: [] }), /Spark|5h/)
  assert.match(draw({ primary: null, secondary: null }), /waiting for usage data/)
  assert.match(draw({ error: "offline" }), /unavailable/)
})
