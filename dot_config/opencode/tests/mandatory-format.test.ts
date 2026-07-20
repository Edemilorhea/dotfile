import { expect, test } from "bun:test"
import { mkdir, mkdtemp, rm, symlink, writeFile } from "node:fs/promises"
import { join } from "node:path"
import { tmpdir } from "node:os"
import {
  collectModifiedFiles,
  createFormatAfterHook,
  resolveFormatter,
  shouldFormatFile,
  type FormatterSelection,
} from "../plugin/mandatory-format"

async function withProject(
  run: (projectDirectory: string) => Promise<void>,
): Promise<void> {
  const projectDirectory = await mkdtemp(join(tmpdir(), "mandatory-format-"))
  try {
    await run(projectDirectory)
  } finally {
    await rm(projectDirectory, { recursive: true, force: true })
  }
}

test("extracts direct and apply_patch file paths", () => {
  expect(collectModifiedFiles("edit", { filePath: "src/app.ts" })).toEqual([
    "src/app.ts",
  ])
  expect(
    collectModifiedFiles("apply_patch", {
      patchText: [
        "*** Begin Patch",
        "*** Update File: src/app.ts",
        "*** Move to: src/main.ts",
        "*** Add File: src/style.css",
        "*** End Patch",
      ].join("\n"),
    }),
  ).toEqual(["src/app.ts", "src/main.ts", "src/style.css"])
})

test("recognizes supported extensions case-insensitively", () => {
  expect(shouldFormatFile("Component.TSX")).toBe(true)
  expect(shouldFormatFile("image.png")).toBe(false)
  expect(shouldFormatFile("Program.cs", ["cs"])).toBe(true)
})

test("detects Prettier from package dependencies", async () => {
  await withProject(async (projectDirectory) => {
    await writeFile(
      join(projectDirectory, "package.json"),
      JSON.stringify({ devDependencies: { prettier: "3.0.0" } }),
    )
    const filePath = join(projectDirectory, "src", "app.ts")

    expect(resolveFormatter(filePath, projectDirectory)).toEqual({
      formatter: "prettier",
      cwd: projectDirectory,
    })
  })
})

test("detects the nearest formatter configuration", async () => {
  await withProject(async (projectDirectory) => {
    const nestedDirectory = join(projectDirectory, "packages", "web")
    await mkdir(nestedDirectory, { recursive: true })
    await writeFile(join(projectDirectory, "dprint.json"), "{}")
    await writeFile(join(nestedDirectory, "biome.json"), "{}")

    expect(
      resolveFormatter(join(nestedDirectory, "src", "app.ts"), projectDirectory),
    ).toEqual({ formatter: "biome", cwd: nestedDirectory })
  })
})

test("supports explicit dprint policy and extension overrides", async () => {
  await withProject(async (projectDirectory) => {
    const policyDirectory = join(projectDirectory, ".opencode")
    await mkdir(policyDirectory)
    await writeFile(
      join(policyDirectory, "mandatory-format.json"),
      JSON.stringify({ formatter: "dprint", extensions: [".cs"] }),
    )

    expect(
      resolveFormatter(join(projectDirectory, "Program.cs"), projectDirectory),
    ).toEqual({
      formatter: "dprint",
      extensions: [".cs"],
      cwd: projectDirectory,
    })
  })
})

test("rejects ambiguous formatter detection", async () => {
  await withProject(async (projectDirectory) => {
    await writeFile(join(projectDirectory, "biome.json"), "{}")
    await writeFile(join(projectDirectory, ".prettierrc"), "{}")

    expect(() =>
      resolveFormatter(join(projectDirectory, "app.ts"), projectDirectory),
    ).toThrow("Multiple formatters detected")
  })
})

test("after hook waits for the formatter runner", async () => {
  await withProject(async (projectDirectory) => {
    await writeFile(join(projectDirectory, ".prettierrc"), "{}")
    const filePath = join(projectDirectory, "app.ts")
    await writeFile(filePath, "const value=1")

    const calls: Array<{
      selection: FormatterSelection
      filePath: string
    }> = []
    let release: (() => void) | undefined
    const wait = new Promise<void>((resolve) => {
      release = resolve
    })
    const hook = createFormatAfterHook(
      projectDirectory,
      async (selection, formattedFile) => {
        calls.push({ selection, filePath: formattedFile })
        await wait
      },
    )

    let completed = false
    const pending = hook({ tool: "write", args: { filePath } }).then(() => {
      completed = true
    })
    await Promise.resolve()

    expect(calls).toEqual([
      {
        selection: { formatter: "prettier", cwd: projectDirectory },
        filePath,
      },
    ])
    expect(completed).toBe(false)

    release?.()
    await pending
    expect(completed).toBe(true)
  })
})

test("after hook ignores unsupported files without formatter configuration", async () => {
  await withProject(async (projectDirectory) => {
    const filePath = join(projectDirectory, "image.png")
    await writeFile(filePath, "not-an-image")
    let called = false
    const hook = createFormatAfterHook(projectDirectory, async () => {
      called = true
    })

    await hook({ tool: "write", args: { filePath } })

    expect(called).toBe(false)
  })
})

test("allows project directories whose names start with two dots", async () => {
  await withProject(async (projectDirectory) => {
    const cacheDirectory = join(projectDirectory, "..cache")
    await mkdir(cacheDirectory)
    await writeFile(join(projectDirectory, ".prettierrc"), "{}")

    expect(
      resolveFormatter(join(cacheDirectory, "app.ts"), projectDirectory),
    ).toEqual({ formatter: "prettier", cwd: projectDirectory })
  })
})

test("after hook rejects a symlink that escapes the project", async () => {
  await withProject(async (projectDirectory) => {
    const externalDirectory = await mkdtemp(join(tmpdir(), "mandatory-format-external-"))
    try {
      const externalFile = join(externalDirectory, "outside.ts")
      await writeFile(externalFile, "const outside=1")
      await writeFile(join(projectDirectory, ".prettierrc"), "{}")
      const linkPath = join(projectDirectory, "external")
      await symlink(
        externalDirectory,
        linkPath,
        process.platform === "win32" ? "junction" : "dir",
      )
      const linkedFile = join(linkPath, "outside.ts")
      const hook = createFormatAfterHook(projectDirectory, async () => {})

      await expect(
        hook({ tool: "write", args: { filePath: linkedFile } }),
      ).rejects.toThrow("outside the project directory")
    } finally {
      await rm(externalDirectory, { recursive: true, force: true })
    }
  })
})
