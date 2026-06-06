# config.nu — Nushell 0.113.1+

$env.NU_LOG_LEVEL = "TRACE"

# ================================
# Prompt
# ================================
if ($env.OPENCODE_SESSION? | is-not-empty) {
    $env.PROMPT_COMMAND = {||
        let path_segment = ($env.PWD | str replace $nu.home-dir "~")
        $"(ansi green_bold)❯(ansi reset) (ansi cyan)($path_segment)(ansi reset) "
    }
    $env.PROMPT_COMMAND_RIGHT = {|| "" }
    $env.PROMPT_INDICATOR = ""
    $env.PROMPT_MULTILINE_INDICATOR = "::: "
} else if $nu.os-info.name == "windows" {
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
            mut clear = false
            if $nu.history-enabled {
                $clear = (history | is-empty) or ((history | last 1 | get -i 0.command) == "clear")
            }
            if ($env.SET_POSHCONTEXT? | is-not-empty) {
                do --env $env.SET_POSHCONTEXT
            }
            mut config_arg = []
            if ($env.POSH_THEMES_PATH? | is-not-empty) {
                let t = ($env.POSH_THEMES_PATH | path join "M365Princess.omp.json")
                if ($t | path exists) { $config_arg = [$"--config=($t)"] }
            }
            (^oh-my-posh print primary
                --save-cache --shell=nu
                ...$config_arg
                $"--shell-version=($env.POSH_SHELL_VERSION)"
                $"--status=($env.LAST_EXIT_CODE)"
                $"--no-status=false"
                $"--execution-time=($env.CMD_DURATION_MS)"
                $"--terminal-width=((term size).columns)"
                $"--job-count=(job list | length)"
                $"--cleared=($clear)")
        }
        $env.PROMPT_COMMAND_RIGHT = {|| "" }
    }
    # Linux/macOS: Starship via vendor/autoload/starship.nu
}

# ================================
# Alias
# ================================
alias tl = tldr
alias nav = navi
alias bunx = bun
alias tlzh = tldrzhtw
alias occmd = cmd /c opencode

# ================================
# 自訂函數
# ================================
def psmux [...args] {
    if $nu.os-info.name != "windows" { print "❌ psmux 僅支援 Windows"; return }
    let scoop = ($nu.home-dir | path join "scoop" "shims" "psmux.exe")
    let cargo = ($nu.home-dir | path join ".cargo" "bin" "psmux.exe")
    let exe = if ($scoop | path exists) { $scoop } else if ($cargo | path exists) { $cargo } else {
        print "psmux not found"; return
    }
    ^$exe ...$args
}

def --env lvim [...args] {
    let bin = ($nu.home-dir | path join ".local" "bin" (if $nu.os-info.name == "windows" { "lvim.ps1" } else { "lvim" }))
    if not ($bin | path exists) { print $"❌ lvim 未找到於: ($bin)"; return }
    ^$bin ...$args
}

def czgit [...args] {
    git -C (chezmoi source-path) ...$args
}

def ocRider [] {
    opencode --port 4096
}

def myhelp [] {
    print "\n自訂指令清單\n"
    help commands | where command_type == "custom" | get name | each { |cmd| print $"  ($cmd)" }
    print ""
}

def tldrzhtw [cmd: string] {
    tldr -L zh_TW $cmd
}

def tldr-fzf [] {
    if (which fzf | is-empty) { print "❌ fzf 未安裝"; return }
    if (which tldr | is-empty) { print "❌ tldr 未安裝"; return }
    let commands = (tldr --list | lines | sort)
    if ($commands | is-empty) { print "請先執行 tldr --update"; return }
    let selected = ($commands | str join (char -i 0) | fzf --read0 --prompt "查詢 TLDR > " | str trim)
    if ($selected | is-not-empty) { tldr $selected }
}

def --env fcd [] {
    if $nu.os-info.name != "windows" { print "❌ fcd 僅支援 Windows"; return }
    if (which fzf | is-empty) { print "❌ fzf 未安裝"; return }
    if (which es | is-empty) { print "❌ es.exe 未安裝"; return }
    let result = (^es -folder | lines | fzf --prompt "跳轉到 > " --layout=reverse --height=40% | str trim)
    if ($result | is-not-empty) { cd $result }
}

