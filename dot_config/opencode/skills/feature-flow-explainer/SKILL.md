---
name: feature-flow-explainer
description: Use whenever the user wants to understand how an implemented or partially implemented feature runs end-to-end, including request lifecycle, data flow, method call flow, state transitions, transaction boundaries, background workers, and current versus target wiring. Trigger on questions such as「這個功能完整怎麼跑」、「一次操作經過哪些方法」、「這些方法什麼時候被呼叫」、「說明資料流、程式流、方法流」or requests to trace a feature from API to database, events, queues, workers, and external systems.
---

# Feature Flow Explainer

從實際程式碼證據重建單一功能或操作由入口至完成的完整執行生命週期。回答誰觸發、哪些方法依序被呼叫、資料如何轉換與保存、交易在哪裡開始和結束、哪些工作同步或交由背景 Worker 執行，以及目前接線狀態。

此 Skill 是**唯讀的理解工作**：不修改程式碼、不建立文件檔，也不執行 correctness、security、performance 或 code-quality 審查；除非使用者另外明確要求。

## 適用範圍與邊界

適用於追蹤一個已實作或部分實作的功能，例如：

- HTTP/API request 至 Controller、Command/Handler、Service、Repository、DbContext 與資料庫。
- Domain Event、integration event、queue message、Outbox、background worker/job 的 producer、dispatch、consumer 與 completion。
- 外部 Adapter/API 呼叫、snapshot/read-back、retry/recovery 與最終狀態。
- 使用者詢問「目前程式怎麼跑」與「目標架構應怎麼跑」之間的差異。

### 與相近 Skills 的分工

| Skill | 使用時機 | 不做什麼 |
|---|---|---|
| `feature-flow-explainer`（本 Skill） | 追蹤一項功能由入口至完成的實際生命週期、資料流、交易、Worker、Event、Queue 與接線狀態。 | 不做廣泛架構教學或缺陷審查。 |
| `change-understanding-review` | 解釋某個 diff、commit 或已完成變更：改了什麼、為何改、前後差異。 | 不以「完整執行生命週期」為主要輸出。 |
| `vibe-coding-tutor` | 對已完成的多檔功能提供教學、架構導覽、延伸練習或 onboarding。 | 不要求逐一追蹤 transaction、Worker 與方法呼叫時機。 |
| 一般程式碼審查 | 評估 correctness、security、performance、maintainability 或是否可核准。 | 不以流程解釋取代審查。 |
| `understand-explain` | 深入解釋特定檔案、函式或模組。 | 不必追蹤跨系統的端到端功能流程。 |

若使用者同時要求流程解釋與 code review，先完成本 Skill 的事實流程報告，再以獨立段落或流程處理審查；不得把推測性的缺陷混入流程事實。

## 證據與準確性規則

1. **先找呼叫者，再描述呼叫順序。** 不可只依類別、方法、介面或命名推測流程。
2. 所有程式特定主張都引用實際 `file:line-range` 與方法名稱；沒有證據時標記 `❓ Unknown`。
3. 優先使用 `grep` 找入口、呼叫者、事件、介面與註冊；用 `read` 閱讀足夠完整的相符區段；用 `glob` 找相關檔案。
4. 追蹤順序預設為：`Endpoint/Controller → Command/Handler → Domain → Repository → DbContext → Event → Worker/Job → Adapter → External System → Completion Transition`。若實際流程不同，以程式碼為準。
5. 不把規劃、註解、dead code、DI/event registration、介面宣告或存在的方法當成已執行的證據。
6. 找不到 Worker host、排程器、consumer registration 或實際 dispatch 呼叫時，明確標示 `❓ Unknown`，不可自行補完。
7. 明確區分 DB transaction 與外部 HTTP/queue 操作；不可暗示外部呼叫被資料庫交易保護，除非有程式碼證據。
8. 每個關鍵方法都需說明「負責」與「不負責」的範圍，以及實際呼叫時機。
9. 若程式碼與需求、設計稿或使用者敘述不一致，分列「目前實作」與「目標設計」，不得混寫。
10. 不自行修改程式碼、設定、資料或測試；不宣稱已實際執行過程式，除非可取得執行證據。

## 工作流程

### Step 1：確認追蹤操作與完成條件

先從程式碼與使用者描述確認：

- 功能名稱與操作入口（HTTP route、UI action、CLI、schedule、event consumer 等）。
- 使用者要理解的是**目前實作**、**最終設計**，或兩者的比較。
- 此次操作何時算「完成」：本地 commit、回傳 HTTP response、外部系統成功、read-back 成功，或 outbox/stream 到達特定狀態。

範例：起點為 `RenameCompany` HTTP request；終點為 BizForm 名稱 read-back 成功，且 Outbox operation 標示 `Succeeded`。只有在起點或終點無法由程式碼或使用者描述判斷、且會改變追蹤範圍時，才詢問澄清問題。

