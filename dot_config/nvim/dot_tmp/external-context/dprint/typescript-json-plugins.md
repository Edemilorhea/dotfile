---
source: Context7 API
library: dprint
package: dprint
topic: TypeScript JavaScript JSON plugin setup
fetched: 2026-06-12T00:00:00Z
official_docs: https://dprint.dev/config | https://dprint.dev/plugins/typescript | https://dprint.dev/plugins/json
---

# dprint TypeScript / JavaScript / JSON setup

Relevant current docs excerpts from Context7:

## Add plugins by command

dprint docs show adding plugins with:

```bash
dprint add typescript markdown json
```

For JSON only:

```bash
dprint add json
```

## dprint.json plugin configuration

The dprint config includes formatter-specific sections and a `plugins` list. The TypeScript plugin applies to both TypeScript and JavaScript:

```jsonc
{
  "lineWidth": 80,
  "typescript": {
    // This applies to both JavaScript & TypeScript
    "quoteStyle": "preferSingle",
    "binaryExpression.operatorPosition": "sameLine"
  },
  "json": {
    "indentWidth": 2
  },
  "excludes": [
    "**/*-lock.json"
  ],
  "plugins": [
    "https://plugins.dprint.dev/typescript-x.x.x.wasm",
    "https://plugins.dprint.dev/json-x.x.x.wasm"
  ]
}
```

Current docs example for TypeScript plugin:

```jsonc
{
  "typescript": {
    // TypeScript & JavaScript config goes here
  },
  "plugins": [
    "https://plugins.dprint.dev/typescript-0.95.15.wasm"
  ]
}
```

Current docs example for multiple plugins:

```jsonc
{
  "plugins": [
    "https://plugins.dprint.dev/typescript-0.95.15.wasm",
    "https://plugins.dprint.dev/json-0.21.3.wasm",
    "https://plugins.dprint.dev/markdown-0.21.1.wasm"
  ]
}
```

## Minimal project dprint.json for LazyVim/conform

```jsonc
{
  "lineWidth": 100,
  "typescript": {
    "quoteStyle": "preferDouble",
    "semiColons": "asi"
  },
  "json": {
    "indentWidth": 2
  },
  "excludes": [
    "**/node_modules",
    "**/*-lock.json"
  ],
  "plugins": [
    "https://plugins.dprint.dev/typescript-0.95.15.wasm",
    "https://plugins.dprint.dev/json-0.21.3.wasm"
  ]
}
```

Use the latest plugin URLs produced by `dprint add typescript json` if you want dprint to manage versions.
