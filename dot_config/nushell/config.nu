# config.nu
#
# Installed by:
# version = "0.112.2"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings, 
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

# ================================
# Debug Logging
# ================================
$env.NU_LOG_LEVEL = "TRACE"

# ================================
# Prompt 主題（跨平台）
# ================================
# 🔧 OpenCode 環境使用簡單 prompt，避免終端狀態衝突
if ($env.OPENCODE_SESSION? | is-not-empty) {
    $env.PROMPT_COMMAND = {|| 
        let path_segment = ($env.PWD | str replace $nu.home-dir "~")
        $"(ansi green_bold)❯(ansi reset) (ansi cyan)($path_segment)(ansi reset) "
    }
    $env.PROMPT_COMMAND_RIGHT = {|| "" }
    $env.PROMPT_INDICATOR = ""
    $env.PROMPT_MULTILINE_INDICATOR = "::: "
} else {
    # 非 OpenCode 環境：載入 oh-my-posh.nu（Windows）或 Starship（Linux，透過 vendor/autoload）
    # oh-my-posh.nu 內部有 OS 檢查，Linux 上會直接跳過
    # Linux/macOS: Starship 透過 vendor/autoload/starship.nu 自動載入
    # 初次設定執行: starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
    source oh-my-posh.nu
}

# ================================
# 📌 常用 Alias
# ================================
alias tl = tldr
alias nav = navi
alias bunx = bun
alias tlzh = tldrzhtw
alias occmd = cmd /c opencode

def psmux [...args] {
    if $nu.os-info.name == "windows" {
        let scoop = $"($env.USERPROFILE)\\scoop\\shims\\psmux.exe"
        let cargo = $"($env.USERPROFILE)\\.cargo\\bin\\psmux.exe"
        let exe = if ($scoop | path exists) {
            $scoop
        } else if ($cargo | path exists) {
            $cargo
        } else {
            print "psmux not found in scoop\\shims or .cargo\\bin"
            return
        }
        ^$exe ...$args
    } else {
        print "❌ psmux 僅支援 Windows"
    }
}


# lvim (跨平台，自動偵測 Windows / Linux)
def --env lvim [...args] {
    let bin = if $nu.os-info.name == "windows" {
        $"($nu.home-dir)\\.local\\bin\\lvim.ps1"
    } else {
        $"($nu.home-dir)/.local/bin/lvim"
    }
    
    if not ($bin | path exists) {
        print $"❌ lvim 未找到於: ($bin)"
        print "請確認 LunarVim 已正確安裝"
        return
    }
    
    ^$bin ...$args
}

# ================================
# 🧩 自訂函數
# ================================

# chezmoi git 捷徑
def czgit [...args] {
    git -C (chezmoi source-path) ...$args
}

# OpenCode Rider 模式
def ocRider [] {
    opencode --port 4096
}

# 顯示自訂函數清單
def myhelp [] {
    print "\n📌 自訂指令清單\n"
    help commands | where command_type == "custom" | get name | each { |cmd| print $"  ($cmd)" }
    print ""
}

# TLDR 中文查詢
def tldrzhtw [cmd: string] {
    tldr -L zh_TW $cmd
}

# TLDR + fzf 互動查詢
def tldr-fzf [] {
    if (which fzf | is-empty) {
        print "❌ fzf 未安裝，無法使用互動查詢"
        return
    }
    if (which tldr | is-empty) {
        print "❌ tldr 未安裝"
        return
    }
    
    let commands = (tldr --list | lines | sort)
    if ($commands | is-empty) {
        print "沒有指令列表，請先執行 tldr --update"
        return
    }
    let selected = ($commands | str join (char -i 0) | fzf --read0 --prompt "查詢 TLDR > " | str trim)
    if ($selected | is-not-empty) {
        tldr $selected
    }
}

