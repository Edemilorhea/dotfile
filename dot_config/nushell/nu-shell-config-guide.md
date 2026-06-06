# Nu Shell 設定教學指南

> 適用版本: Nushell 0.112+
> 最後更新: 2025-05-19

---

## 📁 檔案架構

Nu Shell 的設定分散在多個檔案中，載入順序如下：

```
env.nu      → 最先載入（環境變數、PATH）
config.nu   → 主要設定（配置、函數、別名、快捷鍵）
login.nu    → 登入時執行（可選）
```

| 檔案 | 用途 | 路徑 |
|:---|:---|:---|
| `env.nu` | 環境變數、PATH | `%APPDATA%\nushell\env.nu` (Windows) |
| `config.nu` | 主要設定、函數、別名 | `%APPDATA%\nushell\config.nu` (Windows) |
| `history.sqlite3` | 歷史紀錄 | `%APPDATA%\nushell\history.sqlite3` |

---

## 🎛️ 核心設定項目

### 1️⃣ Shell 行為

```nu
# 顯示歡迎橫幅
$env.config = ($env.config | upsert show_banner false)

# 顯示啟動時間提示（屬於 banner 的一部分）
$env.config = ($env.config | upsert show_banner true)   # 要顯示時間就開 banner

# ANSI 顏色
$env.config = ($env.config | upsert use_ansi_coloring true)

# 表格樣式: basic, heavy, none, compact, thin, rounded, reinforced
$env.config = ($env.config | upsert table { mode: "rounded" })

# 編輯模式: emacs 或 vi
$env.config = ($env.config | upsert edit_mode "emacs")

# rm 指令移到垃圾桶而非永久刪除
$env.config = ($env.config | upsert rm_always_trash true)

# cd 允許縮寫（如 cd ~/d/t 自動展開）
$env.config = ($env.config | upsert cd_with_abbreviations true)

# 表格頁尾顯示模式: never, always, number_of_rows, auto
$env.config = ($env.config | upsert footer_mode "auto")
```

---

### 2️⃣ Tab 補全

```nu
$env.config = ($env.config | upsert completions {
    case_sensitive: false       # 大小寫敏感
    quick: true                 # 快速補全
    partial: true               # 部分匹配
    algorithm: "fuzzy"          # 算法: prefix 或 fuzzy
    external: {
        enable: true             # 啟用外部指令補全
        max_results: 100         # 最大結果數
    }
})
```

**注意**: 若使用 Carapace 補全引擎，需在 `source` 後強制設定：
```nu
source ~/.cache/carapace/init.nu
$env.config.completions.case_sensitive = false   # Carapace 會覆蓋此設定
```

---

### 3️⃣ 歷史紀錄

```nu
$env.config = ($env.config | upsert history {
    max_size: 100_000           # 最大歷史數量
    sync_on_enter: true         # 按 Enter 時同步
    file_format: "sqlite"       # 格式: sqlite 或 txt
    isolation: false            # 不同會話隔離
})
```

---

### 4️⃣ 快捷鍵 (Keybindings)

```nu
$env.config = ($env.config | upsert keybindings [
    # Ctrl+R — fzf 歷史搜尋
    {
        name: fzf_history
        modifier: control
        keycode: char_r
        mode: [emacs vi_normal vi_insert]
        event: {
            send: executehostcommand
            cmd: "commandline edit (history | get command | reverse | uniq | str join (char -i 0) | fzf --read0 --layout=reverse --height=40% --scheme=history --tiebreak=begin | str trim)"
        }
    }
    # Alt+F — 接受建議
    {
        name: accept_suggestion
        modifier: alt
        keycode: char_f
        mode: [emacs vi_insert]
        event: { send: HistoryHintWordComplete }
    }
    # Tab — 補全選單
    {
        name: completion_menu
        modifier: none
        keycode: tab
        mode: [emacs vi_normal vi_insert]
        event: {
            until: [
                { send: menu name: completion_menu }
                { send: menunext }
                { edit: complete }
            ]
        }
    }
])
```

**常用 keycode**: `char_r`, `char_f`, `char_c`, `tab`, `right`, `left`, `up`, `down`, `end`, `home`, `f1`~`f12`

**常用 modifier**: `none`, `control`, `alt`, `shift`

**常用 event**: `executehostcommand`, `HistoryHintWordComplete`, `menunext`, `menuup`, `Complete`

---

### 5️⃣ 選單樣式 (Menus)

```nu
$env.config = ($env.config | upsert menus [
    {
        name: completion_menu
        only_buffer_difference: false
        marker: "| "
        type: {
            layout: columnar     # 或 list
            columns: 4
            col_width: 20
            col_padding: 2
        }
        style: {
            text: green
            selected_text: { attr: r }   # r = reverse
            description_text: yellow
        }
    }
    {
        name: history_menu
        only_buffer_difference: false
        marker: "? "
        type: {
            layout: list
            page_size: 10
        }
        style: {
            text: green
            selected_text: green_reverse
            description_text: yellow
        }
    }
])
```

