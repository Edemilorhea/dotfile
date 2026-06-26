# Plugin 願望清單 / 待評估

記錄「考慮中、但還沒裝」的 plugin。想到要切換時直接看這份，不用重新研究。

狀態標記：🟡 評估中 ｜ 🟢 已採用 ｜ 🔴 已放棄

---

## 🟡 winbuf.nvim — VSCode editor group 風格的 per-window buffer tabs

- **連結**：https://github.com/e-sigs/winbuf.nvim
- **記錄日期**：2026-06
- **解決的痛點**：
  Neovim 的 buffer 是**全域共用**，跟 VSCode 的 editor group 不一樣。
  一般 bufferline（我現在用的）tab 列是**全域一條**，所有 split 共用同一排 tab。
  我之前一直想要「左右 split 各看各的、左邊關掉不影響右邊」—— winbuf 正是解這個。

### 它做什麼
- 用 `winbar`（per-window）取代 `tabline`（全域），**每個 split 各有自己的 tab 列**
- 每個 window 用 window-local 變數（`vim.w`）各自記住「自己開過哪些 buffer」
- **不是真的複製出兩個獨立 buffer**（Neovim 本質做不到，buffer 永遠全域唯一），
  而是用「per-window buffer list」模擬出 VSCode editor group 的體驗

### 招牌功能
- 每個 split 獨立 tab 列
- `<A-h/j/k/l>` 把 buffer 搬到相鄰 split
- **window-scoped 關閉**：在左窗關 buffer 只從左窗移除，只有「沒有任何窗還追蹤」時才真正 `:bdelete`（= 左關右留）
- 關掉 split 時自動清理孤兒 buffer
- 多種 tab 樣式（thin/thick/slant/slope/round）、檔案圖示、LSP 診斷、序號

### ⚠️ 切換前必處理的衝突（重要！）
| 衝突點 | 說明 | 對策 |
|--------|------|------|
| 顯示重疊 | winbuf 用 `winbar`、現有 bufferline 用 `tabline`，會同時出現兩排 tab | 停用 / 移除現有 bufferline |
| cycle 鍵打架 | winbuf 要綁 `<S-h>`/`<S-l>`，但這兩鍵現在是 LazyVim 給 bufferline 用 | 重新規劃 cycle 鍵 |
| **`<C-w>` 被搶** | winbuf README 範例把 `<C-w>` 綁成「關 buffer」，但 `<C-w>` 是 Neovim **切換 window 的核心前綴**（`<C-w>h/j/k/l`）！直接衝突 | **務必改掉**這個鍵，換成別的關閉鍵 |
| 既有設定白做 | 我在 bufferline 加的 `numbers=ordinal`、`\1~\9` 快跳、`\b.`/`\b,` 移動會失效 | 切換時一併撤掉 |

### 切換 checklist（未來真的要裝時）
- [ ] 停用 `lua/plugins/ui-restructured.lua` 裡的 bufferline 區塊
- [ ] 撤掉 `lua/keymap/hotKeyMaps.lua` 裡的 bufferline 專屬 keymap（`\b.` `\b,` `\1~\9`）
- [ ] 安裝 winbuf，**重綁 keymap 並避開 `<C-w>`**
- [ ] 確認 `<C-w>h/j/k/l` 切窗仍正常
- [ ] 測試「左窗關 buffer、右窗保留」是否如預期

### 安裝範例（lazy.nvim，注意已標記要改的鍵）
```lua
{
  "e-sigs/winbuf.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {},
  keys = {
    { "<S-h>", function() require("winbuf").cycle(-1) end, desc = "Prev buffer" },
    { "<S-l>", function() require("winbuf").cycle(1) end, desc = "Next buffer" },
    { "<A-h>", function() require("winbuf").move_buf("h") end, desc = "Move buffer left" },
    { "<A-l>", function() require("winbuf").move_buf("l") end, desc = "Move buffer right" },
    { "<A-j>", function() require("winbuf").move_buf("j") end, desc = "Move buffer down" },
    { "<A-k>", function() require("winbuf").move_buf("k") end, desc = "Move buffer up" },
    -- ⚠️ README 原本用 <C-w> 關 buffer → 會搶走切窗前綴，務必改鍵！
    -- 例如改成 <leader>bw 之類：
    { "<leader>bw", function() require("winbuf").close_buf() end, desc = "Close buffer (window)" },
    { "<leader>bW", function() require("winbuf").close_split() end, desc = "Close split" },
  },
}
```

### 決策提醒
- **偶爾才開 split** → 維持現有 bufferline 就好，別折騰
- **天天開多窗對照** → winbuf 值得，但要好好規劃 keymap（尤其避開 `<C-w>`）

---

## （以下保留給未來其他候選 plugin）
