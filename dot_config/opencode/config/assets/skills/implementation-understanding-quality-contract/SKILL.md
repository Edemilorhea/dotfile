---
name: implementation-understanding-quality-contract
description: Use ONLY when implementation-understanding-tutor explicitly delegates evidence routing, communication gates, verification separation, or final quality checks. Do not trigger independently for ordinary code review.
---

# Implementation Understanding Quality Contract

這是 `implementation-understanding-tutor` 的受控 supporting contract。所有實質教學都必須載入本 contract。它管理 communication skills、specialist evidence、證據規則、verification separation 與輸出前檢查，但不改變 Orchestrator 選定的 scope、mode 或格式。

## Communication Skills

產生任何實質教學前，明確載入 `iso-24495-plain-language` 與 `asd-ste100`。前者控制資訊架構；後者控制句子與術語清晰度。中文內容只採用清晰原則，不宣稱正式符合 STE。

Mechanism 的 `eli5-explainer` 與 `wait-what` gate 由 `implementation-understanding-mechanism-contract` 管理。Actual Code Teach 的 `vibe-coding-tutor` gate 由 `implementation-understanding-code-teach-contract` 管理。提及 skill 名稱不代表已載入；適用時必須明確載入。

## Evidence Routing

Specialist 只提供標準化 evidence，不得決定最終標題、順序或語氣：

- `change-understanding-review`：提供 baseline、Before/After、change units、change intent 與 changed ranges。
- `feature-flow-explainer`：提供 caller、runtime/data/state flow、transaction、async boundary 與 current/target wiring。
- `vibe-coding-tutor`：Code Teach 必須載入；提供 project map、architecture walkthrough、key patterns、已知難點、最小練習與 extension points；不得另起一份 tutorial 報告。
- Orchestrator：選同一個 request、entity、ID 或 payload，去重 evidence；report 映射到六層，guided 映射到目前四視角 learning unit。

禁止逐字拼貼 specialist 報告、保留 specialist 自有章節、重複描述同一條 flow，或讓 specialist 決定輸出格式。缺少 specialist 時，使用可取得的 repository 證據繼續，並標記限制。

## 證據規則

1. 每個 code-specific claim 附目前版本的 `file:line-range`。舊版證據標成 old/diff range。
2. 先找實際 caller，再描述 runtime 順序。Interface、registration 或 method 存在不代表已執行。
3. 每個重要主張標示 **Confirmed**、**Inferred** 或 **Unknown**。Inferred 必須寫推導依據；Unknown 不替作者補故事。
4. 區分目前實作、目標設計與建議。不得混寫。
5. 主路徑先於 branches、edge cases、alternatives 與完整證據清單。
6. 使用同一個具體例子貫穿六層。不要每層更換 request、ID、payload 或比喻。
7. 不讀 secrets、credentials、`.env` 或 generated dependency directories。遵守最近的 repository instructions。

## Verification Separation

Tests Present、Verification Plan、Actual Execution Evidence 必須分開。不得把「測試存在」寫成「測試通過」，也不得沿用沒有可追溯輸出的執行宣稱。只有真的執行才寫 passed/failed，並附 command 與輸出摘要。

## 輸出前 Checklist

- 模式符合使用者範圍；`auto` 未任意縮成 Focused。
- Report 使用六層；guided/teach-back 使用四視角 learning units，沒有把內部六層 ledger 整份倒給讀者。
- 明確 Code Teach 已優先於「完整／所有修改」等範圍詞；沒有錯誤落回純 report。
- 明確 Code Teach 的第一個實質回覆已包含 bounded actual code walkthrough，不只包含 inventory、flow、mechanism 或 causal nodes。
- branch/range/PR/working-tree 的完整 Code Teach 有 coverage ledger；沒有用單一代表路徑冒充所有修改。
- Report 有六個 exact headings，順序正確，沒有省略；`depth` 而非完整性控制篇幅。
- 明確 Code Teach report 的 Layer 1 至 3 合計不超過 3 至 7 個 orientation items，Layer 4 是主體。
- Guided 一輪只有一個主要問題、符合元件/步驟/機制/method-group 資訊預算，並顯示短 progress 與最多兩個下一步。
- Guided 的 Change/Verification 只是 evidence overlays 或簡短 closure，沒有變成額外視角。
- 六層使用同一個具體例子。
- 先 operation flow，再 method/code。
- 每個重要節點都串起 Responsibility、Result、Handoff、Downstream impact；不只列 caller graph。
- Code Teach 前已通過 Orientation Gate；既有 orientation 被明確沿用且未重講，不足時只補最小 map。
- Layer 3 每個主要步驟都有 Logic、Data、Program、State、Boundary、Evidence。
- Layer 4 先有局部 Method-chain mental map；單一 method 至少有一行上下游定位。
- Actual Code Teach 已明確載入 `vibe-coding-tutor`，其 project/architecture/pattern/exercise/extension 支援已整合而非另附報告。
- Layer 4 causal node 只有 Position、Responsibility/Not responsible for、Input/Pre-state、Result/Effect、Handoff/Downstream impact，沒有與 walkthrough 重複。
- Node 只作 navigation；algorithm、branch/return、post-state、caller consumption、confidence 與 downstream impact 被自然整合進 bounded walkthrough，沒有渲染成另一組固定欄位。
- 適用的 mechanism/primitive 已說明 problem、actors/resource、coordination、guarantees、limitations、failure/recovery 與 code touchpoints，然後恢復原 flow/code；沒有逐 token 教 syntax。
- Overall result 描述可觀察語意結果，與只描述程式回傳值的 Return value 明確區分。
- 相似方法的唯一責任與排除責任可清楚區分；wrapper/delegation 已明示。
- 每個 code-specific claim 都有 `file:line-range`。
- Confirmed、Inferred、Unknown 沒有混用。
- Tests Present、Verification Plan、Actual Execution Evidence 已分開。
- ELI5 只套用通過 gate 的單一機制，並有精確說明與比喻限制；高混淆 method cluster 已在相關 Code unit 前主動使用 bounded ELI5。
- 沒有 specialist 報告拼貼或重複 flow。
- Code Teach 沒有混入 conventional Code Review findings；明確要求的 findings 已分開標示。
- Layer 6 沒有新增前五層未出現的資訊。

任何一項失敗都先重整再輸出。
