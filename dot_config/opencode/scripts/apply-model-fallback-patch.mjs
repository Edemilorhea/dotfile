import { readFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const PACKAGE_VERSION = "1.3.4";
const ORGANIZATION_OAUTH_ERROR =
  "oauth authentication is currently not allowed for this organization.";

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const packageDirectory = join(
  scriptDirectory,
  "..",
  "node_modules",
  "@smart-coders-hq",
  "opencode-model-fallback"
);
const packageJsonPath = join(packageDirectory, "package.json");
const bundlePath = join(packageDirectory, "dist", "index.js");

const quotaOriginal = `  "out of credits"\n];`;
const quotaPatched = `  "out of credits",\n  "${ORGANIZATION_OAUTH_ERROR}"\n];`;

const authOriginal = `    if (error.name === "APIError") {\n      const apiMessage = typeof error.data?.message === "string" ? error.data.message : "";\n      const apiStatusCode = typeof error.data?.statusCode === "number" ? error.data.statusCode : undefined;\n      const category = classifyError(apiMessage, apiStatusCode);`;
const authPatched = `    const apiMessage = typeof error.data?.message === "string" ? error.data.message : "";\n    const apiStatusCode = typeof error.data?.statusCode === "number" ? error.data.statusCode : undefined;\n    const isSupportedError = error.name === "APIError" || error.name === "ProviderAuthError" && matchesAnyPattern(apiMessage, ["${ORGANIZATION_OAUTH_ERROR}"]);\n    if (isSupportedError) {\n      const category = classifyError(apiMessage, apiStatusCode);`;

const packageJson = JSON.parse(await readFile(packageJsonPath, "utf8"));
if (packageJson.version !== PACKAGE_VERSION) {
  throw new Error(
    `Unsupported @smart-coders-hq/opencode-model-fallback version: ${packageJson.version}`
  );
}

const bundle = await readFile(bundlePath, "utf8");
const quotaIsPatched = bundle.includes(quotaPatched);
const authIsPatched = bundle.includes(authPatched);

if (quotaIsPatched && authIsPatched) {
  console.log(`model-fallback patch already applied to ${PACKAGE_VERSION}`);
  process.exit(0);
}

if (quotaIsPatched !== authIsPatched) {
  throw new Error("Partial model-fallback patch detected; reinstall dependencies before retrying");
}

if (!bundle.includes(quotaOriginal) || !bundle.includes(authOriginal)) {
  throw new Error("Official model-fallback bundle does not match the pinned patch baseline");
}

const patchedBundle = bundle.replace(quotaOriginal, quotaPatched).replace(authOriginal, authPatched);
await writeFile(bundlePath, patchedBundle, "utf8");

console.log(`model-fallback OAuth patch applied to ${PACKAGE_VERSION}`);
