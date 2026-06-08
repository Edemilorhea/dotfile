# env.nu — Nushell 環境變數設定檔
#
# 載入順序：env.nu → config.nu → login.nu
# 這個檔案專門設定環境變數與 PATH，在 config.nu 之前執行。
# 適合放：$env.XXX 設定、PATH 擴充、外部工具橋接（keychain、nix 等）

# ================================
# 基本環境變數
# ================================

# WezTerm 日誌等級，設為 warn 避免終端機出現多餘的 debug 輸出
$env.WEZTERM_LOG = "warn"

# 停用 virtualenv / pyenv 修改 prompt 的行為
# （讓 prompt 由 starship 或 oh-my-posh 統一管理）
$env.VIRTUAL_ENV_DISABLE_PROMPT = 1
$env.PYENV_VIRTUALENV_DISABLE_PROMPT = 1

# carapace 補全時不分大小寫（"1" 啟用）
$env.CARAPACE_MATCH = "1"

# ================================
# PATH 擴充（Windows）
# ================================

# Windows：把使用者設定目錄加入 PATH
if $nu.os-info.name == "windows" {
    $env.PATH = ($env.PATH | append $"($env.USERPROFILE)\\.config")
}

# Windows：自動偵測 Git 安裝路徑（依常見位置逐一嘗試）
# Linux/macOS 的 Git 通常已在系統 PATH，不需額外處理
if $nu.os-info.name == "windows" {
    let git_candidates = [
        'C:\Program Files\Git\bin'
        'C:\Program Files (x86)\Git\bin'
        ($env.LOCALAPPDATA | path join 'Programs\Git\bin')
        ($env.PROGRAMFILES | path join 'Git\bin')
    ]
    for $path in $git_candidates {
        if ($path | path exists) {
            $env.PATH = ($env.PATH | prepend $path)
            break
        }
    }
}

# ================================
# WSL 工作目錄修正
# ================================

# WSL 環境下，如果從 Windows 路徑（/mnt/c/... 等）開啟終端機
# 自動切換到 Linux home 目錄，避免在 Windows 路徑下操作
if $nu.os-info.name != "windows" {
    if ($env.PWD | str starts-with "/mnt/") {
        cd ~
    }
}

# ================================
# PATH 擴充（Linux/macOS）
# ================================

# 依序加入手動安裝工具的 bin 目錄（只加入實際存在的路徑）
# prepend 讓這些路徑優先於系統路徑
if $nu.os-info.name != "windows" {
    let local_bins = [
        $"($nu.home-dir)/.atuin/bin"         # atuin（歷史管理工具）
        $"($nu.home-dir)/.nix-profile/bin"   # Nix 使用者 profile
        "/nix/var/nix/profiles/default/bin"  # Nix 系統 profile
        $"($nu.home-dir)/.local/bin"          # 使用者自行安裝的工具
    ]
    for $path in $local_bins {
        if ($path | path exists) {
            $env.PATH = ($env.PATH | prepend $path)
        }
    }
}

# Bun（JavaScript runtime / package manager）
if ($"($nu.home-dir)/.bun/bin" | path exists) {
    $env.PATH = ($env.PATH | prepend $"($nu.home-dir)/.bun/bin")
}

# ================================
# SSH Agent（keychain 橋接）
# ================================
#
# keychain 是一個 ssh-agent 管理工具：
#   - 讓 ssh-agent 在 session 之間持續存活（重開 terminal 不用重輸密碼）
#   - 啟動後把 SSH_AUTH_SOCK / SSH_AGENT_PID 寫入 ~/.keychain/<hostname>-sh
#
# 這段做的事：
#   1. 掃描 ~/.ssh/ 下所有私鑰（排除 .pub、config、known_hosts）
#   2. 呼叫 keychain 載入所有私鑰（第一次會問 passphrase）
#   3. 讀取 keychain 輸出的環境變數，設進 nushell（讓後續 ssh 指令能找到 agent）
#
# 注意：nushell 不能直接 source bash 腳本，所以必須手動解析 keychain 輸出的 sh 格式
if $nu.os-info.name != "windows" {
    if (which keychain | is-not-empty) {
        # 自動掃描 ~/.ssh/ 下所有私鑰
        let ssh_keys = (
            ls $"($nu.home-dir)/.ssh/"
            | where name !~ '\.pub$'       # 排除公鑰
            | where name !~ 'config$'      # 排除 ssh config 檔
            | where name !~ 'known_hosts'  # 排除 known_hosts
            | where name !~ '\.sqlite'     # 排除 sqlite 資料庫（atuin 等工具會放在這）
            | where { |f| ($f.name | path exists) }
            | get name
        )
        if ($ssh_keys | length) > 0 {
            # --quiet: 不印多餘輸出
            # --nogui: 不彈出圖形視窗問密碼（在終端機直接問）
            # ...$ssh_keys: spread 語法，展開 list 為多個參數
            ^keychain --quiet --nogui ...$ssh_keys

            # keychain 把環境變數寫入 ~/.keychain/<hostname>-sh
            # 格式範例：
            #   SSH_AUTH_SOCK=/tmp/ssh-xxx/agent.123; export SSH_AUTH_SOCK;
            #   SSH_AGENT_PID=123; export SSH_AGENT_PID;
            let kc_file = $"($nu.home-dir)/.keychain/(sys host | get hostname)-sh"
            if ($kc_file | path exists) {
                let kc_lines = (open $kc_file | str trim | lines)

                # 用 parse 樣板解析出值（nushell 不支援 source bash 格式）
                let sock_line = ($kc_lines | where { |l| $l | str starts-with "SSH_AUTH_SOCK=" } | first)
                let pid_line = ($kc_lines | where { |l| $l | str starts-with "SSH_AGENT_PID=" } | first)
                $env.SSH_AUTH_SOCK = ($sock_line | parse "SSH_AUTH_SOCK={val}; export SSH_AUTH_SOCK;" | get val.0 | str trim)
                $env.SSH_AGENT_PID = ($pid_line | parse "SSH_AGENT_PID={val}; export SSH_AGENT_PID;" | get val.0 | str trim)
            }
        }
    }
}
