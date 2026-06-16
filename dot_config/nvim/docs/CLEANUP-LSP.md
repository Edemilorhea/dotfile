# LSP 清理指南

## 🎯 目標

移除不需要的 LSP,只保留:
- ✅ **vtsls** (TypeScript/JavaScript/Solid.js)
- ❌ **ts_ls** (已被 vtsls 取代)
- ❌ **eslint** (專案不需要)

---

## 🚀 方法 1: 在 Neovim 中清理 (推薦)

### 步驟 1: 開啟 Neovim

```bash
nvim
```

### 步驟 2: 開啟 Mason

```vim
:Mason
```

### 步驟 3: 移除不需要的 LSP

在 Mason 介面中:
1. 找到 `typescript-language-server` (ts_ls)
2. 按 `X` 解除安裝
3. 找到 `eslint-lsp` (如果有)
4. 按 `X` 解除安裝

### 步驟 4: 重新啟動 Neovim

```vim
:qa
```

---

## 🔧 方法 2: 手動刪除 (如果方法 1 失敗)

### Windows PowerShell

```powershell
# 刪除 typescript-language-server (ts_ls)
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\nvim-data\mason\packages\typescript-language-server"

# 刪除 eslint-lsp
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\nvim-data\mason\packages\eslint-lsp"
```

---

## ✅ 驗證清理結果

### 步驟 1: 重新啟動 Neovim

```vim
:qa
```

### 步驟 2: 開啟一個 TypeScript 檔案

```vim
nvim test.ts
```

### 步驟 3: 檢查 LSP 狀態

```vim
:LspCheckBuffer
```

**預期結果**:
```
✅ 當前 buffer 的 LSP 伺服器:
  • vtsls (支援補全: 是)
```

**不應該看到**:
- ❌ ts_ls
- ❌ eslint

### 步驟 4: 測試補全

1. 輸入一些程式碼
2. 應該只看到**一組**補全建議 (來自 vtsls)
3. 不應該有重複的建議

---

## 📊 清理前後對比

### 清理前 ❌
```
當前 buffer 的 LSP 伺服器:
  • vtsls (支援補全: 是)
  • ts_ls (支援補全: 是)  ← 重複!
```

補全建議會出現兩次,例如:
```
function test()  (vtsls)
function test()  (ts_ls)  ← 重複!
```

### 清理後 ✅
```
當前 buffer 的 LSP 伺服器:
  • vtsls (支援補全: 是)
```

補全建議只出現一次:
```
function test()  (vtsls)
```

---

## 🔍 檢查已安裝的 LSP

在 Neovim 中執行:

```vim
:Mason
```

**應該看到的 LSP** (已安裝):
- ✅ vtsls
- ✅ lua_ls
- ✅ jsonls
- ✅ html
- ✅ cssls
- ✅ tailwindcss
- ✅ emmet_ls
- ✅ omnisharp
- ✅ pyright
- ✅ marksman

**不應該看到的 LSP**:
- ❌ typescript-language-server (ts_ls)
- ❌ eslint-lsp

---

## ❓ 常見問題

### Q: 為什麼要移除 ts_ls?

A: 
- vtsls 效能更好 (Rust vs Node.js)
- 記憶體佔用更低
- 功能完全相同
- 同時使用會造成重複補全

### Q: 移除後會影響功能嗎?

A: 
- ❌ 不會!vtsls 提供完全相同的功能
- ✅ 效能會更好
- ✅ 記憶體佔用更低
- ✅ 不會有重複補全

### Q: 如果我想要 ESLint 怎麼辦?

A: 
1. 刪除 `lua/plugins/disable-eslint.lua`
2. 在 `lua/plugins/lsp.lua` 中取消註解 `"eslint"`
3. 為專案建立 ESLint 配置檔案
4. 重新啟動 Neovim

---

## 📝 相關檔案

- `lua/plugins/lsp.lua` - LSP 主配置
- `lua/plugins/disable-eslint.lua` - 停用不需要的 LSP
- `lua/plugins/blink.lua` - 補全配置

---

## 🎯 下一步

清理完成後:
1. ✅ 重新啟動 Neovim
2. ✅ 測試 TypeScript/JavaScript 補全
3. ✅ 確認沒有重複建議
4. ✅ 享受更快的效能! 🚀
