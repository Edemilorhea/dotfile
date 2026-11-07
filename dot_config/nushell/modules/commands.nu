# General custom commands.
def psmux [...args] {
    if $nu.os-info.name != "windows" { print "❌ psmux 僅支援 Windows"; return }
    let scoop = ($nu.home-dir | path join "scoop" "shims" "psmux.exe")
    let cargo = ($nu.home-dir | path join ".cargo" "bin" "psmux.exe")
    let exe = if ($cargo | path exists) { $cargo } else if ($scoop | path exists) { $scoop } else { print "psmux not found"; return }
    ^$exe ...$args
}
def --env lvim [...args] {
    let bin = ($nu.home-dir | path join ".local" "bin" (if $nu.os-info.name == "windows" { "lvim.ps1" } else { "lvim" }))
    if not ($bin | path exists) { print $"❌ lvim 未找到於: ($bin)"; return }
    ^$bin ...$args
}
def czgit [...args] { git -C (chezmoi source-path) ...$args }
def ocRider [] { opencode --port 4096 }
def myhelp [] { print "\n自訂指令清單\n"; help commands | where command_type == "custom" | get name | each { |cmd| print $"  ($cmd)" }; print "" }
def tldrzhtw [cmd: string] { tldr -L zh_TW $cmd }
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
def --wrapped pw [...args] { if $nu.os-info.name != "windows" { print "❌ pw 僅支援 Windows"; return }; ^pwsh -NoProfile -Command ($args | str join " ") }
def --wrapped pwe [...args] { if $nu.os-info.name != "windows" { print "❌ pwe 僅支援 Windows"; return }; ^pwsh -NoProfile -Command ($args | str join " ") | lines | each { |l| $l } }
def --wrapped bx [...args] { ^bash -c ($args | str join " ") }

# OpenCode asset manager. Script lookup order: $env.OPENCODE_ASSETS_ROOT,
# the repo path the installer renders into commands/selfmade/assets.md,
# the current git repo, then an Everything (es) search.
def "nu-complete oca action" [] { [list profiles plan apply status update-plugins remove doctor] }
def oca-script [] {
    let name = "opencode-assets.ps1"
    let md = ($nu.home-dir | path join ".config" "opencode" "commands" "selfmade" "assets.md")
    let git_root = (do -i { ^git rev-parse --show-toplevel } | complete | get stdout | str trim)
    let candidates = [
        (if ($env.OPENCODE_ASSETS_ROOT? | is-not-empty) { $env.OPENCODE_ASSETS_ROOT | path join $name })
        (if ($md | path exists) { open --raw $md | parse --regex ('-File "(?<p>[^"]+' + $name + ')"') | get -o 0.p })
        (if ($git_root | is-not-empty) { $git_root | path join $name })
        (if (which es | is-not-empty) { ^es -n 1 -whole-word $name | lines | get -o 0 })
    ]
    $candidates | compact --empty | where { path exists } | get -o 0
}
def --wrapped oca [action?: string@"nu-complete oca action", ...rest] {
    let script = (oca-script)
    if ($script | is-empty) { print "? 找不到 opencode-assets.ps1：請先 clone repo 並 apply 一次，或設定 $env.OPENCODE_ASSETS_ROOT"; return }
    let args = if $action == null { $rest } else { [$action ...$rest] }
    ^pwsh -NoProfile -File $script ...$args
}
