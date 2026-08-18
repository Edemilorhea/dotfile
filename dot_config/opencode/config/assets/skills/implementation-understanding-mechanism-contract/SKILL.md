---
name: implementation-understanding-mechanism-contract
description: Use ONLY when implementation-understanding-tutor explicitly delegates a mechanism, primitive bridge, ELI5 gate, or comprehension repair. Do not trigger independently for general framework explanations.
---

# Implementation Understanding Mechanism Contract

這是 `implementation-understanding-tutor` 的受控 supporting contract。只處理理解目前 Flow handoff 或 Code group 所需的單一 mechanism，以及 ELI5 與理解失敗修補 gate。沿用 Orchestrator 的 scope、共同例子與輸出骨架。

## Just-in-time Mechanism

Mechanism 是可獨立閱讀的視角，但採 just-in-time 原則。若它是理解下一個 Flow handoff 或 Code group 的必要前提，先插入一個短 unit，再精確映回 code 並恢復原本導讀；若不是必要前提，記入待讀清單，不立即展開。例：transaction、outbox、eventual consistency、`Channel`、lock、DI scope、retry、idempotency。

符合任一條件且該 mechanism 是理解目前或下一個 handoff/code group 的必要前提時才建立 unit：

- 讀者明確詢問。
- construct 非直觀且控制 concurrency、lifecycle 或 state。
- 它決定 handoff guarantee、failure 或 downstream behavior。
- deep 或 guided Code Teach 首次實質使用該特定 construct。

若不必要，記入待讀，不得因模式本身自動插入。不要解釋每個 syntax token，也不要假設 architecture 理解代表 mechanism 理解。一次只解釋一個主要 mechanism。

## Primitive Bridge

每個 unit 固定回答：

1. **Problem / general meaning**：要解決的問題與最小語意。
2. **Actors / shared resource**：誰參與、誰 write/read、保護或交換什麼。
3. **Coordination sequence**：它們如何協作與交接。
4. **Guarantees / prevented failures**：允許什麼，避免什麼 race、loss 或 duplication。
5. **Limitations**：例如 process-local，不等於 durable 或 distributed coordination。
6. **Failure / retry / recovery**：失敗如何影響 downstream，如何恢復；不適用時明寫。
7. **Exact code touchpoints**：對回 `file:line-range`，然後接回被暫停的 Flow 或 Code step。

## ELI5 Gate

蒐集證據後辨識真正難點。只有難點符合下列至少兩項，才明確載入 `eli5-explainer`：

- 抽象且不可直接觀察。
- 跨元件或跨時間。
- 違反初學者直覺。
- 涉及順序、狀態或邊界。
- 是已知理解缺口。
- 是本次第一次出現的重要機制。

預防性規則：若一個機制由至少 3 個相似命名或相鄰責任的方法協作，且讀者需要分辨責任交接，視為「已知高混淆 method cluster」。不必等待使用者表示看不懂；在相關 Code unit 前明確載入 `eli5-explainer`。

對符合 gate 或高混淆 cluster 的單一機制，依序加入「直覺模型 → 精確技術說明 → 比喻限制」。ELI5 只套用該機制，不套整篇。Endpoint 接 request、DTO mapping、回傳 ID、一般 `SaveChanges` 等可直接觀察內容，通常不載入 ELI5。

常見候選包括 transaction、outbox、eventual consistency、dependency injection、event dispatch、async queue、idempotency、snapshot、retry、recovery 與 domain invariant。候選仍須通過 gate。

## 理解失敗修補

使用者表示看不懂、太複雜、必須重讀、串不起來或要求換個方式時，明確載入 `wait-what`。`wait-what` 只用於理解已失敗後的修補：只修補一個最小理解缺口，不重貼或濃縮整份報告。
