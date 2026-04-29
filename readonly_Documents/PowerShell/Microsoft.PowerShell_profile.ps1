# ================================
# 🚀 模組載入
# ================================
Import-Module PSReadLine
Import-Module PSFzf
Import-Module -Name Terminal-Icons
# Terminal-Icons 智慧載入 (自動修復損壞的設定)
#function Initialize-TerminalIcons {
#    $configRoot = Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'powershell\Community\Terminal-Icons'
#
#    # 如果之前有壞掉的設定，先乾脆砍掉
#    if (Test-Path $configRoot) {
#        try {
#            # 簡單測試一下 XML 是否能被 Import-Clixml 正常讀（例如 prefs.xml 或任何一個 xml）
#            Get-ChildItem $configRoot -Filter *.xml -ErrorAction SilentlyContinue |
#                Select-Object -First 1 |
#                ForEach-Object {
#                    Import-Clixml -Path $_.FullName -ErrorAction Stop | Out-Null
#                }
#        } catch {
#            Remove-Item $configRoot -Recurse -Force -ErrorAction SilentlyContinue
#        }
#    }
#
#    if (Get-Module -ListAvailable -Name Terminal-Icons) {
#        try {
#            Import-Module Terminal-Icons -ErrorAction Stop
#        } catch {
#            Write-Verbose "Failed to load Terminal-Icons: $($_.Exception.Message)"
#        }
#    }
#}
#
#Initialize-TerminalIcons

Import-Module PSEverything


# ================================
# 🌈 Oh My Posh 主題設定
# ================================
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\M365Princess.omp.json" | Invoke-Expression  # [omp-manager]
# ================================
# 🧩 WinGet 指令不存在提示
# ================================
Import-Module -Name Microsoft.WinGet.CommandNotFound

# ================================
# 🧠 Zoxide 智慧跳轉 (會自動處理 zi 與 fzf 的整合)
# ================================
Invoke-Expression (& { (zoxide init powershell) -join "`n" })

# (已移除您自訂的 function zi {...} 區塊)

# ================================
# ⌨️ PSReadLine + fzf 查歷史
# ================================
# Set-PSReadLineKeyHandler -Key Ctrl+r -ScriptBlock {
#     $line = fzf (Get-History | ForEach-Object { $_.CommandLine })
#     if ($line) { [Microsoft.PowerShell.PSConsoleReadLine]::Insert($line) }
# }
Set-PsFzfOption `
    -EnableAliasFuzzyEdit `
    -EnableAliasFuzzyHistory `
    -EnableAliasFuzzyKillProcess `
    -EnableAliasFuzzySetLocation `
    -EnableAliasFuzzyZLocation `
    -EnableAliasFuzzyScoop `
    -GitKeyBindings `
    -PSReadlineChordProvider 'Ctrl+f' `
    -PSReadlineChordReverseHistory 'Ctrl+r' `
    -PSReadlineChordSetLocation 'Alt+c'


# ================================
# 📂 GUI 選擇資料夾
# ================================
function cdgui {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "請選擇資料夾"
    if ($dialog.ShowDialog() -eq "OK") {
        Set-Location $dialog.SelectedPath
        Write-Host "`n✅ 已切換到：$($dialog.SelectedPath)`n"
    } else {
        Write-Host "`n❌ 已取消選擇`n"
    }
}

function cdlvim {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "請選擇要用 lvim 開啟的資料夾"
    if ($dialog.ShowDialog() -eq "OK") {
        Set-Location $dialog.SelectedPath
        & lvim .
    } else {
        Write-Host "`n❌ 已取消選擇`n"
    }
}


function tldr-fzf {
    $commands = tldr --list | Sort-Object
    if (-not $commands) {
        Write-Host "沒有指令列表，請先執行 tldr --update"
        return
    }

    $selected = $commands | fzf --prompt "查詢 TLDR > "
    if ($selected) {
        tldr $selected
    }
}

Function tldrzhtw {
    param([string]$cmd)
    tldr -L zh_TW $cmd
}


# ================================
# 📌 常用 Alias
# ================================
Set-Alias lvim 'C:\Users\TC\.local\bin\lvim.ps1'
Set-Alias tlzh tldrzhtw
Set-Alias tl tldr
Set-Alias nav navi

$env:WEZTERM_LOG = "debug"
$env:PATH += ";$env:USERPROFILE\.config"

# ================================
# ✨ 環境設定 (確保 UTF-8 輸出，移除重複和錯誤行)
# ================================
# 設定控制台輸出編碼為 UTF-8 (若 PowerShell 7+ 預設已是，此行可選)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()


#快速搜尋所有路徑
$global:EverythingFolderCache = $null

function fcd-refresh {
    $global:EverythingFolderCache = Search-Everything -Filter "folder:" -Global
    Write-Host "✅ 快取已更新：$($global:EverythingFolderCache.Count) 個資料夾"
}

function fcd {
    if (-not $global:EverythingFolderCache) {
        Write-Host "⏳ 首次載入中..."
        fcd-refresh
    }

    $selected = $global:EverythingFolderCache | fzf --prompt "跳轉到 > "

    if ($selected) {
        Set-Location $selected
        Write-Host "`n✅ 已切換到：$selected`n"
    }
}


# 預測選項
Set-PSReadLineOption -PredictionSource HistoryAndPlugin  # 歷史記錄 + 插件
Set-PSReadLineOption -PredictionViewStyle ListView       # 清單檢視
Set-PSReadLineOption -MaximumHistoryCount 10000         # 歷史記錄數量

# 快捷鍵設定
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key RightArrow -Function ForwardWord
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function AcceptNextSuggestionWord
Set-PSReadLineKeyHandler -Key Alt+F -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Key F2 -Function SwitchPredictionView

# 移除 Alt+A 綁定 (讓 Zellij Leader 鍵生效)
Remove-PSReadLineKeyHandler -Chord "Alt+a"

Set-Alias bunx "bun"

# OpenCode 包裝腳本 - 防止退出時關閉終端
Set-Alias oc "C:\Users\tc_tseng\.config\opencode-wrapper.ps1"

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
