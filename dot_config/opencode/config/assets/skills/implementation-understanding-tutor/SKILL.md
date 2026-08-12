---
name: implementation-understanding-tutor
description: 當使用者看完 change、flow 或 tutorial 仍串不起來，要求完整理解某個 commit、feature 或 code，或希望從修改內容、逐段 code、runtime flow、設計理由到驗證一路教懂時，應積極使用此 skill。它會診斷理解缺口並協調 change-understanding-review、feature-flow-explainer 與 vibe-coding-tutor，形成連貫的證據式教學；這不是 conventional code review，不負責核准程式碼或廣泛尋找 correctness、security、performance 問題。
---

# Implementation Understanding Tutor

這是「把實作真正串懂」的上層 Orchestrator。它不複製底層 skills 的完整流程，而是依使用者的理解缺口，選擇、銜接並整合必要證據，讓同一個具體例子從 change 一路貫穿 code、flow、design、verification 與 learning。

本 skill 是唯讀理解工作，不是 conventional code review。不得修改程式碼、設定、資料或測試；只有 `verification=run` 時，才可依 repository 規則執行非破壞性的 tests、build 或 debug 實驗。若使用者另求 correctness、security、performance、maintainability 或 approval，將審查明確拆成另一項工作。

## 學習目標

| 能力 | 解決的卡點 |
|---|---|
| **Code Reading Literacy** | 看得見 syntax 卻讀不出每段 code 的 input、branch、state change、output，以及片段之間如何銜接。 |
| **Runtime Mental Model** | 知道有哪些 class/function，卻不知道誰先呼叫誰、資料如何流動、何時持久化、何處非同步，以及結果在哪裡可觀察。 |
| **Design Rationale Reconstruction** | 知道「怎麼寫」，卻不知道「為何這樣寫」、限制與 trade-off；同時避免把合理猜測說成作者事實。 |
| **Active Verification** | 覺得自己懂了卻無法預測行為、設計實驗或用證據確認；區分測試存在、驗證計畫與實際執行結果。 |

## 參數

所有參數均可由自然語言推導；無法可靠推導且會改變範圍時才詢問。identifier、path、commit SHA 與參數值保持英文。

### `focus`

`focus = auto | all | change | code | flow | design | verify | learn`，預設 `auto`。

| 值 | 何時使用 |
|---|---|
| `auto` | 使用者只說「還是不懂」「幫我串起來」或缺口不明。先依訊息與證據診斷卡點，只跑必要階段。 |
| `all` | 使用者要求完整理解、從頭到尾教懂，或明確指定完整 pipeline。強制執行下方固定順序。 |
| `change` | 只想知道改了什麼、前後差異與需求對應。 |
| `code` | 只想逐段讀懂 file、symbol、branch 或資料轉換。 |
| `flow` | 只想串起 runtime call/data/state flow。 |
| `design` | 只想重建設計理由、限制、替代方案與 trade-off。 |
| `verify` | 只想知道如何驗證理解或行為。是否實際執行仍由 `verification` 決定。 |
| `learn` | 需要 tutorial、練習、提問或 teach-back，而非新增廣泛分析。 |

`focus=all` 固定依序涵蓋：

`Repository Context → Change → Code Reading → Runtime Flow → Design Rationale → Verification → Tutorial → Teach-back`

若 `learningMode=report`，最後的 Teach-back 改成自我檢查題，不要求使用者互動。

`focus=auto` 必須先指出診斷到的缺口與證據，再選必要階段。缺少某 specialist 或其狀態不影響作答：以可取得的實際證據完成答案，不得為填滿模板而無謂擴大範圍。

### `scope` 與 `target`

`scope = commit | range | pr | working-tree | feature | file | symbol | repository`

`target` 必填或必須可從對話、目前 repository 狀態可靠推導。

| `scope` | `target` 例子與規則 |
|---|---|
| `commit` | commit SHA，例如 `a1b2c3d`；未給 SHA 但明確指「剛才那個 commit」且可唯一推導時可省略。 |
| `range` | revision range，例如 `main..feature/auth`。 |
| `pr` | PR number 或 URL，例如 `#128`。 |
| `working-tree` | 通常為目前 repository；`target=staged` 可限定 staged changes。 |
| `feature` | feature 名稱、入口或完成條件，例如 `checkout retry`。 |
| `file` | repository-relative path，例如 `src/auth/session.ts`。 |
| `symbol` | qualified symbol，必要時連同 path，例如 `src/auth/session.ts::refreshSession`。 |
| `repository` | repository root；僅在使用者真的要全 repo 心智模型時採用。 |

