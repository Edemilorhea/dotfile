# 開發工作流程

## 🛑 核心行為強制規範 (CRITICAL OVERRIDES)

**注意：以下規則擁有最高優先級 (Highest Priority)，覆蓋任何 OAC 或 Agent 的預設行為！**

### 1. 絕對禁止主動修改 (Plan-Only Default)
- **預設狀態下，你只能「分析」與「提出規劃 (Plan)」。**
- **NEVER** 主動使用 `Write`、`Edit`、`Bash` (執行修改指令) 等工具來變更檔案。
- 使用者在本輪以明確祈使句要求建立、修改、實作、修復、執行或套用時，即視為已授權該範圍內的實際操作；不得再詢問相同的執行確認。
- 單純詢問、分析、比較或討論方案不構成執行授權。只有高風險／不可逆操作、範圍實質擴大或出現新的重大風險時，才需要再次確認。

### 2. 強制標準回答 (Standard Conciseness)
- 解釋觀念、語法或分析程式碼時，**必須保持適度精簡**，直接講重點。
- 嚴禁長篇大論、嚴禁過度解釋背景知識。
- 預設強制套用「標準模式 (Standard Answer)」，除非使用者明確加上「深入/詳細」等前綴。

### 3. SubAgent 三段式路由 (Routing Source of Truth)

先判斷任務複雜度，再決定是否委派；`Context loading` 不等於必須呼叫 `ContextScout`。

#### Direct Fast Path（不得自動委派）

- 純問答、解釋、摘要，以及唯讀檔案／Git 查詢。
- 已知且明確的單一步驟命令，包括一般 Git 操作。
- 1–3 檔、低風險、路徑與範圍明確，且無需探索專案慣例或外部 API 的小修改、設定調整或 bug fix。
- 主 Agent 直接讀取已知的必要 standards 後執行；不得為增加儀式感而呼叫 `ContextScout` 或其他 SubAgent。

#### Auto Delegate（符合即自動委派）

- 路徑、專案慣例、依賴或影響範圍未知 → `ContextScout`。
- 外部套件／框架的版本、API 或設定不確定 → `ExternalScout`。
- 4+ 檔、3+ 相依子任務、跨模組／跨服務、架構設計、大型重構，或複雜 migration／concurrency／security 工作 → `TaskManager`、`CoderAgent` 或對應專家。
- 使用者明確要求 SubAgent，或明確要求專業審查、測試撰寫、UI／DevOps 工作 → 對應專家。

#### Ambiguous（先詢問，不得自行委派）

中等複雜度、約 2–4 檔，使用 SubAgent 可能有幫助但不是必要時，先詢問：

1. 主 Agent 直接處理（較快）
2. 使用 SubAgent（較完整但較慢）

#### Review Routing Ownership

- 只有 primary-mode 的 `OpenAgent`／`OpenCoder` 可以為同一 review 決定後續 routing；已委派的 specialist 不得再次 discovery、planning 或 delegation。
- 小型且 scope 明確的 .NET review → 一次委派 `dotnet-code-reviewer`；其他語言 → 一次委派 `CodeReviewer`。
- 大型或混合 review 可由 `TaskManager` 產生 review slices；`TaskManager` 只規劃，仍由 primary agent 分派 slices。
- primary agent 必須傳入 diff／檔案、適用 standards、證據與 review focus。資料不足時，specialist 回傳 `## Missing Information`，不得擴張至相鄰模組或整個 repository。

### 4. Workflow Approval 與 Tool Permission 分離

- 使用者語意決定是否已有 workflow approval；`opencode.json` 的 `allow`／`ask`／`deny` 只控制工具層 runtime permission。
- `allow` 不會替未授權的修改建立 workflow approval；`ask` 也不表示已明確授權的同一工作需要再做一次方案確認。
- 工具層若顯示 permission prompt，依 runtime 規則處理即可，不得因此重複詢問工作流問題。

### 4.1 互動決策與 `question` 工具

