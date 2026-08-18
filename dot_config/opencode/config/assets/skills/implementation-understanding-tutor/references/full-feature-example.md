# Full Feature Golden Example

這是格式範例，不是真實 repository 的分析。所有 path、line range 與行為均為虛構。使用此範例校準順序、欄位與資訊密度，不得複製其架構假設到使用者專案。

# Place Order Implementation Understanding

## Layer 1：功能全貌與初始心智圖

**主線：** 使用者送出訂單後，系統先在同一個 transaction 建立訂單與 outbox message，再由 worker 將已提交的訂單通知物流服務。

- Scope：`POST /orders` 到物流 API 的第一次 delivery attempt。
- Not covered：付款 provider 內部流程、物流服務內部實作。
- Business problem：即使 API process 在 DB commit 後中止，物流通知仍不能永久遺失。
- Actors：customer、Orders API、database、outbox worker、Logistics API。
- Trigger：customer 提交 `CreateOrderRequest`。
- Completion：API 回傳 `orderId`，且 worker 最終將 shipment request 標成 delivered 或留下可重試狀態。
- Shared example：`orderId=ORD-42`、`customerId=C-7`、`total=1200`。

初始地圖：

1. Endpoint 接收 `CreateOrderRequest`。
2. Handler 驗證 customer 與 items。
3. Domain 建立 `Order(ORD-42)`。
4. Repository 儲存 order 與 outbox message。
5. Transaction commit 後 API 回傳 `ORD-42`。
6. Worker 讀取 outbox message 並呼叫 Logistics API。
7. Worker 記錄 delivered 或 retry state。

## Layer 2：完整操作流

**前置條件：** customer `C-7` 存在，商品仍可下單，worker 已啟動。

1. `OrdersController.Create` 接收 request 並呼叫 handler。同步區段開始。`src/api/OrdersController.cs:21-35`
2. `CreateOrderHandler.Handle` 驗證 request，建立 `Order` 與 `OrderPlaced` event。`src/application/CreateOrderHandler.cs:30-67`
3. `OrderRepository.Add` 將 order 加入 unit of work；outbox interceptor 將 event 轉成 message。`src/infrastructure/OrderRepository.cs:18-25`、`src/infrastructure/OutboxInterceptor.cs:24-58`
4. `UnitOfWork.Commit` 在同一個 DB transaction 寫入 order 與 outbox message。Transaction boundary 在此結束。`src/infrastructure/UnitOfWork.cs:15-31`
5. API 回傳 `201` 與 `ORD-42`。同步區段結束。`src/api/OrdersController.cs:31-35`
6. `OutboxWorker` 在另一個 process/time window 讀取 message，呼叫 Logistics API。非同步區段開始。`src/workers/OutboxWorker.cs:28-71`
7. 成功時標記 delivered；暫時失敗時增加 retry count。`src/workers/OutboxWorker.cs:52-68`

Observable result：client 先看到 `201 { orderId: "ORD-42" }`；物流成功後，outbox row 的 `ProcessedAt` 有值。

Branches：無效 item 在步驟 2 拒絕；DB commit 失敗時步驟 5 不回傳成功；Logistics timeout 在步驟 7 保留 retry state。

## Layer 3：逐步四流對齊

### Step 1：接收 request

- **Logic**：Endpoint 只接受通過 transport validation 的 request。
- **Data**：JSON 轉成 `CreateOrderRequest(customerId, items)`。
- **Program**：ASP.NET runtime → `OrdersController.Create` → handler。
- **State**：尚未修改 domain 或 DB。
- **Boundary**：HTTP API boundary。
- **Evidence**：`src/api/OrdersController.cs:21-35`，Confirmed。

### Step 2：建立 order

- **Logic**：customer 與 items 必須有效；總額由 domain 計算。
- **Data**：Request DTO 轉成 `Order(ORD-42, C-7, 1200)` 與 `OrderPlaced(ORD-42)`。
- **Program**：Handler → validator → `Order.Create` → return order。
- **State**：建立未持久化的 aggregate 與 domain event。
- **Boundary**：Application 到 domain boundary。
- **Evidence**：`src/application/CreateOrderHandler.cs:30-67`、`src/domain/Order.cs:19-54`，Confirmed。

