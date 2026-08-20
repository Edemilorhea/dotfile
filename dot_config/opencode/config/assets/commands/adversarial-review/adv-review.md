---
description: 平行派出 Skeptic、RedTeam、Simplifier，對重大結論或計畫進行多方抗辯
---

# 多方抗辯流程（Adversarial Review）

**待審對象**: $ARGUMENTS

若待審對象為空，以當前對話中最近一個重大結論、設計、計畫或根因判定為準。

1. 整理自足的待審包，包含結論或計畫、證據、假設、影響範圍及驗證方式。
2. 在同一則訊息中透過 task 工具平行呼叫 `Skeptic`、`RedTeam`、`Simplifier`。不得串行，也不得合併角色。
3. 將每個具體反對理由納入修正，或明確說明不適用的證據。
4. 兩個以上 Agent 回傳 `REFUTED` 時，擋回並在修正後重新抗辯。
5. 零或一個 Agent 回傳 `REFUTED` 時，可繼續，但必須把未解風險回報給使用者。

最終回報必須列出三個 Agent 的 verdict、關鍵理由，以及 `抗辯結果：N/3 存活`。
