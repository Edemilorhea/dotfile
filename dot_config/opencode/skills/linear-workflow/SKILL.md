---
name: linear-workflow
description: Plan, create, rewrite, prioritize, and review Linear work. Use whenever the user wants to turn a requirement into Linear issues or projects, rewrite an existing Linear artifact, decide between an issue and a project with milestones, inspect current Linear progress, recover the last active task, or determine the next actionable item.
---

# Linear Workflow

以 Linear 為唯一事實來源，提供兩種模式：

- `plan`：分析需求並建立合適的 Linear 結構。
- `review`：唯讀審閱目前進度、阻塞與下一步。

## 共通原則

1. 先讀後寫。先查使用者、team、既有 projects、issues 與 statuses，再做判斷。
2. 不猜測 team、project、issue、status、cycle、milestone、assignee 或日期。
3. 優先沿用既有工作，建立前先搜尋近似標題與相同目的，避免重複。
4. Linear 寫入使用 `linear_save_*` tools；讀取使用 `linear_get_*` 與 `linear_list_*` tools。
5. 遇到 tool、權限或部分寫入失敗，停止後續寫入，列出已建立項目的 identifiers 與未完成項目；不得假裝 rollback 成功。
6. 需要使用者做選擇時使用 `question` tool。只有缺少的資訊會改變結構或歸屬時才詢問。

## Artifact 改寫路由

當使用者要求建立、改寫或精簡既有 Linear Issue／Project 的內容時，`linear-workflow` 是 Linear 資料的讀寫 owner，但必須先判斷是否需要一個內容產出 skill。

1. 先讀取目標 Linear artifact、關聯 issue／project 與既有 dependencies。
2. 依主要目的選擇 **一個** primary content skill：
   - 精簡技術方案、系統邊界、實作檔案分類、關鍵規則與流程圖 → `develop-solution-brief`
   - 單一架構決策、替代方案與取捨 → `develop-adr`
   - 產品目標、範圍、使用者需求與成功指標 → `deliver-prd`
   - 使用者故事或可測試情境 → `deliver-user-stories` 或 `deliver-acceptance-criteria`
   - 已有文字的清晰度、精簡與可讀性調整 → `copy-editing`
3. primary content skill 只產出或改寫內容草稿，不得自行建立、更新或重新歸屬 Linear work。
4. `linear-workflow` 將草稿套入既有 artifact、保留已驗證的 identifier／dependency／scope，使用 `linear_save_*` 寫入，並重新讀取驗證。
5. 不要無條件串接多個 content skills。只有單一 skill 無法滿足目標，且鏈結會實質改變產物範圍時，才用 `question` 取得使用者同意。

技術實作型 Issue 的預設精簡結構為：

```markdown
## 要做什麼

## 實作檔案分類

## 為什麼做

## 重要業務規則

## 重要流程

## 範圍

## 驗收條件

## Dependencies
```

僅保留能指導實作或驗收的內容；不要把 research note、未知 API 細節或未選定方案寫成既定事實。

## Scope 解析

1. 使用 `linear_get_user("me")` 取得目前使用者。
2. 有明確 team key/name、project、issue identifier 時，先精確驗證。
3. 沒有明確 team 時：
   - 若目前對話或唯一 active work 可可靠指向一個 team，使用該 team並在摘要中說明依據。
   - 否則列出可用 teams，以 `question` tool 要求選擇，不得任選第一個。
4. Project 或 issue scope 不明確且存在多個候選時，同樣要求選擇。

## Plan 模式

### 輸入

命令參數可能是：

- `<requirement>`：分析後直接建立；此命令呼叫即授權在該需求範圍內寫入 Linear。
- `preview <requirement>`：只顯示規劃，不寫入 Linear。

若 requirement 為空，要求使用者描述目標、完成條件與已知期限。若需求已有足夠資訊，不重複確認執行。

### 需求拆解

萃取以下內容；缺少但不影響主要結構的欄位可標示 `未指定`：

- 最終 outcome 與 acceptance criteria
- deliverables 或可獨立驗證的工作單元
- dependencies、blockers 與可平行項目
- target date、urgency、風險與涉及 teams
- 已存在的 related project/issues

### 結構判斷

使用實際複雜度，而非只看描述長度。

#### 建立單一 Issue

符合大多數條件時使用單一 issue：

- 一個明確 outcome 與 owner
- 一條主要工作流，沒有獨立階段
- 可在數個工作日內完成
- 不需要跨 team 協調
- 不需要 4 個以上可獨立追蹤的工作單元

Issue description 至少包含：

```markdown
## Goal

## Scope

## Acceptance Criteria

## Dependencies
```

省略沒有內容的 section，不填虛構資訊。

#### 建立 Project + Milestones + Issues

符合任一實質條件時使用 project：

- 有多個可獨立交付的 outcomes 或 workstreams
- 需要 4 個以上 issues 才能可靠追蹤
- 有明確 discovery、implementation、validation、rollout 等階段
- 預期跨越多週、跨 team，或有多個 owners
- 需要 milestone-level checkpoint 或整體 target date