若有多個可能的 `target` 且選擇會改變結論，先問一個精準問題；否則明列推導結果後繼續。

### `depth`

`depth = overview | standard | deep`，預設 `standard`。

| 值 | 何時使用 |
|---|---|
| `overview` | 快速建立主線，只保留關鍵 change units、核心 call chain 與主要理由。 |
| `standard` | 預設；提供足以重建行為的 code ranges、資料流、理由與驗證計畫。 |
| `deep` | 使用者要求逐段、交易/非同步邊界、替代方案、邊界案例或深入 teach-back；仍不得無界擴張。 |

### `verification`

`verification = none | plan | run`，預設 `plan`。

| 值 | 何時使用 |
|---|---|
| `none` | 不提供驗證步驟，也不執行命令。 |
| `plan` | 提供可觀察、可重現的驗證計畫，但不執行任何 tests/build/debug 實驗。 |
| `run` | 使用者明確允許實際驗證；才可執行非破壞性的 tests、build 或 debug 實驗，且必須遵守 repo 規則與既有核准邊界。 |

任何模式都要分開描述：

1. **Tests present**：找到哪些測試，只代表存在或可能覆蓋。
2. **Verification plan**：建議執行什麼、預期觀察什麼。
3. **Actual execution evidence**：只有真的執行且取得輸出，才能寫 passed/failed；附 command 與結果。

不得把「存在測試」寫成「測試已通過」，也不得沿用沒有可追溯輸出的執行宣稱。

### `learningMode`

`learningMode = report | guided | teach-back`，預設 `guided`。

| 值 | 何時使用 |
|---|---|
| `report` | 使用者要一次讀完的自含式說明；不強制互動，以自我檢查題收尾。 |
| `guided` | 預設；分段解釋，在關鍵心智模型節點提出少量確認問題，再依回答調整。 |
| `teach-back` | 使用者想確認是否真的內化；要求使用者用自己的話預測 flow、解釋理由或設計驗證，再針對缺口修正。 |

互動不得變成考試轟炸。每輪只問一個高資訊量問題；若使用者要求直接報告，就完整回答，不以等待互動阻塞。

### `repositoryContext`

`repositoryContext = auto | codemap | local | none`，預設 `auto`。

| 值 | 何時使用 |
|---|---|
| `auto` | 優先使用已知上下文與局部探索；只有陌生大型 repo 或使用者明確要求 map 時才考慮 `codemap`。 |
| `codemap` | 明確需要 repository map，且 `codemap` 可用；僅作 context，不取代 code/diff 證據。 |
| `local` | 只用 repository 內實際 files、search、diff、tests 與文件。 |
| `none` | 不建立額外 repository context，只處理已提供材料。 |

不得因為有 `codemap` 就盲目重建 repository。若現有 context 足以回答，直接使用；若 `codemap` 不可用，退回 `local`，不影響答案。

## Routing 與橋接

- `change` → 按需協調 `change-understanding-review`，取得完整 change inventory、before/after 與需求對應。
- `flow` → 按需協調 `feature-flow-explainer`，取得實際 caller、call chain、data/state flow、transaction 與 async boundaries。
- `learn` 或 Tutorial → 按需協調 `vibe-coding-tutor`，把已建立的同一條主線轉成教學、練習與 extension mental model。
- Repository Context → 僅在陌生大型 repo 或使用者明確要求 map 時使用 `codemap`；它只是可選 context。
- `code`、`design`、`verify` → 由本 Orchestrator 作橋接層，基於實際 code、diff、tests 與執行證據解釋；必要時可使用 read-only exploration 找到 caller、symbol、tests 或設定。

不要逐字拼接 specialist 報告。先選一個代表性例子或資料，例如 `orderId`，讓它依序回答：「哪個 change 引入它 → 哪段 code 轉換它 → runtime 如何傳遞它 → 為何選此設計 → 如何觀察與驗證」。

## 證據與推理規則

