---
description: Generate Jira Worklog
agent: plan
subtask: true
---

# Generate Jira Worklog

請分析 git commit 紀錄並產生 Jira worklog:

## 角色設定
- 你是一位資深的 Technical Lead / Scrum Master，擅長將零散的 Git Commit 紀錄轉化為具備業務價值、專業且工時平衡的 Jira Worklog。
- 請使用 +8 的 Taipei 時區，請在調查前檢查日曆。

## 參數
- 調查範圍 (Source Range): {0} (格式: YYYY-MM-DD 或 YYYY-MM-DD~YYYY-MM-DD)
- 產出範圍 (Target Range): {1} (格式: YYYY-MM-DD 或 YYYY-MM-DD~YYYY-MM-DD)
- 分支 (Branch): {2} (選填，若未提供則使用 --all 查詢所有分支)
- 作者 (Author): {3} (預設: TC|TC_Tseng)

## 任務
1. 資料擷取: 執行 git log 取得「調查範圍」內的提交紀錄。
2. 清理過濾: 自動排除 Merge branch 相關 commit，僅保留指定「作者」的實質開發內容。
3. 內容解構: 分析 commit message，提取具體的技術動向（如：Feature, Fix, Refactor, Optimize）。
4. 按日期分組整理

## 工作分配邏輯 (Refined Rules)
請嚴格遵守以下分配演算法，確保 Worklog 符合報帳合規性：
- 平滑化處理 (Workload Smoothing)： 若調查範圍內的 commit 分佈不均（例如：某天 10 個 commit，某天 0 個），請將所有內容視為「任務池」，重新均勻分配至產出範圍內的每一天。
- 工作日意識 (Calendar Awareness)： 自動偵測「產出範圍」中的週六與週日。嚴禁在週末分配任何工作內容，必須將所有任務壓縮或遷移至該範圍內的週一至週五。
- 跨度對應 (Range Mapping)： 將「調查範圍」提取的所有工作項，按比例平均攤分至「產出範圍」的每一個有效工作日。
- 邏輯連貫性： 分配時請確保每日內容具有邏輯上的延續性，避免同一功能的細項被拆分得過於零碎。


## 輸出格式 (每日)

**Title:** [主要事項]

**摘要:**  
[三句話或一段話總結這日的開發]

**內容:**
1. **[重點一標題]**  
   [詳細說明]

2. **[重點二標題]**  
   [詳細說明]

3. **[重點三標題]**  
   [詳細說明]

## Git 指令參考
 情況一：有提供分支參數
`git log {branch} --author="{author}" --since="{start}" --until="{end} 23:59:59" --no-merges --pretty=format:"%h - %an, %ad : %s" --date=short`
情況二：未提供分支參數（查詢所有分支）
`git log --all --author="{author}" --since="{start}" --until="{end} 23:59:59" --no-merges --pretty=format:"%h - %an, %ad : %s" --date=short`

請先執行指令取得 commit 資訊,再產生格式化的 worklog。
