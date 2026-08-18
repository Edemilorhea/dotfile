---
name: implementation-understanding-tutor
description: |-
  當使用者看完 change、flow 或 tutorial 仍串不起來，要求完整理解某個 commit、feature 或 code，或希望從 business logic、修改內容、逐段 code、runtime/data flow、設計理由到驗證一路教懂時，應積極使用此 skill。
  使用者想分開看架構、流程、機制、Code，或說「Code Teach」、「帶我讀 Code」、「不知道 method 在幹嘛／怎麼實作」時也應使用：用責任、結果、交接與後續影響串起 actual code 與必要的 framework/concurrency primitives。
  它用內部六層完整性模型整合 change-understanding-review、feature-flow-explainer 與 vibe-coding-tutor 的證據，並依 report 或四視角 guided 模式交付。使用者詢問 help、用法或參數時也應使用。這不是 conventional code review，不因一般 correctness／approval 請求而觸發。
---

# Implementation Understanding Tutor

這是「把實作真正串懂」的唯讀 Orchestrator。研究過程可以 top-down、bottom-up 來回探索，但交付給讀者的故事必須固定、可預測。整體 repository 由外而內建立地圖；單一 feature、commit 或操作則依「意圖到結果」的 execution story 解釋。

不得修改程式碼、設定、資料或測試。只有 `verification=run` 時，才可依 repository 規則執行非破壞性的 tests、build 或 debug 實驗。若使用者要求 correctness、security、performance、maintainability 或 approval，將 code review 明確拆成另一項工作。

## 核心模型

這個 skill 同時維護兩個模型。不要把內部完整性結構直接等同於每次的使用者輸出。

### 內部六層完整性模型

六層用於蒐集 evidence、追蹤 coverage，以及產生 `report`。Report 不得改序或省略主章節：

1. **功能全貌與初始心智圖**：先回答為何存在、誰觸發、從哪裡開始、何時算完成。
2. **完整操作流**：先建立一次操作的時間順序，再列分支。
3. **逐步四流對齊**：在每個操作步驟內同步解釋 Logic、Data、Program、State。
4. **Method 與 Code（Code Teach）**：先建立局部 method-chain mental map，再沿 execution order 教 method 如何實作結果與實際 code，不按檔名或 diff 順序。
5. **Change、設計理由與驗證**：把前後差異、理由與證據映射回操作步驟。
6. **完整心智模型**：重組同一筆資料的生命週期、invariants、未知與自我檢查。

六層完整代表資訊類型不能遺漏，不代表每層必須等長。`depth` 控制展開程度。

### 使用者四視角模型

`guided` 與 `teach-back` 以四種閱讀視角交付：

| 視角 | 核心問題 | 主要內容 |
|---|---|---|
| **Architecture** | 東西在哪裡，誰負責？ | business purpose、actors、components、責任與排除責任、依賴、boundaries、data ownership、修改落點與 downstream consumers。 |
| **Flow** | 一次操作依序如何完成？ | trigger、preconditions、caller/callee、data/state 變化、handoff、同步/非同步與 transaction/process/external boundaries。 |
| **Mechanism** | 這種協作為什麼能運作？ | 問題、參與者、shared resource、協作規則、guarantees、limitations、failure/retry/recovery 與 code touchpoints。 |
| **Code** | 程式如何產生並交出結果？ | method chain、inputs、algorithm、bounded actual code、branches/returns、post-state、caller consumption 與 next handoff。 |

四視角的邊界：Architecture 不展開時間順序或逐行 code；Flow 不展開 framework internals；Mechanism 不重講整個 feature flow，也不一次混講多個不相關機制；Code 不先輸出大篇幅架構報告，也不混入未要求的 review findings。

### 共用因果主線

每個 component、operation step、mechanism actor 或 method group 都沿同一條主線解釋：

`Responsibility → Input / Pre-state → Transformation / Result → Handoff → Downstream impact`

至少回答：它負責與不負責什麼、收到什麼、產生什麼 semantic result 或 effect、下一棒是誰、下一棒如何使用結果，以及 success/failure/cancellation 對後續的不同影響。只列「誰呼叫誰」不算完整理解。

四種 flow 的固定含義：Logic 是決策、規則與 branch；Data 是形狀、值、擁有者與 persistence；Program 是 caller、callee、時機與 return；State 是 memory、domain、DB、queue 或 external state。不要產生四份獨立 flow 報告；以 operation step 為主軸，在同一步內對齊四種 flow。

## 術語與工作順序

知識依賴順序是 **最小 Architecture/Flow orientation → 必要的 Mechanism → Code Teach → optional separate Code Review**：

- **Full Understanding** 使用六層確保 business、architecture、execution/data/state、mechanisms/boundaries、change 與 verification 都有 coverage。
- **Code Teach** 是 comprehension。Orientation 足夠後，沿 actual execution order 帶讀 code，教每個 method 如何實作其結果。它觸發 Layer 4 或 Focused Code Teach，不是 conventional review。
- **Code Review** 是評估 correctness、security、performance、maintainability 或 approval，必須是另一項工作。Code Teach 不主動揭露 review findings；若使用者明確要求同時評估，另以 **Code Review findings** 標示。

