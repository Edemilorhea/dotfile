---
description: Build a factual GSS worklog and optionally generate Jira-ready daily entries.
agent: build
subtask: true
---

# GSS Worklog

Arguments: `$ARGUMENTS`

使用 Linear、Locu、目前 repository 的 Git 證據與 Obsidian 建立可追溯的 GSS worklog。時區固定為 `Asia/Taipei`；Linear 範圍固定為 team `GSS` (`0a08b91d-008b-4dc6-b14e-eb62432f7041`)。

## 支援形式

- `preview today|yesterday|YYYY-MM-DD..YYYY-MM-DD`：唯讀預覽。
- `sync today|yesterday|YYYY-MM-DD..YYYY-MM-DD`：只寫入 Obsidian managed section。
- `map <locu-task-id> <TEAM_KEY-123>`：新增或更新一筆明確 mapping。
- `jira <source-range> [target-range] [branch] [author]`：直接產生 Jira-ready 內容。

拒絕其他形式並顯示上述用法。日期範圍為 inclusive dates；查詢 API 時轉成 `Asia/Taipei` 的 ISO 8601 起點與 exclusive end。不得以標題相似度推斷 Locu-to-Linear mapping。

## 事實調查流程

1. 驗證 source range，並先確認該範圍的日曆日期與星期。
2. 使用 Linear tools 查詢範圍內 current/planned GSS issues。
3. 使用唯讀 `locu_sessions`，設定 `includeActivities=true`。只有顯示名稱需要時才使用 `locu_tasks`；若 tool 不可用，明確標示缺少的 tool，不得捏造 Locu 資料。
4. 從目前工作目錄執行 `git rev-parse --show-toplevel`。若找到 repository，使用唯讀 Git 指令取得 short hash、author time、subject、changed-file summary 與 diff statistics，並排除 merge commits。
5. Jira direct mode 的 branch 預設為所有分支，author 預設為 `TC|TC_Tseng`；有參數時使用指定值。`preview` 與 `sync` 保留所有作者的事實資料，但需清楚顯示作者。
6. 可選擇使用已安裝且已驗證登入的 `gh` 或 `glab` 補充既有 commit 的 PR/MR metadata。Git 仍是 source of truth；缺少 CLI 不算錯誤。
7. 若不在 Git repository，省略 Git 證據並顯示 `未偵測到 Git repository`。
8. 使用明確的 `未知` 或 `無資料`，不得從 branch、commit subject 或時間缺口推測工作內容。

不得 create、stage、commit、reset、clean 或修改 Git state。Locu tools 僅可讀取，不得儲存 PAT 或完整 session payload。

## Preview 與 Sync

事實性 worklog 必須保留以下區段：

- `## 工作範圍（Linear）`
- `## 實際投入（Locu）`：Time、Duration、Locu task、Linear issue、Description。
- `## Git 證據`：Commit、Time、Author、Summary、Files、Diff stat。
- `## 計畫與實際對照`

`preview` 不得建立或修改檔案。`sync` 完成 managed section 後，仍須先展示結果摘要。

完成 `preview` 或 `sync` 後必須詢問：

是否產生可直接貼到 Jira 的內容？

1. 是
2. 否

請使用者以數字回答。選擇 `1` 才進入 Jira 輸出流程；選擇 `2` 則結束，不得自行產生或寫檔。

## Jira 輸出流程

Jira 輸出是由事實證據衍生的呈現結果，不得改寫 Linear、Locu、Git 或 Obsidian 中的原始事實。

1. Source range 使用已完成的 worklog range；direct `jira` mode 使用第一個參數。
2. Target range 使用 direct mode 的第二個參數；未提供時預設與 source range 相同，並明確告知使用者。
3. 產生前必須詢問請假日期；使用者須回覆日期清單或 `無`。
4. 從 target range 排除星期六、星期日與確認的請假日。若沒有有效工作日，停止並回報。
5. 以 Linear、Locu 與 Git 的可驗證內容建立工作項目池。相同功能保持連續，依有效工作日平均配置；不得新增不存在的工作、issue、commit、工時或成果。
6. Source 與 target range 不同時，清楚標示為 `Jira presentation allocation`；不得暗示 allocated date 是原始 commit 或 Locu 發生日期。
7. 若完全沒有可驗證證據，停止產生 Jira 內容。

每個有效工作日產生一個可直接貼到 Jira 的區塊，使用繁體中文內容並依序包含：

- `Date: YYYY-MM-DD`
- `Title: <主要事項>`
- `Summary: <一段精簡摘要>`
- `Content:` 下方列出 1–3 個具體項目，每項包含技術動作與可驗證成果。

不同日期以水平線分隔。Jira-ready 內容直接回傳至對話；除非使用者另外明確要求，不得建立 `Documents/Jira_Worklog`、PDF、Obsidian note 或其他檔案。

## Obsidian 儲存

- Vault：`Notes`
- 新 note：`50 Worklogs/GSS/YYYY/YYYY-MM/YYYY-MM-DD.md`
- Mapping：`50 Worklogs/GSS/_config/task-mapping.yaml`
- CLI：`C:\Users\tc_tseng\AppData\Local\Programs\Obsidian\Obsidian.com`

`sync` 前先讀取 note；不存在才建立。既有 note 必須同時包含 `<!-- worklog:managed:start -->` 與 `<!-- worklog:managed:end -->`，否則停止並詢問。只替換 markers 之間的事實性區段，保留所有人工內容；不得覆寫舊 flat layout 歷史 notes。Jira allocation 不得寫入 managed section。

## Mapping 變更

`map` 是唯一可修改 `task-mapping.yaml` 的模式。Locu task ID 不得為空；Linear identifier 必須符合 `<TEAM_KEY>-<number>`，並以 Linear tool 驗證屬於目前 scope。先讀取既有 mapping，只更新指定 task ID；不存在時建立 `mappings` list。所有 mapping 讀寫使用 Obsidian CLI。

遇到 unmapped Locu task 時，顯示 ID 與候選 GSS issues，停止 mapping step，要求使用者執行 `/selfmade:worklog map <locu-task-id> <TEAM_KEY-123>`。
