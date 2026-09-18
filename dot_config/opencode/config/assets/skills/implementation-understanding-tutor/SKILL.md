---
name: implementation-understanding-tutor
description: |-
  當使用者看完 change、flow 或 tutorial 仍串不起來，要求完整理解某個 commit、feature 或 code，或希望從 business logic、修改內容、逐段 code、runtime/data flow、設計理由到驗證一路教懂時，應積極使用此 skill。
  使用者想分開看架構、流程、機制、Code，或說「Code Teach」、「帶我讀 Code」、「導讀整個分支的修改」、「不知道 method 在幹嘛／怎麼實作」時也應使用：用責任、結果、交接與後續影響串起 actual code 與必要的 framework/concurrency primitives。
  它整合 change-understanding-review、feature-flow-explainer 與 vibe-coding-tutor 的證據，以四視角分段或一次報告交付。這不是 conventional code review，不因一般 correctness／approval 請求而觸發。
---

# Implementation Understanding Tutor

這是「把實作真正串懂」的唯讀教學流程。研究時可以來回探索，但交付給讀者的內容固定、可預測、一次一個閱讀單位。不得修改程式碼、設定、資料或測試；使用者要求 correctness、security、performance 或 approval 時，把 code review 拆成另一項工作。

## 使用者怎麼說就怎麼做

使用者不需要記參數。只用三件事決定行為：

| 使用者說的話                                                         | 決定             | 值                                                                                                                                                                              |
| -------------------------------------------------------------------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 「這個 commit」「這個分支的修改」「這個 feature」「這個 method」「整個 repo」 | **看哪裡**（範圍）   | commit / range / PR / working tree / feature / file / symbol / repository                                                                                                       |
| 「看架構」「看流程」「看機制」「看 Code」「Code Teach」「帶我讀 code」   | **看什麼**（視角）   | Architecture / Flow / Mechanism / Code                                                                                                                                          |
| 「一步一步」「帶我」（預設）／「一次輸出」「完整報告」／「考我」            | **怎麼給**（模式）   | guided / report / teach-back                                                                                                                                                    |
| 「只看 X」「不要展開其他」                                                | **只看**（Focused） | 單一 method、payload、transaction、branch 或 data flow                                                                                                                          |

判斷規則：

1. 教學動詞優先：「Code Teach」「帶我讀 code」「逐段讀」「method 怎麼實作」= 視角 Code、模式 guided，第一個實質回覆就要出現 code。
2. 「完整」「全部」「整個分支」只擴大範圍，不改變視角，也不自動變成 report。
3. 只有「一次輸出」「完整報告」「可留存」才用 report；「剩下全部輸出」表示從 guided 切到 report 收尾。
4. 不得把完整請求自行縮成 Focused；範圍真的判不出來時，只問一個會改變範圍的問題。

內部參數（`scope`、`target`、`depth`、`focus`、`learningMode`、`verification`）全由上述自然語言推導，不向使用者展示、不要求使用者指定。`verification` 預設只給計畫；使用者明確要求執行時才跑非破壞性的 tests 或 build。

## 四視角

| 視角             | 回答的問題               | 內容                                                                                                    | 不做什麼                          |
| ---------------- | ------------------------ | ------------------------------------------------------------------------------------------------------- | --------------------------------- |
| **Architecture** | 東西在哪裡，誰負責？     | business purpose、actors、components、責任與排除責任、依賴、boundaries、data ownership、修改落點        | 不展開時間順序或逐行 code         |
| **Flow**         | 一次操作依序如何完成？   | trigger、preconditions、caller/callee、data/state 變化、handoff、同步/非同步與 transaction/process 邊界 | 不展開 framework internals        |
| **Mechanism**    | 這種協作為什麼能運作？   | 問題、參與者、shared resource、協作規則、guarantees、limitations、failure/retry、code touchpoints       | 不重講整個 flow，一次只講一個機制 |
| **Code**         | 程式如何產生並交出結果？ | method chain、inputs、algorithm、bounded actual code、branches/returns、post-state、下一棒如何使用      | 不先輸出架構長文，不混入 review   |

每個 component、step、mechanism 或 method 都沿同一條主線解釋：`Responsibility → Input / Pre-state → Transformation / Result → Handoff → Downstream impact`。只列「誰呼叫誰」不算理解；必須說出它負責什麼、產生什麼結果、下一棒怎麼用、失敗時後續有何不同。

Mechanism 只在理解下一段 code 所必需時 just-in-time 插入，放在使用它的 code 之前。

## 每輪閱讀預算（guided / teach-back）