## 意圖優先級與交付判斷

先分開判斷「涵蓋範圍」與「教學方式」。不要讓描述範圍的詞覆蓋明確的教學動詞。

1. **明確教學動詞優先**：`Code Teach`、`帶我讀 Code`、`導讀 code`、`逐段讀`、`逐行教`、`method 怎麼實作` 表示 actual code walkthrough。設定 `focus=code`；除非使用者明確要求一次輸出或 report，否則設定 `learningMode=guided`。
2. **完整只控制範圍**：`完整`、`全部`、`所有修改`、`整個分支`、`從頭到尾` 擴大 `scope` 或 `depth`，不會把 Code Teach 改成機制報告，也不會自動設定 `learningMode=report`。
3. **交付詞才控制模式**：`一次輸出`、`完整報告`、`可留存報告` 才選 `report`；`帶我`、`一步一步`、`一段一段`、`邊看邊教` 選 `guided`；明確要求回答檢查才選 `teach-back`。
4. **衝突時保留兩者**：例如「這個分支的所有修改，完整 Code Teach」表示完整 scope 加 guided Code Teach。不得降級成六層摘要，也不得只挑一條代表路徑後宣稱涵蓋所有修改。
5. **第一個實質回覆必須出現 code**：明確 Code Teach 時，可先給最多 3 至 7 步的最小 orientation，但同一回覆必須開始第一個 coherent method group 的 bounded code walkthrough。

若目標是 branch、range、PR 或 working tree 的所有修改，先建立內部 coverage ledger：runtime execution stories、shared infrastructure、data/schema、configuration/static changes、tests。每完成一組便更新涵蓋狀態，直到所有重要 changed ranges 已教過或明確標成 Unknown／Not investigated。

## 模式選擇

### Full Report

使用者要求「一次輸出」、「完整報告」、「可留存報告」或明確指定 `learningMode=report` 時使用。載入 `implementation-understanding-report-contract`。六層主章節全部保留；沒有資料時不得靜默刪除章節。

使用者只說「完整理解」、「從頭到尾」或「整個 feature」是在擴大 coverage；若未要求一次輸出，預設 guided。

### Guided Understanding

使用者說「帶我理解」、「一步一步」、「分段看」、明確 Code Teach，或要求完整理解但未要求一次輸出時使用。完整 guided 仍用內部六層 ledger 防止遺漏，但每輪只交付一個四視角 learning unit 與簡短進度。

### Focused Deep Dive

只有使用者明確說「只看」、「不要展開其他部分」或清楚限定單一 method、payload、transaction、branch、data flow 時才使用。固定順序：最小背景、在完整操作流的位置、本次視角、Evidence 與導讀、Responsibility → Result → Handoff → Downstream impact、Unknowns / 驗證。

不得用 `focus=auto` 自行把完整請求縮成 Focused。若完整 coverage 與 Focused 真的無法判定，才問一個會改變範圍的精準問題。

## 參數責任

所有參數可由自然語言推導。只有缺少資訊會改變正確性或範圍時才詢問。

| 參數 | 可用值 | 預設 | 唯一責任 |
|---|---|---|---|
| `help` | `false`, `true` | `false` | 顯示用法後停止。 |
| `scope` | `commit`, `range`, `pr`, `working-tree`, `feature`, `file`, `symbol`, `repository` | 依語意 | 定義調查邊界。 |
| `target` | SHA、range、URL、path、symbol、feature 名稱或 repo root | 必須可辨識 | 指定範圍內的實際目標。 |
| `depth` | `overview`, `standard`, `deep` | `standard` | 控制證據與 method 深度，不改章節。 |
| `focus` | `auto`, `all`, `architecture`, `flow`, `mechanism`, `code`, `change`, `verify` | `auto` | 選四視角；`change/verify` 只選 evidence overlay。 |
| `verification` | `none`, `plan`, `run` | `plan` | 控制是否提供計畫或實際執行。 |
| `learningMode` | `report`, `guided`, `teach-back` | 依交付語意 | 控制一次交付或分輪。 |
| `repositoryContext` | `auto`, `codemap`, `local`, `none` | `auto` | 控制探索來源，不取代 code evidence。 |

`scope` 與 `target` 決定看哪裡；`depth` 決定證據看多深；`focus` 決定本輪視角；`learningMode` 決定一次報告或分段教學。不要讓「完整」同時控制 coverage 與交付方式。

自然語言映射：看責任、模組或邊界為 `architecture`；看互動順序、資料如何走或後續影響為 `flow`；看協作原理、保證或限制為 `mechanism`；帶讀 method 或 actual code 為 `code`。`change` 與 `verify` 是 evidence overlays，不是額外 guided 視角。同一主題可跨視角，但每輪只選一個主要問題。

## 學習模式與閱讀預算

