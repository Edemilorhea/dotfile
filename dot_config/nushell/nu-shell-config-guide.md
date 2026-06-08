# Nushell 設定教學

## 為什麼寫設定這麼麻煩？

Nushell 和 bash/zsh 的設計哲學根本不同：

| | bash / zsh | nushell |
|---|---|---|
| 資料模型 | 一切都是字串 | 結構化資料（table、list、record）|
| 管道傳遞 | 純文字 | 有型別的物件 |
| 環境變數 | `export VAR=value` | `$env.VAR = value` |
| Scope | 鬆散（大部分是全域） | 嚴格隔離 |
| 外部工具整合 | 直接 `source` | 需手動解析輸出 |

**痛點來源：** keychain、nvm、virtualenv 這些工具假設你用 bash/zsh，輸出的是 `export VAR=value`。nushell 不認這個語法，每次橋接都要手動解析。

---

## 管道（Pipeline）怎麼運作

### bash 的管道：純文字傳遞

```bash
ls -la | grep ".txt" | awk '{print $9}'
```

每個步驟之間傳的是**純字串**，你要自己解析格式。

### nushell 的管道：結構化資料傳遞

```nu
ls | where name =~ ".txt" | get name
```

`ls` 回傳的不是文字，是一個 **table**（像 Excel 那種表格），每一列都有欄位。後面的指令直接操作欄位，不需要解析字串。

---

## 核心概念

### 1. 所有輸出都是資料

```nu
ls
# 回傳 table：
# ╭───┬──────────┬──────┬──────────╮
# │ # │   name   │ type │   size   │
# ├───┼──────────┼──────┼──────────┤
# │ 0 │ foo.txt  │ file │   1.2 KB │
# │ 1 │ bar/     │ dir  │          │
# ╰───┴──────────┴──────┴──────────╯

ls | get name          # 取出 name 欄位 → list
ls | get 0             # 取出第一列 → record
ls | get 0.name        # 取出第一列的 name → 字串
```

### 2. 管道連接就是欄位操作

```nu
# 找出所有 .txt 檔，按大小排序，取前 5 個
ls
| where name =~ "\.txt$"   # 過濾：name 欄位符合 regex
| sort-by size -r           # 排序：按 size 欄位，-r 倒序
| first 5                   # 取前 5 列
| get name                  # 只要 name 欄位
```

等效的 bash 要寫：
```bash
find . -name "*.txt" -printf "%s %f\n" | sort -rn | head -5 | awk '{print $2}'
```

### 3. where 是過濾，get 是取欄位

```nu
ls | where type == "file"        # 只要檔案（不要目錄）
ls | where size > 1mb            # 大於 1MB 的檔案（nushell 認識單位）
ls | where { |row| $row.name | str starts-with "." }  # 隱藏檔案

ls | get name            # 取 name 欄位 → list
ls | get 0.name          # 取第 0 列的 name → 字串
ls | select name size    # 只保留 name 和 size 兩個欄位
```

### 4. 字串處理

```nu
# bash：用 sed/awk/cut
echo "SSH_AUTH_SOCK=/tmp/agent.123; export SSH_AUTH_SOCK;" | sed 's/SSH_AUTH_SOCK=//; s/;.*//'

# nushell：用 parse（樣板解析）
"SSH_AUTH_SOCK=/tmp/agent.123; export SSH_AUTH_SOCK;"
| parse "SSH_AUTH_SOCK={val}; export SSH_AUTH_SOCK;"
| get val.0
# → "/tmp/agent.123"
```

`parse` 的樣板語法：`{佔位符}` 會匹配任意字串，結果存成欄位。

其他字串指令：
```nu
"hello world" | str upcase          # → "HELLO WORLD"
"hello world" | str replace "world" "nushell"
"hello world" | split words         # → ["hello", "world"]
"  hello  "   | str trim            # → "hello"
"hello"       | str starts-with "h" # → true
```

### 5. 條件判斷

```nu
# if/else
if ($path | path exists) {
    print "存在"
} else {
    print "不存在"
}

# 三元運算（nushell 用 if 表達式）
let label = if $is_windows { "Windows" } else { "Linux" }
```

### 6. 迴圈與 closure 的 scope 陷阱

這是 nushell 最容易踩的坑：

```nu
# ❌ 錯誤：在 each 的 closure 裡設 $env 不會影響外層
[1 2 3] | each { |x|
    $env.MY_VAR = $x  # 這個設定在 closure 結束後就消失了
}

# ✅ 正確：在外層直接設
let value = ([1 2 3] | first)
$env.MY_VAR = $value
```

