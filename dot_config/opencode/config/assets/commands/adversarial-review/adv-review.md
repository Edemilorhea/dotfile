---
description: 以固定範圍、固定預算與證據裁決對重大結論或計畫進行多方抗辯
---

# 多方抗辯流程（Adversarial Review）

**待審對象**: $ARGUMENTS

若待審對象為空，以當前對話中最近一個重大結論、設計、計畫、修正或根因判定為準。

## Review Contract

每個命題建立不可變 contract：`review_id`、`version`、`object_type`（`hypothesis | root_cause | plan | fix | implementation | verification`）、`original_question`、唯一 `claim`、`decision`、`evidence`、`scope`、`out_of_scope`、`pass_criteria`、`budget`。

固定預算為每次命令最多兩個命題、每個命題三個 reviewer、初始最多六次 task calls、最多一次明確決定的額外 review、總計最多十二次 calls。同一 `review_id` 與 `version` 不得改寫命題、決策、範圍、通過標準或預算；其他 finding 列為超出預算，不得自動分批。

## 執行

1. 在同一則訊息中平行呼叫 `Skeptic`、`RedTeam`、`Simplifier`。不得串行、合併角色、自動重試或自動重審。
2. 每個 objection 必須包含 `objection_id`、`classification: BLOCKER | QUALIFIER | OUT_OF_SCOPE`、`relation_to_claim`、`decision_impact`、`evidence_strength: VERIFIED | OBSERVED | INFERRED | SPECULATIVE` 及 `evidence`。
3. 只有直接影響命題或決策且證據充分的 blocker 能推翻命題。`SPECULATIVE` 不得單獨造成 `REFUTED`；qualifier 與 out-of-scope 不阻斷。相同失效條件、證據和決策影響的 objection 必須去重。
4. Agent verdict 是線索，不是票數。主代理必須獨立驗證所有會改變裁決的新事實。

## 裁決與終止

- `REFUTED`：至少一個決定性 blocker 已由主代理獨立驗證。
- `INCONCLUSIVE`：關鍵證據不足或衝突，或兩個以上 Agent 失敗、取消或未有效完成。
- `SURVIVED`：至少兩個 Agent 有效完成，且沒有已驗證 blocker 或未解的關鍵證據；這只表示通過有限審查。
- `ABORTED`：缺少可審命題，或需改命題、擴大範圍、增加預算、超過呼叫上限。

單一 Agent 失敗可降級完成，但必須標示 `coverage: degraded`。完成一輪或命中任一終止條件後立即停止。修正命題必須使用 `version: 2` 或新 `review_id`，並由主代理或使用者明確決定；每次命令最多一次額外 review。擴大 scope、改變 decision 或增加 budget 前必須詢問使用者。

## 回報

先輸出 `抗辯結果：<SURVIVED | REFUTED | INCONCLUSIVE | ABORTED> - <主要理由>`，再列三鏡頭簡表、blocker 與驗證結果、qualifier、out-of-scope、coverage、calls/budget，以及是否值得建立新 review。不得以過程淹沒主要裁決。
