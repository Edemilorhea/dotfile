---
name: implementation-understanding-report-contract
description: Use ONLY when implementation-understanding-tutor explicitly delegates report composition or six-layer coverage. Do not trigger independently for general explanations, code review, or repository analysis.
---

# Implementation Understanding Report Contract

這是 `implementation-understanding-tutor` 的受控 supporting contract。只處理六層 report 的內容完整性與組裝，不自行改變 scope、focus、learning mode、標題順序或 Orchestrator 已選定的共同例子。

## Report 完整性

六層用於蒐集 evidence、追蹤 coverage，以及產生 `report`。Report 不得改序或省略主章節：

1. **功能全貌與初始心智圖**：先回答為何存在、誰觸發、從哪裡開始、何時算完成。
2. **完整操作流**：先建立一次操作的時間順序，再列分支。
3. **逐步四流對齊**：在每個操作步驟內同步解釋 Logic、Data、Program、State。
4. **Method 與 Code（Code Teach）**：交由 `implementation-understanding-code-teach-contract`。
5. **Change、設計理由與驗證**：把前後差異、理由與證據映射回操作步驟。
6. **完整心智模型**：重組同一筆資料的生命週期、invariants、未知與自我檢查。

六層完整代表資訊類型不能遺漏，不代表每層必須等長。`depth` 控制展開程度。沒有資料時明寫 `Not applicable`、`Not investigated`、`Unknown` 或 `No evidence found`，不得靜默刪除章節。

## Layer 1：功能全貌與初始心智圖

固定包含：範圍與不涵蓋內容、business problem、actors/use case、trigger、完成條件、主要 modules/boundaries、data ownership、每個主要 component 的責任與排除責任、downstream consumers、3 至 7 步初始地圖、共用具體例子。

## Layer 2：完整操作流

固定包含：前置條件、trigger、主要成功路徑、每一步的 responsibility/result/handoff/downstream impact、同步/非同步區段、transaction boundaries、external effects、observable result、分支清單。先完成主路徑，再列失敗與替代分支。

## Layer 3：逐步四流對齊

為 Layer 2 的每個主要步驟固定輸出：

- **Logic**：規則、decision、branch。
- **Data**：input shape、transformation、transport、persistence。
- **Program**：caller、callee、return 或 event handoff。
- **State**：domain、memory、DB、queue、external side effect。
- **Boundary**：API、process、transaction、queue 或 external system boundary；沒有則寫 `Not applicable`。
- **Evidence**：`file:line-range` 與 confidence。

不要先產生四份獨立 flow 報告。應以 operation step 為主軸，將四種 flow 放在同一步內。

## Layer 5：Change、設計理由與驗證

固定包含：

- **Before / After**：baseline、行為差異與 old/current evidence。
- **Change Map**：`[ADDED]`、`[MODIFIED]`、`[REMOVED]`，每項映射到 Layer 2/3 的步驟。
- **Design Rationale**：分開列 Confirmed、Inferred、Unknown、constraint 與 trade-off。
- **Tests Present**：只陳述找到的測試及可能覆蓋範圍。
- **Verification Plan**：command/experiment、輸入、預期觀察。
- **Actual Execution Evidence**：只有真的執行才寫 passed/failed，附 command 與輸出摘要；否則寫 `Not run`。
- **Unknowns**：未證實的理由、caller、branch 或環境行為。

不得把「測試存在」寫成「測試通過」，也不得沿用沒有可追溯輸出的執行宣稱。`verification=none` 時保留三個驗證欄位並寫 `Not requested` 或 `Not run`。

## Layer 6：完整心智模型

固定包含：文字心智圖、同一筆資料生命週期、5 至 7 句完整重述、invariants、自我檢查題、未追蹤路徑。Layer 6 只能重組 Layer 1 至 5 已證實或已標記的內容，不得新增事實。

## Code Teach Report

`report` 遇到明確 Code Teach 仍必須以 Layer 4 為主體。先明確載入 `implementation-understanding-code-teach-contract`；Layer 1 至 Layer 3 只提供讀 code 所需的 orientation，不得讓 change inventory、機制摘要或 causal nodes 佔據主要篇幅。每個重要 method/group 都必須引用 bounded actual code 並沿 execution order 教學。

明確 Code Teach 加 `report` 時，Layer 1 至 Layer 3 合計最多 3 至 7 個主要 orientation items；Layer 3 可在每個 item 內緊湊對齊 Logic/Data/Program/State/Boundary/Evidence。保留三個 exact headings 與必要資訊，但不得在 Layer 4 actual code 前展開 branches、完整 inventory 或非必要 mechanism。

## Report Headings

```markdown
# [target] Implementation Understanding

## Layer 1：功能全貌與初始心智圖

## Layer 2：完整操作流

## Layer 3：逐步四流對齊

## Layer 4：Method 與 Code

## Layer 5：Change、設計理由與驗證

## Layer 6：完整心智模型
```

需要中型完整範例時，由 Orchestrator 讀取其 `references/full-feature-example.md`。該檔案是格式與資訊密度的 golden example，不是真實專案的事實來源。
