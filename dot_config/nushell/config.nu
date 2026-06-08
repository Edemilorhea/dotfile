# config.nu — Nushell 主設定檔
#
# 載入順序：env.nu → config.nu → login.nu
# 這個檔案設定 nushell 的行為、外觀、快捷鍵、自訂函數等。
# 環境變數請放 env.nu，這裡專注在 shell 行為設定。

# 日誌等級（TRACE / DEBUG / INFO / WARN / ERROR）
# 開發設定時可設 TRACE 看詳細載入資訊，平常可移除或設 WARN
$env.NU_LOG_LEVEL = "TRACE"

# ================================
# Prompt（命令提示符）
# ================================

if ($env.OPENCODE_SESSION? | is-not-empty) {
    # 在 OpenCode AI 編輯器 session 內使用簡化 prompt
    # 避免 oh-my-posh / starship 在 AI 工具裡產生亂碼或干擾
    $env.PROMPT_COMMAND = {||
        let path_segment = ($env.PWD | str replace $nu.home-dir "~")
        $"(ansi green_bold)❯(ansi reset) (ansi cyan)($path_segment)(ansi reset) "
    }
    $env.PROMPT_COMMAND_RIGHT = {|| "" }  # 右側 prompt 留空
    $env.PROMPT_INDICATOR = ""
    $env.PROMPT_MULTILINE_INDICATOR = "::: "  # 多行輸入時的提示符
} else if $nu.os-info.name == "windows" {
    # Windows：使用 oh-my-posh 渲染 prompt
    if (which oh-my-posh | is-not-empty) {
        $env.POWERLINE_COMMAND = "oh-my-posh"
        $env.PROMPT_INDICATOR = ""
        $env.POSH_SESSION_ID = "e87f7998-38b8-4ffa-bbe7-d49a50ee8de6"
        $env.POSH_SHELL = "nu"
        $env.POSH_SHELL_VERSION = (version | get version)
        $env.VIRTUAL_ENV_DISABLE_PROMPT = 1
        $env.PYENV_VIRTUALENV_DISABLE_PROMPT = 1
        $env.PROMPT_MULTILINE_INDICATOR = "❯❯ "

        $env.PROMPT_COMMAND = {||
            # 偵測是否剛執行了 clear（避免 clear 後 prompt 顯示異常）
            mut clear = false
            if $nu.history-enabled {
                $clear = (history | is-empty) or ((history | last 1 | get -o 0.command) == "clear")
            }
            # 若有 SET_POSHCONTEXT hook（oh-my-posh 內部用）則執行
            if ($env.SET_POSHCONTEXT? | is-not-empty) {
                do --env $env.SET_POSHCONTEXT
            }
            # 決定 oh-my-posh 主題設定檔路徑
            mut config_arg = []
            if ($env.POSH_THEMES_PATH? | is-not-empty) {
                let t = ($env.POSH_THEMES_PATH | path join "M365Princess.omp.json")
                if ($t | path exists) { $config_arg = [$"--config=($t)"] }
            }
            # 呼叫 oh-my-posh 產生 prompt 字串
            (^oh-my-posh print primary
                --save-cache --shell=nu
                ...$config_arg
                $"--shell-version=($env.POSH_SHELL_VERSION)"
                $"--status=($env.LAST_EXIT_CODE)"       # 上一個指令的退出碼
                $"--no-status=false"
                $"--execution-time=($env.CMD_DURATION_MS)"  # 指令執行時間（毫秒）
                $"--terminal-width=((term size).columns)"   # 終端機寬度（自適應）
                $"--job-count=(job list | length)"          # 背景工作數量
                $"--cleared=($clear)")
        }
        $env.PROMPT_COMMAND_RIGHT = {|| "" }
    }
    # Linux/macOS：由 vendor/autoload/starship.nu 自動載入 starship prompt
}

# ================================
# Alias（指令別名）
# ================================
alias tl = tldr                # tldr：簡化版 man page
alias nav = navi               # navi：互動式指令速查工具
alias bunx = bun               # bunx 等同 bun（習慣性別名）
alias tlzh = tldrzhtw          # tldr 繁體中文版（見下方自訂函數）
if $nu.os-info.name == "windows" {
    alias occmd = cmd /c opencode  # Windows 下用 cmd 執行 opencode（相容性用）
}

# ================================
# 自訂函數
# ================================

# psmux：Windows 專用的 terminal multiplexer 啟動器
# 自動尋找 psmux.exe（支援 scoop 和 cargo 安裝位置）
def psmux [...args] {
    if $nu.os-info.name != "windows" { print "❌ psmux 僅支援 Windows"; return }
    let scoop = ($nu.home-dir | path join "scoop" "shims" "psmux.exe")
    let cargo = ($nu.home-dir | path join ".cargo" "bin" "psmux.exe")
    let exe = if ($scoop | path exists) { $scoop } else if ($cargo | path exists) { $cargo } else {
        print "psmux not found"; return
    }
    ^$exe ...$args
}

