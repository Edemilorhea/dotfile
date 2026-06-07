# env.nu
#
# Installed by:
# version = "0.112.2"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.

# ================================
# 🌈 環境變數
# ================================
$env.WEZTERM_LOG = "warn"
$env.VIRTUAL_ENV_DISABLE_PROMPT = 1
$env.PYENV_VIRTUALENV_DISABLE_PROMPT = 1
$env.CARAPACE_MATCH = "1"  # carapace 補全不分大小寫

# 添加 PATH（跨平台）
if $nu.os-info.name == "windows" {
    $env.PATH = ($env.PATH | append $"($env.USERPROFILE)\\.config")
}

# 智慧偵測 Git 路徑 (跨平台)
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
# Linux/macOS 通常 Git 已在 PATH,不需額外處理

# WSL：從 Windows 路徑進入時自動切換到 home
if $nu.os-info.name != "windows" {
    if ($env.PWD | str starts-with "/mnt/") {
        cd ~
    }
}

# Linux 手動安裝工具的 PATH
if $nu.os-info.name != "windows" {
    let local_bins = [
        $"($nu.home-dir)/.atuin/bin"
        $"($nu.home-dir)/.nix-profile/bin"
        "/nix/var/nix/profiles/default/bin"
        $"($nu.home-dir)/.local/bin"
    ]
    for $path in $local_bins {
        if ($path | path exists) {
            $env.PATH = ($env.PATH | prepend $path)
        }
    }
}