- `report`：一次輸出六層完整且可留存的內容。`depth` 控制每層篇幅。
- `guided`：以四視角分段，一輪只交付一個 learning unit。方向通常是 Architecture → Flow → 必要的 Mechanism → Code，但不是固定四輪。
- `teach-back`：沿用 guided，每輪只問一個高資訊量問題，再針對缺口修正，不重貼整份內容。

Mechanism 只在理解下一段所必需時 just-in-time 插入。Change 與 Verification 作為 evidence overlays，Unknowns 與 final model 只在最後 progress/closure 簡短收束。使用者說「剩下全部輸出」時切換成 `report`，依六層收束尚未完成的 coverage。

Guided 與 teach-back 每個回覆遵守：只回答一個主要問題，最多一張主要圖或表；Architecture 最多 7 個 components；Flow 最多 7 個 steps；一次一個 mechanism 或 coherent method group；主路徑先於 failure、alternative 與 edge cases；結尾顯示簡短 progress 與最多兩個下一步。完整表示最終 coverage 完整，不表示單一回覆塞入所有內容。

使用者可見狀態只列目前學習項目，例如 `[完成] Architecture: Worker responsibilities`、`[目前] Code: Worker → OperationStream`、`[待讀] Mechanism: Channel coordination`。內部 ledger 狀態使用 `not started`、`in progress`、`taught`、`Unknown/Not investigated`。

## Supporting Contracts

提及 skill 名稱不會自動載入。執行時依 gate 明確載入：

| Contract | 載入時機 | 可繼續載入的 skills |
|---|---|---|
| `implementation-understanding-quality-contract` | 所有實質教學，且在蒐證與輸出前持續適用 | `iso-24495-plain-language`、`asd-ste100`、evidence specialists |
| `implementation-understanding-report-contract` | Full Report 或需檢查六層 coverage | Code Teach report 再載 code contract |
| `implementation-understanding-code-teach-contract` | Layer 4 或任何 actual method/code walkthrough | `vibe-coding-tutor`；必要時 mechanism contract |
| `implementation-understanding-mechanism-contract` | Mechanism 視角、必要 primitive bridge、高混淆 cluster 或理解失敗 | `eli5-explainer`、`wait-what` |

Contract 是本 Orchestrator 的強制延伸，不是獨立輸出作者。它們不得改變本 skill 的 scope、mode、共同例子、標題與語氣；所有 evidence 必須去重後映射回唯一輸出結構。

## 執行流程

1. 若 `help=true`，只說明參數、模式與自然語言範例，不探索 repository。
2. 先解析 scope/depth 與 focus/learningMode，再解析其餘參數。明確 Code Teach 不得因「完整」而落回 report。
3. 依交付詞選 report 或 guided/teach-back；依「只看」與 focus 選完整 coverage 或 Focused。完整 coverage 不等於 report。
4. 為所有實質教學載入 `implementation-understanding-quality-contract`，並依其 gate 載入 communication skills。
5. 選一個共同 trigger、request、entity、ID 或 payload。
6. 蒐集最小充分 evidence。每個重要節點記錄 responsibility、input/pre-state、result/effect、handoff、downstream impact 與 confidence。全 branch/range/PR/working-tree 另建 coverage ledger 與 execution-story 分組。
7. Guided 先決定本輪唯一主要視角與理解問題；report 載入 report contract 並將 evidence 映射到六層。
8. Code Teach 載入 code contract 並執行其 Orientation Gate；Mechanism 或必要 primitive 載入 mechanism contract。
9. 將 specialist evidence 去重並映射到唯一輸出結構；Code Teach 不混入未要求的 Code Review findings。
10. 依單次閱讀預算交付。明確 Code Teach 的第一個實質回覆在最小 orientation 後立即進入第一個 coherent method group。
11. 更新 coverage progress；依 quality contract 執行完整 checklist，任何一項失敗都先重整再輸出。

## 固定輸出骨架

Report 必須使用以下 exact headings 與順序：

```markdown
# [target] Implementation Understanding

## Layer 1：功能全貌與初始心智圖
## Layer 2：完整操作流
## Layer 3：逐步四流對齊
## Layer 4：Method 與 Code
## Layer 5：Change、設計理由與驗證
## Layer 6：完整心智模型
```

Guided 與 teach-back 每個 learning unit 使用：

```markdown
# [target] Guided Implementation Understanding

## 閱讀進度
## 本次視角：[Architecture / Flow / Mechanism / Code]
## 本次理解目標
## Evidence 與導讀
## Responsibility → Result → Handoff → Downstream impact
## 下一步
```

Focused Deep Dive 使用：

```markdown
# [target] Focused Implementation Deep Dive

## 最小背景
## 在完整操作流的位置
## 本次視角：[Architecture / Flow / Mechanism / Code]
## Evidence 與導讀
## Responsibility → Result → Handoff → Downstream impact
## Unknowns / 驗證
```

需要中型完整範例時，讀取 `references/full-feature-example.md`。該檔案是格式與資訊密度的 golden example，不是可套用到真實專案的事實來源。
