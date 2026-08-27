---
description: 多方抗辯 (Adversarial Review) - 以固定範圍、固定預算與證據裁決審查重大結論
---

# 多方抗辯流程（Adversarial Review）

**待審對象**: $ARGUMENTS

若為空，以當前對話中最近一個重大結論、設計、計畫、修正或根因判定為準。

## 目的

防止「聽起來合理但其實是錯的」結論被採信。三個獨立鏡頭負責找反例；主代理負責驗證決定性事實與作出裁決。`SURVIVED` 只表示命題通過本次有限審查，不等於已證明為真。

## 執行步驟

### 1. 建立不可變 Review Contract

每個命題建立一份自足 contract：

```yaml
review_id: <唯一 ID>
version: 1
object_type: hypothesis | root_cause | plan | fix | implementation | verification
original_question: <原始問題>
claim: <唯一、可反駁的一句話命題>
decision: <此命題將支援的決策>
evidence: <file:line、測試輸出或量測值>
scope: <本次允許檢查的元件、情境與檔案>
out_of_scope: <明確排除項目>
pass_criteria: <何時可判定通過有限審查>
budget:
  max_claims: 2
  reviewers_per_claim: 3
  max_initial_calls: 6
  max_extra_reviews: 1
  max_total_calls: 12
```

同一 `review_id` 與 `version` 的 `claim`、`decision`、`scope`、`out_of_scope`、`pass_criteria` 和 `budget` 不得在審查中改寫。多條獨立 finding 必須使用不同 `review_id`，每次命令最多審兩條；其餘列為超出預算，不得自動分批。

### 2. 單輪平行審查

同一則訊息透過 task 工具平行呼叫 `Skeptic`、`RedTeam`、`Simplifier`，不得串行、合併角色或自動重試。每個 prompt 必須包含完全相同的 contract、相關檔案路徑及該鏡頭任務。

每個 objection 必須包含：

- `objection_id`
- `classification: BLOCKER | QUALIFIER | OUT_OF_SCOPE`
- `relation_to_claim`
- `decision_impact`
- `evidence_strength: VERIFIED | OBSERVED | INFERRED | SPECULATIVE`
- `evidence`

只有直接影響 `claim` 或 `decision` 且證據充分的 `BLOCKER` 能推翻命題。`SPECULATIVE` 不得單獨造成 `REFUTED`。次要限制屬於 `QUALIFIER`；contract 範圍外的內容屬於 `OUT_OF_SCOPE`，不得阻斷。相同失效條件、證據與決策影響的 objection 必須去重。

### 3. 主代理驗證與裁決

Agent verdict 是線索，不是票數。主代理必須以 Read、Grep、測試、文件或其他可觀察方式，獨立驗證所有會改變最終裁決的新事實。無法驗證時保留原 evidence strength，不得假裝已確認。

最終終態只有：

- `REFUTED`：至少一個決定性 blocker 已由主代理獨立驗證。
- `INCONCLUSIVE`：關鍵證據不足或衝突，或兩個以上 Agent 失敗、取消或未有效完成。
- `SURVIVED`：至少兩個 Agent 有效完成，且沒有已驗證 blocker 或未解的關鍵證據。這不是事實證明。
- `ABORTED`：缺少可審命題、需要改命題或擴大範圍、需要增加預算，或已達呼叫上限而無法完成。

單一 Agent 失敗時可降級完成，但必須標示 `coverage: degraded`。`NOT_APPLICABLE` 若有具體理由，視為有效完成，不視為支持票。

### 4. 終止與版本規則

完成一輪、找到已驗證 blocker、關鍵證據不足、兩個以上 Agent 失敗、需要超出 scope、需要改寫命題或達到預算時立即停止。不得自動修改或重跑。

修正後的命題必須成為 `version: 2` 或新的 `review_id`。只有在主代理或使用者明確決定後才能開始；每次命令最多一次額外 review。若需擴大 scope、改變 decision 或增加 budget，必須先詢問使用者。

### 5. Outcome-first 回報

先回報：`抗辯結果：<SURVIVED | REFUTED | INCONCLUSIVE | ABORTED> - <一句主要理由>`。

接著依序列出：

1. 三鏡頭簡表：鏡頭、verdict、關鍵理由、是否有效完成。
2. `BLOCKER`：含主代理驗證結果。
3. `QUALIFIER`。
4. `OUT_OF_SCOPE`。
5. Coverage 與實際使用的 calls/budget。
6. 是否值得建立 v2 或新 review；不得直接宣稱將自動重審。

## 禁止事項

- 不得因為趕時間跳過任何一個鏡頭；呼叫失敗必須依降級規則處理。
- 不得把三個鏡頭合併成一個 agent 跑（獨立性是抗辯的前提）。
- 不得用多數票代替事實驗證。
- 不得在同一版本內移動範圍、通過標準或命題。
- 不得讓 `QUALIFIER`、`OUT_OF_SCOPE` 或單獨的 `SPECULATIVE` objection 推翻命題。
- 不得自動重審、無限保存歷史或超過 contract budget。
- 未經抗辯的單源重大結論只能標示為「未抗辯假設」，不得當事實陳述。