- 只回答一個主要問題，最多一張主要圖或表。
- Architecture 最多 7 個 components；Flow 最多 7 個 steps；Mechanism 一次一個；Code 一次一個 coherent method group（約 10–40 行）。
- 主路徑先於 failure、alternative 與 edge cases。
- Code 編號反映呼叫階層：被 9 呼叫的方法編為 9.1、9.2，不另起 10、11。
- 結尾固定：簡短進度（`[完成]`／`[目前]`／`[待讀]`）＋最多兩個下一步選項。
- teach-back：每輪只問一個高資訊量問題，針對缺口修正，不重貼整份內容。

使用者說「看不懂」「還是不懂」「X 跟 Y 的關係」時：停在同一單位，載入 `wait-what` 或 `eli5-explainer`，用不同的切法重講（例如先畫兩者關係圖，再回到 code）；不得重複原本結構。

## 內部完整性

為了不漏，內部維護六層 coverage：(1) 功能全貌與初始心智圖 (2) 完整操作流 (3) 逐步四流對齊（Logic / Data / Program / State）(4) Method 與 Code (5) Change、設計理由與驗證 (6) 完整心智模型。六層只用於蒐證、追蹤 coverage 與組 report；guided 每輪仍只交付一個視角單位。

範圍是分支、range、PR 或 working tree 的所有修改時，先建 coverage ledger：runtime execution stories、shared infrastructure、data/schema、configuration、tests。每教完一組就更新，直到所有重要 changed ranges 已教過或明確標成 `Unknown / Not investigated`。不得只挑一條代表路徑就宣稱涵蓋所有修改。

涉及外部系統（例如 Bizform 的 subjectId 規則）的事實，必須以工作區的呼叫程式碼、設定或使用者確認為據；沒有證據就標 `Unknown`，不得假設。

## Supporting Contracts

提及 skill 名稱不會自動載入。依 gate 明確載入：

| Contract                                          | 載入時機                                        | 可繼續載入                                     |
| ------------------------------------------------- | ----------------------------------------------- | ---------------------------------------------- |
| `implementation-understanding-quality-contract`   | 所有實質教學，蒐證與輸出前持續適用              | `iso-24495-plain-language`、`asd-ste100`       |
| `implementation-understanding-report-contract`    | report 模式或需檢查六層 coverage                | code contract                                  |
| `implementation-understanding-code-teach-contract` | Code 視角或任何 actual method/code walkthrough | `vibe-coding-tutor`；必要時 mechanism contract |
| `implementation-understanding-mechanism-contract` | Mechanism 視角、必要 primitive bridge、理解失敗 | `eli5-explainer`、`wait-what`                  |

Contract 不得改變本 skill 的範圍、模式、標題與語氣；所有 evidence 去重後映射回唯一輸出結構。

## 執行流程

1. 依「使用者怎麼說」決定範圍、視角、模式；判不出範圍時問一個問題。
2. 載入 quality contract。
3. 選一個共同的 trigger、request、entity 或 payload 當貫穿例子。
4. 蒐集最小充分 evidence（`grep` 找入口與呼叫者、`read` 讀相符區段）；每個節點記錄責任、輸入、結果、交接、後續影響與 confidence。全分支範圍另建 coverage ledger。
5. Code 視角載入 code contract；Mechanism 載入 mechanism contract；report 載入 report contract。
6. 依閱讀預算交付一個單位；Code Teach 的第一個實質回覆在最多 3–7 步 orientation 後立即進入第一個 method group。
7. 更新進度；輸出前依 quality contract 檢查，不通過先重整。

## 輸出骨架

Report：

```markdown
# [target] Implementation Understanding

## Layer 1：功能全貌與初始心智圖
## Layer 2：完整操作流
## Layer 3：逐步四流對齊
## Layer 4：Method 與 Code
## Layer 5：Change、設計理由與驗證
## Layer 6：完整心智模型
```

Guided / teach-back 每個單位：

```markdown
# [target] Guided Implementation Understanding

## 閱讀進度
## 本次視角：[Architecture / Flow / Mechanism / Code]
## 本次理解目標
## Evidence 與導讀
## Responsibility → Result → Handoff → Downstream impact
## 下一步
```

Focused：

```markdown
# [target] Focused Implementation Deep Dive

## 最小背景
## 在完整操作流的位置
## 本次視角：[Architecture / Flow / Mechanism / Code]
## Evidence 與導讀
## Responsibility → Result → Handoff → Downstream impact
## Unknowns / 驗證
```

需要中型完整範例時，讀取 `references/full-feature-example.md`；它是格式與資訊密度的範例，不是專案事實來源。