### Step 3-4：原子寫入 order 與 outbox

- **Logic**：只有同時保存 business state 與待送訊息，後續 delivery 才可恢復。
- **Data**：`OrderPlaced` 序列化成 outbox payload，保留 `ORD-42`。
- **Program**：Handler → repository/interceptor → unit of work → database。
- **State**：同一 transaction 新增 `Orders` row 與 `OutboxMessages` row。
- **Boundary**：Database transaction boundary。
- **Evidence**：`src/infrastructure/OutboxInterceptor.cs:24-58`、`src/infrastructure/UnitOfWork.cs:15-31`，Confirmed。

### Step 5：回傳 API 結果

- **Logic**：只有 commit 成功才回傳 `201`。
- **Data**：Domain ID 投影成 `{ orderId: "ORD-42" }`。
- **Program**：Unit of work return → handler → controller → client。
- **State**：DB 已提交；外部物流可能尚未收到通知。
- **Boundary**：HTTP response boundary。
- **Evidence**：`src/api/OrdersController.cs:31-35`，Confirmed。

### Step 6-7：非同步 delivery

- **Logic**：未處理 message 可執行；timeout 進 retry，成功則完成。
- **Data**：Outbox payload 轉成 `CreateShipmentRequest(orderId=ORD-42)`。
- **Program**：Scheduler → worker → Logistics client → worker result handler。
- **State**：成功設定 `ProcessedAt`；失敗增加 `RetryCount` 與 `NextAttemptAt`。
- **Boundary**：Process、queue-like polling、external API boundaries。
- **Evidence**：`src/workers/OutboxWorker.cs:28-71`，Confirmed；物流端是否去重為 Unknown。

## Layer 4：Method 與 Code

**Orientation Gate：** Layer 1 至 3 已建立 order/outbox 的 business、architecture、execution、data、state 與 boundary map；此處沿用，不重講。進入 actual Code Teach 時已載入 `vibe-coding-tutor`，其 pattern 與小型理解檢查直接整合如下。

### Method-chain mental map

**Producer**

- `CreateOrderHandler.Handle → 建立訂單與待送通知，要求兩者一起持久化，並在成功後交回訂單 ID。`
- `UnitOfWork.Commit → 將 order 與 outbox row 一起提交。` **[crosses database transaction boundary]**

**Consumer**

- `OutboxWorker.Process → 在另一個執行時段取得已提交的待送通知，並推進一次 delivery attempt。` **[crosses process/time boundary; polling handoff]**

**External**

- `LogisticsClient.CreateShipment → 將 ORD-42 的 shipment request 送到物流服務。` **[crosses external-system boundary]**

**Completion**

- `OutboxRepository.MarkProcessed / ScheduleRetry → 將本次嘗試記成已完成，或留下可再次嘗試的狀態。`

**直覺模型：** 同一個上鎖抽屜先一起收好「訂單收據」和「待寄物流通知」。Handler 負責放入並鎖好；worker 之後只拿待寄通知去投遞，再把它標成已寄或待重試。

**精確技術說明：** `Handle` 產生並提交 order/outbox；commit 是 transaction 交接點。`Process` 在另一個 time window 消費已提交的 outbox row，external client 只負責一次 API call，repository completion method 才記錄 processed/retry state。

**比喻限制：** 抽屜只說明 atomic commit 與責任交接；它不保證 worker 只送一次，也不證明 Logistics API 已去重或已完成內部處理。

### Code Teach group 1：`CreateOrderHandler.Handle`

以下 causal node 只作導航：

- **Position**：`OrdersController.Create` → **`Handle`** → `UnitOfWork.Commit` → controller 使用回傳 ID。
- **Responsibility / Not responsible for**：協調建立訂單並提交 business/outbox state；不投遞物流通知，也不處理 retry 或 completion state。
- **Input / Pre-state**：DB 尚無 `ORD-42`；輸入是 `CreateOrderRequest(C-7, items)` 與 cancellation token。
- **Result / Effect**：系統已持久保存 `ORD-42` 及其待送物流通知，呼叫端可取得訂單 ID。
- **Handoff / Downstream impact**：controller 以 ID 回 `201`；已提交的 outbox row 讓 worker 之後能接棒。Commit 失敗時兩者都不能發生。