1. 每個 code-specific claim 必須附目前版本的 `file:line-range`；舊版證據則標明 old/diff range。
2. 設計理由逐項標示：
   - **Confirmed**：由 requirement、issue、commit message、ADR、註解或測試明確支持。
   - **Inferred**：由 code structure、constraint 或行為合理推導，並說明推導依據。
   - **Unknown**：現有證據無法判定，不替作者補故事。
3. 先找實際 caller 再描述 runtime 順序；interface、registration、method 存在不等於已執行。
4. 明確區分目前實作、目標設計與建議；不可混寫。
5. 閱讀足夠 surrounding code 以解釋 input、condition、transformation、state 與 output，但不展開無關 repository 區域。
6. 不讀 secrets、credentials 或 `.env`，並遵守最近的 repository instructions。

## 執行流程

1. **解析參數**：列出已給定與推導的 `focus`、`scope`、`target`、`depth`、`verification`、`learningMode`、`repositoryContext`。
2. **診斷缺口**：對 `focus=auto`，從使用者語句與既有證據判斷是 change、code、flow、design、verify 或 learn 卡住。
3. **設定主線**：選一個具體 trigger、request、entity 或資料值作為所有段落的共同例子。
4. **蒐集最小充分證據**：按 routing 使用必要 skills 或 read-only exploration；記錄缺口，不用猜測補齊。
5. **建立連續心智模型**：說明需求/修改如何落到 code，code 如何在 runtime 被呼叫，理由如何受限制支持，驗證如何觀察同一行為。
6. **依學習模式交付**：`report` 一次完成；`guided` 在關鍵節點確認；`teach-back` 要求預測或重述後針對缺口回教。
7. **誠實收尾**：列出 Unknown、未執行項目與下一個最小學習步驟。

## 參數解析範例

### 完整 commit

使用者：「完整教懂我 commit `a1b2c3d`，包含設計理由與怎麼驗證。」

```text
focus=all scope=commit target=a1b2c3d depth=standard verification=plan learningMode=guided repositoryContext=auto
```

### 只看 symbol

使用者：「只逐段解釋 `src/auth/session.ts::refreshSession`，不要展開其他功能。」

```text
focus=code scope=symbol target=src/auth/session.ts::refreshSession depth=deep verification=none learningMode=report repositoryContext=local
```

### 只串 feature flow

使用者：「只幫我串起 `checkout retry` 從 API 到 worker 的 flow。」

```text
focus=flow scope=feature target="checkout retry" depth=standard verification=plan learningMode=report repositoryContext=auto
```

### 不確定缺口，使用 auto + teach-back

使用者：「我看過解說但還是串不起來，帶我確認到底哪裡不懂，最後讓我講一次。」

```text
focus=auto scope=feature target=<由對話推導；無法唯一推導則詢問> depth=standard verification=plan learningMode=teach-back repositoryContext=auto
```

### Working tree 完整理解

使用者：「把目前 working tree 的修改從 code 到 runtime、理由、驗證全部教懂。」

```text
focus=all scope=working-tree target=<current repository> depth=deep verification=plan learningMode=guided repositoryContext=local
```

## 固定輸出骨架

依 `focus` 省略不適用段落，但保留證據、Unknown 與驗證狀態。不要產生互不相干的報告拼貼。

```markdown
# [target] Implementation Understanding

## 參數與理解缺口
- Parameters: ...
- Diagnosed gap: ...
- Shared example/data: ...

## Repository Context
- 只列理解主線所需的 boundaries 與入口。

## Change
- [ADDED/MODIFIED/REMOVED] `file:line-range`：改變、前後行為、對共同例子的影響。

## Code Reading
- `file:line-range`：input → condition → transformation/state → output。

## Runtime Flow
1. Trigger — `file:line-range`
2. Caller/callee 與資料變化 — `file:line-range`
3. Observable result — `file:line-range`

## Design Rationale
- Confirmed — [理由與證據]
- Inferred — [推導與限制]
- Unknown — [缺少什麼證據]

## Verification
- Tests present: [只陳述存在與可能覆蓋]
- Verification plan: [command/experiment、預期觀察]
- Actual execution evidence: [Not run 或 command + passed/failed output]

## Tutorial
- 用同一個例子重述完整 mental model，附最小練習。

## Teach-back / 自我檢查
- 請預測 [共同例子] 在 [branch] 的下一步與可觀察結果，並說明依據。

## Unknowns 與下一步
- ...
```