**顏色值**: `green`, `blue`, `red`, `yellow`, `cyan`, `magenta`, `white`, `black`
**屬性**: `r` (reverse), `b` (bold), `u` (underline), `i` (italic)

---

### 6️⃣ 提示符 (Prompt)

Nu Shell 使用環境變數設定提示符：

```nu
# 主要提示符（左側）
$env.PROMPT_COMMAND = {|| $"($env.PWD) > " }

# 右側提示符
$env.PROMPT_COMMAND_RIGHT = {|| $"(date now | format date '%H:%M:%S')" }

# 輸入指示器（預設 `>`）
$env.PROMPT_INDICATOR = {|| "> " }

# 多行輸入指示器
$env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }

# 提示符顏色（使用 Oh My Posh 時通常不設定）
```

**推薦**: 使用 [Oh My Posh](https://ohmyposh.dev/) 管理提示符：
```nu
oh-my-posh init nu --config ~/.config/oh-my-posh/theme.json | save -f ~/.oh-my-posh.nu
source ~/.oh-my-posh.nu
```

---

### 7️⃣ 游標與顯示

```nu
# 游標形狀: block, line, underscore
$env.config = ($env.config | upsert cursor_shape {
    emacs: line
    vi_insert: block
    vi_normal: underscore
})

# 外部編輯器（Ctrl+O 開啟）
$env.config = ($env.config | upsert buffer_editor "nvim")

# 鈴聲
$env.config = ($env.config | upsert bell: false)
```

---

## 📝 定義函數與別名

### 別名 (Alias)

```nu
alias ll = ls -l
alias la = ls -a
alias tl = tldr
alias nav = navi
```

### 函數 (Def)

```nu
# 基本函數
def greet [name: string] {
    $"Hello, ($name)!"
}

# 多參數函數
def copy-files [from: path, to: path, --verbose (-v)] {
    let files = (ls $from)
    if $verbose {
        echo $"Copying ($files | length) files..."
    }
    $files | each { |it| cp $it.name $to }
}

# 環境函數（可修改 $env）
def --env set-project [name: string] {
    $env.PROJECT_NAME = $name
    cd $"~/projects/($name)"
}

# 私有函數（不顯示在 help 中）
def "private clean-temp" [] {
    rm -rf /tmp/*
}
```

---

## 🌍 環境變數

### 設定方式

```nu
# 設定環境變數
$env.MY_VAR = "hello"

# 設定 PATH（Windows）
$env.PATH = ($env.PATH | append "C:\\Program Files\\MyApp")
$env.PATH = ($env.PATH | prepend "C:\\Tools")   # 優先搜尋

# 設定多個環境變數
load-env {
    RUST_BACKTRACE: "1"
    CARGO_NET_OFFLINE: "false"
}

# 移除環境變數
hide-env MY_VAR
```

### 跨平台 PATH

```nu
let my_path = if $nu.os-info.name == "windows" {
    "C:\\Tools"
} else {
    "/usr/local/bin"
}
$env.PATH = ($env.PATH | append $my_path)
```

---

## 🔄 常用外部工具整合

### Zoxide（智慧 cd）

```nu
if not ("~/.zoxide.nu" | path exists) {
    zoxide init nushell | save -f ~/.zoxide.nu
}
source ~/.zoxide.nu
```

### Carapace（補全引擎）

```nu
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
mkdir ~/.cache/carapace
if not ("~/.cache/carapace/init.nu" | path exists) {
    carapace _carapace nushell | save --force ~/.cache/carapace/init.nu
}
source ~/.cache/carapace/init.nu
$env.config.completions.case_sensitive = false   # 強制不分大小寫
```

### Atuin（跨 Shell 歷史同步）

```nu
mkdir ~/.cache/atuin
if not ("~/.cache/atuin/init.nu" | path exists) {
    atuin init nu | save --force ~/.cache/atuin/init.nu
}
source ~/.cache/atuin/init.nu
```

### fzf（互動選擇）

需安裝 fzf，然後在 keybindings 中設定快捷鍵（見上方範例）。

---

## 💡 最佳實踐

### ✅ DO

- 使用 `let` 定義局部變數，`$env` 定義環境變數
- 用 `def --env` 定義需要修改環境的函數
- 外部工具初始化加 `if not ... path exists` 判斷，避免每次啟動重新生成
- 使用結構化管道 `| where` / `| select` / `| sort-by` 處理資料
- 善用 `open` 和 `save` 處理各種格式（JSON, CSV, TOML, YAML）

### ❌ DON'T

- 不要把 `$nu.home-path` 和 `$nu.home_path` 搞混（Nu 0.112 使用 `-`）
- 不要忘記字串插值語法是 `$"...($var)..."` 不是 `"...$var..."`
- 不要在 `env.nu` 中定義函數（只放環境變數和 PATH）
- 不要把 Carapace 設定放在補全設定之前（會被覆蓋）

---

## 🔗 參考資源

- [Nu Shell 官方文件](https://www.nushell.sh/book/)
- [Nu Shell 指令參考](https://www.nushell.sh/commands/)
- [Nu Shell GitHub](https://github.com/nushell/nushell)
- [指令對照表](nu-shell-cheatsheet.md)
