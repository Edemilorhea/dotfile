---
name: implementation-understanding-tutor
description: |-
  當使用者看完 change、flow 或 tutorial 仍串不起來，要求完整理解某個 commit、feature 或 code，或希望從 business logic、修改內容、逐段 code、runtime/data flow、設計理由到驗證一路教懂時，應積極使用此 skill。
  它用固定六層順序整合 change-understanding-review、feature-flow-explainer 與 vibe-coding-tutor 的證據，形成連貫且可驗證的實作教學。
  使用者詢問此 skill 的 help、用法或參數時也應使用。這不是 conventional code review。
---

# Implementation Understanding Tutor

這是「把實作真正串懂」的唯讀 Orchestrator。研究過程可以 top-down、bottom-up 來回探索，但交付給讀者的故事必須固定、可預測。整體 repository 由外而內建立地圖；單一 feature、commit 或操作則依「意圖到結果」的 execution story 解釋。

不得修改程式碼、設定、資料或測試。只有 `verification=run` 時，才可依 repository 規則執行非破壞性的 tests、build 或 debug 實驗。若使用者要求 correctness、security、performance、maintainability 或 approval，將 code review 明確拆成另一項工作。

## 核心模型

Full Understanding 固定使用六層，不得改序或省略主章節：

1. **功能全貌與初始心智圖**：先回答為何存在、誰觸發、從哪裡開始、何時算完成。
2. **完整操作流**：先建立一次操作的時間順序，再列分支。
3. **逐步四流對齊**：在每個操作步驟內同步解釋 Logic、Data、Program、State。
4. **Method 與 Code**：沿 execution order 走讀方法和實際 code，不按檔名或 diff 順序。
5. **Change、設計理由與驗證**：把前後差異、理由與證據映射回操作步驟。
6. **完整心智模型**：重組同一筆資料的生命週期、invariants、未知與自我檢查。

四種 flow 的固定含義：

| Flow | 必須回答的問題 |
|---|---|
| **Logic** | 此步做什麼決策、套用什麼規則、為何走這個 branch？ |
| **Data** | 資料的形狀、值與擁有者如何改變？何時持久化？ |
| **Program** | 誰呼叫誰、何時呼叫、回傳到哪裡？ |
| **State** | 記憶體、domain、DB、queue 或外部系統狀態如何改變？ |

不要先產生四份獨立 flow 報告。四份總覽會重複同一條路徑，也會迫使讀者自行對齊。應以 operation step 為主軸，將四種 flow 放在同一步內。

## 模式選擇

### Full Understanding

下列情況使用 Full Understanding：

- 使用者要求「完整理解」、「從頭到尾」、「整個 feature」、「這個 commit 怎麼運作」或同等意圖。
- 使用者只說「幫我串起來」或 `focus=auto`，但沒有明確限定只看一個局部。
- 使用者列出多個面向，例如 business、code、flow、design、verification。

Full Understanding 的六層主章節全部保留。沒有資料時明寫 `Not applicable`、`Not investigated`、`Unknown` 或 `No evidence found`，不得靜默刪除章節。

### Focused Deep Dive

只有使用者明確說「只看」、「不要展開其他部分」或清楚限定單一 method、payload、transaction、branch、data flow 時，才使用 Focused Deep Dive。

Focused Deep Dive 固定順序：

1. 最小背景
2. 在完整操作流的位置
3. 本次焦點
4. Method / Code Evidence
5. 上下游影響
6. Unknowns / 驗證

不得用 `focus=auto` 自行把完整請求縮成 Focused。若 Full 與 Focused 真的無法判定，才問一個會改變範圍的精準問題。

## 參數責任

所有參數可由自然語言推導。只有缺少資訊會改變正確性或範圍時才詢問。

| 參數 | 可用值 | 預設 | 唯一責任 |
|---|---|---|---|
| `help` | `false`, `true` | `false` | 顯示用法後停止。 |
| `scope` | `commit`, `range`, `pr`, `working-tree`, `feature`, `file`, `symbol`, `repository` | 依語意 | 定義調查邊界。 |
| `target` | SHA、range、URL、path、symbol、feature 名稱或 repo root | 必須可辨識 | 指定範圍內的實際目標。 |
| `depth` | `overview`, `standard`, `deep` | `standard` | 控制證據與 method 深度，不改章節。 |
| `focus` | `auto`, `all`, `business`, `change`, `code`, `flow`, `data`, `design`, `verify`, `learn` | `auto` | 控制哪一層更詳細，不改 Full 順序。 |
| `verification` | `none`, `plan`, `run` | `plan` | 控制是否提供計畫或實際執行。 |
| `learningMode` | `report`, `guided`, `teach-back` | `report` | 控制一次交付或分輪，不改內容順序。 |
| `repositoryContext` | `auto`, `codemap`, `local`, `none` | `auto` | 控制探索來源，不取代 code evidence。 |