**Implementation algorithm：** (1) 驗證 request；(2) 建立 aggregate/event；(3) 交 repository tracking；(4) await commit；(5) commit 成功才 return ID。`src/application/CreateOrderHandler.cs:30-67`

**Bounded code walkthrough：**

```csharp
validator.Validate(request);                         // 無效輸入在寫 state 前停止
var order = Order.Create(request.CustomerId, items); // 建立 ORD-42 與 OrderPlaced
repository.Add(order);                               // 加入 unit-of-work tracking，尚未 commit
await unitOfWork.Commit(cancellationToken);           // 等 order/outbox 同一 transaction 完成
return order.Id;                                      // 只在 commit 成功後交回 ORD-42
```

- `Validate` 失敗：拋出 validation error；沒有 order/outbox post-state。
- `Commit` 失敗或 cancellation：不執行 `return`，caller 不得回 `201`。
- 正常 `return ORD-42`：程式值是 ID；語意是 transaction 已成功，並不表示物流已收到。
- **Post-state**：成功時 DB 有 order 與 outbox row；失敗時此 transaction 不留下半套結果。
- **Caller consumption / next handoff**：controller 把 ID 投影成 `201` response；worker 稍後從已提交 outbox row 接棒。

### Code Teach group 2：`OutboxWorker.Process`

以下 causal node 只作導航：

- **Position**：hosted-service polling loop → **`Process`** → `LogisticsClient.CreateShipment` → `MarkProcessed` / `ScheduleRetry` → commit。
- **Responsibility / Not responsible for**：協調單次 delivery attempt 並推進 outbox state；不建立 order、不回應原始 HTTP request，也不決定物流服務內部是否去重。
- **Input / Pre-state**：`ORD-42` 的 outbox row 已 commit、`ProcessedAt=null` 且已到期；worker 收到 message payload。
- **Result / Effect**：一筆到期通知已完成一次物流投遞嘗試，資料庫留下成功或重試結果。
- **Handoff / Downstream impact**：成功 state 使未來 polling 跳過此 row；retry state 使未來 iteration 能再次接棒。未分類 exception 的 downstream effect 是 Unknown。

**Implementation algorithm：** (1) payload mapping；(2) await 外部 call；(3) success branch 標記 processed，timeout branch 安排 retry；(4) await commit 保存 branch 結果。`src/workers/OutboxWorker.cs:28-71`

#### Mechanism Unit / Primitive Bridge：`async` / `await`

- **Problem / general meaning**：外部與 DB I/O 不會立即完成；`await` 暫停 method，完成後從下一行續跑。
- **Actors / shared resource**：worker 啟動兩次 I/O，Logistics client 與 database 完成它們；`async/await` 不保護 shared memory。
- **Coordination sequence**：先等 Logistics 結果，依 success/timeout 選 branch，再等 DB commit 保存結果。
- **Guarantees / prevented failures**：後續 branch 只在 await 取得結果後執行，exception 在 await 點進入 `catch`；它不防止兩個 workers 同時處理同一 row。
- **Limitations**：只描述此 process 內的非同步控制流；不提供 transaction、cross-process mutual exclusion、delivery exactly-once 或 distributed coordination。
- **Failure / retry / recovery**：timeout 進 retry branch；cancellation 或其他 exception 的 recovery 無證據，標成 Unknown。
- **Exact code touchpoints**：`await logistics.CreateShipment` 是 lines 45-46 的 external I/O；`await unitOfWork.Commit` 是 lines 66-67 的 persistence I/O。回到演算法第 2 步繼續。

**Bounded code walkthrough：**

```csharp
var request = mapper.ToShipment(message.Payload); // Input + Transformation
try {
    await logistics.CreateShipment(request);       // Call across external boundary
    outbox.MarkProcessed(message, clock.UtcNow);   // State: completion
} catch (TimeoutException) {
    outbox.ScheduleRetry(message, clock.UtcNow);   // State: retry
}
await unitOfWork.Commit(cancellationToken);         // Persist result
```

