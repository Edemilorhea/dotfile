import assert from "node:assert/strict";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import { createPlugin } from "@smart-coders-hq/opencode-model-fallback";

const ORGANIZATION_OAUTH_ERROR =
  "OAuth authentication is currently not allowed for this organization.";

async function createHarness() {
  const directory = await mkdtemp(join(tmpdir(), "model-fallback-patch-"));
  const prompts = [];
  const message = {
    info: {
      id: "message-1",
      role: "user",
      agent: "TaskManager",
      model: {
        providerID: "anthropic",
        modelID: "claude-opus-4-8",
      },
    },
    parts: [{ type: "text", text: "smoke test" }],
  };

  await writeFile(
    join(directory, "model-fallback.json"),
    JSON.stringify({
      enabled: true,
      logging: false,
      patterns: [ORGANIZATION_OAUTH_ERROR],
      defaults: {
        fallbackOn: ["quota_exceeded"],
        cooldownMs: 300000,
        retryOriginalAfterMs: 900000,
        maxFallbackDepth: 3,
      },
      agents: {
        TaskManager: {
          fallbackModels: ["openai/gpt-5.6-sol"],
        },
      },
    })
  );

  const client = {
    app: {
      log: async () => ({}),
    },
    session: {
      messages: async () => ({ data: [message] }),
      abort: async () => ({}),
      revert: async () => ({}),
      prompt: async (input) => {
        prompts.push(input);
        return {};
      },
    },
    tui: {
      showToast: async () => ({}),
    },
  };

  const hooks = await createPlugin({ client, directory });

  return {
    hooks,
    prompts,
    cleanup: () => rm(directory, { force: true, recursive: true }),
  };
}

test("falls back when retry status contains the organization OAuth error", async () => {
  const harness = await createHarness();

  try {
    await harness.hooks.event({
      event: {
        type: "session.status",
        properties: {
          sessionID: "session-retry",
          status: {
            type: "retry",
            message: ORGANIZATION_OAUTH_ERROR,
          },
        },
      },
    });

    assert.equal(harness.prompts.length, 1);
    assert.deepEqual(harness.prompts[0].body.model, {
      providerID: "openai",
      modelID: "gpt-5.6-sol",
    });
  } finally {
    await harness.cleanup();
  }
});

test("falls back when ProviderAuthError contains the organization OAuth error", async () => {
  const harness = await createHarness();

  try {
    await harness.hooks.event({
      event: {
        type: "session.error",
        properties: {
          sessionID: "session-error",
          error: {
            name: "ProviderAuthError",
            data: {
              message: ORGANIZATION_OAUTH_ERROR,
              statusCode: 403,
            },
          },
        },
      },
    });

    assert.equal(harness.prompts.length, 1);
    assert.deepEqual(harness.prompts[0].body.model, {
      providerID: "openai",
      modelID: "gpt-5.6-sol",
    });
  } finally {
    await harness.cleanup();
  }
});

test("does not fall back for unrelated ProviderAuthError messages", async () => {
  const harness = await createHarness();

  try {
    await harness.hooks.event({
      event: {
        type: "session.error",
        properties: {
          sessionID: "session-unrelated-auth-error",
          error: {
            name: "ProviderAuthError",
            data: {
              message: "OAuth token is invalid.",
              statusCode: 403,
            },
          },
        },
      },
    });

    assert.equal(harness.prompts.length, 0);
  } finally {
    await harness.cleanup();
  }
});
