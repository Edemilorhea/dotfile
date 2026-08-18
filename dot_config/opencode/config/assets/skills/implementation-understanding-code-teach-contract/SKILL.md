---
name: implementation-understanding-code-teach-contract
description: Use ONLY when implementation-understanding-tutor explicitly delegates Layer 4 or an actual method/code walkthrough. Do not trigger independently for ordinary code review or code generation.
---

# Implementation Understanding Code Teach Contract

這是 `implementation-understanding-tutor` 的受控 supporting contract。只處理 actual Code Teach。沿用 Orchestrator 已選定的 scope、mode、共同例子、coverage ledger 與輸出骨架，不另起 tutorial report。

## Orientation Gate

開始逐 method 細讀前，讀者必須已有相關 business、architecture、execution、data、state 與 boundaries 的可用地圖。Layer 1 的初始心智圖是 pre-code map；Layer 6 仍是教學後重建的 final model。

- 若先前對話已建立足夠 orientation，明說「沿用已建立的 orientation」，不要重講完整架構。
- 若不足，只補能定位本次 method 的最小地圖，再進 Code Teach；不要藉 gate 展開完整報告。
- Orientation Gate 判斷理解前提，不假設懂 architecture 就等於懂語言或 framework primitives。

明確 Code Teach 的第一個實質回覆可先給最多 3 至 7 步的最小 orientation，但同一回覆必須開始第一個 coherent method group 的 bounded actual code walkthrough。不要先花一整輪只交付 change inventory、architecture 或 mechanism report。

## 必要 Skill 載入

進入 actual Code Teach 時，必須明確載入 `vibe-coding-tutor`。用其 evidence/teaching support 補強 project map、architecture walkthrough、key patterns、small exercises 與 extension points；去重後整合進 Orchestrator 的既有輸出，不得附加另一份 report。

遇到必要 mechanism 或高混淆 method cluster 時，明確載入 `implementation-understanding-mechanism-contract`。由該 contract 判斷並載入 `eli5-explainer`。使用者表示理解失敗時，該 contract 可載入 `wait-what` 修補單一缺口。

## Method-chain Mental Map

固定先輸出 **Method-chain mental map**，再按實際 execution order 教 code。這張局部 map 不重複完整操作流；它將每個方法壓成一句結果，以顯示責任如何交接。

- 依實際機制分組，例如 Producer、Wake-up、Consumer、External、Completion；不存在的組別不得硬造。
- 每個節點使用 `MethodName → 一句執行結果`，並標出跨 transaction、process、queue 或 external boundary 的交接。
- 只有單一 method 時，可用一行標示其上下游位置，不需假裝存在多方法鏈。
- 若符合高混淆 method cluster 規則，在 map 後、causal nodes 前加入 bounded ELI5。

## Causal Node 與 Walkthrough

每個 method/group 先用五欄 causal node 作導航：

1. **Position**
2. **Responsibility / Not responsible for**
3. **Input / Pre-state**
4. **Result / Effect**
5. **Handoff / Downstream impact**

Node 只負責定位，不重複 algorithm，也不是 implementation teaching 的替代品。若多個 node 的 Result/Effect 幾乎相同，重新切分責任或明確指出 wrapper/delegation。

Node 後立即進入自然的 implementation walkthrough，不再建立第二張固定欄位表。Walkthrough 必須：

- 引用足夠且有界的 actual code，通常 10 至 40 行，以語意完整為準，不在 branch 或 handoff 中間硬切。
- 依 actual execution order 串起 algorithm，不按檔名或 diff 順序。
- 在相關行旁說明 branch、early return、null、status、exception、void 的語意。
- 說明 post-state、caller consumption，以及 success/failure/cancellation 對 downstream 的差異。
- 區分可觀察的 semantic result 與只描述程式回傳值的 return value。
- 每個 code-specific claim 附 `file:line-range` 與 confidence。
- 有助理解時才加入一個 trace、prediction、small exercise 或 teach-back。

這些是 walkthrough 必須涵蓋的證據，不是另外十個 headings 或 card fields。主路徑先於 failure、alternative 與 edge cases。

## Coverage

Method 涵蓋深度：

- `overview`：主要入口、關鍵決策與跨邊界方法。
- `standard`：所有會影響選定路徑行為、資料、狀態或副作用的方法。
- `deep`：選定路徑實際經過的所有方法，加上重要 helper 與失敗 branch；不要無謂展開 framework internals。

若目標是 branch、range、PR 或 working tree 的所有修改，沿用內部 coverage ledger，依實際 caller 與 execution order 教每條 runtime story。無 runtime path 的變更依 consumer、載入時機或 build/runtime effect 教。不得用單一代表路徑冒充所有修改。

Code Teach 是 comprehension，不是 correctness、security、performance、maintainability 或 approval review。不要混入未要求的 Code Review findings；若使用者明確同時要求評估，另以 **Code Review findings** 標示。
