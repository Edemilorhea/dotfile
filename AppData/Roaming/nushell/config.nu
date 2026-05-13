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
alias tlzh = tldrzhtw

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

# ================================
# ⌨️ 快捷鍵設定
# ================================
# 設定 fzf 歷史搜尋 (Ctrl+R)
$env.config = ($env.config | upsert keybindings [
    {
        name: fzf_history
        modifier: control
        keycode: char_r
        mode: [emacs vi_normal vi_insert]
        event: {
            send: executehostcommand
            cmd: "commandline (history | get command | reverse | uniq | str join (char -i 0) | fzf --read0 --layout=reverse --height=40% | str trim)"
        }
    }
    {
        name: accept_suggestion
        modifier: alt
        keycode: char_f
        mode: [emacs vi_insert]
        event: { send: HistoryHintWordComplete }
    }
])
