# config.nu — Nushell 主設定檔
#
# 載入順序：env.nu → config.nu → login.nu
# 這個檔案設定 nushell 的行為、外觀、快捷鍵、自訂函數等。
# 環境變數請放 env.nu，這裡專注在 shell 行為設定。

# Nushell 內部診斷日誌請以 CLI 啟用，確保可在設定載入失敗前寫入檔案：
# nu -i --log-level trace --log-target file --log-file ~/nu-internal-trace.log

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

# ================================
# 可信專案指令（project / p）
# ================================
# 信任名單只保存 canonical 專案根目錄；專案命令在子行程執行，
# 不使用 overlay，避免 Nushell 0.113 的 Tab 補全 regression。
# 專案根目錄需包含 .nu/project.nu，並以 `def main` 作為入口。
def __project-trust-file [] {
    $nu.home-dir | path join ".config" "nushell" "trusted-projects.nuon"
}

def __project-trusted-roots [] {
    let trust_file = (__project-trust-file)
    if not ($trust_file | path exists) { return [] }

    try {
        open $trust_file | where { |root| $root | describe | str starts-with "string" }
    } catch {
        print $"⚠️ 無法讀取可信專案清單：($trust_file)"
        []
    }
}

def __project-root [directory: string] {
    let current = try { $directory | path expand --strict } catch { return null }

    __project-trusted-roots
    | each { |root|
        let canonical_root = try { $root | path expand --strict } catch { return null }
        if $canonical_root == null { return null }

        let relative = ($current | path relative-to $canonical_root)
        let first_component = ($relative | path split | first)
        if $first_component != ".." { $canonical_root } else { null }
    }
    | compact
    | sort-by { |root| $root | str length }
    | last
}

def "project trust" [directory?: string] {
    let requested_root = ($directory | default $env.PWD)
    let root = try { $requested_root | path expand --strict } catch {
        print $"❌ 無法解析專案路徑：($requested_root)"
        return
    }
    let module = ($root | path join ".nu" "project.nu")
    if not ($module | path exists) {
        print $"❌ 找不到專案入口：($module)"
        return
    }

    let trusted_roots = (__project-trusted-roots)
    if $root in $trusted_roots {
        print $"✓ 已信任：($root)"
        return
    }

    (($trusted_roots | append $root) | to nuon) | save --force (__project-trust-file)
    print $"✓ 已信任：($root)"
}

def "project untrust" [directory?: string] {
    let requested_root = ($directory | default $env.PWD)
    let root = try { $requested_root | path expand --strict } catch {
        print $"❌ 無法解析專案路徑：($requested_root)"
        return
    }

    ((__project-trusted-roots | where { |trusted| $trusted != $root }) | to nuon)
    | save --force (__project-trust-file)
    print $"✓ 已取消信任：($root)"
}

def "project status" [] {
    let root = (__project-root $env.PWD)
    if $root == null {
        print "目前不在可信專案內。"
        return
    }

    print $"可信專案：($root)"
    print $"入口：($root | path join '.nu' 'project.nu')"
}

def "project run" [command: string, ...args] {
    let root = (__project-root $env.PWD)
    if $root == null {
        print "❌ 目前不在可信專案內；請先在專案根目錄執行 `project trust`。"
        return
    }

    let module = ($root | path join ".nu" "project.nu")
    if not ($module | path exists) {
        print $"❌ 找不到專案入口：($module)"
        return
    }

    ^nu $module $command ...$args
}