**規則：** `each`、`where`、`for` 裡的 closure 是獨立 scope，無法修改外部變數或環境變數。要修改外部狀態，必須把結果傳出來，在外層賦值。

```nu
# ✅ 從 closure 取值，在外層設定
let sock = (
    open ~/.keychain/host-sh
    | lines
    | where { |l| $l | str starts-with "SSH_AUTH_SOCK=" }
    | first
    | parse "SSH_AUTH_SOCK={val}; export SSH_AUTH_SOCK;"
    | get val.0
)
$env.SSH_AUTH_SOCK = $sock  # 在外層設定
```

### 7. 環境變數

```nu
# 設定
$env.MY_VAR = "hello"

# 讀取
$env.MY_VAR          # → "hello"
$env.MY_VAR?         # Optional access，不存在時回傳 null 而非報錯
$env.MY_VAR? | default "fallback"  # 不存在時用預設值

# PATH 操作
$env.PATH = ($env.PATH | append "/new/path")   # 加到最後
$env.PATH = ($env.PATH | prepend "/new/path")  # 加到最前（優先）
$env.PATH = ($env.PATH | where { |p| $p != "/remove/this" })  # 移除
```

### 8. 呼叫外部指令

```nu
# 外部指令前加 ^（明確表示這是外部程式，不是 nushell built-in）
^git status
^keychain --quiet ~/.ssh/id_ed25519

# 不加 ^ 也可以，但如果有同名的 nushell 函數會優先用函數
git status   # 如果有定義 def git [...] 會用那個，否則用外部的

# 傳遞 list 為多個參數：用 spread 語法 ...
let args = ["--quiet", "--nogui"]
^keychain ...$args   # 等效於 keychain --quiet --nogui
```

---

## 設定檔結構

```
~/.config/nushell/
├── env.nu          # 環境變數、PATH（最先載入）
├── config.nu       # shell 行為、函數、快捷鍵（第二載入）
├── login.nu        # 只在 login shell 執行（可選）
└── vendor/
    └── autoload/   # 這裡的 .nu 檔案全部自動載入
        ├── zoxide.nu
        ├── atuin.nu
        └── starship.nu
```

**原則：**
- `env.nu`：只放 `$env.XXX =` 和 PATH 修改
- `config.nu`：放函數定義、alias、快捷鍵、行為設定
- `vendor/autoload/`：放工具自動產生的整合腳本

---

## 常見外部工具橋接模式

### 問題：工具輸出 bash 格式，nushell 不能直接 source

```bash
# bash/zsh 可以直接這樣
eval "$(zoxide init bash)"
source ~/.keychain/host-sh
```

```nu
# nushell 要手動解析，或讓工具產生 .nu 格式的腳本存到 vendor/autoload/

# 方法一：讓工具產生 nushell 腳本（推薦）
zoxide init nushell | save -f vendor/autoload/zoxide.nu
atuin init nu | save -f vendor/autoload/atuin.nu
starship init nu | save -f vendor/autoload/starship.nu

# 方法二：手動解析工具輸出（不得已時用）
let value = (^some-tool env --shell bash
    | lines
    | where { |l| $l | str contains "VAR_NAME=" }
    | first
    | parse "export VAR_NAME={val}"
    | get val.0)
$env.VAR_NAME = $value
```

---

## 速查表

| 需求 | bash | nushell |
|---|---|---|
| 設定環境變數 | `export VAR=val` | `$env.VAR = "val"` |
| 讀取環境變數 | `$VAR` | `$env.VAR` |
| 宣告變數 | `VAR=val` | `let var = val` |
| 可變變數 | `VAR=val` | `mut var = val` |
| 條件判斷 | `if [ ... ]; then` | `if condition { }` |
| 迴圈 | `for x in list; do` | `for x in $list { }` |
| 函數定義 | `function foo() { }` | `def foo [] { }` |
| 函數（可改 env）| 無需特別標記 | `def --env foo [] { }` |
| 呼叫外部指令 | 直接寫 | `^指令` 或直接寫 |
| 管道 | `cmd1 \| cmd2` | `cmd1 \| cmd2`（相同） |
| 取得欄位 | `awk '{print $1}'` | `get column_name` |
| 過濾 | `grep pattern` | `where name =~ "pattern"` |
| 計算 list 長度 | `${#arr[@]}` | `$list \| length` |
| 字串插值 | `"hello $var"` | `$"hello ($var)"` |