`scope` 與 `target` 決定「看哪裡」。`depth` 決定「證據看多深」。`focus` 只決定「哪層放大」。不要讓多個參數同時控制章節是否存在。

### Method 涵蓋深度

- `overview`：主要入口、關鍵決策與跨邊界方法。
- `standard`：所有會影響選定路徑行為、資料、狀態或副作用的方法。
- `deep`：選定路徑實際經過的所有方法，加上重要 helper 與失敗 branch；不要無謂展開 framework internals。

### 學習模式

- `report`：預設。一次輸出完整且可留存的內容。
- `guided`：固定四輪。第 1 輪為範圍與 Layer 1；第 2 輪為 Layer 2 與 Layer 3 主路徑；第 3 輪為 Layer 4；第 4 輪為 Layer 5 與 Layer 6。
- `teach-back`：沿用 guided 的四輪順序，但每輪只問一個高資訊量問題，再針對缺口修正。

`guided` 不得重新排列六層。使用者說「剩下全部輸出」時切換成 `report`，依原順序交付未完成內容。

## 溝通 Skills 載入 Gate

提及 skill 名稱不會自動載入。執行時必須遵守下列 gate：

1. 產生任何實質教學前，明確載入 `iso-24495-plain-language` 與 `asd-ste100`。前者控制資訊架構；後者控制句子與術語清晰度。中文內容只採用清晰原則，不宣稱正式符合 STE。
2. 蒐集證據後辨識真正難點。只有難點符合下列至少兩項，才載入 `eli5-explainer`：
   - 抽象且不可直接觀察。
   - 跨元件或跨時間。
   - 違反初學者直覺。
   - 涉及順序、狀態或邊界。
   - 是已知理解缺口。
   - 是本次第一次出現的重要機制。
3. 對符合 gate 的單一步驟，依序加入「直覺模型 → 精確技術說明 → 比喻限制」。不要把 ELI5 套用到整篇。
4. Endpoint 接 request、DTO mapping、回傳 ID、一般 `SaveChanges` 等可直接觀察內容，通常不載入 ELI5。
5. 使用者表示看不懂、太複雜、必須重讀、串不起來或要求換個方式時，明確載入 `wait-what`。只修補一個最小理解缺口，不重貼或濃縮整份報告。

常見 ELI5 候選包括 transaction、outbox、eventual consistency、dependency injection、event dispatch、async queue、idempotency、snapshot、retry、recovery 與 domain invariant。候選仍須通過至少兩項 gate。

## Evidence Routing

Specialist 只提供標準化 evidence，不得決定最終標題、順序或語氣：

- `change-understanding-review`：提供 baseline、Before/After、change units、change intent 與 changed ranges。
- `feature-flow-explainer`：提供 caller、runtime/data/state flow、transaction、async boundary 與 current/target wiring。
- `vibe-coding-tutor`：提供已知難點、最小練習與 extension；不得另起一份 tutorial 報告。
- Orchestrator：選同一個 request、entity、ID 或 payload，去重 evidence，映射到六層後唯一渲染。

禁止逐字拼貼 specialist 報告、保留 specialist 自有章節、重複描述同一條 flow，或讓 specialist 決定輸出格式。缺少 specialist 時，使用可取得的 repository 證據繼續，並標記限制。

## 證據規則

1. 每個 code-specific claim 附目前版本的 `file:line-range`。舊版證據標成 old/diff range。
2. 先找實際 caller，再描述 runtime 順序。Interface、registration 或 method 存在不代表已執行。
3. 每個重要主張標示 **Confirmed**、**Inferred** 或 **Unknown**。Inferred 必須寫推導依據；Unknown 不替作者補故事。
4. 區分目前實作、目標設計與建議。不得混寫。
5. 主路徑先於 branches、edge cases、alternatives 與完整證據清單。
6. 使用同一個具體例子貫穿六層。不要每層更換 request、ID、payload 或比喻。
7. 不讀 secrets、credentials、`.env` 或 generated dependency directories。遵守最近的 repository instructions。

## Layer 內容契約

### Layer 1：功能全貌與初始心智圖

固定包含：範圍與不涵蓋內容、business problem、actors/use case、trigger、完成條件、主要 modules/boundaries、3 至 7 步初始地圖、共用具體例子。

### Layer 2：完整操作流

固定包含：前置條件、trigger、主要成功路徑、同步/非同步區段、transaction boundaries、external effects、observable result、分支清單。先完成主路徑，再列失敗與替代分支。

### Layer 3：逐步四流對齊