# p dev、p test 等同於 project run dev、project run test。
def p [command: string, ...args] {
    project run $command ...$args
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

    # nushell 內建指令不能交給 carapace 補全參數：
    # carapace 不認識 cd/ls 等內建指令時，會 fallback 回傳「所有外部指令清單」，
    # 而非空值；nushell 收到非 null 結果就不會再用自己的內建補全（如目錄補全），
    # 導致 `cd wor<Tab>` 變成對著一堆不相干的指令名稱做模糊匹配 → NO RECORDS FOUND。
    # 故先攔截這些指令，直接回傳 null，讓 nushell 用內建補全處理。
    let carapace_skip_builtins = [cd ls cp mv rm mkdir open save touch]

    # 設定外部補全器：把每次 Tab 的輸入傳給 carapace，回傳 JSON 格式的補全清單
    $env.config.completions.external.completer = {|spans|
        if $spans.0 in $carapace_skip_builtins { return null }
        carapace $spans.0 nushell ...$spans | from json
    }
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
# 用絕對路徑呼叫 fnm，避免 PATH 順序問題導致 which 成立但 ^fnm 找不到
# 僅限 Unix（WSL / Linux / macOS）：Windows 的 fnm 不在 ~/.local/bin，且 --shell bash 不適用。
let fnm_bin = ($nu.home-dir | path join ".local" "bin" "fnm")
if ($nu.os-info.name != "windows") and ($fnm_bin | path exists) {
    # 1. 解析 `fnm env` 的所有 export 成 record（此步會建立 multishell 目錄）
    let fnm_vars = (^$fnm_bin env --shell bash
        | lines
        | where { |l| $l | str starts-with "export " }
        | parse 'export {name}="{value}"'
        # 排除 PATH（fnm 的 PATH 行含 "$PATH" 變數，解析後會是壞值；PATH 由下方自行處理）
        | where name != "PATH"
        | reduce --fold {} { |it, acc| $acc | upsert $it.name $it.value })
    # 2. 注入 fnm 環境變數（FNM_DIR、FNM_MULTISHELL_PATH 等）
    load-env $fnm_vars
    # 3. 把 multishell bin 加到 PATH 最前面，讓 node 優先於 Windows node.exe
    $env.PATH = ($env.PATH | prepend $"($fnm_vars.FNM_MULTISHELL_PATH)/bin")
    # 4. 環境就緒後才啟用 node 版本，建立 multishell bin 內的 node symlink
    with-env $fnm_vars { ^$fnm_bin use default --install-if-missing | ignore }
}

# ================================
# 指令與啟動診斷日誌（診斷用）
# ================================
# 預設不對共用檔案做每個命令的同步寫入；多 pane 下這可能放大 I/O 競爭。
# 需要命令時間軸時，請在啟動前設定 NU_COMMAND_LOG=1。
let __nu_command_log_enabled = (($env.NU_COMMAND_LOG? | default "0") == "1")
let __nu_command_log_path = ($nu.home-dir | path join "nu_cmd.log")
if $__nu_command_log_enabled {
    # append（而非覆寫）既有 hooks，保留 atuin 等整合。
    $env.config.hooks.pre_execution = (
        $env.config.hooks.pre_execution? | default [] | append {||
            let command = (commandline)
            let timestamp = (date now | format date "%Y-%m-%dT%H:%M:%S%.3f%z")
            $"[START] ($timestamp) ($command)\n" | save --append $__nu_command_log_path
        }
    )
    $env.config.hooks.pre_prompt = (
        $env.config.hooks.pre_prompt? | default [] | append {||
            let timestamp = (date now | format date "%Y-%m-%dT%H:%M:%S%.3f%z")
            $"[END]   ($timestamp)\n" | save --append $__nu_command_log_path
        }
    )
}

# 啟動診斷在第一個 prompt 出現時寫入 READY；缺少此行即表示卡在較早階段。
let __nu_startup_debug_enabled = (($env.NU_STARTUP_DEBUG? | default "0") == "1")
let __nu_startup_log_path = ($nu.home-dir | path join "nu-startup-debug.log")
if $__nu_startup_debug_enabled {
    let timestamp = (date now | format date "%Y-%m-%dT%H:%M:%S%.3f%z")
    $"[CONFIG_ENTER] ($timestamp)\n" | save --append $__nu_startup_log_path
    $env.config.hooks.pre_prompt = (
        $env.config.hooks.pre_prompt? | default [] | append {||
            let ready_timestamp = (date now | format date "%Y-%m-%dT%H:%M:%S%.3f%z")
            $"[PROMPT_READY] ($ready_timestamp)\n" | save --append $__nu_startup_log_path
        }
    )
}

# ================================
# 機器專屬設定（不進 chezmoi repo）
# ================================
# 在這裡放：公司 proxy、機器特定 alias、實驗性設定、secret 等
# 每台機器自行建立 ~/.config/nushell/local.nu，不會被 chezmoi 追蹤
#
# ⚠️ 這裡必須用 source，不能用 overlay use！
# nushell 0.113 的 overlay 有 regression（issue #14213 復發）：
# overlay 啟用後，Tab 補全的基準目錄會凍結在 nu 啟動時的目錄，
# cd 之後補全永遠對著舊目錄找 → NO RECORDS FOUND。
# source 為 parse-time 載入且要求檔案必須存在；
# env.nu 已保證 local.nu 必定存在（不存在時自動建立空檔）。
source ~/.config/nushell/local.nu

# ================================
# 將 Windows (/mnt/c) 路徑降到最低優先級
# ================================
# 放在 config.nu 最尾端，確保涵蓋 env.nu / local.nu 所有 PATH 設定。
# 僅在 WSL 執行(偵測 /proc/version 含 microsoft)：
# 先去重(uniq)再以 sort-by 穩定排序：starts-with "/mnt/c" 為 false 的(Linux)
# 排前面、true 的(Windows)排後面，組內原順序不變，不刪除任何路徑。
# 非 WSL(macOS / 純 Linux / Windows)完全跳過此段。
if ("/proc/version" | path exists) and ((open /proc/version | str downcase | str contains "microsoft")) {
    $env.PATH = ($env.PATH | split row (char esep) | uniq | sort-by { |p| $p | str starts-with "/mnt/c" })
}

# ================================
# 歡迎語
# ================================
# 啟動時顯示目前時間、nushell 版本、使用者名稱
# USERNAME? / USER?：? 表示 optional access，欄位不存在時不報錯，回傳 null
# default "User"：null 時的 fallback 值
let __user = ($env.USERNAME? | default ($env.USER? | default "User"))
print $"\n🕐 (date now | format date '%Y-%m-%d %H:%M:%S')  |  🐚 Nushell (version | get version)  |  👤 ($__user)\n"