def --env cdgui [] {
    if $nu.os-info.name != "windows" { print "❌ cdgui 僅支援 Windows"; return }
    let result = (^pwsh -NoProfile -Command @'
Add-Type -AssemblyName System.Windows.Forms
$d = New-Object System.Windows.Forms.FolderBrowserDialog
if ($d.ShowDialog() -eq "OK") { $d.SelectedPath }
'@ | str trim)
    if ($result | is-not-empty) { cd $result } else { print "❌ 已取消" }
}

def --env cdlvim [] {
    if $nu.os-info.name != "windows" { print "❌ cdlvim 僅支援 Windows"; return }
    let result = (^pwsh -NoProfile -Command @'
Add-Type -AssemblyName System.Windows.Forms
$d = New-Object System.Windows.Forms.FolderBrowserDialog
if ($d.ShowDialog() -eq "OK") { $d.SelectedPath }
'@ | str trim)
    if ($result | is-not-empty) { cd $result; ^lvim . } else { print "❌ 已取消" }
}

def --wrapped pw [...args] {
    if $nu.os-info.name != "windows" { print "❌ pw 僅支援 Windows"; return }
    ^pwsh -NoProfile -Command ($args | str join " ")
}

def --wrapped pwe [...args] {
    if $nu.os-info.name != "windows" { print "❌ pwe 僅支援 Windows"; return }
    ^pwsh -NoProfile -Command ($args | str join " ") | lines | each { |l| $l }
}

def --wrapped bx [...args] {
    ^bash -c ($args | str join " ")
}

# ================================
# 快捷鍵
# ================================
$env.config.keybindings = [
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
    {
        name: accept_suggestion
        modifier: alt
        keycode: char_f
        mode: [emacs vi_insert]
        event: { send: HistoryHintWordComplete }
    }
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
    {
        name: accept_next_word
        modifier: none
        keycode: end
        mode: [emacs vi_insert]
        event: { send: HistoryHintWordComplete }
    }
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
]

# ================================
# 補全設定
# ================================
$env.config.completions.case_sensitive = false
$env.config.completions.quick = true
$env.config.completions.partial = true
$env.config.completions.algorithm = "fuzzy"
$env.config.completions.external.enable = true
$env.config.completions.external.max_results = 100

# ================================
# 歷史設定
# ================================
$env.config.history.max_size = 100_000
$env.config.history.sync_on_enter = true
$env.config.history.file_format = "sqlite"
$env.config.history.isolation = false

# ================================
# 選單
# ================================
$env.config.menus = [
    {
        name: completion_menu
        only_buffer_difference: false
        marker: "| "
        type: { layout: columnar, columns: 4, col_width: 20, col_padding: 2 }
        style: { text: green, selected_text: { attr: r }, description_text: yellow }
    }
    {
        name: history_menu
        only_buffer_difference: false
        marker: "? "
        type: { layout: list, page_size: 10 }
        style: { text: green, selected_text: green_reverse, description_text: yellow }
    }
]

$env.config.use_ansi_coloring = true
$env.config.show_banner = false
$env.config.bracketed_paste = true
$env.config.render_right_prompt_on_last_line = true

# ================================
# Carapace 補全
# ================================
if (which carapace | is-not-empty) {
    $env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
    $env.config.completions.external.completer = {|spans| carapace $spans.0 nushell ...$spans | from json }
} else {
    print "⚠️  carapace 未安裝"
}

# ================================
# zoxide
# ================================
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
# Atuin
# ================================
if (which atuin | is-not-empty) {
    let __atuin_autoload = ($nu.default-config-dir | path join "vendor" "autoload" "atuin.nu")
    if not ($__atuin_autoload | path exists) {
        mkdir ($nu.default-config-dir | path join "vendor" "autoload")
        atuin init nu | save --force $__atuin_autoload
    }
} else {
    print "⚠️  atuin 未安裝"
}

# ================================
# Log（診斷用）
# ================================
let __nu_log_path = $"($nu.home-dir)/nu_cmd.log"

$env.config.hooks.pre_execution = [{||
    let cmd = (commandline)
    let ts = (date now | format date "%Y-%m-%d %H:%M:%S%.3f")
    $"[START $ts] ($cmd)\n" | save --append $__nu_log_path
}]

$env.config.hooks.pre_prompt = [{||
    let ts = (date now | format date "%Y-%m-%d %H:%M:%S%.3f")
    $"[END   $ts]\n" | save --append $__nu_log_path
}]

# ================================
# 歡迎語
# ================================
let __user = ($env.USERNAME? | default ($env.USER? | default "User"))
print $"\n🕐 (date now | format date '%Y-%m-%d %H:%M:%S')  |  🐚 Nushell (version | get version)  |  👤 ($__user)\n"