只有存在至少兩個有意義的 checkpoints 時才建立 milestones。不要為小型 project 製造只有一個 milestone 的儀式性結構。

若規劃超過 12 個 issues、3 個 milestones、涉及多個 teams，或需要改變既有 public commitment，先展示摘要並用 `question` tool 確認，因為這已屬明顯擴大範圍。

### 優先順序與依賴

先建立 dependency graph，再指派 Linear priority：

| Priority | 使用條件 |
|---|---|
| Urgent (1) | production incident、security exposure、明確 SLA breach 或阻塞所有交付 |
| High (2) | critical path、解除多個 blockers、近期 deadline 必要工作 |
| Medium (3) | 一般計畫內工作與主要 implementation |
| Low (4) | polish、optional improvement、非必要 follow-up |
| None (0) | 尚未排程或資訊不足，不應假裝已決定 |

同一 priority 內依下列順序排列：

1. prerequisite 與 blocker removal
2. highest-risk unknowns
3. critical-path implementation
4. validation、documentation 與 rollout
5. optional polish

依賴不能只靠 priority 表達。建立 issues 後，使用 `blockedBy` 或 `blocks` relations 記錄真實依賴；可平行工作不得互相設為 blocker。

### 建立順序

1. 搜尋相同或高度近似的 active project/issues，必要時沿用並回報。
2. 單一 issue：建立 issue，設定 team、title、description、priority，以及已確認的 assignee/due date/project。
3. Project flow：
   1. 建立 project，包含 summary、description、state 與已確認日期。
   2. 依時間順序建立有意義的 milestones。
   3. 依 topological order 建立 issues，並掛到 project/milestone。
   4. 已取得 identifiers 後補齊跨 issue relations。
4. 每次寫入後保留回傳的 identifier；下一步只能引用已成功建立的項目。
5. 完成後重新讀取 project/issues，核對數量、priority、milestone 與 relations。

### Plan 回報格式

```markdown
## Linear 規劃結果

- Decision: Single Issue | Project
- Team: <team>
- Reason: <結構判斷理由>
- Created/Reused: <identifiers and URLs>

## 執行順序

| Order | Item | Priority | Depends on | Milestone |
|---|---|---|---|---|

## 注意事項

- <unknowns, assumptions, or partial failures>
```

Preview 模式將 `Created/Reused` 改為 `Proposed`，且不得呼叫任何 `linear_save_*` tool。

## Review 模式

Review 永遠唯讀，不得修改 status、priority、assignee、project 或 issue。

### Scope 有明確參數

- Issue identifier：使用 `linear_get_issue`，包含 relations、project、milestone 與 comments（需要判斷最近進度時）。
- Project name/ID/slug：使用 `linear_get_project`（包含 milestones）與 `linear_list_issues(project=...)`。
- Team name/key：取得該 team 的 active projects 與指派給目前使用者的 active issues。

### Scope 為空：恢復上次工作

1. 查詢目前使用者被指派且未完成/未取消的 issues，依 `updatedAt` 由新到舊。
2. 優先辨識：
   - 唯一 `in progress` issue
   - 最近更新且有明確 active project 的 issue
   - 目前對話已提到的 issue/project
3. 只有一個高可信候選時直接審閱，並說明選擇依據。
4. 沒有高可信候選或有多個相近候選時，不得猜測。建立分層選單：
   - Teams
   - 所選 team 的 active Projects
   - 所選 project 的 active Issues，另列 `No project` issues
5. 每一層需要選擇時使用 `question` tool；選項保持精簡並顯示名稱、identifier/status 與最近更新日。

### Review 判斷

以 Linear 中可驗證資料回答：

- Current focus：目前 in-progress issue 或 project 的 active milestone
- Progress：各 status 數量與完成比例；沒有 estimate 時不得捏造 effort percentage
- Done：最近完成項目
- Next：dependencies 已滿足、最高優先且可執行的 1–3 項
- Blocked：blocked relations、阻塞原因與 owner（若有）
- Risks：overdue、stale、無 owner、無 milestone、priority 衝突或 critical path 缺口
- Unknown：Linear 未記錄、無法驗證的資訊

`Next` 必須尊重 dependency graph。被 blocker 卡住的 High/Urgent issue 不是可直接執行的 next item，應先列解除 blocker 的工作。

### Review 回報格式

```markdown
## Linear 狀況摘要

- Scope: <team/project/issue>
- Current focus: <identifier and title>
- Progress: <factual counts>
- Last updated: <timestamp>

## 下一步

1. <actionable issue and reason>

## 阻塞與風險

- <blocker/risk or 無>

## 最近完成

- <completed item or 無資料>

## 未知資訊

- <unknowns or 無>
```

若 scope 是 team，先按 project 分組，再列沒有 project 的 issues，避免把不同工作流混為一談。
