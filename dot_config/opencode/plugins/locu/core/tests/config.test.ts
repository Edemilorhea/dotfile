import { afterEach, expect, test } from "bun:test"
import { mkdtemp, rm, writeFile } from "fs/promises"
import { tmpdir } from "os"
import { join } from "path"

const originalToken = process.env.LOCU_PAT

afterEach(() => {
  if (originalToken === undefined) {
    delete process.env.LOCU_PAT
  } else {
    process.env.LOCU_PAT = originalToken
  }
})

test("resolveLocuToken loads LOCU_PAT from an explicitly configured .env file", async () => {
  const directory = await mkdtemp(join(tmpdir(), "locu-config-"))
  const envPath = join(directory, ".env")
  await writeFile(envPath, "LOCU_PAT=env-file-token\n", "utf8")
  delete process.env.LOCU_PAT

  try {
    const { resolveLocuToken } = await import("../config")

    await expect(resolveLocuToken({ searchPaths: [envPath] })).resolves.toBe("env-file-token")
  } finally {
    await rm(directory, { force: true, recursive: true })
  }
})

test("resolveLocuToken prefers the process environment without mutating it", async () => {
  process.env.LOCU_PAT = " environment-token "
  const { resolveLocuToken } = await import("../config")

  await expect(resolveLocuToken({ searchPaths: ["missing.env"] })).resolves.toBe("environment-token")
  expect(process.env.LOCU_PAT).toBe(" environment-token ")
})

test("resolveLocuToken supports quoted export syntax", async () => {
  const directory = await mkdtemp(join(tmpdir(), "locu-config-"))
  const envPath = join(directory, ".env")
  await writeFile(envPath, "export LOCU_PAT='quoted-token'\n", "utf8")
  delete process.env.LOCU_PAT

  try {
    const { resolveLocuToken } = await import("../config")

    await expect(resolveLocuToken({ searchPaths: [envPath] })).resolves.toBe("quoted-token")
    expect(process.env.LOCU_PAT).toBeUndefined()
  } finally {
    await rm(directory, { force: true, recursive: true })
  }
})

test("resolveLocuToken reports a safe error when no token exists", async () => {
  delete process.env.LOCU_PAT
  const { resolveLocuToken } = await import("../config")

  await expect(resolveLocuToken({ searchPaths: ["missing.env"] })).rejects.toThrow(
    "LOCU_PAT is not set.",
  )
})
