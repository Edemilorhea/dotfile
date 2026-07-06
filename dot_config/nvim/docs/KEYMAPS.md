# Neovim Keymap 參考文件

> 最後更新：2026-06-12  
> 環境：LazyVim + 自訂插件  
> 圖例：`[LazyVim]` = LazyVim 內建　`[Neovim]` = Neovim 原生　`[自訂]` = 個人設定

---

## 目錄

1. [基本操作](#基本操作)
2. [視窗與分割](#視窗與分割)
3. [Buffer 管理](#buffer-管理)
4. [Tab 管理](#tab-管理)
5. [檔案搜尋 (Telescope)](#檔案搜尋-telescope)
6. [LSP 功能](#lsp-功能)
7. [診斷 (Diagnostics)](#診斷-diagnostics)
8. [Git 整合](#git-整合)
9. [Terminal 群組](#terminal-群組)
10. [Trouble 錯誤清單](#trouble-錯誤清單)
11. [Todo 管理](#todo-管理)
12. [Markdown 工具](#markdown-工具)
13. [UI 切換](#ui-切換)
14. [Flash 跳轉](#flash-跳轉)
15. [Surround 操作](#surround-操作)
16. [程式碼註解](#程式碼註解)
17. [Treesitter 選取](#treesitter-選取)
18. [Noice 通知](#noice-通知)
19. [Session 管理](#session-管理)
20. [其他工具](#其他工具)
21. [移動與導航](#移動與導航)

---

## 基本操作

| 鍵      | 功能                                   | 來源        |
| ------- | -------------------------------------- | ----------- |
| `<Esc>` | 清除搜尋高亮                           | `[LazyVim]` |
| `<C-S>` | 儲存檔案                               | `[LazyVim]` |
| `n`     | 下一個搜尋結果（置中）                 | `[LazyVim]` |
| `N`     | 上一個搜尋結果（置中）                 | `[LazyVim]` |
| `j`     | 向下（支援 wrap 行）                   | `[LazyVim]` |
| `k`     | 向上（支援 wrap 行）                   | `[LazyVim]` |
| `H`     | 跳到行首非空白字元                     | `[LazyVim]` |
| `L`     | 跳到行尾                               | `[LazyVim]` |
| `D`     | 刪除到行尾（black hole，不影響暫存器） | `[LazyVim]` |
| `dd`    | 刪除整行（black hole）                 | `[LazyVim]` |
| `d`     | 刪除（black hole）                     | `[LazyVim]` |
| `Y`     | 複製到行尾                             | `[Neovim]`  |
| `O`     | 在上方新增空行（不進入 insert mode）   | `[LazyVim]` |
| `o`     | 在下方新增空行（不進入 insert mode）   | `[LazyVim]` |
| `[`     | 在游標上方新增空行                     | `[LazyVim]` |
| `]`     | 在游標下方新增空行                     | `[LazyVim]` |
| `<M-j>` | 將行向下移動                           | `[LazyVim]` |
| `<M-k>` | 將行向上移動                           | `[LazyVim]` |
| `\ur`   | 重繪畫面 / 清除搜尋高亮 / 更新 diff    | `[LazyVim]` |
| `\K`    | Keywordprg                             | `[LazyVim]` |
| `\l`    | 開啟 Lazy 插件管理器                   | `[LazyVim]` |
| `\L`    | LazyVim Changelog                      | `[LazyVim]` |
| `\r`    | 重新載入 LazyVim 設定                  | `[LazyVim]` |
| `\qq`   | 全部退出                               | `[LazyVim]` |
| `gx`    | 用系統程式開啟游標下的路徑或 URI       | `[Neovim]`  |

---

## 視窗與分割

| 鍵          | 功能                         | 來源        |
| ----------- | ---------------------------- | ----------- |
| `<C-H>`     | 移到左側視窗                 | `[LazyVim]` |
| `<C-J>`     | 移到下方視窗                 | `[LazyVim]` |
| `<C-K>`     | 移到上方視窗                 | `[LazyVim]` |
| `<C-L>`     | 移到右側視窗                 | `[LazyVim]` |
| `<C-Up>`    | 增加視窗高度                 | `[LazyVim]` |
| `<C-Down>`  | 減少視窗高度                 | `[LazyVim]` |
| `<C-Left>`  | 減少視窗寬度                 | `[LazyVim]` |
| `<C-Right>` | 增加視窗寬度                 | `[LazyVim]` |
| `<C-W>`     | 視窗 Hydra 模式（which-key） | `[LazyVim]` |
| `\|`        | 垂直分割視窗                 | `[LazyVim]` |
| `\-`        | 水平分割視窗                 | `[LazyVim]` |
| `\wd`       | 刪除視窗                     | `[LazyVim]` |
| `\wm`       | 切換縮放模式                 | `[LazyVim]` |
| `\uZ`       | 切換縮放模式                 | `[LazyVim]` |
| `\uz`       | 切換 Zen Mode                | `[LazyVim]` |

---

## Buffer 管理

| 鍵        | 功能                   | 來源                                            |
| --------- | ---------------------- | ----------------------------------------------- |
| `<Tab>`   | 切換到下一個 Buffer    | `[自訂]` `keymap/neovim.lua`                    |
| `<S-Tab>` | 切換到上一個 Buffer    | `[自訂]` `keymap/neovim.lua`                    |
| `[b`      | 上一個 Buffer          | `[LazyVim]`                                     |
| `]b`      | 下一個 Buffer          | `[LazyVim]`                                     |
| `[B`      | 將 Buffer 向左移動     | `[LazyVim]`                                     |
| `]B`      | 將 Buffer 向右移動     | `[LazyVim]`                                     |
| `\bb`     | 切換到上一個 Buffer    | `[LazyVim]`                                     |
| `\``      | 切換到上一個 Buffer    | `[LazyVim]`                                     |
| `\bd`     | 刪除 Buffer            | `[自訂]` `keymap/neovim.lua`（與 LazyVim 相同） |
| `\bD`     | 刪除 Buffer 和視窗     | `[LazyVim]`                                     |
| `\bo`     | 刪除其他 Buffer        | `[LazyVim]`                                     |
| `\bi`     | 刪除不可見 Buffer      | `[LazyVim]`                                     |
| `\bl`     | 刪除左側所有 Buffer    | `[LazyVim]`                                     |
| `\br`     | 刪除右側所有 Buffer    | `[LazyVim]`                                     |
| `\bp`     | 釘選 / 取消釘選 Buffer | `[LazyVim]`                                     |
| `\bP`     | 刪除未釘選的 Buffer    | `[LazyVim]`                                     |
| `\bj`     | 選取 Buffer            | `[LazyVim]`                                     |
| `\bc`     | 選擇關閉 Buffer        | `[LazyVim]`                                     |

---

## Tab 管理

| 鍵            | 功能         | 來源        |
| ------------- | ------------ | ----------- |
| `\<Tab><Tab>` | 新增 Tab     | `[LazyVim]` |
| `\<Tab>d`     | 關閉 Tab     | `[LazyVim]` |
| `\<Tab>o`     | 關閉其他 Tab | `[LazyVim]` |
| `\<Tab>[`     | 上一個 Tab   | `[LazyVim]` |
| `\<Tab>]`     | 下一個 Tab   | `[LazyVim]` |
| `\<Tab>f`     | 第一個 Tab   | `[LazyVim]` |
| `\<Tab>l`     | 最後一個 Tab | `[LazyVim]` |

---

## 檔案搜尋 (Telescope)

| 鍵         | 功能                       | 來源                         |
| ---------- | -------------------------- | ---------------------------- | --- | ----- | --------- | ---------------------------- |
| `\<Space>` | 搜尋檔案（Root Dir）       | `[LazyVim]`                  |
| `\ff`      | Find Files                 | `[自訂]` `plugins/tools.lua` |     | `\fg` | Live Grep | `[自訂]` `plugins/tools.lua` |
| `\fb`      | Buffers                    | `[自訂]` `plugins/tools.lua` |
| `\fh`      | Help Tags                  | `[自訂]` `plugins/tools.lua` |
| `\fr`      | Recent Files               | `[自訂]` `plugins/tools.lua` |
| `\fw`      | Find Word                  | `[自訂]` `plugins/tools.lua` |
| `\fF`      | Find Files (cwd)           | `[LazyVim]`                  |
| `\fR`      | Recent Files (cwd)         | `[LazyVim]`                  |
| `\fB`      | Buffers (all)              | `[LazyVim]`                  |
| `\fc`      | Find Config File           | `[LazyVim]`                  |
| `\fn`      | New File                   | `[LazyVim]`                  |
| `\fp`      | Projects                   | `[LazyVim]`                  |
| `\fe`      | Explorer Snacks (root dir) | `[LazyVim]`                  |
| `\fE`      | Explorer Snacks (cwd)      | `[LazyVim]`                  |
| `\E`       | Explorer Snacks (cwd)      | `[LazyVim]`                  |
| `\e`       | 切換檔案總管               | `[LazyVim]`                  |
| `\o`       | 聚焦檔案總管               | `[LazyVim]`                  |
| `\/`       | Grep (Root Dir)            | `[LazyVim]`                  |
| `\,`       | Buffers                    | `[LazyVim]`                  |
| `\:`       | Command History            | `[LazyVim]`                  |
| `\sg`      | Grep (Root Dir)            | `[LazyVim]`                  |
| `\sG`      | Grep (cwd)                 | `[LazyVim]`                  |
| `\sB`      | Grep Open Buffers          | `[LazyVim]`                  |
| `\sb`      | Buffer Lines               | `[LazyVim]`                  |
| `\sw`      | 搜尋游標下的字（Root Dir） | `[LazyVim]`                  |
| `\sW`      | 搜尋游標下的字（cwd）      | `[LazyVim]`                  |
| `\sr`      | Search and Replace         | `[LazyVim]`                  |
| `\sR`      | Resume 上次搜尋            | `[LazyVim]`                  |
| `\sh`      | Help Pages                 | `[LazyVim]`                  |
| `\sk`      | Keymaps                    | `[LazyVim]`                  |
| `\sc`      | Command History            | `[LazyVim]`                  |
| `\sC`      | Commands                   | `[LazyVim]`                  |
| `\sa`      | Autocmds                   | `[LazyVim]`                  |
| `\sd`      | Diagnostics                | `[LazyVim]`                  |
| `\sD`      | Buffer Diagnostics         | `[LazyVim]`                  |
| `\si`      | Icons                      | `[LazyVim]`                  |
| `\sj`      | Jumps                      | `[LazyVim]`                  |
| `\sl`      | Location List              | `[LazyVim]`                  |
| `\sm`      | Marks                      | `[LazyVim]`                  |
| `\sM`      | Man Pages                  | `[LazyVim]`                  |
| `\sq`      | Quickfix List              | `[LazyVim]`                  |
| `\sH`      | Highlights                 | `[LazyVim]`                  |
| `\s"`      | Registers                  | `[LazyVim]`                  |
| `\sp`      | Search for Plugin Spec     | `[LazyVim]`                  |
| `\su`      | Undotree                   | `[LazyVim]`                  |
| `\uC`      | Colorschemes               | `[LazyVim]`                  |
| `\?`       | Buffer Keymaps (which-key) | `[LazyVim]`                  |

---

## LSP 功能

| 鍵    | 功能                                 | 來源                |
| ----- | ------------------------------------ | ------------------- |
| `gd`  | 跳轉至定義                           | `[LazyVim]`         |
| `grt` | 跳轉至型別定義                       | `[Neovim]` 原生 LSP |
| `gri` | 跳轉至實作                           | `[Neovim]` 原生 LSP |
| `grr` | 顯示參考                             | `[Neovim]` 原生 LSP |
| `gra` | Code Action                          | `[Neovim]` 原生 LSP |
| `grn` | 擴展選取區塊 / Rename                | `[Neovim]` 原生 LSP |
| `gO`  | Document Symbols                     | `[Neovim]` 原生 LSP |
| `K`   | Hover 說明                           | `[LazyVim]`         |
| `ca`  | LSP Code Action                      | `[LazyVim]`         |
| `\ca` | Code Action                          | `[LazyVim]`         |
| `\cr` | Rename Symbol                        | `[LazyVim]`         |
| `\cf` | Format                               | `[LazyVim]`         |
| `\cF` | Format Injected Langs                | `[LazyVim]`         |
| `\cd` | Line Diagnostics                     | `[LazyVim]`         |
| `\cs` | Symbols (Trouble)                    | `[LazyVim]`         |
| `\cS` | LSP references/definitions (Trouble) | `[LazyVim]`         |
| `\cm` | Mason                                | `[LazyVim]`         |

---

## 診斷 (Diagnostics)

| 鍵       | 功能                     | 來源        |
| -------- | ------------------------ | ----------- |
| `[d`     | 上一個診斷               | `[LazyVim]` |
| `]d`     | 下一個診斷               | `[LazyVim]` |
| `[D`     | 跳到 buffer 第一個診斷   | `[LazyVim]` |
| `]D`     | 跳到 buffer 最後一個診斷 | `[LazyVim]` |
| `[e`     | 上一個 Error             | `[LazyVim]` |
| `]e`     | 下一個 Error             | `[LazyVim]` |
| `[w`     | 上一個 Warning           | `[LazyVim]` |
| `]w`     | 下一個 Warning           | `[LazyVim]` |
| `[q`     | 上一個 Trouble/Quickfix  | `[LazyVim]` |
| `]q`     | 下一個 Trouble/Quickfix  | `[LazyVim]` |
| `<C-W>d` | 顯示游標下的診斷         | `[Neovim]`  |

---

## Git 整合

| 鍵    | 功能                         | 來源                                                          |
| ----- | ---------------------------- | ------------------------------------------------------------- |
| `\gg` | Lazygit (Root Dir)           | `[LazyVim]`                                                   |
| `\gG` | Lazygit (cwd)                | `[LazyVim]`                                                   |
| `\tg` | Lazygit（floaterm 版）       | `[自訂]` `plugins/tools.lua`                                  |
| `\gs` | Git Status                   | `[LazyVim]`                                                   |
| `\gS` | Git Stash                    | `[LazyVim]`                                                   |
| `\gb` | Git Blame Line               | `[LazyVim]`                                                   |
| `\gl` | Git Log                      | `[LazyVim]`                                                   |
| `\gL` | Git Log (cwd)                | `[LazyVim]`                                                   |
| `\gf` | Git Current File History     | `[LazyVim]`                                                   |
| `\gd` | Git Diff (hunks)             | `[LazyVim]`                                                   |
| `\gD` | Git Diff (origin)            | `[LazyVim]`                                                   |
| `\gv` | Diffview：對比目前變更       | `[自訂]` `plugins/neovim-only.lua`                            |
| `\gh` | Diffview：目前檔案歷史       | `[自訂]` `plugins/neovim-only.lua`                            |
| `\gB` | Git Browse (open)            | `[LazyVim]`                                                   |
| `\gY` | Git Browse (copy)            | `[LazyVim]`                                                   |
| `\gi` | GitHub Issues (open)         | `[LazyVim]`                                                   |
| `\gI` | GitHub Issues (all)          | `[LazyVim]`                                                   |
| `\gp` | GitHub Pull Requests (open)  | `[LazyVim]`                                                   |
| `\gP` | GitHub Pull Requests (all)   | `[LazyVim]`                                                   |
| `\lg` | 開啟 LazyGit（lazygit.nvim） | `[自訂]` `plugins/neovim-only.lua` ⚠️ 與 `\gg` 重複，考慮移除 |

> **注意**：`\tg`（floaterm 版）和 `\gg`/`\gG`（LazyVim 版）功能相同，三選一即可。

---

## Terminal 群組

> 全部由 floaterm 提供，統一使用 `\t` 前綴。

| 鍵           | 功能                   | 來源                                 |
| ------------ | ---------------------- | ------------------------------------ |
| `\tc`        | 開新浮動終端           | `[自訂]` `plugins/tools.lua`         |
| `\tt`        | 切換終端顯示           | `[自訂]` `plugins/tools.lua`         |
| `\tp`        | 上一個終端             | `[自訂]` `plugins/tools.lua`         |
| `\tn`        | 下一個終端             | `[自訂]` `plugins/tools.lua`         |
| `\tq`        | 關閉終端               | `[自訂]` `plugins/tools.lua`         |
| `\th`        | 隱藏終端               | `[自訂]` `plugins/tools.lua`         |
| `\tg`        | Lazygit（floaterm 版） | `[自訂]` `plugins/tools.lua`         |
| `\ft`        | Terminal (Root Dir)    | `[LazyVim]` 內建（與 floaterm 並存） |
| `\fT`        | Terminal (cwd)         | `[LazyVim]` 內建（與 floaterm 並存） |
| `<Esc><Esc>` | 退出 terminal mode     | `[自訂]` `keymap/neovim.lua`         |

---

## Trouble 錯誤清單

| 鍵    | 功能                         | 來源        |
| ----- | ---------------------------- | ----------- |
| `\xx` | Diagnostics (Trouble)        | `[LazyVim]` |
| `\xX` | Buffer Diagnostics (Trouble) | `[LazyVim]` |
| `\xq` | Quickfix List (Trouble)      | `[LazyVim]` |
| `\xQ` | Quickfix List (Trouble)      | `[LazyVim]` |
| `\xl` | Location List (Trouble)      | `[LazyVim]` |
| `\xL` | Location List (Trouble)      | `[LazyVim]` |
| `\xT` | Todo/Fix/Fixme (Trouble)     | `[LazyVim]` |
| `\xt` | Todo (Trouble)               | `[LazyVim]` |

---

## Todo 管理

| 鍵    | 功能                | 來源        |
| ----- | ------------------- | ----------- |
| `[t`  | 上一個 Todo Comment | `[LazyVim]` |
| `]t`  | 下一個 Todo Comment | `[LazyVim]` |
| `\st` | Todo                | `[LazyVim]` |
| `\sT` | Todo/Fix/Fixme      | `[LazyVim]` |

---

## Markdown 工具

| 鍵     | 功能                         | 來源                                       |
| ------ | ---------------------------- | ------------------------------------------ |
| `\mpp` | Markdown Preview             | `[自訂]` peek.nvim                         |
| `\mpo` | Peek Open                    | `[自訂]` peek.nvim                         |
| `\mpc` | Peek Close                   | `[自訂]` peek.nvim                         |
| `\ms`  | Stop Preview                 | `[自訂]`                                   |
| `\mt`  | Toggle Preview               | `[自訂]`                                   |
| `\ip`  | 貼上圖片並插入 Markdown 語法 | `[自訂]` `plugins/tools.lua` img-clip.nvim |

---

## UI 切換

| 鍵    | 功能                        | 來源        |
| ----- | --------------------------- | ----------- |
| `\uf` | Toggle Auto Format (Global) | `[LazyVim]` |
| `\uF` | Toggle Auto Format (Buffer) | `[LazyVim]` |
| `\us` | Toggle Spelling             | `[LazyVim]` |
| `\uw` | Toggle Wrap                 | `[LazyVim]` |
| `\ul` | Toggle Line Numbers         | `[LazyVim]` |
| `\uL` | Toggle Relative Number      | `[LazyVim]` |
| `\ud` | Toggle Diagnostics          | `[LazyVim]` |
| `\uc` | Toggle Conceal Level        | `[LazyVim]` |
| `\uT` | Toggle Treesitter Highlight | `[LazyVim]` |
| `\ub` | Toggle Dark Background      | `[LazyVim]` |
| `\uD` | Toggle Dimming              | `[LazyVim]` |
| `\ua` | Toggle Animations           | `[LazyVim]` |
| `\ug` | Toggle Indent Guides        | `[LazyVim]` |
| `\uS` | Toggle Smooth Scroll        | `[LazyVim]` |
| `\uA` | Toggle Tabline              | `[LazyVim]` |
| `\uh` | Toggle Inlay Hints          | `[LazyVim]` |
| `\up` | Toggle Mini Pairs           | `[LazyVim]` |
| `\uI` | Inspect Tree                | `[LazyVim]` |
| `\ui` | Inspect Pos                 | `[LazyVim]` |
| `\uC` | Colorschemes                | `[LazyVim]` |
| `\un` | Dismiss All Notifications   | `[LazyVim]` |
| `\n`  | Notification History        | `[LazyVim]` |

---

## Flash 跳轉

| 鍵    | 功能                | 來源                   |
| ----- | ------------------- | ---------------------- |
| `s`   | Flash 跳轉          | `[LazyVim]` flash.nvim |
| `S`   | Flash Treesitter    | `[LazyVim]` flash.nvim |
| `\hf` | [H]op [F]lash       | `[自訂]`               |
| `\hF` | Flash Treesitter    | `[自訂]`               |
| `\he` | Toggle Flash Search | `[自訂]`               |

---

## Surround 操作

| 鍵           | 功能                           | 來源                      |
| ------------ | ------------------------------ | ------------------------- |
| `ys{motion}` | 新增 surrounding               | `[LazyVim]` nvim-surround |
| `yss`        | 新增 surrounding（整行）       | `[LazyVim]` nvim-surround |
| `yS{motion}` | 新增 surrounding（新行）       | `[LazyVim]` nvim-surround |
| `ySS`        | 新增 surrounding（整行，新行） | `[LazyVim]` nvim-surround |
| `cs`         | 修改 surrounding               | `[LazyVim]` nvim-surround |
| `cS`         | 修改 surrounding（新行）       | `[LazyVim]` nvim-surround |
| `ds`         | 刪除 surrounding               | `[LazyVim]` nvim-surround |
| `g[`         | 移到左側 "around"              | `[LazyVim]`               |
| `g]`         | 移到右側 "around"              | `[LazyVim]`               |

---

## 程式碼註解

| 鍵      | 功能                         | 來源            |
| ------- | ---------------------------- | --------------- |
| `gc`    | 切換註解（motion）           | `[Neovim]` 原生 |
| `gcc`   | 切換整行註解                 | `[Neovim]` 原生 |
| `gco`   | 在下方新增註解               | `[Neovim]` 原生 |
| `gcO`   | 在上方新增註解               | `[Neovim]` 原生 |
| `<C-/>` | 切換整行註解                 | `[LazyVim]`     |
| `<C-_>` | 切換整行註解（同上，相容性） | `[LazyVim]`     |

---

## Treesitter 選取

| 鍵          | 功能              | 來源                   |
| ----------- | ----------------- | ---------------------- |
| `<C-Space>` | 初始化 / 擴展選取 | `[LazyVim]` treesitter |
| `gnn`       | 初始化選取區塊    | `[LazyVim]` treesitter |
| `grc`       | 擴展至範圍        | `[LazyVim]` treesitter |
| `grm`       | 縮減選取區塊      | `[LazyVim]` treesitter |
| `[i`        | 跳到 scope 上緣   | `[LazyVim]`            |
| `]i`        | 跳到 scope 下緣   | `[LazyVim]`            |

---

## Noice 通知

| 鍵     | 功能                     | 來源                   |
| ------ | ------------------------ | ---------------------- |
| `\sn`  | +noice 群組              | `[LazyVim]` noice.nvim |
| `\snl` | Noice Last Message       | `[LazyVim]` noice.nvim |
| `\snh` | Noice History            | `[LazyVim]` noice.nvim |
| `\sna` | Noice All                | `[LazyVim]` noice.nvim |
| `\snd` | Dismiss All              | `[LazyVim]` noice.nvim |
| `\snt` | Noice Picker (Telescope) | `[LazyVim]` noice.nvim |

---

## Session 管理

| 鍵     | 功能                       | 來源        |
| ------ | -------------------------- | ----------- |
| `\qs`  | Restore Session            | `[LazyVim]` |
| `\ql`  | Restore Last Session       | `[LazyVim]` |
| `\qS`  | Select Session             | `[LazyVim]` |
| `\qd`  | Don't Save Current Session | `[LazyVim]` |
| `\S`   | Select Scratch Buffer      | `[LazyVim]` |
| `\.`   | Toggle Scratch Buffer      | `[LazyVim]` |
| `\dps` | Profiler Scratch Buffer    | `[LazyVim]` |
| `\dpp` | Toggle Profiler            | `[LazyVim]` |
| `\dph` | Toggle Profiler Highlights | `[LazyVim]` |

---

## 其他工具

| 鍵                | 功能                     | 來源        |
| ----------------- | ------------------------ | ----------- |
| `<C-Q>`           | Visual Block mode        | `[自訂]`    |
| `<C-F>`           | 向前捲動                 | `[Neovim]`  |
| `<C-B>`           | 向後捲動                 | `[Neovim]`  |
| `<Up>` / `<Down>` | 上下移動（command line） | `[LazyVim]` |

---

## 自訂 Keymap 彙整

> 快速查閱所有個人設定的快捷鍵及其所在檔案。

| 鍵           | 功能                    | 檔案                                       |
| ------------ | ----------------------- | ------------------------------------------ |
| `<Tab>`      | 下一個 Buffer           | `keymap/neovim.lua`                        |
| `<S-Tab>`    | 上一個 Buffer           | `keymap/neovim.lua`                        |
| `\bd`        | 刪除 Buffer             | `keymap/neovim.lua`                        |
| `\sv`        | 垂直分割                | `keymap/neovim.lua`                        |
| `\sh`        | 水平分割                | `keymap/neovim.lua`                        |
| `\sx`        | 關閉分割                | `keymap/neovim.lua`                        |
| `\sr`        | 取代游標下的字          | `keymap/neovim.lua`                        |
| `<Esc><Esc>` | 退出 terminal mode      | `keymap/neovim.lua`                        |
| `\tc`        | 開新浮動終端            | `plugins/tools.lua`                        |
| `\tt`        | 切換終端                | `plugins/tools.lua`                        |
| `\tp`        | 上一個終端              | `plugins/tools.lua`                        |
| `\tn`        | 下一個終端              | `plugins/tools.lua`                        |
| `\tq`        | 關閉終端                | `plugins/tools.lua`                        |
| `\th`        | 隱藏終端                | `plugins/tools.lua`                        |
| `\tg`        | Lazygit（floaterm）     | `plugins/tools.lua`                        |
| `\ff`        | Find Files              | `plugins/tools.lua`                        |
| `\fg`        | Live Grep               | `plugins/tools.lua`                        |
| `\fb`        | Buffers                 | `plugins/tools.lua`                        |
| `\fh`        | Help Tags               | `plugins/tools.lua`                        |
| `\fr`        | Recent Files            | `plugins/tools.lua`                        |
| `\fw`        | Find Word               | `plugins/tools.lua`                        |
| `\ip`        | 貼上圖片                | `plugins/tools.lua`                        |
| `\lg`        | LazyGit（lazygit.nvim） | `plugins/neovim-only.lua` ⚠️ 與 `\gg` 重複 |