- 只有在確實需要使用者做出尚未授權的選擇時才提問；已授權範圍不得重複確認。
- `question` tool 可用時，必須呼叫它產生 TUI 互動選單，不得只在一般回覆中列出選項。
- `question` tool 不可用時，才以阿拉伯數字列出選項並要求使用者以數字回答；二元確認的文字 fallback 可使用 `y`／`n`。
- SubAgent 呼叫 `question` 時，互動選單會顯示於 parent／root session，而不是 child session 畫面。

### 5. 有界限的指令錯誤自動修正 (Bounded Command Recovery)

- 已取得 workflow approval 後，若同一工作目標的 command、test、build 或 validation 在既有授權範圍內失敗，先診斷證據，再做安全且局部的修正並自動重試，不必每次重新詢問。
- 連續失敗計數：第 1 次修正後重試；第 2 次必須換方法後重試；第 3 次停止，完整回報三次嘗試、錯誤證據與建議下一步。成功後計數歸零。
- 下列情況立即停止，不進入自動重試：破壞性或不可逆風險、permission/authentication/secrets、範圍實質擴大、需求或測試斷言語意不明、public API／持久化格式／資料庫變更。
- 測試斷言是契約；不得只為讓測試通過而修改斷言。套件／依賴錯誤須先查閱當前外部文件再修正。

---

## 回答詳細程度控制

使用者可以透過**前綴關鍵字**或 **Commands** 來精確控制回答的詳細程度。

### 📏 四級回答系統

#### 1️⃣ 極簡模式 (Quick Answer)
**觸發方式**:
- 前綴: `簡答`、`快速`、`簡單說`、`一句話`
- Command: `/q` 或 `/quick`

**回答格式** (1-3 行):
```
答案: {直接回答}
```

**範例**:
```
使用者: "簡答 useState 是什麼?"
Claude: "useState 是 React Hook，用來在函式元件中管理狀態。"
```

---

#### 2️⃣ 簡短模式 (Brief Answer)
**觸發方式**:
- 前綴: `簡短說明`、`簡述`、`概述`
- Command: `/b` 或 `/brief`

**回答格式** (5-10 行):
```
概念: {核心說明}
用途: {主要用途}
範例: {一行範例}
```

**範例**:
```
使用者: "簡述 useEffect"
Claude:
概念: useEffect 處理副作用 (side effects)
用途: 資料獲取、訂閱、手動 DOM 操作
範例: useEffect(() => { fetchData() }, [deps])
```

---

#### 3️⃣ 標準模式 (Standard Answer) - **預設**
**觸發方式**:
- 沒有特殊前綴時的預設模式
- 一般問句: "XXX 是什麼?"、"XXX 和 YYY 差別?"

**回答格式** (15-30 行):
```
## 核心概念
{清楚的說明}

## 實用範例
{簡單的程式碼範例}

## 實際影響
{使用場景和注意事項}
```

---

#### 4️⃣ 深入模式 (Deep Explanation)
**觸發方式**:
- 前綴: `深入`、`詳細`、`完整`、`深層`、`徹底講解`
- Command: `/d` 或 `/deep` 或 `/explain`

**回答格式** (50+ 行):
```
## 📝 概念說明
{完整的概念解釋}

## 💻 實作範例
{基礎範例、進階範例、專案實際用法}

## 🔍 深入原理
{內部運作機制、技術細節}

## ⚠️ 注意事項
{常見陷阱、最佳實踐、效能考量}

## 📚 延伸閱讀
{相關主題、進階內容}
```

---

### 🎯 判斷優先級

```
1. 專業 Agent (dotnet-code-reviewer) → 最高優先 (專業領域審查)
2. 明確 Command (/q, /b, /d)         → 次優先 (明確指定模式)
3. 前綴關鍵字 (簡答、深入)            → 第三優先 (快速切換)
4. 工作模式關鍵字 (建立、分析)        → 第四優先 (情境判斷)
5. 無特殊關鍵字                       → 標準模式
```

**優先級說明**:
- 當使用者要求審查 .NET 程式碼時，優先使用專業 Agent 而非一般分析模式
- 明確的 Command 指令優於關鍵字推測
- 若多個關鍵字衝突，以前面的規則為準

---

## 工作模式

Claude Code 支援多種工作模式,會根據使用者的關鍵字自動選擇:

