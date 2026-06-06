# Nu Shell 官方文件導讀指南

> 目標：學習 Nu Shell 作為主力 Shell
> 適用版本: Nushell 0.112+
> 最後更新: 2025-05-19

---

## 📖 文件總覽

Nu Shell 官方文件網站：https://www.nushell.sh/book/

---

## 🔴 必讀（優先順序最高，建議依序閱讀）

這些章節涵蓋 Nu Shell 的核心概念和日常使用，**學完就能順暢操作**。

### 1. [Thinking in Nushell](https://www.nushell.sh/book/thinking_in_nu.html)
- **為什麼必讀**：Nu 和 Bash/PowerShell 的思維差異
- **重點內容**：結構化資料、管道、強型別、錯誤處理
- **預估時間**：15 分鐘
- **建議**：開始用 Nu 之前先看，避免帶著 Bash 思維用 Nu

### 2. [Moving around](https://www.nushell.sh/book/moving_around.html)
- **為什麼必讀**：基本操作（cd, ls, pwd, paths）
- **重點內容**：Glob 模式、路徑操作、特殊目錄（~, ., ..）
- **預估時間**：10 分鐘

### 3. [Types of data](https://www.nushell.sh/book/types_of_data.html)
- **為什麼必讀**：Nu 的型別系統是核心特色
- **重點內容**：Int, Float, String, Bool, Date, Duration, Filesize, Binary, List, Table, Record
- **預估時間**：20 分鐘
- **重點**：理解 `filesize` (10KB, 5MB)、`duration` (2min, 3hr) 這種 Nu 獨有型別

### 4. [Loading data](https://www.nushell.sh/book/loading_data.html)
- **為什麼必讀**：Nu 最強大的功能之一
- **重點內容**：`open` 指令（自動辨識 JSON, CSV, TOML, YAML, SQLite, Excel）
- **預估時間**：15 分鐘
- **實用範例**：`open data.json | where status == active | to csv`

### 5. [Working with lists](https://www.nushell.sh/book/working_with_lists.html)
- **為什麼必讀**：List 是管道操作基礎
- **重點內容**：`each`, `where`, `filter`, `reduce`, `append`, `prepend`
- **預估時間**：15 分鐘

### 6. [Working with tables](https://www.nushell.sh/book/working_with_tables.html)
- **為什麼必讀**：Table 是 Nu 的核心資料結構
- **重點內容**：`select`, `get`, `sort-by`, `group-by`, `join`, `flatten`
- **預估時間**：20 分鐘
- **重點**：這是 Nu 和傳統 Shell 最大的差異所在

### 7. [Pipeline](https://www.nushell.sh/book/pipeline.html)
- **為什麼必讀**：理解管道如何傳遞結構化資料
- **重點內容**：`|` 管道、`$in` 變數、多行管道
- **預估時間**：10 分鐘

### 8. [Configuration](https://www.nushell.sh/book/configuration.html)
- **為什麼必讀**：自訂你的 Shell 環境
- **重點內容**：`config.nu`, `env.nu`, `$env.config` 結構
- **預估時間**：20 分鐘
- **建議**：搭配本文的 [nu-shell-config-guide.md](nu-shell-config-guide.md) 一起學

### 9. [Custom commands](https://www.nushell.sh/book/custom_commands.html)
- **為什麼必讀**：寫自己的函數和別名
- **重點內容**：`def`, `def --env`, 參數型別、標誌參數（flags）
- **預估時間**：20 分鐘
- **實用性**：⭐⭐⭐⭐⭐ 每天寫 Nu 都會用到

### 10. [Environment](https://www.nushell.sh/book/environment.html)
- **為什麼必讀**：管理環境變數和 PATH
- **重點內容**：`$env`, `load-env`, `hide-env`, PATH 操作
- **預估時間**：15 分鐘

---

## 🟡 建議讀（提升生產力，1-2 週內學完）

這些章節讓你從「會用」變成「用好」，建議在熟悉基本操作後閱讀。

### 11. [Variables and subexpressions](https://www.nushell.sh/book/variables_and_subexpressions.html)
- **內容**：`let`, `mut`, `const`, `$()` 子表達式
- **重要性**：理解不可變性（immutability）和變數作用域
- **預估時間**：15 分鐘

### 12. [Operators](https://www.nushell.sh/book/operators.html)
- **內容**：數學運算、邏輯運算、正則匹配（`=~`, `!~`）
- **重要性**：寫條件判斷時必備
- **預估時間**：10 分鐘

### 13. [Conditions](https://www.nushell.sh/book/conditions.html)
- **內容**：`if`, `match`, `match -i`
- **重要性**：流程控制基礎
- **預估時間**：15 分鐘
- **重點**：`match` 是 Nu 強大的模式匹配

### 14. [Loops](https://www.nushell.sh/book/loops.html)
- **內容**：`for`, `while`, `loop`, `break`, `continue`
- **重要性**：自動化任務
- **預估時間**：10 分鐘
- **建議**：Nu 中多用 `each` 和管道，少用傳統迴圈

### 15. [Modules](https://www.nushell.sh/book/modules.html)
- **內容**：組織和重用程式碼
- **重要性**：設定檔變大後需要模組化管理
- **預估時間**：20 分鐘
- **實用性**：中大型設定必備

### 16. [Overlays](https://www.nushell.sh/book/overlays.html)
- **內容**：臨時切換環境（類似 Python venv）
- **重要性**：管理不同專案環境
- **預估時間**：15 分鐘

### 17. [Working with strings](https://www.nushell.sh/book/working_with_strings.html)
- **內容**：字串插值、多行字串、字串操作
- **重要性**：字串處理是日常操作
- **預估時間**：15 分鐘
- **重點**：`$"Hello ($name)"` 插值語法

