# Claude Code StatusLine
# 讀取 JSON 輸入
try {
    $input_data = $input | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Host "USER" -NoNewline
    exit 0
}

# 基本資訊
$username = $env:USERNAME
$current_dir = Split-Path $input_data.workspace.current_dir -Leaf
$model = $input_data.model.display_name

# Git 資訊（跳過 optional locks）
$git_branch = ""
try {
    Push-Location $input_data.workspace.current_dir -ErrorAction SilentlyContinue
    $git_branch = git --no-optional-locks branch --show-current 2>$null
    Pop-Location
} catch {
    $git_branch = ""
}

# 時間
$time = Get-Date -Format "HH:mm"

# 組合輸出 - 優化顯示格式
$parts = @()

# 模型資訊（簡化顯示）
if ($model) {
    $model_short = $model -replace "Claude ", ""
    $parts += "$model_short"
}

# 使用者和目錄
$parts += " $username"
$parts += " $current_dir"

# Git 分支
if ($git_branch) {
    $parts += " $git_branch"
}

# 時間
$parts += " $time"

$output = $parts -join " | "
Write-Host $output -NoNewline
