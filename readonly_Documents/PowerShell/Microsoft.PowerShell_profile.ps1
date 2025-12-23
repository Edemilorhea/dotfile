# ================================
# 🚀 模組載入
# ================================
Import-Module PSFzf
Import-Module Terminal-Icons

# ================================
# 🌈 Oh My Posh 主題設定
# ================================
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\M365Princess.omp.json" | Invoke-Expression

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
Set-PSReadLineKeyHandler -Key Ctrl+r -ScriptBlock {
    $line = fzf (Get-History | ForEach-Object { $_.CommandLine })
    if ($line) { [Microsoft.PowerShell.PSConsoleReadLine]::Insert($line) }
}

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


# ================================
# ✨ 環境設定 (確保 UTF-8 輸出，移除重複和錯誤行)
# ================================
# 設定控制台輸出編碼為 UTF-8 (若 PowerShell 7+ 預設已是，此行可選)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# (已移除 $env:PYTHONWARNINGS = "" 和其他重複/錯誤的編碼設定行)


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