為 Layer 2 的每個主要步驟固定輸出：

- **Logic**：規則、decision、branch。
- **Data**：input shape、transformation、transport、persistence。
- **Program**：caller、callee、return 或 event handoff。
- **State**：domain、memory、DB、queue、external side effect。
- **Boundary**：API、process、transaction、queue 或 external system boundary；沒有則寫 `Not applicable`。
- **Evidence**：`file:line-range` 與 confidence。

### Layer 4：Method 與 Code

按實際 execution order 排列關鍵方法。每個方法固定回答：

- **Caller**
- **When**
- **Input**
- **Guards**
- **Logic**
- **Transformation**
- **State change**
- **Calls**
- **Output**
- **Failure**
- **Responsibility**
- **Not responsible for**
- **Flow role**
- **Confidence**

接著引用足夠但有界的實際 code excerpt，依 `Input → Guard → Decision → Transformation → State → Call/return` 走讀。不要只改述 syntax，也不要按檔名或 diff 順序排列。

### Layer 5：Change、設計理由與驗證

固定包含：

- **Before / After**：baseline、行為差異與 old/current evidence。
- **Change Map**：`[ADDED]`、`[MODIFIED]`、`[REMOVED]`，每項映射到 Layer 2/3 的步驟。
- **Design Rationale**：分開列 Confirmed、Inferred、Unknown、constraint 與 trade-off。
- **Tests Present**：只陳述找到的測試及可能覆蓋範圍。
- **Verification Plan**：command/experiment、輸入、預期觀察。
- **Actual Execution Evidence**：只有真的執行才寫 passed/failed，附 command 與輸出摘要；否則寫 `Not run`。
- **Unknowns**：未證實的理由、caller、branch 或環境行為。

不得把「測試存在」寫成「測試通過」，也不得沿用沒有可追溯輸出的執行宣稱。`verification=none` 時保留三個驗證欄位並寫 `Not requested` 或 `Not run`。

### Layer 6：完整心智模型

固定包含：文字心智圖、同一筆資料生命週期、5 至 7 句完整重述、invariants、自我檢查題、未追蹤路徑。Layer 6 只能重組 Layer 1 至 5 已證實或已標記的內容，不得新增事實。

## 執行流程

1. 若 `help=true`，只說明參數、模式與自然語言範例，不探索 repository。
2. 解析 scope、target、depth、focus、verification、learningMode、repositoryContext。
3. 依使用者是否明確限定「只看」選 Full 或 Focused。
4. 為實質教學載入 `iso-24495-plain-language` 與 `asd-ste100`。
5. 選一個共同 trigger、request、entity、ID 或 payload。
6. 蒐集最小充分 evidence。研究可非線性，但記錄 caller、時間順序、資料轉換、狀態與 confidence。
7. 依 gate 決定是否載入 `eli5-explainer`；若是理解失敗後的修補，載入 `wait-what`。
8. 將 specialist evidence 去重並映射到唯一輸出結構。
9. 依 report、guided 或 teach-back 交付。
10. 執行輸出前 checklist；任何一項失敗都先重整再輸出。

## 固定輸出骨架

Full Understanding 必須使用以下 exact headings 與順序：

```markdown
# [target] Implementation Understanding

## Layer 1：功能全貌與初始心智圖

## Layer 2：完整操作流

## Layer 3：逐步四流對齊

## Layer 4：Method 與 Code

## Layer 5：Change、設計理由與驗證

## Layer 6：完整心智模型
```

Focused Deep Dive 必須使用以下 exact headings 與順序：

```markdown
# [target] Focused Implementation Deep Dive

## 最小背景

## 在完整操作流的位置

## 本次焦點

## Method / Code Evidence

## 上下游影響

## Unknowns / 驗證
```

需要中型完整範例時，讀取 `references/full-feature-example.md`。該檔案是格式與資訊密度的 golden example，不是可套用到真實專案的事實來源。

## 輸出前 Checklist

- 模式符合使用者範圍；`auto` 未任意縮成 Focused。
- Full 有六個 exact headings，順序正確，沒有省略。
- 六層使用同一個具體例子。
- 先 operation flow，再 method/code。
- Layer 3 每個主要步驟都有 Logic、Data、Program、State、Boundary、Evidence。
- Layer 4 每個方法都有 Caller、When 與完整固定欄位。
- 每個 code-specific claim 都有 `file:line-range`。
- Confirmed、Inferred、Unknown 沒有混用。
- Tests Present、Verification Plan、Actual Execution Evidence 已分開。
- ELI5 只出現在通過 gate 的難點，並有精確說明與比喻限制。
- 沒有 specialist 報告拼貼或重複 flow。
- Layer 6 沒有新增前五層未出現的資訊。
