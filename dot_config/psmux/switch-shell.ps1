#!/usr/bin/env pwsh
# psmux Shell 切換工具
# 用途: 快速在 Nushell 和 PowerShell 之間切換

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("nu", "pwsh", "status")]
    [string]$Shell = "status"
)

$ConfigDir = "$env:USERPROFILE\.config\psmux"
$MainConfig = "$ConfigDir\psmux.conf"
$BackupConfig = "$ConfigDir\psmux.conf.backup"

function Get-CurrentShell {
    $content = Get-Content $MainConfig -Raw
    if ($content -match 'set -g default-shell "nu\.exe"') {
        return "Nushell"
    } elseif ($content -match 'set -g default-shell "pwsh\.exe"') {
        return "PowerShell"
    } else {
        return "Unknown"
    }
}

function Switch-ToNushell {
    Write-Host "🔄 切換到 Nushell..." -ForegroundColor Cyan
    
    $content = Get-Content $MainConfig -Raw
    $content = $content -replace 'set -g default-shell "pwsh\.exe"', 'set -g default-shell "nu.exe"'
    $content = $content -replace 'set -g default-command "pwsh\.exe -NoLogo"', '# set -g default-command "pwsh.exe -NoLogo"'
    
    Set-Content -Path $MainConfig -Value $content -NoNewline
    
    Write-Host "✅ 已切換到 Nushell" -ForegroundColor Green
    Write-Host "⚠️  請重新啟動 psmux 以套用變更:" -ForegroundColor Yellow
    Write-Host "   psmux kill-server && psmux" -ForegroundColor Gray
}

function Switch-ToPowerShell {
    Write-Host "🔄 切換到 PowerShell..." -ForegroundColor Cyan
    
    $content = Get-Content $MainConfig -Raw
    $content = $content -replace 'set -g default-shell "nu\.exe"', 'set -g default-shell "pwsh.exe"'
    $content = $content -replace '# set -g default-command "pwsh\.exe -NoLogo"', 'set -g default-command "pwsh.exe -NoLogo"'
    
    Set-Content -Path $MainConfig -Value $content -NoNewline
    
    Write-Host "✅ 已切換到 PowerShell" -ForegroundColor Green
    Write-Host "⚠️  請重新啟動 psmux 以套用變更:" -ForegroundColor Yellow
    Write-Host "   psmux kill-server && psmux" -ForegroundColor Gray
}

function Show-Status {
    $current = Get-CurrentShell
    Write-Host "`n📊 psmux Shell 狀態" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "當前 Shell: " -NoNewline
    Write-Host $current -ForegroundColor Green
    Write-Host "`n可用命令:" -ForegroundColor Yellow
    Write-Host "  pwsh switch-shell.ps1 nu     # 切換到 Nushell" -ForegroundColor Gray
    Write-Host "  pwsh switch-shell.ps1 pwsh   # 切換到 PowerShell" -ForegroundColor Gray
    Write-Host "  pwsh switch-shell.ps1 status # 顯示當前狀態" -ForegroundColor Gray
    Write-Host ""
}

# 主邏輯
switch ($Shell) {
    "nu" {
        Switch-ToNushell
    }
    "pwsh" {
        Switch-ToPowerShell
    }
    "status" {
        Show-Status
    }
}
