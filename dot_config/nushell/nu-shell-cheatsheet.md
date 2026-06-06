# Nu Shell 指令對照表 (Cheat Sheet)

> 適用版本: Nushell 0.112+
> 最後更新: 2025-05-19

---

## 📁 檔案操作

| 功能 | Bash | PowerShell | Nu Shell |
|:---|:---|:---|:---|
| 列出檔案 | `ls -la` | `Get-ChildItem` / `ls` | `ls` |
| 切換目錄 | `cd` | `Set-Location` / `cd` | `cd` |
| 目前路徑 | `pwd` | `Get-Location` / `pwd` | `pwd` |
| 複製檔案 | `cp -r` | `Copy-Item` / `cp` | `cp` |
| 移動檔案 | `mv` | `Move-Item` / `mv` | `mv` |
| 刪除檔案 | `rm -rf` | `Remove-Item` / `rm` | `rm` |
| 建立目錄 | `mkdir -p` | `New-Item -ItemType Directory` | `mkdir` |
| 查看內容 | `cat` | `Get-Content` / `cat` | `open` |
| 查看前幾行 | `head -n 10` | `Get-Content \| Select -First 10` | `open \| first 10` |
| 查看後幾行 | `tail -n 10` | `Get-Content \| Select -Last 10` | `open \| last 10` |
| 搜尋檔案 | `find . -name "*.txt"` | `Get-ChildItem -Recurse -Filter` | `ls **/*.txt` |
| 建立空檔案 | `touch file.txt` | `New-Item file.txt` | `touch file.txt` |

---

## 🔍 文字處理

| 功能 | Bash | PowerShell | Nu Shell |
|:---|:---|:---|:---|
| 搜尋文字 | `grep "pattern"` | `Select-String` / `grep` | `grep` / `find` |
| 取代文字 | `sed 's/old/new/g'` | `-replace` | `str replace` |
| 排序 | `sort` | `Sort-Object` | `sort` |
| 去重複 | `uniq` | `Get-Unique` | `uniq` |
| 計算行數 | `wc -l` | `(Get-Content).Count` | `length` |
| 擷取欄位 | `awk '{print $1}'` | `Select-Object` | `get` / `$col` |
| 字串長度 | `${#str}` | `$str.Length` | `$str \| str length` |

---

## 💻 系統資訊

| 功能 | Bash | PowerShell | Nu Shell |
|:---|:---|:---|:---|
| 執行中的程序 | `ps aux` | `Get-Process` / `ps` | `ps` |
| 終止程序 | `kill -9 PID` | `Stop-Process` / `kill` | `kill PID` |
| 環境變數 | `env` / `echo $VAR` | `Get-ChildItem env:` / `$env:VAR` | `$env` / `$env.VAR` |
| 執行路徑 | `which command` | `Get-Command` / `where.exe` | `which` |
| 磁碟空間 | `df -h` | `Get-Volume` | `df` |
| 系統資訊 | `uname -a` | `Get-ComputerInfo` | `sys` / `uname` |

---

## 🌐 網路

| 功能 | Bash | PowerShell | Nu Shell |
|:---|:---|:---|:---|
| 下載檔案 | `curl -O` | `Invoke-WebRequest` / `curl` | `http get` / `curl` |
| 發送 POST | `curl -X POST` | `Invoke-RestMethod` | `http post` |
| Ping | `ping host` | `Test-Connection` / `ping` | `ping` |
| DNS 查詢 | `dig` / `nslookup` | `Resolve-DnsName` | 需外部指令 |

---

## 📝 變數與流程控制

| 功能 | Bash | PowerShell | Nu Shell |
|:---|:---|:---|:---|
| 定義變數 | `name="value"` | `$name = "value"` | `let name = "value"` |
| 定義常數 | `readonly` | `$const` | `const` |
| 定義環境變數 | `export VAR=val` | `$env:VAR = "val"` | `$env.VAR = "val"` |
| 字串插值 | `"Hello $name"` | `"Hello $name"` | `$"Hello ($name)"` |
| 陣列 | `arr=(a b c)` | `@("a", "b")` | `[a b c]` |
| 條件判斷 | `if [ ]; then` | `if ($x -gt 5)` | `if $x > 5` |
| 迴圈 | `for i in ...; do` | `foreach ($i in ...)` | `for $i in ...` |
| 函數 | `func() { ... }` | `function Func { ... }` | `def func [] { ... }` |
| 回傳值 | `echo "result"` | `return $result` | `$result` |

---

## 🔄 管道與過濾（Nu 的強項）

Nu Shell 所有資料都是**結構化的表格**，管道處理非常強大：

```nu
# 列出所有 .txt 檔案，只顯示名稱和大小，依大小排序
ls **/*.txt | select name size | sort-by size

# 查看 process，只顯示記憶體 > 100MB 的
ps | where mem > 100MB | select name pid mem

# 開啟 JSON，過濾，轉成 CSV
open data.json | where status == "active" | to csv

# 統計目錄下各副檔名檔案數量
ls | group-by type | items { |k, v| {type: $k, count: ($v | length)} }

# 搜尋並取代，再存回檔案
open file.txt | str replace "old" "new" | save file.txt

# 查看表格的前 5 筆，只選特定欄位
ls | first 5 | select name size modified
```

### Nu Shell 獨特語法

```nu
# 表格過濾
ls | where size > 1MB and name =~ "report"

# 表格變形（pivot）
ls | get name | wrap filename

# 聚合統計
ls | get size | math avg    # 平均
ls | get size | math sum    # 總和
ls | get size | math max    # 最大值

# 條件選擇
let x = 10
if $x > 5 { "big" } else { "small" }

# 模式匹配
match $x {
    1 => "one",
    2 => "two",
    _ => "other"
}

# 管道錯誤處理
do { ls /nonexistent } | complete
```

---

## 📊 資料格式轉換

| 功能 | Nu Shell 指令 |
|:---|:---|
| JSON → 表格 | `open data.json` |
| 表格 → JSON | `ls \| to json` |
| 表格 → CSV | `ls \| to csv` |
| 表格 → YAML | `ls \| to yaml` |
| 表格 → TOML | `ls \| to toml` |
| CSV → 表格 | `open data.csv` |
| XML → 表格 | `open data.xml` |
| SQLite → 表格 | `open database.sqlite` |

---

## 💡 常用快捷鍵

| 快捷鍵 | 功能 |
|:---|:---|
| `Tab` | 補全 |
| `Ctrl+R` | fzf 歷史搜尋 |
| `Ctrl+F` | fzf 搜尋當前目錄檔案 |
| `Alt+C` | fzf 跳轉目錄 |
| `Alt+F` | 接受建議 |
| `End` | 接受下一個單字建議 |
| `F2` | 切換歷史提示模式 |
| `Ctrl+C` | 取消目前指令 |
| `Ctrl+D` | 退出 Shell |

---

## 🔗 參考資源

- [Nu Shell 官方文件](https://www.nushell.sh/book/)
- [Nu Shell 指令參考](https://www.nushell.sh/commands/)
- [Nu Shell 設定指南](nu-shell-config-guide.md)
