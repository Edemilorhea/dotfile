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
# Oh My Posh
# ================================
source oh-my-posh.nu

# ================================
# 🧠 Zoxide 智慧跳轉
# ================================
source zoxide.nu

# ================================
# 📌 常用 Alias
# ================================
alias tl = tldr
alias nav = navi
alias bunx = bun
alias tlzh = tldrzhtw

# lvim (跨平台，自動偵測 Windows / Linux)
def --env lvim [...args] {
    let bin = if $nu.os-info.name == "windows" {
        $"($nu.home-path)\\.local\\bin\\lvim.ps1"
    } else {
        $"($nu.home-path)/.local/bin/lvim"
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

# fcd — Everything CLI + fzf 快速跳轉 (對應 PowerShell fcd)
# 需要安裝 Everything + es.exe (https://www.voidtools.com/support/everything/command_line_interface/)
def --env fcd [] {
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

# oc — OpenCode wrapper (跨平台，自動偵測 Windows / Linux)
def oc [...args] {
    if $nu.os-info.name == "windows" {
        ^pwsh -NoProfile -File $"($nu.home-path)\\.config\\opencode-wrapper.ps1" ...$args
    } else {
        ^bash $"($nu.home-path)/.config/opencode-wrapper.sh" ...$args
    }
}

# ================================
# ⌨️ 快捷鍵設定
# ================================
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
    # Ctrl+F — fzf 互動選指令 (對應 PSFzf PSReadlineChordProvider)
    {
        name: fzf_provider
        modifier: control
        keycode: char_f
        mode: [emacs vi_normal vi_insert]
        event: {
            send: executehostcommand
            cmd: "commandline edit (history | get command | reverse | uniq | str join (char -i 0) | fzf --read0 --layout=reverse --height=40% --scheme=history --tiebreak=begin --prompt 'CMD > ' | str trim)"
        }
    }
    # Alt+C — fzf 跳轉目錄 (對應 PSFzf PSReadlineChordSetLocation)
    {
        name: fzf_cd
        modifier: alt
        keycode: char_c
        mode: [emacs vi_normal vi_insert]
        event: {
            send: executehostcommand
            cmd: "let __dir = (ls **/* | where type == dir | get name | str join (char -i 0) | fzf --read0 --layout=reverse --height=40% --prompt 'CD > ' | str trim); if ($__dir | is-not-empty) { cd $__dir }"
        }
    }
    # RightArrow — 接受下一個單字建議
    {
        name: accept_next_word
        modifier: none
        keycode: right
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
# 🔧 補全設定 (對應 PSReadLine Tab → MenuComplete)
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

# ================================
# 🚀 zoxide 初始化
# ================================
zoxide init nushell | save -f ~/.zoxide.nu
source ~/.zoxide.nu