### Step 2：蒐集實際程式證據

依下列順序蒐集，而非只讀一個看似相關的類別：

1. 找 route、Controller/Endpoint、command/event message 與外部入口。
2. 找入口實際呼叫的 Handler、Service、Domain method、Repository 與 `SaveChanges`/commit。
3. 找 entity、DTO、payload、snapshot、serializer 與資料欄位的轉換點。
4. 找 transaction scope、unit of work、outbox insert、sequence allocation 與 rollback 行為。
5. 找 event dispatch、queue publish、worker host、poll/claim、job registration 與 consumer。
6. 找 adapter/external client、read-back、success/failure transition、retry/recovery。
7. 找測試、組態與註冊證據以確認已接線程度；registration 本身仍不可當作實際觸發證據。

### Step 3：建立可驗證的呼叫鏈

對每個關鍵方法記錄下列欄位；若未知，保留 `Unknown`，不要猜測：

| Method | Caller | Trigger | Input | Responsibility | Output | Transaction | Status |
|---|---|---|---|---|---|---|---|
| `TryClaimNextOperation` | `OutboxWorker`（若程式碼證實） | 每次 polling 取得下一份工作 | `CancellationToken` | 原子取得可執行工作 | `OperationId` 或 `null` | 短 transaction | ✅ / 🟡 / ❓ |

呼叫鏈必須從已知入口一路延伸到已知完成條件；中途缺口需要清楚畫為 Unknown，而不是由名稱補推。

### Step 4：追蹤資料生命週期

除了方法順序，還要說明每一筆資料的產生、轉換、保存、恢復與消費。例如：

```text
HTTP CompanyName
  → Trim
  → Company.Name
  → RenameCompanySyncPayload
  → JSON Payload
  → Outbox Operation
  → Snapshot
  → BizForm Adapter Request
  → Read-back Result
```

每個轉換至少回答：

- 為何在這裡轉換，以及新資料結構解決什麼邊界或持久化需求。
- 原始值是否仍被保存；若否，在哪個轉換點被取代。
- 哪個值或 payload 是 immutable snapshot。
- process 重啟後從哪個已持久化資料恢復，而非依賴記憶體狀態。

### Step 5：標記 Transaction 邊界

用顯式區塊呈現每個經程式碼證實的邊界，例如：

```text
Transaction A
├─ 修改本地資料
├─ 配置 Sequence
├─ 建立 Outbox Operation
└─ Commit

Transaction 外
├─ 讀取 Snapshot
├─ HTTP 呼叫
└─ Read-back

Transaction B
├─ Operation → Succeeded
└─ Stream progress → Sequence
```

同時說明：

- 哪些寫入必須一起 commit，以及任一失敗時哪些寫入會一起 rollback。
- 為何外部 HTTP 不應放在長時間 DB transaction 中（例如鎖定時間、遠端延遲與遠端結果不受 DB rollback 控制）；若實作例外，引用證據說明。
- transaction 外的失敗留下什麼可恢復狀態，以及下一個 retry/recovery 從何處開始。

### Step 6：標記同步與非同步分界

固定分區，讓使用者能立即辨識 HTTP request 不會直接呼叫哪些方法：

```text
Request 直接呼叫
HTTP → Handler → Repository → Local Commit

Background Worker 呼叫
Recovery → Claim → Snapshot → External Call → Completion
```

每段只列實際可證實的呼叫。若找不到 Worker host 或排程註冊，說明 `❓ Worker host/trigger Unknown`，並將下游方法標為已存在但未證實接線，而非寫成 HTTP 的同步流程。

### Step 7：建立狀態生命週期

從 entity、enum、transition method、guard、呼叫者與持久化程式碼重建狀態圖。範例格式：

```text
Pending
   ↓ Claim
Processing
   ├─ 成功 → Succeeded
   ├─ 失敗 → Failed
   └─ 當機 → Recovery → Failed
```

每個箭頭都要指出：誰改變狀態、轉換條件、是否在 transaction 中、是否推進 stream/sequence，以及對後續 operation 或資料可見性的影響。

### Step 8：區分現況、目標與未知

每一段流程、方法與狀態使用下列標記：

| 標記 | 意義 |
|---|---|
| ✅ | 已實作且已接線：存在實際 caller/registration 與可追蹤路徑證據。 |
| 🟡 | 已實作、尚未接線：方法或類別存在，但找不到可證實的實際執行路徑。 |
| 🔵 | 規劃中：僅存在需求、設計或明確未實作意圖。 |
| 🟠 | 暫時保留：兼容、migration、fallback 或過渡用途仍存在。 |
| 🔴 | 未來停用：程式碼或文件明確標示 legacy/deprecated/removal intent。 |
| ❓ | Unknown：程式碼證據不足或範圍無法確認。 |

「方法存在」不等於「完整功能可運作」；所有接線結論都要提供呼叫鏈或註冊與 trigger 的實際證據。

