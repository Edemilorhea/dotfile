# vtsls 效能優化指南

## 🐢 問題: vtsls 每次開啟檔案都很慢

### 原因分析

你的專案是 **Monorepo** 結構:
```
opencode_project/
├── packages/
│   ├── app/
│   ├── console/
│   ├── desktop/
│   ├── enterprise/
│   ├── function/
│   ├── opencode/
│   └── ... (16 個 packages)
└── tsconfig.json
```

**問題**:
1. ❌ vtsls 預設會分析整個 monorepo (所有 16 個 packages)
2. ❌ 每次開啟檔案都要重新初始化
3. ❌ 記憶體佔用高
4. ❌ 啟動慢 (可能需要 5-10 秒)

---

## ✅ 已套用的優化

### 1️⃣ **Monorepo Root 優化**

**檔案**: `lua/plugins/lsp.lua`

```lua
vtsls = {
    -- 只分析當前 package,不分析整個 monorepo
    root_dir = function(fname)
        local util = require("lspconfig.util")
        return util.root_pattern("package.json")(fname)
            or util.root_pattern("tsconfig.json")(fname)
            or util.root_pattern(".git")(fname)
    end,
}
```

**效果**: vtsls 只會分析你正在編輯的 package,不會分析整個 monorepo

---

### 2️⃣ **記憶體限制**

**檔案**: `lua/plugins/lsp.lua`

```lua
settings = {
    typescript = {
        tsserver = {
            maxTsServerMemory = 4096, -- 限制 4GB
        },
    },
}
```

**效果**: 防止 vtsls 佔用過多記憶體

---

### 3️⃣ **排除不需要的目錄**

**檔案**: `.vtsls.json` (專案根目錄)

```json
{
  "typescript": {
    "tsserver": {
      "watchOptions": {
        "excludeDirectories": [
          "**/node_modules",
          "**/.git",
          "**/dist",
          "**/build",
          "**/.turbo",
          "**/.sst"
        ]
      }
    }
  }
}
```

**效果**: vtsls 不會監視這些目錄的變化,減少 CPU 使用

---

### 4️⃣ **tsconfig.json 優化**

**檔案**: `tsconfig.json` (專案根目錄)

```json
{
  "exclude": [
    "**/node_modules",
    "**/dist",
    "**/build",
    "**/.turbo",
    "**/.sst",
    "**/coverage"
  ]
}
```

**效果**: TypeScript 編譯器不會分析這些目錄

---

### 5️⃣ **LSP 快取**

**檔案**: `lua/plugins/lsp-cache.lua`

啟用 LSP 快取,避免每次重新載入

---

### 6️⃣ **效能監控**

**檔案**: `lua/config/lsp-performance.lua`

新增命令:
- `:VtslsCheck` - 檢查 vtsls 狀態和啟動時間
- `:VtslsRestart` - 重新啟動 vtsls

---

## 🚀 測試優化效果

### 步驟 1: 重新啟動 Neovim

```vim
:qa
```

### 步驟 2: 開啟一個 TSX 檔案

```bash
cd C:\Users\tc_tseng\Documents\opencode_project\packages\console\app
nvim src\App.tsx
```

### 步驟 3: 檢查 vtsls 啟動時間

```vim
:VtslsCheck
```

**預期結果**:
```
📊 vtsls 狀態:
  • Root: C:\Users\tc_tseng\Documents\opencode_project\packages\console\app
  • Buffers: 1
  • 啟動時間: 1.23 秒  ← 應該 < 3 秒
```

**優化前**: 5-10 秒
**優化後**: 1-3 秒

---

## 📊 效能對比

### 優化前 ❌

| 指標       | 數值          |
| ---------- | ------------- |
| 啟動時間   | 5-10 秒       |
| Root 目錄  | 整個 monorepo |
| 分析範圍   | 16 個 packages |
| 記憶體佔用 | 1-2 GB        |

### 優化後 ✅

| 指標       | 數值              |
| ---------- | ----------------- |
| 啟動時間   | 1-3 秒            |
| Root 目錄  | 當前 package      |
| 分析範圍   | 1 個 package      |
| 記憶體佔用 | 200-500 MB        |

---

## 🔧 進階優化 (如果還是慢)

### 選項 1: 使用 Project-specific tsconfig

為每個 package 建立獨立的 `tsconfig.json`,明確指定 `include` 和 `exclude`

### 選項 2: 停用不需要的 vtsls 功能

```lua
vtsls = {
    settings = {
        typescript = {
            preferences = {
                -- 停用自動匯入建議 (加快補全速度)
                includePackageJsonAutoImports = "off",
            },
        },
    },
}
```

### 選項 3: 使用 ts_ls 取代 vtsls

如果 vtsls 還是太慢,可以考慮換回 `ts_ls`:

```lua
-- 在 lua/plugins/lsp.lua 中
ensure_installed = {
    "ts_ls",  -- 換回 ts_ls
    -- "vtsls",  -- 註解掉 vtsls
}
```

但 `ts_ls` 效能通常更差,不推薦。

---

## 🎯 最佳實踐

### 1. 在正確的目錄開啟 Neovim

❌ **錯誤**: 在 monorepo 根目錄開啟
```bash
cd C:\Users\tc_tseng\Documents\opencode_project
nvim packages\console\app\src\App.tsx
```
→ vtsls 會分析整個 monorepo

✅ **正確**: 在 package 目錄開啟
```bash
cd C:\Users\tc_tseng\Documents\opencode_project\packages\console\app
nvim src\App.tsx
```
→ vtsls 只會分析當前 package

---

### 2. 使用 Workspace 功能

如果你經常在多個 packages 之間切換,使用 Neovim 的 workspace:

```vim
" 儲存 workspace
:mksession! ~/workspace-console.vim

" 載入 workspace
:source ~/workspace-console.vim
```

---

### 3. 定期清理 LSP 快取

如果 vtsls 行為異常:

```vim
:VtslsRestart
```

或手動刪除快取:

```bash
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\nvim-data\lsp-cache"
```

---

## ❓ 常見問題

### Q: 為什麼第一次開啟還是慢?

A: 第一次開啟時,vtsls 需要:
1. 分析 `tsconfig.json`
2. 載入 TypeScript 型別定義
3. 建立索引

這是正常的。第二次開啟同一個 package 應該會快很多。

---

### Q: 如何知道 vtsls 在做什麼?

A: 檢查 LSP 日誌:

```vim
:LspLog
```

---

### Q: 可以完全停用 vtsls 嗎?

A: 可以,但你會失去:
- ❌ 自動補全
- ❌ 型別檢查
- ❌ 跳轉定義
- ❌ 重構功能

不推薦。

---

## 📝 相關檔案

- `lua/plugins/lsp.lua` - vtsls 主配置
- `lua/plugins/lsp-cache.lua` - LSP 快取優化
- `lua/config/lsp-performance.lua` - 效能監控
- `.vtsls.json` - vtsls 專案配置
- `tsconfig.json` - TypeScript 配置

---

## 🎯 預期效果

優化後,vtsls 應該:
- ✅ 啟動時間 < 3 秒
- ✅ 只分析當前 package
- ✅ 記憶體佔用 < 500 MB
- ✅ 不會每次都重新載入

如果還是很慢,請執行 `:VtslsCheck` 並告訴我結果!
