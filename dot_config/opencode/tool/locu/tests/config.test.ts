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