- Mapping 只建立 Logistics DTO，尚未改 durable state。
- External call 正常完成：走 success branch，`ProcessedAt` 取得時間值。
- `TimeoutException`：catch 吃下本次 timeout，`ProcessedAt` 維持 null，設定 retry state；這不是成功 return。
- 其他 exception：證據未顯示 branch，標為 Unknown，不猜測是否 commit。
- Method 正常完成時回傳不含 domain value 的 `Task`；語意結果在 persisted outbox state，不在 return payload。
- **Post-state**：成功 branch 可觀察 processed；timeout branch 可觀察 `RetryCount/NextAttemptAt`；兩者都要 commit 才 durable。
- **Caller consumption / next handoff**：polling loop 以 Task completion 判定本次呼叫結束；retry row 由未來 polling iteration 再取用。
- **理解檢查**：若 Logistics call timeout，commit 前 `ProcessedAt`、`RetryCount`、`NextAttemptAt` 各應是什麼狀態？

## Layer 5：Change、設計理由與驗證

### Before / After

- Before：Handler 在 commit 後直接呼叫 Logistics API。Process crash 可能留下已提交 order，但沒有可恢復通知。Old evidence：`src/application/CreateOrderHandler.cs:45-58` (old)。
- After：Handler 只提交 order 與 outbox；worker 執行外部呼叫。Current evidence：`src/infrastructure/OutboxInterceptor.cs:24-58`、`src/workers/OutboxWorker.cs:28-71`。

### Change Map

- `[MODIFIED]` `src/application/CreateOrderHandler.cs:45-67`：移除直接 external call，映射 Layer 2 步驟 3 至 5。
- `[ADDED]` `src/infrastructure/OutboxInterceptor.cs:24-58`：將 domain event 寫成 outbox，映射步驟 3 至 4。
- `[ADDED]` `src/workers/OutboxWorker.cs:28-71`：執行 async delivery/retry，映射步驟 6 至 7。

### Design Rationale

- **Confirmed**：測試要求 order 與 outbox 同時 commit。`tests/OrderOutboxTests.cs:18-66`
- **Inferred**：設計目的是縮小 DB commit 後 process crash 的訊息遺失窗口；依據是移除直接 call 並新增持久化 outbox。
- **Unknown**：作者是否比較過 message broker transaction；沒有 ADR 或 issue evidence。
- Trade-off：增加 delivery latency、worker 與 retry state；換取可恢復性。

### Tests Present

- `tests/OrderOutboxTests.cs:18-66` 存在 atomic persistence 測試。
- `tests/OutboxWorkerTests.cs:22-94` 存在 success 與 timeout retry 測試。
- 測試存在不代表本次已執行。

### Verification Plan

1. 執行 `dotnet test tests/Orders.Tests.csproj --filter Outbox`。
2. 觀察 successful create 同時產生 order/outbox rows。
3. 模擬 Logistics timeout，觀察 `RetryCount` 增加且 `ProcessedAt` 保持 null。

### Actual Execution Evidence

`Not run`。本範例沒有真實 repository 或 command output。

### Unknowns

- Logistics API 是否用 `orderId` 實作 idempotency。
- Worker 遇到永久錯誤的 dead-letter policy。

## Layer 6：完整心智模型

文字心智圖：

`HTTP request → Handler/Domain → Order + Event → DB transaction(Order + Outbox) → HTTP 201 → Worker → Logistics API → Processed/Retry state`

資料生命週期：`ORD-42` 從 domain ID 進入 order row 與 outbox payload，再成為 Logistics request key，最後可由 outbox delivery state 觀察。

完整重述：

1. Customer 送出 request，controller 將 use case 交給 handler。
2. Handler 驗證資料並建立 `Order(ORD-42)` 與 domain event。
3. Interceptor 將 event 轉成 outbox row。
4. Unit of work 原子提交 order 與 outbox，因此兩者一起成功或一起失敗。
5. API 在 commit 後先回傳 `ORD-42`，不等待 Logistics API。
6. Worker 之後送出 shipment request，成功時標記 processed，timeout 時留下 retry state。
7. 目前證據沒有證明 Logistics API 具備去重能力。

Invariants：API 不得在 commit 前回傳成功；已提交且需要物流的 order 必須有 outbox row；只有成功 delivery 才設定 `ProcessedAt`。

自我檢查：若 DB commit 成功後 API process 立即中止，哪一筆資料讓新 worker 仍能恢復物流通知？

未追蹤路徑：permanent failure、dead-letter、Logistics 端 idempotency。