# fcd — Everything CLI + fzf 快速跳轉 (對應 PowerShell fcd，僅支援 Windows)
# 需要安裝 Everything + es.exe (https://www.voidtools.com/support/everything/command_line_interface/)
def --env fcd [] {
    if $nu.os-info.name != "windows" {
        print "❌ fcd 僅支援 Windows（依賴 Everything CLI）"
        return
    }
    if (which fzf | is-empty) {
        print "❌ fzf 未安裝，無法使用互動選擇"
        return
    }
    if (which es | is-empty) {
        print "❌ Everything CLI (es.exe) 未安裝"
        print "下載: https://www.voidtools.com/support/everything/command_line_interface/"
        return
    }
    
    let result = (^es -folder | lines | fzf --prompt "跳轉到 > " --layout=reverse --height=40% | str trim)
    if ($result | is-not-empty) {
        cd $result
        print $"\n✅ 已切換到：($result)\n"
    }
}

# cdgui — GUI 選資料夾 (透過 pwsh 橋接 Windows Forms，僅支援 Windows)
def --env cdgui [] {
    if $nu.os-info.name != "windows" {
        print "❌ cdgui 僅支援 Windows"
        return
    }
    let result = (^pwsh -NoProfile -Command @'
Add-Type -AssemblyName System.Windows.Forms
$d = New-Object System.Windows.Forms.FolderBrowserDialog
$d.Description = "請選擇資料夾"
if ($d.ShowDialog() -eq "OK") { $d.SelectedPath }
'@ | str trim)
    if ($result | is-not-empty) {
        cd $result
        print $"\n✅ 已切換到：($result)\n"
    } else {
        print "\n❌ 已取消選擇\n"
    }
}

# cdlvim — GUI 選資料夾後用 lvim 開啟 (僅支援 Windows)
def --env cdlvim [] {
    if $nu.os-info.name != "windows" {
        print "❌ cdlvim 僅支援 Windows"
        return
    }
    let result = (^pwsh -NoProfile -Command @'
Add-Type -AssemblyName System.Windows.Forms
$d = New-Object System.Windows.Forms.FolderBrowserDialog
$d.Description = "請選擇要用 lvim 開啟的資料夾"
if ($d.ShowDialog() -eq "OK") { $d.SelectedPath }
'@ | str trim)
    if ($result | is-not-empty) {
        cd $result
        ^lvim .
    } else {
        print "\n❌ 已取消選擇\n"
    }
}

# pw — PowerShell 快捷執行（免去 pwsh -Command '...' 的麻煩，僅支援 Windows）
# 使用方式: pw Get-Process | Select-Object Name
#          pw "Get-Date -Format yyyy-MM-dd"
def --wrapped pw [...args] {
    if $nu.os-info.name != "windows" {
        print "❌ pw 僅支援 Windows（依賴 pwsh）"
        return
    }
    let cmd = ($args | str join " ")
    ^pwsh -NoProfile -Command $cmd
}

# pwe — PowerShell 執行並轉換輸出為 Nu 表格（適合管道後續處理，僅支援 Windows）
# 使用方式: pwe Get-Process | where Name =~ chrome | select Name Id
def --wrapped pwe [...args] {
    if $nu.os-info.name != "windows" {
        print "❌ pwe 僅支援 Windows（依賴 pwsh）"
        return
    }
    let cmd = ($args | str join " ")
    ^pwsh -NoProfile -Command $cmd | lines | parse "{output}" | get output? | default []
}

# bx — Bash 快捷執行（避免覆蓋系統 bash 指令）
# 使用方式: bx ls -la
#          bx "echo $HOME"
def --wrapped bx [...args] {
    let cmd = ($args | str join " ")
    if $nu.os-info.name == "windows" {
        # Windows 嘗試使用 WSL bash 或 Git Bash
        if (which bash | length) > 0 {
            ^bash -c $cmd
        } else {
            error make { msg: "bash not found. Please install WSL or Git Bash." }
        }
    } else {
        ^bash -c $cmd
    }
}

# ================================
# ⌨️ 快捷鍵設定
# ================================
$env.config = ($env.config | upsert keybindings [
    # Ctrl+R — atuin 互動式歷史搜尋 (由 vendor/autoload/atuin.nu 綁定)
    # Ctrl+Alt+R — fzf nushell 本地歷史搜尋 (第二選擇，離線或偏好 fzf 時使用)
    {
        name: fzf_history
        modifier: control_alt
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
    # Ctrl+F — fzf 搜尋當前目錄下所有檔案
    # 🔧 修復: 改用 fd 避免 ls **/* 在大目錄遞迴掃描卡住；無 fd 則限制深度 4 層
    {
        name: fzf_files
        modifier: control
        keycode: char_f
        mode: [emacs vi_normal vi_insert]
        event: {
            send: executehostcommand
            cmd: "let __file = (if (which fd | is-not-empty) { ^fd --type f --hidden --exclude .git | lines } else { glob '**/*' --depth 4 | where { |p| ($p | path type) == 'file' } | each { |p| $p | path relative-to $env.PWD } } | str join (char -i 0) | fzf --read0 --layout=reverse --height=40% --prompt 'FILE > ' | str trim); if ($__file | is-not-empty) { commandline edit $__file }"
        }
    }
    # Alt+C — fzf 跳轉目錄 (對應 PSFzf PSReadlineChordSetLocation)
    # 🔧 修復: 改用 fd 避免 ls **/* 在大目錄遞迴掃描卡住；無 fd 則限制深度 4 層
    {
        name: fzf_cd
        modifier: alt
        keycode: char_c
        mode: [emacs vi_normal vi_insert]
        event: {
            send: executehostcommand
            cmd: "let __dir = (if (which fd | is-not-empty) { ^fd --type d --hidden --exclude .git | lines } else { glob '**/*' --depth 4 | where { |p| ($p | path type) == 'dir' } | each { |p| $p | path relative-to $env.PWD } } | str join (char -i 0) | fzf --read0 --layout=reverse --height=40% --prompt 'CD > ' | str trim); if ($__dir | is-not-empty) { cd $__dir }"
        }
    }
    # End — 接受下一個單字建議 (避免覆蓋右方向鍵移動游標)
    {
        name: accept_next_word
        modifier: none
        keycode: end
        mode: [emacs vi_insert]
        event: { send: HistoryHintWordComplete }
    }
    # F2 — 切換歷史提示模式
    {
        name: toggle_history_hint
        modifier: none
        keycode: f2
        mode: [emacs vi_normal vi_insert]
        event: { send: executehostcommand, cmd: "" }
    }
])

# ================================
# 📋 Tab 補全設定 (類似 PSReadLine MenuComplete)
# ================================
$env.config = ($env.config | upsert completions {
    case_sensitive: false
    quick: true
    partial: true
    algorithm: "fuzzy"
    external: {
        enable: true
        max_results: 100
    }
})

# 啟用歷史選單 (輸入時自動彈出)
$env.config = ($env.config | upsert history {
    max_size: 100_000
    sync_on_enter: true
    file_format: "sqlite"
    isolation: false
})

# 配置選單樣式
$env.config = ($env.config | upsert menus [
    {
        name: completion_menu
        only_buffer_difference: false
        marker: "| "
        type: {
            layout: columnar
            columns: 4
            col_width: 20
            col_padding: 2
        }
        style: {
            text: green
            selected_text: { attr: r }
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

# Tab 鍵綁定 (正常補全：指令、路徑、參數)
$env.config = ($env.config | upsert keybindings (
    $env.config.keybindings | append {
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
))

# ================================  
# 💡 啟用 ANSI 顏色與 inline 自動提示 (灰色建議文字)
# ================================
$env.config = ($env.config | upsert use_ansi_coloring true)

# 關閉啟動歡迎橫幅，開啟啟動時間提示
$env.config = ($env.config | upsert show_banner false)
$env.config = ($env.config | upsert show_hints true)

# ================================
# 🚀 zoxide 初始化
# ================================
# zoxide.nu 放在 vendor/autoload/，Nushell 啟動時自動載入
# 首次或檔案不存在時自動生成
if (which zoxide | is-not-empty) {
    let __zoxide_autoload = ($nu.default-config-dir | path join "vendor" "autoload" "zoxide.nu")
    if not ($__zoxide_autoload | path exists) {
        mkdir ($nu.default-config-dir | path join "vendor" "autoload")
        zoxide init nushell | save -f $__zoxide_autoload
        print "✅ zoxide.nu 已生成，請重新開啟終端機生效"
    }
} else {
    print "⚠️  zoxide 未安裝，跳過初始化"
}

# ================================
# 🎯 Carapace 補全引擎
# ================================
if (which carapace | is-not-empty) {
    $env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
    $env.config.completions.case_sensitive = false
    # 使用 external completer（不需要 source，避免 parse-time 問題）
    $env.config.completions.external.enable = true
    $env.config.completions.external.completer = {|spans|
        carapace $spans.0 nushell ...$spans | from json
    }
} else {
    print "⚠️  carapace 未安裝，正在嘗試自動安裝..."
    let __os = $nu.os-info.name
    if $__os == "windows" {
        if (which winget | is-not-empty) {
            ^winget install rsteube.Carapace --silent
        } else {
            print "❌ 找不到 winget，請手動安裝: https://carapace.sh"
        }
    } else if $__os == "macos" {
        if (which brew | is-not-empty) {
            ^brew install carapace
        } else {
            print "❌ 找不到 brew，請手動安裝: https://carapace.sh"
        }
    } else {
        ^curl -sSL https://raw.githubusercontent.com/carapace-sh/carapace-bin/master/install.sh | bash
    }
    if (which carapace | is-not-empty) {
        print "✅ carapace 安裝成功，請重新開啟終端機生效"
    } else {
        print "❌ carapace 安裝失敗，請手動安裝: https://carapace.sh"
    }
}

# ================================
# 🔍 Atuin 跨 Shell 歷史同步
# ================================
# atuin.nu 放在 vendor/autoload/，Nushell 啟動時自動載入
# 🔧 修復: 只在檔案不存在時生成，避免每次啟動執行 atuin init 造成卡住
# 若需強制更新，手動刪除 vendor/autoload/atuin.nu 再重啟即可
if (which atuin | is-not-empty) {
    let __atuin_autoload = ($nu.default-config-dir | path join "vendor" "autoload" "atuin.nu")
    if not ($__atuin_autoload | path exists) {
        mkdir ($nu.default-config-dir | path join "vendor" "autoload")
        atuin init nu | save --force $__atuin_autoload
    }
} else {
    print "⚠️  atuin 未安裝，正在嘗試自動安裝..."
    let __os = $nu.os-info.name
    if $__os == "windows" {
        if (which winget | is-not-empty) {
            ^winget install atuin --silent
        } else {
            print "❌ 找不到 winget，請手動安裝: https://atuin.sh"
        }
    } else {
        # Linux / macOS — 官方安裝腳本
        if (which curl | is-not-empty) {
            ^bash -c "curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh"
        } else {
            print "❌ 找不到 curl，請手動安裝: https://atuin.sh"
        }
    }
    if (which atuin | is-not-empty) {
        print "✅ atuin 安裝成功，請重新開啟終端機生效"
    } else {
        print "❌ atuin 安裝失敗，請手動安裝: https://atuin.sh"
    }
}

# ================================
# 🎉 自訂歡迎語
# ================================
let __now = (date now | format date "%Y-%m-%d %H:%M:%S")
let __ver = (version | get version)
let __user = ($env.USERNAME? | default ($env.USER? | default "User"))
print $"\n🕐 ($__now)  |  🐚 Nushell ($__ver)  |  👤 ($__user)\n"

# ================================
# 📋 命令執行 Log（診斷用）
# ================================
let __nu_log_path = if $nu.os-info.name == "windows" {
    $"($env.USERPROFILE)\\nu_cmd.log"
} else {
    $"($nu.home-dir)/nu_cmd.log"
}

$env.config = ($env.config | upsert hooks.pre_execution [
    {||
        let cmd = (commandline)
        let timestamp = (date now | format date "%Y-%m-%d %H:%M:%S%.3f")
        $"[START $timestamp] ($cmd)\n" | save --append $__nu_log_path
    }
])

# ================================
# 📋 Bracketed Paste — 貼上多行時不立即執行
# ================================
$env.config = ($env.config | upsert bracketed_paste true)

$env.config = ($env.config | upsert hooks.pre_prompt [
    {||
        let timestamp = (date now | format date "%Y-%m-%d %H:%M:%S%.3f")
        $"[END   $timestamp]\n" | save --append $__nu_log_path
    }
])