### 18. [Date and time](https://www.nushell.sh/book/date_and_time.html)
- **內容**：日期運算、格式化、時區
- **重要性**：日誌分析、檔案管理常用
- **預估時間**：10 分鐘

### 19. [Regular expressions](https://www.nushell.sh/book/regular_expressions.html)
- **內容**：`find`, `str find`, `str replace` 搭配 regex
- **重要性**：文字過濾和取代
- **預估時間**：15 分鐘

### 20. [Parallelism](https://www.nushell.sh/book/parallelism.html)
- **內容**：`par-each` 平行處理
- **重要性**：大量資料處理加速
- **預估時間**：10 分鐘

---

## 🟢 需要再讀（遇到問題時查閱）

這些章節偏進階或特定場景，不需要一次讀完，**遇到相關需求時再查**。

### 21. [Nu as a shell](https://www.nushell.sh/book/nu_as_a_shell.html)
- **場景**：理解 Shebang (`#!/usr/bin/env nu`)、登入 Shell 設定
- **建議**：寫 Nu 腳本檔案時再看

### 22. [Command signing](https://www.nushell.sh/book/command_signing.html)
- **場景**：企業環境需要指令簽名驗證
- **建議**：有資安需求時再看

### 23. [Shells in shells](https://www.nushell.sh/book/shells_in_shells.html)
- **場景**：同時在多個目錄操作，類似 Zsh 的 `dirstack`
- **建議**：需要快速切換多個工作目錄時再看

### 24. [Escaping commands](https://www.nushell.sh/book/escaping_commands.html)
- **場景**：呼叫外部指令時參數有特殊字元
- **建議**：遇到引號或特殊字元問題時查閱

### 25. [Plugins](https://www.nushell.sh/book/plugins.html)
- **場景**：擴展 Nu 功能（自訂指令、新資料型別）
- **建議**：需要寫 Rust 插件時再看

### 26. [Coloring and theming in Nu](https://www.nushell.sh/book/coloring_and_theming.html)
- **場景**：自訂表格顏色、語法高亮
- **建議**：想要美化輸出時再看

### 27. [Coming from Bash](https://www.nushell.sh/book/coming_from_bash.html)
- **場景**：Bash 轉 Nu 的對照表
- **建議**：忘記某個 Bash 指令在 Nu 怎麼寫時查閱
- **替代**：也可以查本文的 [nu-shell-cheatsheet.md](nu-shell-cheatsheet.md)

### 28. [Coming from CMD](https://www.nushell.sh/book/coming_from_cmd.html)
- **場景**：CMD 轉 Nu
- **建議**：很少需要

### 29. [Scripts](https://www.nushell.sh/book/scripts.html)
- **場景**：寫獨立的 `.nu` 腳本檔案
- **建議**：需要寫可重複使用的腳本時再看

### 30. [Testing](https://www.nushell.sh/book/testing.html)
- **場景**：為 Nu 腳本寫單元測試
- **建議**：腳本變複雜、需要測試時再看

---

## 📅 建議學習路徑

### 第 1 天：建立基礎（2-3 小時）
1. `Thinking in Nushell` → 建立正確思維
2. `Moving around` + `Types of data` → 基本操作
3. `Loading data` + `Working with tables` → 核心特色

### 第 1 週：日常操作（每天 30 分鐘）
4. `Pipeline` + `Custom commands` → 寫自己的工具
5. `Environment` + `Configuration` → 設定環境
6. `Working with lists` + `Working with strings` → 資料處理

### 第 2-3 週：提升效率
7. `Variables and subexpressions` + `Operators`
8. `Conditions` + `Loops`
9. `Modules` + `Overlays`

### 持續：遇到問題時查閱
- 需要寫腳本 → 查 `Scripts`, `Nu as a shell`
- 需要平行處理 → 查 `Parallelism`
- 需要外掛 → 查 `Plugins`

---

## 🛠️ 實踐建議

| 階段 | 任務 |
| --- | --- |
| **第 1 天** | 把 Bash/PowerShell 別名全部轉成 Nu 的 `alias` 和 `def` |
| **第 1 週** | 每天找一個原本用 Bash 做的操作，改用 Nu 的管道方式重寫 |
| **第 2 週** | 開始用 Nu 腳本處理原本用 Python/Node 做的簡單資料處理 |
| **持續** | 每學到一個新指令，用 `help 指令名` 查看用法和範例 |

---

## 🔗 官方資源

| 資源 | 網址 | 用途 |
| --- | --- | --- |
| 官方文件 | https://www.nushell.sh/book/ | 主要學習來源 |
| 指令參考 | https://www.nushell.sh/commands/ | 查指令用法 |
| GitHub | https://github.com/nushell/nushell | 原始碼、Issues |
| Discord | https://discord.gg/NtAbbGn | 社群討論 |
| 範例腳本 | https://github.com/nushell/nu_scripts | 社群貢獻的實用腳本 |

---

## 💡 學習心法

1. **接受結構化思維**：放棄「一切皆字串」的想法，擁抱表格和 List
2. **多用管道**：`ls | where size > 1MB | sort-by modified` 這種寫法會上癮
3. **善用 `help`**：`help commands`, `help 指令名`, `help --find 關鍵字`
4. **從 Bash 思維轉換**：不要想「Bash 怎麼做」，要想「Nu 最適合怎麼做」

---

> **總結**：先讀完 🔴 必讀（約 2-3 小時），你就能順暢使用 Nu Shell。之後邊用邊讀 🟡 建議，遇到特定問題再查 🟢 需要再讀。