# lvim：LunarVim 啟動器
# --env 表示這個函數可以修改外部環境（cd 等操作會影響呼叫端）
def --env lvim [...args] {
    let bin = ($nu.home-dir | path join ".local" "bin" (if $nu.os-info.name == "windows" { "lvim.ps1" } else { "lvim" }))
    if not ($bin | path exists) { print $"❌ lvim 未找到於: ($bin)"; return }
    ^$bin ...$args
}

# czgit：在 chezmoi 的 source 目錄執行 git 指令
# chezmoi 是 dotfiles 管理工具，source-path 是它實際儲存檔案的位置
def czgit [...args] {
    git -C (chezmoi source-path) ...$args
}

# ocRider：用固定 port 4096 啟動 OpenCode（給 JetBrains Rider 用）
def ocRider [] {
    opencode --port 4096
}

# myhelp：列出所有自訂指令名稱
def myhelp [] {
    print "\n自訂指令清單\n"
    help commands | where command_type == "custom" | get name | each { |cmd| print $"  ($cmd)" }
    print ""
}

# tldrzhtw：tldr 繁體中文版
def tldrzhtw [cmd: string] {
    tldr -L zh_TW $cmd
}

# tldr-fzf：用 fzf 模糊搜尋並預覽 tldr 指令
def tldr-fzf [] {
    if (which fzf | is-empty) { print "❌ fzf 未安裝"; return }
    if (which tldr | is-empty) { print "❌ tldr 未安裝"; return }
    let commands = (tldr --list | lines | sort)
    if ($commands | is-empty) { print "請先執行 tldr --update"; return }
    # char -i 0 = null byte，作為 fzf --read0 的分隔符（支援含空格的指令名）
    let selected = ($commands | str join (char -i 0) | fzf --read0 --prompt "查詢 TLDR > " | str trim)
    if ($selected | is-not-empty) { tldr $selected }
}

# fcd：Windows 專用，用 fzf 搜尋資料夾並跳轉
# 使用 es.exe（Everything 命令列工具）搜尋所有資料夾
def --env fcd [] {
    if $nu.os-info.name != "windows" { print "❌ fcd 僅支援 Windows"; return }
    if (which fzf | is-empty) { print "❌ fzf 未安裝"; return }
    if (which es | is-empty) { print "❌ es.exe 未安裝"; return }
    let result = (^es -folder | lines | fzf --prompt "跳轉到 > " --layout=reverse --height=40% | str trim)
    if ($result | is-not-empty) { cd $result }
}

