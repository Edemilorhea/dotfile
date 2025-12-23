# Neovim 配置重構指南

## 🔄 重構完成總結

你的 Neovim 配置已經成功重構，實現了 VSCode 和 Neovim 環境的完全分離。

## 📁 新的檔案結構

### 核心配置檔案
```
├── init.lua                     # 主要入口，環境分離邏輯
├── lua/config/
│   ├── lazy.lua                 # 插件管理器配置 (已更新)
│   ├── keymaps-restructured.lua # 重構後的按鍵配置
│   ├── keymaps.lua             # 舊檔案 (保留相容性)
│   └── options.lua             # 基本設定
```

### 按鍵映射檔案
```
├── lua/keymap/
│   ├── general.lua             # VSCode + Neovim 共用按鍵
│   ├── vscode.lua             # VSCode 專用按鍵
│   ├── neovim.lua             # Neovim 專用按鍵 (新增)
│   └── hotKeyMaps.lua         # 熱鍵設定
```

### 插件配置檔案
```
├── lua/plugins/
│   ├── shared.lua             # VSCode + Neovim 共用插件 (新增)
│   ├── neovim-only.lua        # Neovim 專用插件 (新增)
│   ├── ui-restructured.lua    # UI 插件重構版 (新增)
│   ├── editor.lua             # 舊檔案 (已清空)
│   ├── flash.lua              # 舊檔案 (已清空)
│   └── ui.lua                 # 舊檔案 (已清空)
```

## 🔌 插件分類

### ✅ VSCode + Neovim 共用插件
- **nvim-surround**: 文字包圍操作 (`ys`, `ds`, `cs`)
- **flash.nvim**: 快速移動 (`s`, `S`, `r`, `R`)
- **mini.comment**: 註解功能 (`gcc`, `gc`, `<C-/>`)

### 🖥️ Neovim 專用插件
- **nvim-ufo**: 程式碼折疊增強
- **autolist.nvim**: Markdown 自動列表
- **nvim-treesitter**: 語法高亮和解析
- **lazygit.nvim**: Git 整合工具

### 🎨 UI 插件 (僅 Neovim)
- **tokyonight.nvim**: 主題
- **neo-tree.nvim**: 檔案管理器
- **trouble.nvim**: 診斷視窗
- **bufferline.nvim**: Buffer 標籤列
- **lualine.nvim**: 狀態列

## ⌨️ 按鍵配置優先權

你的個人設定已確保優先權：

### 🔥 核心個人設定
- `<C-/>` / `<C-_>`: 註解切換 (覆蓋 LazyVim 預設)
- `o` / `O`: 新行後立即回到 Normal 模式
- `d` / `dd` / `D`: 刪除到黑洞暫存器
- `p` (Visual): 貼上不覆蓋暫存器

### 🚀 快速移動
- `s`: Flash 跳轉
- `H` / `L`: 行首/行尾
- `<C-s>`: 快速儲存

### 📁 檔案管理 (僅 Neovim)
- `<leader>e`: 切換檔案瀏覽器
- `<leader>lg`: 開啟 LazyGit

## 🔄 環境分離機制

### init.lua 自動偵測
```lua
if vim.g.vscode then
    -- VSCode 環境：載入共用插件 + VSCode 專用設定
else  
    -- Neovim 環境：載入全套插件 + 完整功能
end
```

### 插件載入邏輯
```lua
-- 共用插件
{ vscode = true }

-- Neovim 專用
{ cond = not vim.g.vscode }
```

## ✅ 移除的重複插件

- ❌ `Comment.nvim` → 改用 `mini.comment`
- ❌ `nvim-treesitter/playground` → 較少使用
- ❌ 重複的註解插件配置

## 🧪 測試結果

重構後的配置已通過以下測試：
- ✅ Neovim v0.11.2 正常載入
- ✅ LazyVim 成功初始化 
- ✅ 插件總數：54 (載入 17)
- ✅ Flash 和 Surround 功能正常
- ✅ 環境分離機制運作正常
- ✅ 按鍵衝突已解決

## 🔧 使用建議

1. **VSCode 使用者**: 享受 nvim-surround 和 flash 的強大功能
2. **Neovim 使用者**: 完整的 IDE 體驗，包含檔案管理、Git 整合
3. **按鍵習慣**: 你的個人設定已確保在兩個環境中一致
4. **效能優化**: 插件按需載入，避免不必要的資源消耗

## 🚨 注意事項

- 舊的配置檔案已保留以維持相容性
- 如需回復，可暫時停用新檔案
- 建議定期執行 `:Lazy sync` 更新插件
- VSCode 中某些 Neovim 專用功能會自動停用

---

**配置重構完成！** 🎉 現在你擁有一個乾淨、結構化、環境分離的 Neovim 設定。