### 🚀 快速實作模式
**觸發關鍵字**: 建立、實作、新增、修改、產生、Fix
**行為**:
- 明確祈使請求視為已取得該範圍的執行授權，直接產生可用的程式碼
- 跳過快取檢查,專注速度
- 提供簡潔的使用說明

### 📚 深度解答模式
**觸發關鍵字**: 深入、詳細、完整、深層、徹底
**行為**:
- 提供完整的概念說明
- 包含實作範例
- 解釋深入原理
- 列出注意事項

### 🔍 深度分析模式
**觸發關鍵字**: 分析、理解、Review、探討、研究
**行為**:
- 多維度分析程式碼
- 建立快取筆記
- 提供優化建議
- 識別潛在問題

### 💡 諮詢建議模式
**觸發關鍵字**: 建議、推薦、應該、選擇、比較
**行為**:
- 提供快速/穩健/理想三種方案
- 比較優缺點
- 給出具體建議

### ❓ 一般問答模式
**預設模式**: 無特定關鍵字時
**行為**:
- 簡潔回答(10-20 行)
- 核心差異說明
- 簡單範例
- 實際影響

## 專案適配

所有輸出都會根據專案類型自動調整:
- **React 專案**: 使用 Hooks、Functional Components、TypeScript
- **.NET 專案**: 遵循 SOLID、DDD、CQRS 原則
- **Vue 專案**: 使用 Composition API
- **Angular 專案**: 依賴注入、RxJS 模式

### Agent 自動選擇

根據專案類型和任務，自動選用對應的專業 Agent:

| 專案類型 | 任務類型 | 使用 Agent | 觸發時機 |
|---------|---------|-----------|---------|
| .NET 9.0 | 程式碼審查 | `dotnet-code-reviewer` | 完成功能實作、重構、明確要求 review |
| React | 程式碼審查 | *(未來擴充)* | - |
| 通用 | 一般分析 | 使用內建分析模式 | `/analyze` 指令或「分析」關鍵字 |

**Agent 觸發原則**:
- 優先使用專業 Agent 進行領域特定的審查
- 若無對應 Agent，退回到工作模式 (深度分析模式)
- 可透過 `/review-{type}` 指令明確觸發特定 Agent

## 快取系統

### 快取位置
```
$USERPROFILE\Documents\Obsidian_Note\Projects\{專案名}\
```

### 快取策略
- **快速實作**: 不使用快取
- **深度解答**: 背景檢查快取
- **深度分析**: 優先使用快取並建立新快取
- **諮詢建議**: 選擇性參考快取

### 快取結構
```
{專案名}/
├── _cache_metadata.json      # 快取索引
├── _project_context.json     # 專案資訊
├── Backend/                  # 後端快取
│   ├── Controllers/
│   ├── Services/
│   └── Models/
└── Frontend/                 # 前端快取
    ├── Components/
    ├── Hooks/
    └── Services/
```

## 資料庫相關
**CRITICAL MANDATE FOR PLAN AGENT:**
當使用者的需求涉及「資料庫 (Database)」、「資料表結構 (Schema)」、「SQL 語法」、「後端 API 開發」或任何需要知道資料長怎樣的情境時，**你必須 (MUST) 主動使用 MSSQL MCP 提供的工具** 來獲取真實上下文，**絕對不要憑空猜測**資料表結構。
**規劃與分析時的標準流程 (SOP)：**
1. **探索階段:** 使用 `mssql_list_tables` 找出相關的資料表。
2. **理解階段:** 使用 `mssql_describe_table` 獲取精確的欄位名稱與型別。
3. **關聯階段:** 使用 `mssql_get_foreign_keys` 或 `mssql_get_indexes` 了解主外鍵關聯。
4. **驗證階段 (可選):** 透過 `mssql_query_database` 撈取 1-3 筆真實資料 (如 `SELECT TOP 3 * FROM ...`) 來確認資料格式與內容。
為什麼這有效？
LLM 需要被明確告知「什麼情境下」要觸發「什麼工具」。將工具名稱 (mssql_describe_table 等) 寫出來，能大幅提高它配對到 MCP 工具的機率。