# cdgui：Windows 專用，用圖形資料夾選擇對話框跳轉目錄
def --env cdgui [] {
    if $nu.os-info.name != "windows" { print "❌ cdgui 僅支援 Windows"; return }
    let result = (^pwsh -NoProfile -Command @'
Add-Type -AssemblyName System.Windows.Forms
$d = New-Object System.Windows.Forms.FolderBrowserDialog
if ($d.ShowDialog() -eq "OK") { $d.SelectedPath }
'@ | str trim)
    if ($result | is-not-empty) { cd $result } else { print "❌ 已取消" }
}

# cdlvim：Windows 專用，用圖形對話框選資料夾後直接用 lvim 開啟
def --env cdlvim [] {
    if $nu.os-info.name != "windows" { print "❌ cdlvim 僅支援 Windows"; return }
    let result = (^pwsh -NoProfile -Command @'
Add-Type -AssemblyName System.Windows.Forms
$d = New-Object System.Windows.Forms.FolderBrowserDialog
if ($d.ShowDialog() -eq "OK") { $d.SelectedPath }
'@ | str trim)
    if ($result | is-not-empty) { cd $result; ^lvim . } else { print "❌ 已取消" }
}

# pw：Windows 專用，快速執行 PowerShell 指令
# --wrapped 允許接收任意參數（包含 flag 形式的參數）
def --wrapped pw [...args] {
    if $nu.os-info.name != "windows" { print "❌ pw 僅支援 Windows"; return }
    ^pwsh -NoProfile -Command ($args | str join " ")
}

# pwe：pw 的 pipeline 版本，把輸出轉為 nushell 可處理的 list
def --wrapped pwe [...args] {
    if $nu.os-info.name != "windows" { print "❌ pwe 僅支援 Windows"; return }
    ^pwsh -NoProfile -Command ($args | str join " ") | lines | each { |l| $l }
}

# bx：快速執行 bash 指令（在 nushell 裡偶爾需要 bash 語法時用）
def --wrapped bx [...args] {
    ^bash -c ($args | str join " ")
}

# ================================
# 快捷鍵
# ================================
$env.config.keybindings = [
    {
        # Ctrl+Alt+R：用 fzf 搜尋歷史指令
        # history | get command：取出所有歷史指令文字
        # reverse | uniq：最新的排前面，去除重複
        # fzf --scheme=history：fzf 使用歷史搜尋模式（優先顯示最近使用）
        name: fzf_history
        modifier: control_alt
        keycode: char_r
        mode: [emacs vi_normal vi_insert]
        event: {
            send: executehostcommand
            cmd: "commandline edit (history | get command | reverse | uniq | str join (char -i 0) | fzf --read0 --layout=reverse --height=40% --scheme=history --tiebreak=begin | str trim)"
        }
    }
    {
        # Alt+F：接受自動補全的下一個單字（類似 zsh 的 forward-word）
        name: accept_suggestion
        modifier: alt
        keycode: char_f
        mode: [emacs vi_insert]
        event: { send: HistoryHintWordComplete }
    }
    {
        # Ctrl+F：用 fzf 搜尋檔案並插入路徑到命令列
        # 優先用 fd（比 find 快），fallback 用 glob
        name: fzf_files
        modifier: control
        keycode: char_f
        mode: [emacs vi_normal vi_insert]
        event: {
            send: executehostcommand
            cmd: "let __file = (if (which fd | is-not-empty) { ^fd --type f --hidden --exclude .git | lines } else { glob '**/*' --depth 4 | where { |p| ($p | path type) == 'file' } | each { |p| $p | path relative-to $env.PWD } } | str join (char -i 0) | fzf --read0 --layout=reverse --height=40% --prompt 'FILE > ' | str trim); if ($__file | is-not-empty) { commandline edit $__file }"
        }
    }
    {
        # Alt+C：用 fzf 搜尋目錄並直接 cd 跳轉
        name: fzf_cd
        modifier: alt
        keycode: char_c
        mode: [emacs vi_normal vi_insert]
        event: {
            send: executehostcommand
            cmd: "let __dir = (if (which fd | is-not-empty) { ^fd --type d --hidden --exclude .git | lines } else { glob '**/*' --depth 4 | where { |p| ($p | path type) == 'dir' } | each { |p| $p | path relative-to $env.PWD } } | str join (char -i 0) | fzf --read0 --layout=reverse --height=40% --prompt 'CD > ' | str trim); if ($__dir | is-not-empty) { cd $__dir }"
        }
    }
    {
        # End 鍵：接受自動補全的下一個單字
        name: accept_next_word
        modifier: none
        keycode: end
        mode: [emacs vi_insert]
        event: { send: HistoryHintWordComplete }
    }
    {
        # Tab：觸發補全選單
        # until：依序嘗試，第一個成功的就停止
        #   - 開啟補全選單
        #   - 若選單已開啟則移到下一個選項
        #   - fallback 為直接補全
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
]

# ================================
# 補全設定
# ================================
$env.config.completions.case_sensitive = false   # 補全不分大小寫
$env.config.completions.quick = true              # 只有一個選項時自動補全
$env.config.completions.partial = true            # 支援部分匹配補全
$env.config.completions.algorithm = "fuzzy"       # 使用模糊匹配演算法
$env.config.completions.external.enable = true    # 啟用外部指令補全（carapace 等）
$env.config.completions.external.max_results = 100  # 外部補全最多顯示 100 個選項

# ================================
# 歷史設定
# ================================
$env.config.history.max_size = 100_000       # 最多保留 10 萬筆歷史
$env.config.history.sync_on_enter = true     # 每次執行指令後立即同步到磁碟
$env.config.history.file_format = "sqlite"  # 用 SQLite 格式儲存（支援搜尋、去重）
$env.config.history.isolation = false        # false = 多個 nushell 視窗共享歷史

# ================================
# 選單樣式
# ================================
$env.config.menus = [
    {
        # 補全選單：4 欄格狀排列
        name: completion_menu
        only_buffer_difference: false
        marker: "| "
        type: { layout: columnar, columns: 4, col_width: 20, col_padding: 2 }
        style: { text: green, selected_text: { attr: r }, description_text: yellow }
    }
    {
        # 歷史選單：清單排列，每頁 10 筆
        name: history_menu
        only_buffer_difference: false
        marker: "? "
        type: { layout: list, page_size: 10 }
        style: { text: green, selected_text: green_reverse, description_text: yellow }
    }
]

$env.config.use_ansi_coloring = true           # 啟用 ANSI 顏色輸出
$env.config.show_banner = false                # 關閉啟動時的 nushell 版本橫幅
$env.config.bracketed_paste = true             # 啟用 bracketed paste（貼上多行時不會立即執行）
$env.config.render_right_prompt_on_last_line = true  # 右側 prompt 顯示在最後一行（多行 prompt 用）

# ================================
# Carapace 補全
# ================================
# carapace 是跨 shell 的通用補全引擎，支援數百個指令
# CARAPACE_BRIDGES：讓 carapace 橋接其他 shell 的補全定義（zsh/fish/bash 的補全規則都能用）
if (which carapace | is-not-empty) {
    $env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
    # 設定外部補全器：把每次 Tab 的輸入傳給 carapace，回傳 JSON 格式的補全清單
    $env.config.completions.external.completer = {|spans| carapace $spans.0 nushell ...$spans | from json }
} else {
    print "⚠️  carapace 未安裝"
}

# ================================
# zoxide（智慧 cd）
# ================================
# zoxide 記錄你常去的目錄，之後用 z <關鍵字> 快速跳轉
# 第一次執行時自動產生 nushell 整合腳本並放到 vendor/autoload/ 目錄
# vendor/autoload/ 下的 .nu 檔案會在每次啟動時自動載入
if (which zoxide | is-not-empty) {
    let __zoxide_autoload = ($nu.default-config-dir | path join "vendor" "autoload" "zoxide.nu")
    if not ($__zoxide_autoload | path exists) {
        mkdir ($nu.default-config-dir | path join "vendor" "autoload")
        zoxide init nushell | save -f $__zoxide_autoload
        print "✅ zoxide.nu 已生成，請重新開啟終端機"
    }
} else {
    print "⚠️  zoxide 未安裝"
}

# ================================
# Atuin（歷史同步）
# ================================
# atuin 把歷史紀錄存到 SQLite，支援跨機器同步、時間戳、工作目錄等搜尋
# 同樣使用 vendor/autoload/ 機制自動整合
if (which atuin | is-not-empty) {
    let __atuin_autoload = ($nu.vendor-autoload-dirs | last | path join "atuin.nu")
    if not ($__atuin_autoload | path exists) {
        mkdir ($nu.vendor-autoload-dirs | last)
        atuin init nu | save --force $__atuin_autoload
    }
} else {
    print "⚠️  atuin 未安裝"
}

# ================================
# fnm（Node.js 版本管理）
# ================================
# fnm 是 nvm 的快速替代品，用 Rust 寫的 Node.js 版本管理工具
# 它需要設定 FNM_MULTISHELL_PATH 和對應的 PATH 才能切換 node 版本
# 注意：nushell 不能直接 eval bash 輸出，所以手動解析 `fnm env --shell bash` 的輸出
if (which fnm | is-not-empty) {
    let multishell = (^fnm env --shell bash
        | lines
        | where { |l| $l | str contains "FNM_MULTISHELL_PATH=" }
        | first
        | str replace 'export FNM_MULTISHELL_PATH="' ""
        | str trim --char '"')
    $env.FNM_MULTISHELL_PATH = $multishell
    $env.PATH = ($env.PATH | prepend $"($multishell)/bin")
}

# ================================
# 指令執行時間日誌（診斷用）
# ================================
# 記錄每個指令的開始和結束時間到 ~/nu_cmd.log
# 可用於診斷哪些指令很慢、或回溯操作記錄
# 如果不需要可整段移除
let __nu_log_path = $"($nu.home-dir)/nu_cmd.log"

# pre_execution：每次執行指令前觸發，記錄 [START 時間] 指令內容
$env.config.hooks.pre_execution = [{||
    let cmd = (commandline)
    let ts = (date now | format date "%Y-%m-%d %H:%M:%S%.3f")
    $"[START $ts] ($cmd)\n" | save --append $__nu_log_path
}]

# pre_prompt：每次 prompt 顯示前觸發（即指令執行完畢後），記錄 [END 時間]
$env.config.hooks.pre_prompt = [{||
    let ts = (date now | format date "%Y-%m-%d %H:%M:%S%.3f")
    $"[END   $ts]\n" | save --append $__nu_log_path
}]

# ================================
# 歡迎語
# ================================
# 啟動時顯示目前時間、nushell 版本、使用者名稱
# USERNAME? / USER?：? 表示 optional access，欄位不存在時不報錯，回傳 null
# default "User"：null 時的 fallback 值
let __user = ($env.USERNAME? | default ($env.USER? | default "User"))
print $"\n🕐 (date now | format date '%Y-%m-%d %H:%M:%S')  |  🐚 Nushell (version | get version)  |  👤 ($__user)\n"