## 固定輸出格式

以 Traditional Chinese 回答；保留原始程式碼、identifier、path、route、欄位名與外部系統名稱。預設使用純文字圖，僅在使用者要求時才額外提供 Mermaid。

```markdown
# 功能執行流：<功能名稱>

## 1. 起點與完成條件
- **起點：** ...（`file:line`）
- **完成條件：** ...
- **追蹤範圍：** 目前實作 | 目標設計 | 比較

## 2. 端到端流程圖
<純文字圖；每個節點含狀態標記>

## 3. 完整編號生命週期
1. ...

## 4. 資料生命週期
<由原始輸入到持久化、snapshot、外部 request/read-back 的轉換表>

## 5. Transaction 邊界
<Transaction A、transaction 外、Transaction B；commit/rollback 與理由>

## 6. 狀態轉換
<狀態圖、轉換者、條件與後續影響>

## 7. 具體資料範例
<至少一個橫跨生命週期的具體資料/sequence 範例>

## 8. 方法使用時機表
<每個關鍵方法的 caller、時機、輸入、輸出、責任、不負責、transaction、status>

## 9. 目前實作狀態
<✅、🟡、🔵、🟠、🔴 的事實與證據>

## 10. 尚未接線與 Unknown
<缺失 caller、host、registration、dispatch 或外部完成證據，以及需要確認的問題>
```

### 端到端流程圖預設

```text
HTTP Request
    ↓
Command Handler
    ↓
Transaction A
    ├─ Local Update
    ├─ Sequence Allocation
    └─ Outbox Insert
    ↓ Commit

Worker
    ↓
Claim
    ↓
Snapshot
    ↓
External API
    ├─ Success → MarkSucceeded
    └─ Failure → MarkFailed
```

此圖是版型，不是事實宣告。移除在實際程式碼中不存在的節點，並在缺乏證據時標示 `❓`。

### 關鍵方法的固定解釋格式

```markdown
### `TryClaimNextOperation` — `path/to/file.ext:10-42`

- **誰呼叫：** Background Worker（或 `❓ Unknown`）
- **何時呼叫：** 每次輪詢準備取得工作時（需有 host/polling 證據）
- **輸入：** `CancellationToken`
- **回傳：** `OperationId` 或 `null`
- **負責：** 原子取得一筆可執行工作。
- **不負責：** Payload 執行、HTTP 呼叫、成功或失敗狀態更新。
- **Transaction：** 短 transaction（引用實際 transaction scope）
- **狀態：** 🟡 已實作、尚未接線
```

## 跨階段資料範例

每份報告至少提供一個從入口到完成的具體例子。若存在 sequence ordering，優先示範阻塞與推進：

```text
NextSequence = 5
LastSucceededSequence = 4

Rename A → Sequence 5
Rename B → Sequence 6

Worker 只能先處理 5。
5 失敗時，6 必須等待。
5 成功後，LastSucceededSequence 才能推進至 5。
```

將例子的每一步對應到已確認的方法、資料列或狀態。若 sequence/ordering 並不存在，改用實際存在的 ID、payload、retry 或 read-back 值，且不要套用此範例的行為。

## 完成前檢查

交付前確認：

- 已以實際 caller 與 `file:line-range` 證據建立入口至終點的路徑。
- 已提供端到端純文字流程圖、方法流、資料流、transaction 邊界與狀態流。
- 已清楚分開 Request 直接呼叫與 Worker/background 呼叫；未證實的 host 已標記 Unknown。
- 每個關鍵方法都有「誰呼叫、何時呼叫、負責、不負責、transaction、狀態」。
- 至少有一個跨階段的具體資料範例。
- 已將已接線、未接線、規劃、保留、停用與未知分開。
- 沒有把 interface、registration、註解、方法存在或目標需求誤寫為實際執行。
- 沒有進行 code review，也沒有修改任何程式碼。

## 手動測試 Prompt

在含對應程式碼的專案中，以以下 Prompt 驗證輸出：

1. **Outbox／Worker**：`請說明一次 Rename Company 從 API、資料庫 Outbox，一直到 Worker 同步 BizForm 的完整流程。這些 Repository 方法分別在什麼時候被呼叫？`
   - 預期：區分 HTTP 與 Worker、顯示交易邊界、Claim/Snapshot/Success/Failure，以及已接線與未接線。
2. **同步 API**：`請追蹤建立使用者的完整資料流，從 Controller 到 Repository 和 SaveChanges。`
   - 預期：不強行加入 Worker；只描述實際存在的同步流程；找出呼叫鏈與資料轉換。
3. **Event-driven 功能**：`這個 Domain Event 是誰建立、何時 dispatch，最後有哪些 Handler 收到？請說明完整方法流。`
   - 預期：找出 producer、dispatch 時機與 consumers；說明 transaction 前後差異；不把 event registration 當成實際觸發證據。
