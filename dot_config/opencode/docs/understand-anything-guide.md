# Understand-Anything 使用指南

## 目的

Understand-Anything 用來把專案程式碼、文件或知識庫轉成可搜尋、可探索、可對話的知識圖譜。它特別適合用在：

- 快速理解陌生 codebase
- 找出功能背後牽涉的模組與檔案
- 分析改動影響範圍
- 整理業務流程與 domain model
- 協助新人 onboarding

---

## 基本使用流程

### 1. 產生知識圖譜

建議第一次使用繁體中文輸出：

```text
/understand --language zh-TW
```

這會掃描專案並產生知識圖譜，通常會輸出到：

```text
.understand-anything/knowledge-graph.json
```

大型專案或 monorepo 可以先限制範圍：

```text
/understand src/backend --language zh-TW
/understand apps/frontend --language zh-TW
```

### 2. 開啟互動式 Dashboard

```text
/understand-dashboard
```

Dashboard 適合用來：

- 搜尋檔案、函式、類別
- 看模組之間的 dependency
- 點擊節點查看摘要與關係
- 從整體架構理解系統

### 3. 用 Chat 問整體問題

```text
/understand-chat 這個專案的整體架構是什麼？
```

常見問題：

```text
/understand-chat 登入流程是怎麼運作的？
/understand-chat 哪些模組處理權限？
/understand-chat 如果我要新增會員等級，應該看哪些檔案？
/understand-chat 哪些地方假設組織只有公司和部門兩層？
```

### 4. 用 Explain 看單一檔案細節

```text
/understand-explain src/auth/login.ts
```

適合用在你已經知道檔案路徑，想理解該檔案的責任、主要邏輯、依賴關係與被呼叫方式。

### 5. 改完後分析影響

```text
/understand-diff
```

適合在 commit 前檢查目前變更可能影響哪些模組與流程。

---

## 核心指令差異

| 指令 | 層級 | 主要用途 | 適合問題 |
| --- | --- | --- | --- |
| `/understand-domain` | 業務 / 領域層 | 整理業務流程、角色、規則、狀態 | 這個功能在業務上是什麼？ |
| `/understand-chat` | 系統 / 模組層 | 對整個 codebase 問問題 | 這個功能由哪些模組、API、Service、DB 完成？ |
| `/understand-explain` | 檔案 / 函式層 | 解釋指定檔案或模組 | 這個檔案具體在做什麼？ |
| `/understand-dashboard` | 視覺化層 | 互動探索知識圖譜 | 系統結構長什麼樣子？ |
| `/understand-diff` | 變更影響層 | 分析目前修改的影響範圍 | 這次改動可能影響哪些地方？ |

---

## 層級差異簡圖

```text
業務目標
  ↓
Domain：業務流程、角色、規則、狀態
  ↓
Chat：模組、檔案、Service、API、DB、UI
  ↓
Explain：單一檔案或函式細節
```

所以三者層級大概是：

```text
/understand-domain
最高層：這個功能在業務上是什麼

/understand-chat
中間層：這個功能由哪些程式碼完成

/understand-explain
最低層：這個檔案具體怎麼做
```

簡單判斷：

- 問「業務規則、流程、角色、狀態」：用 `/understand-domain`
- 問「哪些程式碼實作這個功能」：用 `/understand-chat`
- 問「這個檔案具體在幹嘛」：用 `/understand-explain`

---

## Chat 與 Domain 的差別

### `/understand-chat`

偏向工程實作視角，會回答：

- 哪些檔案相關
- 哪些 Service / Controller / Repository 受影響
- 哪些 API、DB、UI 牽涉其中
- 哪些地方可能有 hard-coded assumption
- 要改功能時應該從哪裡切入

範例：

```text
/understand-chat 哪些地方假設組織結構只有兩層？
```

可能會得到類似：

```text
目前兩層限制可能存在於 CompanyService、DepartmentService、MemberService、組織查詢 API、前端樹狀元件，以及只 join company 和 department 的查詢邏輯。
```

### `/understand-domain`

偏向業務領域視角，會整理：

- 系統有哪些 domain concept
- 業務流程如何流動
- 哪些角色參與流程
- 哪些業務規則被程式碼隱含
- 狀態與流程之間的關係

範例：

```text
/understand-domain
```

再問：

```text
/understand-chat 組織管理 domain 中有哪些業務規則依賴兩層組織結構？
```

可能會得到類似：

```text
目前組織管理隱含公司為最高層、部門只能屬於公司、成員只能掛在部門、權限與資料範圍以公司或部門為邊界。
```

---

## 建議使用順序

### 一般理解 codebase

```text
/understand --language zh-TW
/understand-dashboard
/understand-chat 這個專案的整體架構是什麼？
/understand-chat 主要資料流是怎麼走的？
```

### 要改功能前

```text
/understand-chat 這個功能涉及哪些模組和檔案？
/understand-chat 如果我要修改這個功能，可能會影響哪些 API、Service、DB、UI？
/understand-explain path/to/key-file
```

### 改完後

```text
/understand-diff
```

---

## 進階案例：兩層組織改成無限制層級

需求：

```text
目前有公司管理、部門管理、成員管理。
原本組織限制為公司 → 部門 → 成員。
現在要改成無限制層級的組織樹。
```

這不是單純技術重構，而是業務模型改變。建議先理解 domain，再回頭看實作。

### 1. 先理解 Domain

```text
/understand-domain
```

接著問：

```text
/understand-chat 目前組織管理 domain 中有哪些核心概念、流程和業務規則？
/understand-chat 哪些業務規則隱含假設組織只有公司和部門兩層？
/understand-chat 如果組織改成無限制層級，domain model 需要重新定義哪些概念？
```

應先釐清：

- 「公司」和「部門」以後是否仍是不同概念
- 無限制層級後，每一層是否統一為「組織節點」
- 成員是否可掛在任意節點，還是只能掛在葉節點
- 權限是否沿著組織樹繼承
- 報表、資料可見範圍是否跟組織階層有關
- 原本公司管理與部門管理是否要合併成組織管理

### 2. 再分析實作影響

```text
/understand-chat 哪些程式碼模組實作了公司、部門、成員管理？
/understand-chat 哪些 API、Service、Repository、資料表和 UI 元件依賴兩層組織結構？
/understand-chat 如果改成無限制層級組織樹，最小影響範圍是什麼？
```

### 3. 最後看關鍵檔案

```text
/understand-explain path/to/CompanyService
/understand-explain path/to/DepartmentService
/understand-explain path/to/MemberService
```

### 4. 修改後檢查影響

```text
/understand-diff
```

---

## 實務建議

- 初次理解專案：先 `/understand --language zh-TW`，再開 `/understand-dashboard`
- 不知道從哪裡看：用 `/understand-chat`
- 已知道檔案路徑：用 `/understand-explain`
- 涉及業務規則改變：先 `/understand-domain`
- 改完功能或重構後：用 `/understand-diff`
- 大型 monorepo：先限定子目錄，不要一開始掃全部

一句話：

```text
先用 domain 定義「業務上是什麼」，再用 chat 找「程式碼怎麼實作」，最後用 explain 看「單檔怎麼做」。
```
