param(
    [Parameter(Position = 0)]
    [ValidateSet('list', 'profiles', 'plan', 'apply', 'status', 'remove', 'doctor', 'slim8-migration')]
    [string]$Action,

    [ValidateSet('global', 'project')]
    [string]$Scope = 'project',

    [string[]]$Runtimes = @(),
    [string[]]$Profiles = @(),
    [string[]]$Assets = @(),
    [string[]]$Exclude = @(),
    [string[]]$Overlays = @(),
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$CatalogPath = (Join-Path $HOME '.config\opencode\config\external-assets.json'),
    [ValidateSet('plan', 'apply', 'restore')]
    [string]$MigrationMode = 'plan',
    [string]$BackupPath,
    [switch]$SkipUnsupported,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$script:ManagerVersion = '2.0.0'
$script:Slim8SkillNames = @(
    'simplify',
    'codemap',
    'clonedeps',
    'deepwork',
    'verification-planning',
    'reflect',
    'oh-my-opencode-slim',
    'worktrees'
)
$script:TuiExplicitSelection = $false
$script:AssetSelectionExplicit = $PSBoundParameters.ContainsKey('Assets')
$script:OverlaySelectionExplicit = $PSBoundParameters.ContainsKey('Overlays')
$script:RuntimeSelectionExplicit = $PSBoundParameters.ContainsKey('Runtimes')
$script:TuiBackValue = '__tui_back__'
$script:TuiProjectRoot = [IO.Path]::GetFullPath((Get-Location).Path)
$script:RuntimeTable = $null
$script:SelectedRuntimes = @()
$script:GlobalLockPath = $null

function Test-InteractiveTerminal {
    try {
        return [Environment]::UserInteractive -and
            -not [Console]::IsInputRedirected -and
            -not [Console]::IsOutputRedirected
    }
    catch {
        return $false
    }
}

function New-TuiOption {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][string]$Value,
        [string]$Description,
        [bool]$Installed = $false,
        [bool]$Disabled = $false
    )

    return [pscustomobject]@{
        label = $Label
        value = $Value
        description = $Description
        installed = $Installed
        disabled = $Disabled
    }
}

function Format-TuiItemList {
    param([object[]]$Items, [int]$Maximum = 4)

    $values = @($Items | Where-Object { $_ } | ForEach-Object { [string]$_ })
    if ($values.Count -le $Maximum) { return $values -join ', ' }
    return "$(@($values | Select-Object -First $Maximum) -join ', ') 等 $($values.Count) 項"
}

function Get-TuiItemKind {
    param([Parameter(Mandatory = $true)]$Item)

    if ($Item.channel -eq 'opencode-mcp') { return 'MCP' }
    if ($Item.PSObject.Properties['pluginSpec']) { return 'Plugin' }
    switch ([string]$Item.type) {
        'skill' { return 'Skill' }
        'skill-bundle' { return 'Skill bundle' }
        'skill-command-bundle' { return 'Skill / Command bundle' }
        'agent-command-bundle' { return 'Agent / Command bundle' }
        'marketplace' { return 'Marketplace' }
        'opencode-framework' { return 'OpenCode framework' }
        default { return [string]$Item.type }
    }
}

function Get-TuiItemDescription {
    param([Parameter(Mandatory = $true)]$Asset)

    $details = [Collections.Generic.List[string]]::new()
    if ($Asset.PSObject.Properties['description'] -and $Asset.description) {
        $details.Add([string]$Asset.description)
    }
    if ($Asset.PSObject.Properties['recommendation'] -and $Asset.recommendation) {
        $details.Add("推薦：$($Asset.recommendation)")
    }
    if ($Asset.PSObject.Properties['prerequisites'] -and @($Asset.prerequisites).Count -gt 0) {
        $details.Add("需要：$(Format-TuiItemList @($Asset.prerequisites))")
    }
    if ($Asset.PSObject.Properties['skills'] -and @($Asset.skills).Count -gt 0) {
        $details.Add("Skills：$(Format-TuiItemList @($Asset.skills))")
    }
    if ($Asset.PSObject.Properties['files'] -and @($Asset.files).Count -gt 0) {
        $details.Add("檔案：$(Format-TuiItemList @($Asset.files | ForEach-Object { $_.target }))")
    }
    if ($Asset.PSObject.Properties['targetPath']) { $details.Add("安裝到：$($Asset.targetPath)") }
    if ($Asset.PSObject.Properties['pluginSpec']) { $details.Add("Plugin：$($Asset.pluginSpec)") }
    elseif ($Asset.PSObject.Properties['package']) {
        $package = if ($Asset.PSObject.Properties['packageVersion']) { "$($Asset.package)@$($Asset.packageVersion)" } else { $Asset.package }
        $details.Add("套件：$package")
    }
    if ($Asset.PSObject.Properties['marketplace']) { $details.Add("Marketplace：$($Asset.marketplace)") }
    if ($Asset.channel -eq 'opencode-mcp') {
        $details.Add("設定：$($Asset.configPath) -> mcp.$($Asset.mcpKey)")
    }
    if ($details.Count -eq 0) { $details.Add("類型：$($Asset.type)；管道：$($Asset.channel)") }
    return $details -join '；'
}

function Get-TuiOverlayDescription {
    param(
        [Parameter(Mandatory = $true)]$Overlay,
        [Parameter(Mandatory = $true)]$Catalog
    )

    $description = "$($Overlay.description)；目標：$($Overlay.targetName)"
    if ($Overlay.PSObject.Properties['dependsOn'] -and @($Overlay.dependsOn).Count -gt 0) {
        $dependencies = @($Overlay.dependsOn | ForEach-Object {
            $asset = @($Catalog.assets | Where-Object id -eq $_) | Select-Object -First 1
            if ($asset) { "$(Get-TuiItemKind $asset)：$($_)" } else { [string]$_ }
        })
        $description += "；會同步安裝：$(Format-TuiItemList $dependencies 10)"
    }
    return $description
}

function Read-TuiMenu {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][object[]]$Options,
        [string[]]$SelectedValues = @(),
        [switch]$MultiSelect,
        [switch]$AllowEmpty,
        [switch]$AllowBack
    )

    if ($Options.Count -eq 0) { return $null }
    $current = 0
    $selected = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($value in $SelectedValues) { [void]$selected.Add($value) }

    while ($true) {
        Clear-Host
        Write-Host 'OpenCode 擴充管理器' -ForegroundColor Cyan
        Write-Host $Title -ForegroundColor White
        $help = if ($MultiSelect) {
            '↑/↓：移動  Space：選取  Enter：繼續  x：已安裝在目前位置  [-]：所選 runtime 不支援'
        }
        else { '↑/↓：移動  Enter：確認' }
        if ($AllowBack) { $help += '  Esc：上一頁' }
        Write-Host $help -ForegroundColor DarkGray
        Write-Host

        $pageSize = [Math]::Max(5, [Console]::WindowHeight - 8)
        $pageStart = [Math]::Floor($current / $pageSize) * $pageSize
        $pageEnd = [Math]::Min($Options.Count - 1, $pageStart + $pageSize - 1)
        for ($index = $pageStart; $index -le $pageEnd; $index++) {
            $option = $Options[$index]
            $cursor = if ($index -eq $current) { '>' } else { ' ' }
            $marker = if ($option.disabled) { '[-]' }
            elseif ($MultiSelect) {
                if ($selected.Contains([string]$option.value)) { '[x]' } else { '[ ]' }
            }
            else { '   ' }
            $installedMarker = if ($option.installed) { 'x' } else { ' ' }
            $color = if ($option.disabled) { 'DarkRed' }
            elseif ($index -eq $current) { 'Yellow' }
            else { 'Gray' }
            Write-Host "$cursor $marker $installedMarker $($option.label)" -ForegroundColor $color
            if ($index -eq $current -and $option.description) {
                Write-Host "      $($option.description)" -ForegroundColor DarkGray
            }
        }
        if ($Options.Count -gt $pageSize) {
            Write-Host
            Write-Host "項目 $($pageStart + 1)-$($pageEnd + 1)，共 $($Options.Count) 項" -ForegroundColor DarkGray
        }

        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            'UpArrow' { $current = if ($current -eq 0) { $Options.Count - 1 } else { $current - 1 } }
            'DownArrow' { $current = if ($current -eq $Options.Count - 1) { 0 } else { $current + 1 } }
            'Spacebar' {
                if ($MultiSelect -and -not $Options[$current].disabled) {
                    $value = [string]$Options[$current].value
                    if (-not $selected.Remove($value)) { [void]$selected.Add($value) }
                }
            }
            'Enter' {
                if (-not $MultiSelect) {
                    if (-not $Options[$current].disabled) { return $Options[$current].value }
                }
                elseif ($selected.Count -gt 0 -or $AllowEmpty) {
                    return @($Options | Where-Object { $selected.Contains([string]$_.value) } | ForEach-Object { [string]$_.value })
                }
            }
            'Escape' { if ($AllowBack) { return $script:TuiBackValue } }
        }
    }
}

function Confirm-TuiAction {
    param([Parameter(Mandatory = $true)][string]$Prompt)

    $answer = Read-TuiMenu $Prompt @(
        (New-TuiOption '否，返回上一頁' 'no' '返回選取畫面，不執行變更。')
        (New-TuiOption '是，繼續' 'yes' '立即執行選取的操作。')
    )
    return $answer -eq 'yes'
}

function Start-AssetManagerTui {
    param([Parameter(Mandatory = $true)]$Catalog)

    :main while ($true) {
        $chosenAction = Read-TuiMenu '請選擇要執行的操作' @(
            (New-TuiOption '顯示狀態' 'status' '檢查 Skills、Plugins、套件與其他擴充是否已安裝或發生差異。')
            (New-TuiOption '預覽安裝內容' 'plan' '顯示將套用的內容，但不修改檔案。')
            (New-TuiOption '安裝或更新' 'apply' '套用 Profile，或個別選取 Skills、Plugins、套件與其他擴充。')
            (New-TuiOption '移除受管理項目' 'remove' '移除鎖定檔中記錄的 Skills、Plugins、套件或其他擴充。')
            (New-TuiOption '執行診斷' 'doctor' '驗證 catalog 並偵測安裝差異。')
            (New-TuiOption '瀏覽所有項目' 'list' '依實際類型顯示 catalog 中的所有項目。')
            (New-TuiOption '瀏覽 Profiles' 'profiles' '顯示可用的 Profile 群組。')
            (New-TuiOption '離開' 'exit' '關閉且不進行任何操作。')
        )
        if ($chosenAction -eq 'exit') { return $false }
        $script:Action = $chosenAction
        if ($chosenAction -in @('list', 'profiles')) { return $true }

        :scope while ($true) {
            $selectableAssets = @($Catalog.assets | Where-Object { $_.channel -ne 'provenance-only' })
            $globalItemCount = @($selectableAssets | Where-Object { @($_.scopes) -contains 'global' }).Count
            $projectItemCount = @($selectableAssets | Where-Object { @($_.scopes) -contains 'project' }).Count
            $chosenScope = Read-TuiMenu '請選擇管理範圍' @(
                (New-TuiOption '全域使用者設定' 'global' "共 $globalItemCount 項；可從任何目錄管理使用者層級的安裝。")
                (New-TuiOption '目前專案' 'project' "共 $projectItemCount 項；固定安裝到目前目錄：$($script:TuiProjectRoot)")
            ) -AllowBack
            if ($chosenScope -eq $script:TuiBackValue) { continue main }
            $script:Scope = $chosenScope
            if ($Scope -eq 'project') { $script:ProjectRoot = $script:TuiProjectRoot }

            $resolvedRoot = [IO.Path]::GetFullPath($ProjectRoot)
            $tuiLock = Get-AssetLock (Get-LockPath $Scope $resolvedRoot)
            $installedIds = @($tuiLock.assets | ForEach-Object { [string]$_.id })
            $installedOverlayIds = @($tuiLock.overlays | ForEach-Object { [string]$_.id })
            if ($Action -eq 'remove') {
                $managedOptions = @(@($tuiLock.assets | ForEach-Object {
                    $catalogItem = @($Catalog.assets | Where-Object id -eq $_.id)[0]
                    $kind = if ($catalogItem) { Get-TuiItemKind $catalogItem } else { '擴充項目' }
                    New-TuiOption "[$kind] $($_.id)" "asset:$($_.id)" "安裝管道：$($_.channel)" $true
                }) + @($tuiLock.overlays | ForEach-Object {
                    $catalogOverlay = @($Catalog.overlays | Where-Object id -eq $_.id)[0]
                    $description = if ($catalogOverlay) { Get-TuiOverlayDescription $catalogOverlay $Catalog } else { "目標：$($_.targetPath)" }
                    New-TuiOption "[Overlay] $($_.id)" "overlay:$($_.id)" $description $true
                }))
                if ($managedOptions.Count -eq 0) {
                    Clear-Host
                    Write-Host '此範圍內找不到受管理的項目。' -ForegroundColor Yellow
                    continue scope
                }
                $chosenItems = @(Read-TuiMenu '請選擇要移除的項目' $managedOptions -MultiSelect -AllowBack)
                if ($chosenItems.Count -eq 1 -and $chosenItems[0] -eq $script:TuiBackValue) { continue scope }
                $script:Profiles = @()
                $script:Assets = @($chosenItems | Where-Object { $_.StartsWith('asset:') } | ForEach-Object { $_.Substring(6) })
                $script:Overlays = @($chosenItems | Where-Object { $_.StartsWith('overlay:') } | ForEach-Object { $_.Substring(8) })
                $script:TuiExplicitSelection = $true
                $script:OverlaySelectionExplicit = $true
                if (Confirm-TuiAction "確定要移除 $($chosenItems.Count) 個項目嗎？") { return $true }
                continue scope
            }

            $manifest = if ($Scope -eq 'project') { Get-ProjectManifest $resolvedRoot } else { $null }
            $runtimeTable = @(Get-RuntimeTable $Catalog)
            $lockedRuntimeIds = @($tuiLock.assets | ForEach-Object { Get-LockedRuntimeIds $_ $Catalog } | Select-Object -Unique)
            $suggestedRuntimes = if ($manifest -and @($manifest.runtimes).Count -gt 0) { @($manifest.runtimes) }
                elseif ($lockedRuntimeIds.Count -gt 0) { $lockedRuntimeIds }
                else { @($Catalog.defaultRuntimes) }

            :runtime while ($true) {
                $runtimeOptions = @($runtimeTable | ForEach-Object {
                    $details = [Collections.Generic.List[string]]::new()
                    $details.Add("指令：$($_.command)$(if (-not $_.commandAvailable) { '（不在 PATH 上）' })")
                    $details.Add("設定根目錄：$($_.configRoot)$(if (-not $_.configRootExists) { '（不存在）' })")
                    $details.Add("Plugin 設定鍵：$($_.pluginConfigKey)")
                    New-TuiOption "$($_.name) [$($_.id)]" $_.id ($details -join '；') $_.configRootExists
                })
                $chosenRuntimes = @(Read-TuiMenu '請選擇要安裝到哪些 OpenCode 版本' $runtimeOptions $suggestedRuntimes -MultiSelect -AllowBack)
                if ($chosenRuntimes.Count -eq 1 -and $chosenRuntimes[0] -eq $script:TuiBackValue) { continue scope }
                $script:Runtimes = $chosenRuntimes
                $script:RuntimeSelectionExplicit = $true
                # The TUI renders unsupported items as [-] and confirms the skip list
                # explicitly, so resolution must report them instead of throwing.
                $script:SkipUnsupported = $true
                $selectedRuntimeObjects = @(Resolve-SelectedRuntimes $Catalog $chosenRuntimes)

                $suggestedProfiles = if ($manifest) { @($manifest.profiles) }
                    elseif (@($tuiLock.profiles).Count -gt 0) { @($tuiLock.profiles) }
                    elseif ($Scope -eq 'global') { @($Catalog.defaultProfiles) }
                    else { @() }
                $availableItems = @($selectableAssets | Where-Object { @($_.scopes) -contains $Scope })
                $itemSupport = @{}
                foreach ($item in $availableItems) {
                    $itemSupport[[string]$item.id] = Get-AssetRuntimeSupport $item $Catalog $selectedRuntimeObjects
                }
                $profileOptions = @($Catalog.profiles.PSObject.Properties | ForEach-Object {
                    $profileName = $_.Name
                    $profileAssets = @($availableItems | Where-Object { @($_.profiles) -contains $profileName })
                    $profileItems = @($profileAssets | ForEach-Object {
                        $installedPrefix = if ($installedIds -contains $_.id) { 'x ' } else { '  ' }
                        $blockedSuffix = if ($itemSupport[[string]$_.id].supported.Count -eq 0) { '（不支援）' } else { '' }
                        "$installedPrefix$(Get-TuiItemKind $_)：$($_.id)$blockedSuffix"
                    })
                    if ($profileItems.Count -gt 0) {
                        $installableAssets = @($profileAssets | Where-Object { $itemSupport[[string]$_.id].supported.Count -gt 0 })
                        $profileInstalled = @($installableAssets | Where-Object { $installedIds -notcontains $_.id }).Count -eq 0
                        $profileDescription = "$($_.Value.description)；包含：$(Format-TuiItemList $profileItems 10)"
                        if ($installableAssets.Count -eq 0) {
                            $profileDescription += "；所選 runtime 無法安裝此 Profile 的任何項目"
                        }
                        New-TuiOption $profileName $profileName $profileDescription $profileInstalled ($installableAssets.Count -eq 0)
                    }
                })
                $availableProfileNames = @($profileOptions | Where-Object { -not $_.disabled } | ForEach-Object { $_.value })
                $suggestedProfiles = @($suggestedProfiles | Where-Object { $availableProfileNames -contains $_ })
                $itemOptions = @($availableItems | ForEach-Object {
                    $support = $itemSupport[[string]$_.id]
                    $label = "[$(Get-TuiItemKind $_)] $($_.id)"
                    $description = Get-TuiItemDescription $_
                    if ($support.blocked.Count -gt 0) {
                        $label += " (不支援 $(@($support.blocked | ForEach-Object { $_.runtime }) -join ', '))"
                        $description += "；$(Get-RuntimeBlockSummary $support.blocked)"
                    }
                    New-TuiOption $label $_.id $description ($installedIds -contains $_.id) ($support.supported.Count -eq 0)
                })

                :selection while ($true) {
                    $script:Profiles = @()
                    $script:Assets = @()
                    $script:Exclude = @()
                    $script:Overlays = @()
                    $script:OverlaySelectionExplicit = $false
                    $selectionMode = Read-TuiMenu '請選擇安裝內容的挑選方式' @(
                        (New-TuiOption '使用 Profile' 'profiles' '選一組或多組 Profile，畫面會列出各組包含的具體內容。')
                        (New-TuiOption '只選個別項目' 'individual' '直接挑選一個或多個 Skill、Plugin、套件或其他擴充。')
                        (New-TuiOption '進階選項' 'advanced' '微調 Profile：額外加入、排除，或同時設定兩者。')
                    ) -AllowBack
                    if ($selectionMode -eq $script:TuiBackValue) { continue runtime }
                    if ($selectionMode -eq 'advanced') {
                        $selectionMode = Read-TuiMenu '請選擇 Profile 微調方式' @(
                            (New-TuiOption '加入個別項目' 'add' '使用 Profile，並額外加入指定項目。')
                            (New-TuiOption '排除個別項目' 'exclude' '使用 Profile，但略過其中的指定項目。')
                            (New-TuiOption '同時加入與排除' 'both' '同時設定額外加入與排除清單。')
                        ) -AllowBack
                        if ($selectionMode -eq $script:TuiBackValue) { continue selection }
                    }

                    if ($selectionMode -ne 'individual') {
                        $selectedProfiles = @(Read-TuiMenu '請選擇 Profiles' $profileOptions $suggestedProfiles -MultiSelect -AllowBack)
                        if ($selectedProfiles.Count -eq 1 -and $selectedProfiles[0] -eq $script:TuiBackValue) { continue selection }
                        $script:Profiles = $selectedProfiles
                    }
                    if ($selectionMode -in @('individual', 'add', 'both')) {
                        $title = if ($selectionMode -eq 'individual') { '請選擇要安裝的個別項目' } else { '請選擇要額外加入的項目' }
                        $selectedItems = @(Read-TuiMenu $title $itemOptions -MultiSelect -AllowBack)
                        if ($selectedItems.Count -eq 1 -and $selectedItems[0] -eq $script:TuiBackValue) { continue selection }
                        $script:Assets = $selectedItems
                    }
                    if ($selectionMode -in @('exclude', 'both')) {
                        $excludedItems = @(Read-TuiMenu '請選擇要排除的項目' $itemOptions -MultiSelect -AllowBack)
                        if ($excludedItems.Count -eq 1 -and $excludedItems[0] -eq $script:TuiBackValue) { continue selection }
                        $script:Exclude = $excludedItems
                    }
                    $script:TuiExplicitSelection = $true
                    # A selected Profile can still contain an asset that none of the chosen
                    # runtimes supports. Report it here instead of failing later in apply.
                    try {
                        $resolvedSelection = Get-Selections $Catalog $Scope $resolvedRoot
                    }
                    catch {
                        Clear-Host
                        Write-Host '選取的內容無法安裝到所選的 runtime：' -ForegroundColor Yellow
                        Write-Host $_.Exception.Message -ForegroundColor Gray
                        Wait-TuiContinue
                        continue selection
                    }
                    $blockedSelection = @($resolvedSelection.blocked)
                    if ($blockedSelection.Count -gt 0) {
                        Clear-Host
                        Write-Host '以下項目在所選 runtime 無法安裝，將被略過：' -ForegroundColor Yellow
                        foreach ($blockedAsset in $blockedSelection) {
                            Write-Host "  $($blockedAsset.id)：$(Get-RuntimeBlockSummary $blockedAsset.blocked)" -ForegroundColor Gray
                        }
                        if (-not (Confirm-TuiAction '要略過這些項目並繼續嗎？')) { continue selection }
                    }
                    $availableOverlays = @(
                        if ($Scope -eq 'project') {
                            $Catalog.overlays | Where-Object {
                                @($_.scopes) -contains $Scope -and @($resolvedSelection.assets.id) -contains $_.targetAssetId
                            }
                        }
                    )
                    if ($availableOverlays.Count -gt 0) {
                        $suggestedOverlays = if ($manifest) { @($manifest.overlays) } else { $installedOverlayIds }
                        $overlayOptions = @($availableOverlays | ForEach-Object {
                            New-TuiOption "[Overlay] $($_.name)" $_.id (Get-TuiOverlayDescription $_ $Catalog) ($installedOverlayIds -contains $_.id)
                        })
                        $selectedOverlays = @(Read-TuiMenu '請選擇要套用的增修規則（Overlay）' $overlayOptions $suggestedOverlays -MultiSelect -AllowEmpty -AllowBack)
                        if ($selectedOverlays.Count -eq 1 -and $selectedOverlays[0] -eq $script:TuiBackValue) { continue selection }
                        $script:Overlays = $selectedOverlays
                        $script:OverlaySelectionExplicit = $true
                    }
                    if ($Action -eq 'apply') {
                        $scopeLabel = if ($Scope -eq 'global') { '全域設定' } else { '目前專案' }
                        $runtimeLabel = @($selectedRuntimeObjects | ForEach-Object { $_.id }) -join ', '
                        if (-not (Confirm-TuiAction "確定要將選取內容套用到${scopeLabel}（runtime：$runtimeLabel）嗎？")) { continue selection }
                    }
                    return $true
                }
            }
        }
    }
}

function Write-Result {
    param([Parameter(Mandatory = $true)]$Value)

    if ($Json) {
        $Value | ConvertTo-Json -Depth 20
    }
    else {
        $Value
    }
}

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$FailureMessage,
        [string]$WorkingDirectory,
        [hashtable]$Environment
    )

    $previous = Get-Location
    $previousEnvironment = @{}
    try {
        foreach ($key in @(if ($Environment) { $Environment.Keys } else { @() })) {
            $item = Get-Item -LiteralPath "Env:$key" -ErrorAction SilentlyContinue
            $previousEnvironment[$key] = [pscustomobject]@{
                exists = $null -ne $item
                value = if ($item) { $item.Value } else { $null }
            }
            Set-Item -LiteralPath "Env:$key" -Value $Environment[$key]
        }
        if ($WorkingDirectory) {
            Set-Location -LiteralPath $WorkingDirectory
        }
        & $Command @Arguments | Out-Host
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw "$FailureMessage (exit code $exitCode)"
        }
    }
    finally {
        Set-Location -LiteralPath $previous
        foreach ($key in @(if ($Environment) { $Environment.Keys } else { @() })) {
            $saved = $previousEnvironment[$key]
            if ($saved.exists) {
                Set-Item -LiteralPath "Env:$key" -Value $saved.value
            }
            else {
                Remove-Item -LiteralPath "Env:$key" -ErrorAction SilentlyContinue
            }
        }
    }
}

function Resolve-HomePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    if ($Path -eq '~') {
        return $HOME
    }
    if ($Path.StartsWith('~/') -or $Path.StartsWith('~\')) {
        return Join-Path $HOME $Path.Substring(2)
    }
    return [Environment]::ExpandEnvironmentVariables($Path)
}

function Test-RuntimeToken {
    param([Parameter(Mandatory = $true)][string]$Path)

    return $Path.Contains('{configRoot}')
}

function Expand-RuntimeToken {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowNull()]$Runtime
    )

    if (-not (Test-RuntimeToken $Path)) {
        return $Path
    }
    if (-not $Runtime) {
        throw "Path uses the {configRoot} token but no runtime was supplied: $Path"
    }
    return $Path.Replace('{configRoot}', $Runtime.configRoot)
}

function Get-CanonicalPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $full = [IO.Path]::GetFullPath($Path)
    $root = [IO.Path]::GetPathRoot($full)
    if ([string]::IsNullOrEmpty($root)) {
        return $full
    }
    $current = $root
    $segments = $full.Substring($root.Length).Split([char[]]@('\', '/'), [StringSplitOptions]::RemoveEmptyEntries)
    foreach ($segment in $segments) {
        $current = Join-Path $current $segment
        if (-not (Test-Path -LiteralPath $current)) {
            continue
        }
        $item = Get-Item -LiteralPath $current -Force
        if (-not $item.LinkType) {
            continue
        }
        $resolved = $item.ResolveLinkTarget($true)
        if ($resolved) {
            $current = $resolved.FullName
        }
    }
    return [IO.Path]::GetFullPath($current)
}

function Resolve-TargetPath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ResolvedScope,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot,
        [AllowNull()]$Runtime
    )

    $Path = Expand-RuntimeToken $Path $Runtime
    if ($Path.StartsWith('~')) {
        return [IO.Path]::GetFullPath((Resolve-HomePath $Path))
    }
    if ([IO.Path]::IsPathRooted($Path)) {
        return [IO.Path]::GetFullPath($Path)
    }
    if ($ResolvedScope -ne 'project') {
        throw "Relative target paths require project scope: $Path"
    }
    return [IO.Path]::GetFullPath((Join-Path $ResolvedProjectRoot $Path))
}

function Test-PathWithinRoot {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root
    )

    $fullPath = [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    return $fullPath.Equals($fullRoot, [StringComparison]::OrdinalIgnoreCase) -or
        $fullPath.StartsWith("$fullRoot$([IO.Path]::DirectorySeparatorChar)", [StringComparison]::OrdinalIgnoreCase)
}

function Get-Catalog {
    if (-not (Test-Path -LiteralPath $CatalogPath)) {
        throw "Asset catalog not found: $CatalogPath"
    }
    $catalog = Get-Content -LiteralPath $CatalogPath -Raw | ConvertFrom-Json
    $schemaVersion = if ($catalog.PSObject.Properties['schemaVersion']) { $catalog.schemaVersion } else { '<missing>' }
    if ($schemaVersion -ne 5) {
        throw "Unsupported asset catalog schema: $schemaVersion"
    }
    if (-not $catalog.PSObject.Properties['runtimes'] -or $catalog.runtimes -isnot [pscustomobject] -or
        @($catalog.runtimes.PSObject.Properties).Count -eq 0) {
        throw "Asset catalog schema 5 requires a non-empty runtimes object: $CatalogPath"
    }
    $globalLock = if ($catalog.PSObject.Properties['managerPaths'] -and
        $catalog.managerPaths.PSObject.Properties['globalLock']) {
        [string]$catalog.managerPaths.globalLock
    }
    else { '~/.config/opencode/config/assets.lock.json' }
    $script:GlobalLockPath = [IO.Path]::GetFullPath((Resolve-HomePath $globalLock))
    return $catalog
}

function Get-RuntimeTable {
    param([Parameter(Mandatory = $true)]$Catalog)

    if ($script:RuntimeTable) {
        return $script:RuntimeTable
    }
    $rows = foreach ($property in $Catalog.runtimes.PSObject.Properties) {
        $definition = $property.Value
        foreach ($required in @('name', 'command', 'configRoot', 'pluginConfigKey')) {
            if (-not $definition.PSObject.Properties[$required] -or
                [string]::IsNullOrWhiteSpace([string]$definition.PSObject.Properties[$required].Value)) {
                throw "Runtime $($property.Name) requires $required."
            }
        }
        $configured = [string]$definition.configRoot
        if ($definition.PSObject.Properties['configRootEnv'] -and $definition.configRootEnv) {
            $override = Get-Item -LiteralPath "Env:$($definition.configRootEnv)" -ErrorAction SilentlyContinue
            if ($override -and -not [string]::IsNullOrWhiteSpace($override.Value)) {
                $configured = [string]$override.Value
            }
        }
        $configRoot = [IO.Path]::GetFullPath((Resolve-HomePath $configured))
        [pscustomobject]@{
            id = $property.Name
            name = [string]$definition.name
            command = [string]$definition.command
            configRoot = $configRoot
            canonicalConfigRoot = Get-CanonicalPath $configRoot
            pluginConfigKey = [string]$definition.pluginConfigKey
            capabilities = @($definition.capabilities)
            configRootExists = Test-Path -LiteralPath $configRoot -PathType Container
            commandAvailable = $null -ne (Get-Command $definition.command -ErrorAction SilentlyContinue)
        }
    }
    $script:RuntimeTable = @($rows)
    return $script:RuntimeTable
}

function Get-RuntimeById {
    param(
        [Parameter(Mandatory = $true)]$Catalog,
        [Parameter(Mandatory = $true)][string]$RuntimeId
    )

    $runtime = @(Get-RuntimeTable $Catalog | Where-Object id -eq $RuntimeId) | Select-Object -First 1
    if (-not $runtime) {
        throw "Unknown runtime id: $RuntimeId"
    }
    return $runtime
}

function Resolve-SelectedRuntimes {
    param(
        [Parameter(Mandatory = $true)]$Catalog,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Requested
    )

    $table = Get-RuntimeTable $Catalog
    $knownIds = @($table | ForEach-Object { $_.id })
    $requestedIds = @($Requested | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if (@($requestedIds | Where-Object { $_ -in @('all', 'both') }).Count -gt 0) {
        $requestedIds = $knownIds
    }
    if ($requestedIds.Count -eq 0) {
        $requestedIds = @($Catalog.defaultRuntimes)
    }
    if ($requestedIds.Count -eq 0) {
        $requestedIds = $knownIds
    }
    $selectedIds = @($requestedIds | Select-Object -Unique)
    foreach ($id in $selectedIds) {
        if ($knownIds -notcontains $id) {
            throw "Unknown runtime id: $id. Known runtimes: $($knownIds -join ', ')"
        }
    }
    return @($table | Where-Object { $selectedIds -contains $_.id })
}

function Get-AssetRuntimeIds {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)]$Catalog
    )

    if ($Asset.PSObject.Properties['runtimes'] -and @($Asset.runtimes).Count -gt 0) {
        return @($Asset.runtimes | ForEach-Object { [string]$_ })
    }
    return @(Get-RuntimeTable $Catalog | ForEach-Object { $_.id })
}

function Get-AssetRuntimeBlockReason {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)][string]$RuntimeId
    )

    if (-not $Asset.PSObject.Properties['runtimeBlocked']) {
        return $null
    }
    $property = $Asset.runtimeBlocked.PSObject.Properties[$RuntimeId]
    if (-not $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)) {
        return $null
    }
    return [string]$property.Value
}

function Get-AssetRuntimeSupport {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)]$Catalog,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$SelectedRuntimes
    )

    $supportedIds = @(Get-AssetRuntimeIds $Asset $Catalog)
    $supported = @($SelectedRuntimes | Where-Object { $supportedIds -contains $_.id })
    $blocked = foreach ($runtime in @($SelectedRuntimes | Where-Object { $supportedIds -notcontains $_.id })) {
        $reason = Get-AssetRuntimeBlockReason $Asset $runtime.id
        [pscustomobject]@{
            runtime = $runtime.id
            reason = if ($reason) { $reason } else { "$($Asset.id) does not declare support for $($runtime.name)." }
        }
    }
    return [pscustomobject]@{
        declared = $supportedIds
        supported = @($supported)
        blocked = @($blocked)
    }
}

function Get-RuntimeBlockSummary {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Blocked)

    return @($Blocked | ForEach-Object { "$($_.runtime)：$($_.reason)" }) -join ' '
}

function Get-ProjectManifest {
    param([Parameter(Mandatory = $true)][string]$ResolvedProjectRoot)

    $path = Join-Path $ResolvedProjectRoot '.opencode\assets.json'
    if (-not (Test-Path -LiteralPath $path)) {
        return $null
    }
    $manifest = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    $schemaVersion = if ($manifest.PSObject.Properties['schemaVersion']) { $manifest.schemaVersion } else { '<missing>' }
    if ($schemaVersion -notin @(1, 2, 3)) {
        throw "Unsupported project asset manifest schema: $schemaVersion"
    }
    foreach ($propertyName in @('profiles', 'assets', 'exclude', 'overlays', 'runtimes')) {
        if (-not $manifest.PSObject.Properties[$propertyName]) {
            $manifest | Add-Member -NotePropertyName $propertyName -NotePropertyValue @()
        }
    }
    $manifest.schemaVersion = 3
    return $manifest
}

function Save-ProjectManifest {
    param(
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot,
        [Parameter(Mandatory = $true)]$Selection
    )

    $path = Join-Path $ResolvedProjectRoot '.opencode\assets.json'
    $manifest = Get-ProjectManifest $ResolvedProjectRoot
    if (-not $manifest) {
        $manifest = [pscustomobject]@{
            schemaVersion = 3
            profiles = @()
            assets = @()
            exclude = @()
            overlays = @()
            runtimes = @()
        }
    }
    Set-ObjectProperty $manifest 'schemaVersion' 3
    Set-ObjectProperty $manifest 'profiles' @($Selection.profiles)
    Set-ObjectProperty $manifest 'assets' @($Selection.assetIds)
    Set-ObjectProperty $manifest 'exclude' @($Selection.exclude)
    Set-ObjectProperty $manifest 'overlays' @($Selection.overlayIds)
    Set-ObjectProperty $manifest 'runtimes' @($Selection.runtimeIds)
    $parent = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
    $manifest | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $path -Encoding utf8
}

function Get-LockPath {
    param(
        [Parameter(Mandatory = $true)][string]$ResolvedScope,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot
    )

    if ($ResolvedScope -eq 'global') {
        if (-not $script:GlobalLockPath) {
            throw 'The global lock path is not resolved yet; load the catalog first.'
        }
        return $script:GlobalLockPath
    }
    return Join-Path $ResolvedProjectRoot '.opencode\assets.lock.json'
}

function Get-AssetLock {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{
            schemaVersion = 3
            managerVersion = $script:ManagerVersion
            generatedAt = $null
            scope = $Scope
            projectRoot = if ($Scope -eq 'project') { $ProjectRoot } else { $null }
            runtimeRoots = [pscustomobject]@{}
            profiles = @()
            assets = @()
            overlays = @()
            overlayOutputs = @()
        }
    }
    $lock = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    $schemaVersion = if ($lock.PSObject.Properties['schemaVersion']) { $lock.schemaVersion } else { '<missing>' }
    if ($schemaVersion -notin @(1, 2, 3)) {
        throw "Unsupported asset lock schema: $schemaVersion"
    }
    $defaults = [ordered]@{
        managerVersion = $script:ManagerVersion
        generatedAt = $null
        scope = $Scope
        projectRoot = if ($Scope -eq 'project') { $ProjectRoot } else { $null }
        runtimeRoots = [pscustomobject]@{}
        profiles = @()
        assets = @()
        overlays = @()
        overlayOutputs = @()
    }
    foreach ($propertyName in $defaults.Keys) {
        if (-not $lock.PSObject.Properties[$propertyName]) {
            $lock | Add-Member -NotePropertyName $propertyName -NotePropertyValue $defaults[$propertyName]
        }
    }
    $lock.schemaVersion = 3
    return $lock
}

function Get-LockedRuntimeIds {
    param(
        [Parameter(Mandatory = $true)]$Entry,
        [Parameter(Mandatory = $true)]$Catalog
    )

    if ($Entry.PSObject.Properties['runtimes'] -and @($Entry.runtimes).Count -gt 0) {
        return @($Entry.runtimes | ForEach-Object { [string]$_ })
    }
    # Lock schema 1 and 2 predate the runtime dimension; those entries were written
    # by a V1-only manager, so attribute them to the V1 runtime when it still exists.
    $knownIds = @(Get-RuntimeTable $Catalog | ForEach-Object { $_.id })
    if ($knownIds -contains 'v1') { return @('v1') }
    return @($knownIds | Select-Object -First 1)
}

function Save-AssetLock {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Lock
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent | Out-Null
    }
    $Lock.generatedAt = [DateTimeOffset]::UtcNow.ToString('o')
    $Lock.managerVersion = $script:ManagerVersion
    $Lock.schemaVersion = 3
    $Lock | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Path -Encoding utf8
}

function Get-PathsFingerprint {
    param([Parameter(Mandatory = $true)][AllowNull()][AllowEmptyCollection()][string[]]$Paths)

    $records = [Collections.Generic.List[string]]::new()
    foreach ($path in @($Paths | Sort-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $path)) {
            $records.Add("missing|$path")
            continue
        }
        $item = Get-Item -LiteralPath $path -Force
        if (-not $item.PSIsContainer) {
            $records.Add("file|$path|$((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash)")
            continue
        }
        foreach ($file in @(Get-ChildItem -LiteralPath $path -File -Recurse -Force | Sort-Object FullName)) {
            $relative = [IO.Path]::GetRelativePath($path, $file.FullName)
            $records.Add("tree|$path|$relative|$((Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash)")
        }
    }
    $bytes = [Text.Encoding]::UTF8.GetBytes(($records -join "`n"))
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
}

function Get-Selections {
    param(
        [Parameter(Mandatory = $true)]$Catalog,
        [Parameter(Mandatory = $true)][string]$ResolvedScope,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot
    )

    $manifest = if ($ResolvedScope -eq 'project') { Get-ProjectManifest $ResolvedProjectRoot } else { $null }
    $selectedProfiles = @($Profiles)
    $selectedAssets = @($Assets)
    $excludedAssets = @($Exclude)
    $selectedOverlays = @($Overlays)
    $requestedRuntimes = @($Runtimes)
    if ($requestedRuntimes.Count -eq 0 -and $manifest -and -not $script:RuntimeSelectionExplicit) {
        $requestedRuntimes = @($manifest.runtimes)
    }
    $selectedRuntimes = @(Resolve-SelectedRuntimes $Catalog $requestedRuntimes)

    $overlayOnlyRemoval = $Action -eq 'remove' -and $script:OverlaySelectionExplicit -and @($Assets).Count -eq 0
    $assetOnlyRemoval = $Action -eq 'remove' -and $script:AssetSelectionExplicit -and -not $script:OverlaySelectionExplicit
    if ($selectedProfiles.Count -eq 0 -and $manifest -and -not $script:TuiExplicitSelection -and -not $overlayOnlyRemoval) {
        $selectedProfiles = @($manifest.profiles)
    }
    if ($selectedAssets.Count -eq 0 -and $manifest -and -not $script:TuiExplicitSelection -and -not $overlayOnlyRemoval) {
        $selectedAssets = @($manifest.assets)
    }
    if ($excludedAssets.Count -eq 0 -and $manifest -and -not $script:TuiExplicitSelection -and -not $overlayOnlyRemoval) {
        $excludedAssets = @($manifest.exclude)
    }
    if ($selectedOverlays.Count -eq 0 -and $manifest -and -not $script:OverlaySelectionExplicit -and -not $assetOnlyRemoval) {
        $selectedOverlays = @($manifest.overlays)
    }
    if ($selectedProfiles.Count -eq 0 -and $ResolvedScope -eq 'global' -and -not $script:TuiExplicitSelection) {
        $selectedProfiles = @($Catalog.defaultProfiles)
    }

    $selectedProfiles = @($selectedProfiles | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique)
    $selectedAssets = @($selectedAssets | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique)
    $excludedAssets = @($excludedAssets | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique)
    $selectedOverlays = @($selectedOverlays | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique)

    foreach ($profile in $selectedProfiles) {
        if (-not $Catalog.profiles.PSObject.Properties[$profile]) {
            throw "Unknown asset profile: $profile"
        }
    }

    $resolved = [Collections.Generic.List[object]]::new()
    $requiredIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($asset in @($Catalog.assets)) {
        $profileMatch = @($asset.profiles | Where-Object { $selectedProfiles -contains $_ }).Count -gt 0
        $idMatch = $selectedAssets -contains $asset.id
        if (-not ($profileMatch -or $idMatch) -or $excludedAssets -contains $asset.id) {
            continue
        }
        if (@($asset.scopes) -notcontains $ResolvedScope) {
            if ($idMatch) {
                throw "Asset $($asset.id) does not support $ResolvedScope scope."
            }
            continue
        }
        if ($idMatch) { [void]$requiredIds.Add([string]$asset.id) }
        $resolved.Add($asset)
    }

    $resolvedOverlays = [Collections.Generic.List[object]]::new()
    foreach ($id in $selectedOverlays) {
        $overlay = @($Catalog.overlays | Where-Object id -eq $id) | Select-Object -First 1
        if (-not $overlay) { throw "Unknown overlay id: $id" }
        if (@($overlay.scopes) -notcontains $ResolvedScope) {
            throw "Overlay $id does not support $ResolvedScope scope."
        }
        $resolvedOverlays.Add($overlay)
    }

    $pendingDependencies = [Collections.Generic.Queue[string]]::new()
    foreach ($asset in @($resolved)) {
        if ($asset.PSObject.Properties['dependsOn']) {
            foreach ($dependency in @($asset.dependsOn)) {
                $pendingDependencies.Enqueue($dependency)
            }
        }
    }
    foreach ($overlay in @($resolvedOverlays)) {
        if ($overlay.PSObject.Properties['dependsOn']) {
            foreach ($dependency in @($overlay.dependsOn)) {
                $pendingDependencies.Enqueue($dependency)
            }
        }
    }
    while ($pendingDependencies.Count -gt 0) {
        $dependency = $pendingDependencies.Dequeue()
        if (@($resolved | ForEach-Object { $_.id }) -contains $dependency) {
            continue
        }
        $dependencyAsset = @($Catalog.assets | Where-Object id -eq $dependency) | Select-Object -First 1
        if (-not $dependencyAsset) {
            throw "Unknown asset dependency: $dependency"
        }
        if (@($dependencyAsset.scopes) -notcontains $ResolvedScope) {
            throw "Dependency $dependency does not support $ResolvedScope scope."
        }
        [void]$requiredIds.Add([string]$dependencyAsset.id)
        $resolved.Add($dependencyAsset)
        if ($dependencyAsset.PSObject.Properties['dependsOn']) {
            foreach ($nested in @($dependencyAsset.dependsOn)) {
                $pendingDependencies.Enqueue($nested)
            }
        }
    }

    foreach ($id in $selectedAssets) {
        if (-not (@($Catalog.assets.id) -contains $id)) {
            throw "Unknown asset id: $id"
        }
    }

    $runtimeSupport = @{}
    $installable = [Collections.Generic.List[object]]::new()
    $blocked = [Collections.Generic.List[object]]::new()
    # Removal targets whatever the lock already owns, so runtime support must not
    # hide an entry from it.
    $keepUnsupported = $Action -eq 'remove'
    foreach ($asset in @($resolved)) {
        $support = Get-AssetRuntimeSupport $asset $Catalog $selectedRuntimes
        if ($support.supported.Count -gt 0 -or $keepUnsupported) {
            $runtimeSupport[[string]$asset.id] = $support
            $installable.Add($asset)
            if ($support.supported.Count -gt 0) { continue }
        }
        $blocked.Add([pscustomobject]@{
            id = $asset.id
            kind = 'asset'
            channel = $asset.channel
            declaredRuntimes = @($support.declared)
            blocked = @($support.blocked)
            required = $requiredIds.Contains([string]$asset.id)
        })
    }
    # Only apply mutates the runtime, so only apply has to refuse. Read-only actions
    # report the same information through their blocked list.
    if ($blocked.Count -gt 0 -and -not $SkipUnsupported -and $Action -eq 'apply') {
        $required = @($blocked | Where-Object required)
        $report = if ($required.Count -gt 0) { $required } else { @($blocked) }
        $lines = @($report | ForEach-Object { "$($_.id): $(Get-RuntimeBlockSummary $_.blocked)" })
        throw "These assets support none of the selected runtimes ($(@($selectedRuntimes | ForEach-Object { $_.id }) -join ', ')):`n$($lines -join "`n")`nPass -SkipUnsupported to install only what the selected runtimes support."
    }

    return [pscustomobject]@{
        profiles = $selectedProfiles
        assetIds = $selectedAssets
        exclude = $excludedAssets
        assets = @($installable)
        blocked = @($blocked)
        runtimeSupport = $runtimeSupport
        runtimeIds = @($selectedRuntimes | ForEach-Object { $_.id })
        runtimes = @($selectedRuntimes)
        overlayIds = $selectedOverlays
        overlays = @($resolvedOverlays)
    }
}

function Get-AssetTargetRuntimes {
    param(
        [Parameter(Mandatory = $true)]$Selection,
        [Parameter(Mandatory = $true)]$Asset
    )

    $support = $Selection.runtimeSupport[[string]$Asset.id]
    if (-not $support) {
        throw "No resolved runtime support for asset $($Asset.id)."
    }
    return @($support.supported)
}

function Get-InstalledSkillsForSource {
    param(
        [Parameter(Mandatory = $true)][string]$Repository,
        [Parameter(Mandatory = $true)][string]$ResolvedScope,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot
    )

    $root = if ($ResolvedScope -eq 'global') { $HOME } else { $ResolvedProjectRoot }
    $lockPath = Join-Path $root '.agents\.skill-lock.json'
    if (-not (Test-Path -LiteralPath $lockPath)) {
        return @()
    }
    $skillsLock = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
    return @($skillsLock.skills.PSObject.Properties | Where-Object {
        $_.Value.sourceUrl -eq $Repository
    } | ForEach-Object { $_.Name })
}

function Add-SkillsCliFrontmatter {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)][string]$RepositoryPath
    )

    if (-not $Asset.PSObject.Properties['frontmatter']) {
        return
    }
    if (@($Asset.skills) -contains '*') {
        throw "Skills CLI asset $($Asset.id) cannot combine wildcard skills with managed frontmatter."
    }

    $frontmatterConfig = $Asset.frontmatter
    $metadataPath = [IO.Path]::GetFullPath((Resolve-HomePath $frontmatterConfig.sourcePath))
    if (-not (Test-Path -LiteralPath $metadataPath)) {
        throw "Skills CLI frontmatter metadata not found: $metadataPath"
    }
    $metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
    $skillRoot = [IO.Path]::GetFullPath((Join-Path $RepositoryPath $frontmatterConfig.skillRoot))
    if (-not (Test-PathWithinRoot $skillRoot $RepositoryPath)) {
        throw "Skills CLI frontmatter root escapes the repository: $skillRoot"
    }

    foreach ($skillName in @($Asset.skills)) {
        $descriptionProperty = $metadata.PSObject.Properties[$skillName]
        if (-not $descriptionProperty -or [string]::IsNullOrWhiteSpace($descriptionProperty.Value)) {
            throw "Skills CLI frontmatter metadata is missing a description for $skillName."
        }
        $skillPath = [IO.Path]::GetFullPath((Join-Path $skillRoot "$skillName\SKILL.md"))
        if (-not (Test-PathWithinRoot $skillPath $skillRoot) -or -not (Test-Path -LiteralPath $skillPath -PathType Leaf)) {
            throw "Skills CLI source file not found for $skillName."
        }
        $content = [IO.File]::ReadAllText($skillPath)
        if ($content.StartsWith('---')) {
            throw "Skills CLI source already contains frontmatter for $skillName."
        }
        $description = ConvertTo-Json ([string]$descriptionProperty.Value) -Compress
        $adapted = "---`nname: $skillName`ndescription: $description`n---`n`n$content"
        [IO.File]::WriteAllText($skillPath, $adapted, [Text.UTF8Encoding]::new($false))
    }
}

function Install-SkillsCliAsset {
    param(
        [Parameter(Mandatory = $true)]$Catalog,
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)][string]$ResolvedScope,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot
    )

    if ([string]::IsNullOrWhiteSpace($Asset.repository) -or [string]::IsNullOrWhiteSpace($Asset.revision)) {
        throw "Skills CLI asset $($Asset.id) requires repository and revision."
    }
    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) "opencode-assets-$([guid]::NewGuid())"
    $repositoryPath = Join-Path $tempRoot 'source'
    New-Item -ItemType Directory -Path $tempRoot | Out-Null
    try {
        Invoke-CheckedCommand 'git' @('clone', '--filter=blob:none', '--no-checkout', $Asset.repository, $repositoryPath) "Failed to clone $($Asset.repository)"
        Invoke-CheckedCommand 'git' @('-C', $repositoryPath, 'fetch', '--depth', '1', 'origin', $Asset.revision) "Failed to fetch $($Asset.revision)"
        Invoke-CheckedCommand 'git' @('-C', $repositoryPath, 'checkout', '--detach', 'FETCH_HEAD') "Failed to checkout $($Asset.revision)"
        Add-SkillsCliFrontmatter $Asset $repositoryPath

        $installer = $Catalog.installers.skillsCli
        $arguments = @('-y', "$($installer.package)@$($installer.version)", 'add', $repositoryPath)
        if ($ResolvedScope -eq 'global') {
            $arguments += '--global'
        }
        $arguments += @('--yes', '--agent', 'opencode', '--copy', '--skill') + @($Asset.skills)
        Invoke-CheckedCommand 'npx' $arguments "Failed to install $($Asset.id)" $ResolvedProjectRoot
    }
    finally {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    $skillNames = if (@($Asset.skills) -contains '*') {
        @(Get-InstalledSkillsForSource $Asset.repository $ResolvedScope $ResolvedProjectRoot)
    }
    else {
        @($Asset.skills)
    }
    $skillRoot = if ($ResolvedScope -eq 'global') {
        Join-Path $HOME '.agents\skills'
    }
    else {
        Join-Path $ResolvedProjectRoot '.agents\skills'
    }
    return [pscustomobject]@{
        id = $Asset.id
        channel = $Asset.channel
        revision = $Asset.revision
        skills = $skillNames
        installedPaths = @($skillNames | ForEach-Object { Join-Path $skillRoot $_ })
    }
}

function Copy-ManagedPath {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][bool]$PreviouslyOwned
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Managed asset source not found: $Source"
    }
    if ((Test-Path -LiteralPath $Target) -and -not $PreviouslyOwned) {
        throw "Refusing to overwrite an unmanaged asset path: $Target"
    }
    if (Test-Path -LiteralPath $Target) {
        Remove-Item -LiteralPath $Target -Recurse -Force
    }
    $parent = Split-Path -Parent $Target
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent | Out-Null
    }
    Copy-Item -LiteralPath $Source -Destination $Target -Recurse -Force
}

function Get-ManagedRoots {
    param(
        [Parameter(Mandatory = $true)]$Catalog,
        [Parameter(Mandatory = $true)][string]$ResolvedScope,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot
    )

    if ($ResolvedScope -eq 'global') {
        return @(@(Get-RuntimeTable $Catalog | ForEach-Object { $_.canonicalConfigRoot }) + @(
            (Get-CanonicalPath (Join-Path $HOME '.agents')),
            (Get-CanonicalPath (Join-Path $HOME '.claude'))
        ) | Select-Object -Unique)
    }
    return @(
        (Get-CanonicalPath (Join-Path $ResolvedProjectRoot '.opencode')),
        (Get-CanonicalPath (Join-Path $ResolvedProjectRoot '.agents'))
    )
}

function Get-ManagedFileMappings {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)][string]$ResolvedScope,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot,
        [Parameter(Mandatory = $true)][object[]]$TargetRuntimes
    )

    $declared = if ($Asset.PSObject.Properties['files']) {
        @($Asset.files | ForEach-Object { [pscustomobject]@{ source = $_.source; target = $_.target } })
    }
    else {
        @([pscustomobject]@{ source = $Asset.sourcePath; target = $Asset.targetPath })
    }
    $mappings = [Collections.Generic.List[object]]::new()
    $seen = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($runtime in @($TargetRuntimes)) {
        foreach ($entry in $declared) {
            $source = [IO.Path]::GetFullPath((Resolve-HomePath $entry.source))
            $target = Get-CanonicalPath (Resolve-TargetPath $entry.target $ResolvedScope $ResolvedProjectRoot $runtime)
            $existing = $null
            if ($seen.TryGetValue($target, [ref]$existing)) {
                if (-not [string]::Equals($existing.source, $source, [StringComparison]::OrdinalIgnoreCase)) {
                    throw "Asset $($Asset.id) maps two different sources onto one resolved path: $target"
                }
                $existing.runtimes.Add($runtime.id)
                continue
            }
            $runtimeIds = [Collections.Generic.List[string]]::new()
            $runtimeIds.Add($runtime.id)
            $mapping = [pscustomobject]@{ source = $source; target = $target; runtimes = $runtimeIds }
            $seen[$target] = $mapping
            $mappings.Add($mapping)
        }
    }
    return @($mappings)
}

function Install-CopyTemplateAsset {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)][string]$ResolvedScope,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot,
        [Parameter(Mandatory = $true)]$ExistingLock,
        [Parameter(Mandatory = $true)][object[]]$TargetRuntimes,
        [Parameter(Mandatory = $true)]$Catalog
    )

    $ownedPaths = @($ExistingLock.assets | Where-Object { $_.id -eq $Asset.id } | ForEach-Object { $_.installedPaths })
    $mappings = @(Get-ManagedFileMappings $Asset $ResolvedScope $ResolvedProjectRoot $TargetRuntimes)
    $newPaths = @($mappings | ForEach-Object { $_.target })
    foreach ($mapping in $mappings) {
        if (-not (Test-Path -LiteralPath $mapping.source)) {
            throw "Managed asset source not found: $($mapping.source)"
        }
        if ((Test-Path -LiteralPath $mapping.target) -and $ownedPaths -notcontains $mapping.target) {
            throw "Refusing to overwrite an unmanaged asset path: $($mapping.target)"
        }
    }
    # Narrowing the runtime set drops targets that a previous apply owned. Remove them
    # so a deselected runtime does not keep an orphaned copy the lock no longer tracks.
    $managedRoots = @(Get-ManagedRoots $Catalog $ResolvedScope $ResolvedProjectRoot)
    foreach ($stalePath in @($ownedPaths | Where-Object { $newPaths -notcontains $_ })) {
        if (@($managedRoots | Where-Object { Test-PathWithinRoot (Get-CanonicalPath $stalePath) $_ }).Count -eq 0) {
            throw "Refusing to remove a stale managed path outside the managed roots: $stalePath"
        }
        if (Test-Path -LiteralPath $stalePath) {
            Remove-Item -LiteralPath $stalePath -Recurse -Force
        }
    }
    foreach ($mapping in $mappings) {
        Copy-ManagedPath $mapping.source $mapping.target ($ownedPaths -contains $mapping.target)
    }
    return [pscustomobject]@{
        id = $Asset.id
        channel = $Asset.channel
        revision = $null
        skills = @()
        installedPaths = @($mappings | ForEach-Object { $_.target })
    }
}

function Install-JunctionAsset {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot,
        [Parameter(Mandatory = $true)]$ExistingLock
    )

    $repositoryRoot = [IO.Path]::GetFullPath((Resolve-HomePath $Asset.repositoryRoot))
    if (-not (Test-Path -LiteralPath $repositoryRoot)) {
        throw "Junction asset repository not found: $repositoryRoot"
    }
    $targetRoot = Resolve-TargetPath $Asset.skillTargetRoot 'project' $ResolvedProjectRoot
    if (-not (Test-Path -LiteralPath $targetRoot)) {
        New-Item -ItemType Directory -Path $targetRoot | Out-Null
    }
    $ownedPaths = @($ExistingLock.assets | Where-Object { $_.id -eq $Asset.id } | ForEach-Object { $_.installedPaths })
    $installedPaths = [Collections.Generic.List[string]]::new()

    foreach ($skill in @($Asset.skills)) {
        $source = [IO.Path]::GetFullPath((Join-Path (Join-Path $repositoryRoot $Asset.skillSourceRoot) $skill))
        $target = Join-Path $targetRoot $skill
        if (-not (Test-Path -LiteralPath $source)) {
            throw "Junction skill source not found: $source"
        }
        if (Test-Path -LiteralPath $target) {
            $entry = Get-Item -LiteralPath $target -Force
            if (-not ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $ownedPaths -notcontains $target) {
                throw "Refusing to replace unmanaged project skill: $target"
            }
            Remove-Item -LiteralPath $target -Force
        }
        New-Item -ItemType Junction -Path $target -Target $source | Out-Null
        $installedPaths.Add($target)
    }

    foreach ($file in @($Asset.files)) {
        $source = [IO.Path]::GetFullPath((Resolve-HomePath $file.source))
        $target = Resolve-TargetPath $file.target 'project' $ResolvedProjectRoot
        Copy-ManagedPath $source $target ($ownedPaths -contains $target)
        $installedPaths.Add($target)
    }

    return [pscustomobject]@{
        id = $Asset.id
        channel = $Asset.channel
        revision = $null
        skills = @($Asset.skills)
        installedPaths = @($installedPaths)
    }
}

function Install-GitAllowlistAsset {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot,
        [Parameter(Mandatory = $true)]$ExistingLock
    )

    if ([string]::IsNullOrWhiteSpace($Asset.repository) -or [string]::IsNullOrWhiteSpace($Asset.revision)) {
        throw "Git allowlist asset $($Asset.id) requires repository and revision."
    }
    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) "opencode-assets-$([guid]::NewGuid())"
    $repositoryPath = Join-Path $tempRoot 'source'
    $ownedPaths = @($ExistingLock.assets | Where-Object { $_.id -eq $Asset.id } | ForEach-Object { $_.installedPaths })
    $installedPaths = [Collections.Generic.List[string]]::new()
    New-Item -ItemType Directory -Path $tempRoot | Out-Null
    try {
        Invoke-CheckedCommand 'git' @('clone', '--filter=blob:none', '--no-checkout', $Asset.repository, $repositoryPath) "Failed to clone $($Asset.repository)"
        Invoke-CheckedCommand 'git' @('-C', $repositoryPath, 'fetch', '--depth', '1', 'origin', $Asset.revision) "Failed to fetch $($Asset.revision)"
        Invoke-CheckedCommand 'git' @('-C', $repositoryPath, 'checkout', '--detach', 'FETCH_HEAD') "Failed to checkout $($Asset.revision)"
        foreach ($file in @($Asset.files)) {
            $source = [IO.Path]::GetFullPath((Join-Path $repositoryPath $file.source))
            $target = Resolve-TargetPath $file.target 'project' $ResolvedProjectRoot
            Copy-ManagedPath $source $target ($ownedPaths -contains $target)
            $installedPaths.Add($target)
        }
    }
    finally {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    return [pscustomobject]@{
        id = $Asset.id
        channel = $Asset.channel
        revision = $Asset.revision
        skills = @()
        installedPaths = @($installedPaths)
    }
}

function Get-JsonConfig {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        $config = [pscustomobject]@{}
        $config | Add-Member -NotePropertyName '$schema' -NotePropertyValue 'https://opencode.ai/config.json'
        return $config
    }
    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    }
    catch {
        throw "Asset Manager requires strict JSON for managed plugin config: $Path"
    }
}

function Save-JsonConfig {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Config
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent | Out-Null
    }
    $Config | ConvertTo-Json -Depth 50 | Set-Content -LiteralPath $Path -Encoding utf8
}

function Get-OrAddObjectProperty {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if (-not $Object.PSObject.Properties[$Name]) {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue ([pscustomobject]@{})
    }
    return $Object.PSObject.Properties[$Name].Value
}

function Set-ObjectProperty {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        [AllowNull()]$Value
    )

    if ($Object.PSObject.Properties[$Name]) {
        $Object.PSObject.Properties[$Name].Value = $Value
    }
    else {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function Test-JsonValueEqual {
    param(
        [AllowNull()]$Left,
        [AllowNull()]$Right
    )

    return ($Left | ConvertTo-Json -Depth 50 -Compress) -eq ($Right | ConvertTo-Json -Depth 50 -Compress)
}

function Get-DirectoryContentFingerprint {
    param([Parameter(Mandatory = $true)][string]$Path)

    $item = Get-Item -LiteralPath $Path -Force
    if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "Expected a regular directory for fingerprinting: $Path"
    }
    $records = [Collections.Generic.List[string]]::new()
    foreach ($child in @(Get-ChildItem -LiteralPath $Path -Force -Recurse | Sort-Object FullName)) {
        if ($child.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Refusing to fingerprint a directory containing a reparse point: $($child.FullName)"
        }
        $relative = [IO.Path]::GetRelativePath($Path, $child.FullName) -replace '\\', '/'
        if ($child.PSIsContainer) {
            $records.Add("directory|$relative")
        }
        else {
            $hash = (Get-FileHash -LiteralPath $child.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            $records.Add("file|$relative|$hash")
        }
    }
    $bytes = [Text.Encoding]::UTF8.GetBytes(($records -join "`n"))
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
}

function Get-InstalledPathHashes {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Paths)

    return @($Paths | ForEach-Object {
        [pscustomobject]@{
            path = [IO.Path]::GetFullPath($_)
            contentHash = (Get-PathsFingerprint @([IO.Path]::GetFullPath($_)))
        }
    })
}

function Assert-LockedPathsUnchanged {
    param([Parameter(Mandatory = $true)]$Entry)

    $paths = @($Entry.installedPaths)
    if ($paths.Count -eq 0) { return }
    if (-not $Entry.PSObject.Properties['installedPathHashes']) {
        throw "Refusing to modify $($Entry.id): the lock does not contain per-path ownership hashes."
    }
    $hashes = @($Entry.installedPathHashes)
    foreach ($path in $paths) {
        $fullPath = [IO.Path]::GetFullPath($path)
        $record = @($hashes | Where-Object {
            [string]::Equals([IO.Path]::GetFullPath($_.path), $fullPath, [StringComparison]::OrdinalIgnoreCase)
        }) | Select-Object -First 1
        if (-not $record -or (Get-PathsFingerprint @($fullPath)) -ne $record.contentHash) {
            throw "Refusing to modify drifted managed path: $fullPath"
        }
    }
}

function Get-Slim8Asset {
    param([Parameter(Mandatory = $true)]$Catalog)

    $asset = @($Catalog.assets | Where-Object id -eq 'oh-my-opencode-slim') | Select-Object -First 1
    if (-not $asset) { throw 'The asset catalog does not contain oh-my-opencode-slim.' }
    return $asset
}

function Get-Slim8TargetSlug {
    param([Parameter(Mandatory = $true)][string]$SkillsRoot)

    $bytes = [Text.Encoding]::UTF8.GetBytes($SkillsRoot.ToLowerInvariant())
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant().Substring(0, 16)
}

function Get-Slim8Paths {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot,
        [Parameter(Mandatory = $true)]$Catalog
    )

    # Global isolation is a safety invariant, not a per-selection choice: a global
    # copy in ANY runtime config root would shadow the project skills. So this
    # always covers every known runtime, regardless of the current -Runtimes value.
    $runtimeTable = Get-RuntimeTable $Catalog
    $projectSkillsRoot = Get-CanonicalPath (Resolve-TargetPath $Asset.projectSkillsPath 'project' $ResolvedProjectRoot)
    $backupRoot = [IO.Path]::GetFullPath((Resolve-HomePath $Asset.globalSkillsBackupPath))
    $expectedProjectRoot = Get-CanonicalPath ([IO.Path]::GetFullPath((Join-Path $ResolvedProjectRoot '.opencode\skills')))
    if (-not [string]::Equals($projectSkillsRoot, $expectedProjectRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Slim8 project skills must target $expectedProjectRoot"
    }

    $targets = [Collections.Generic.List[object]]::new()
    $seen = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($runtime in @($runtimeTable)) {
        $skillsRoot = Get-CanonicalPath (Resolve-TargetPath $Asset.globalSkillsPath 'global' $ResolvedProjectRoot $runtime)
        $manifestPath = Get-CanonicalPath (Resolve-TargetPath $Asset.globalSkillsManifestPath 'global' $ResolvedProjectRoot $runtime)
        $expectedSkillsRoot = Get-CanonicalPath ([IO.Path]::GetFullPath((Join-Path $runtime.configRoot 'skills')))
        $expectedManifest = Get-CanonicalPath ([IO.Path]::GetFullPath((Join-Path $runtime.configRoot '.oh-my-opencode-slim\skills-manifest.json')))
        if (-not [string]::Equals($skillsRoot, $expectedSkillsRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Slim8 global skills migration for $($runtime.id) must target $expectedSkillsRoot"
        }
        if (-not [string]::Equals($manifestPath, $expectedManifest, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Slim8 tombstones for $($runtime.id) must target $expectedManifest"
        }
        $existing = $null
        if ($seen.TryGetValue($skillsRoot, [ref]$existing)) {
            if (-not [string]::Equals($existing.manifestPath, $manifestPath, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Runtimes share the Slim8 skills root $skillsRoot but resolve different tombstone manifests."
            }
            $existing.runtimes.Add($runtime.id)
            continue
        }
        $runtimeIds = [Collections.Generic.List[string]]::new()
        $runtimeIds.Add($runtime.id)
        $target = [pscustomobject]@{
            slug = Get-Slim8TargetSlug $skillsRoot
            runtimes = $runtimeIds
            skillsRoot = $skillsRoot
            manifestPath = $manifestPath
        }
        $seen[$skillsRoot] = $target
        $targets.Add($target)
    }

    $scannedRoots = @(@($runtimeTable | ForEach-Object { $_.canonicalConfigRoot }) + @(
        (Get-CanonicalPath ([IO.Path]::GetFullPath((Join-Path $HOME '.agents')))),
        (Get-CanonicalPath ([IO.Path]::GetFullPath((Join-Path $HOME '.claude'))))
    ) | Select-Object -Unique)
    if (@($scannedRoots | Where-Object { Test-PathWithinRoot (Get-CanonicalPath $backupRoot) $_ }).Count -gt 0) {
        throw "Slim8 migration backups must be outside every OpenCode skill scan root: $backupRoot"
    }
    return [pscustomobject]@{
        projectSkillsRoot = $projectSkillsRoot
        targets = @($targets)
        backupRoot = $backupRoot
    }
}

function Test-Slim8Manifest {
    param([Parameter(Mandatory = $true)]$Manifest)

    if (-not $Manifest.PSObject.Properties['schemaVersion'] -or $Manifest.schemaVersion -ne 1 -or
        -not $Manifest.PSObject.Properties['skills'] -or $Manifest.skills -isnot [pscustomobject]) {
        return $false
    }
    $allowedStatuses = @('managed', 'customized', 'deleted', 'conflict')
    foreach ($property in $Manifest.skills.PSObject.Properties) {
        $entry = $property.Value
        if ($entry -isnot [pscustomobject] -or -not $entry.PSObject.Properties['status'] -or
            $entry.status -notin $allowedStatuses) {
            return $false
        }
        foreach ($name in @('packageVersion', 'sourceHash', 'lastManagedHash', 'lastSeenHash')) {
            if (-not $entry.PSObject.Properties[$name] -or $entry.PSObject.Properties[$name].Value -isnot [string]) {
                return $false
            }
        }
        if (-not $entry.PSObject.Properties['updatedAt'] -or
            ($entry.updatedAt -isnot [string] -and $entry.updatedAt -isnot [DateTime])) {
            return $false
        }
        if ($entry.PSObject.Properties['stagedPath'] -and $entry.stagedPath -isnot [string]) {
            return $false
        }
    }
    return $true
}

function Get-Slim8Manifest {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        $manifest = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    }
    catch {
        throw "Refusing to replace an unreadable Slim8 skills manifest: $Path"
    }
    if (-not (Test-Slim8Manifest $manifest)) {
        throw "Refusing to replace an invalid Slim8 skills manifest: $Path"
    }
    return $manifest
}

function Save-JsonAtomic {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Value
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
    $temporaryPath = "$Path.$([guid]::NewGuid().ToString('N')).tmp"
    try {
        $Value | ConvertTo-Json -Depth 50 | Set-Content -LiteralPath $temporaryPath -Encoding utf8
        Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
    }
    finally {
        Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
    }
}

function New-PinnedRepositoryCheckout {
    param([Parameter(Mandatory = $true)]$Asset)

    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) "opencode-assets-$([guid]::NewGuid())"
    $repositoryPath = Join-Path $tempRoot 'source'
    New-Item -ItemType Directory -Path $tempRoot | Out-Null
    try {
        Invoke-CheckedCommand 'git' @('clone', '--filter=blob:none', '--no-checkout', $Asset.repository, $repositoryPath) "Failed to clone $($Asset.repository)"
        Invoke-CheckedCommand 'git' @('-C', $repositoryPath, 'fetch', '--depth', '1', 'origin', $Asset.revision) "Failed to fetch $($Asset.revision)"
        Invoke-CheckedCommand 'git' @('-C', $repositoryPath, 'checkout', '--detach', 'FETCH_HEAD') "Failed to checkout $($Asset.revision)"
    }
    catch {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
        throw
    }
    return [pscustomobject]@{ tempRoot = $tempRoot; repositoryPath = $repositoryPath }
}

function Get-Slim8GlobalMigrationPlan {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)][string]$RepositoryPath,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot,
        [Parameter(Mandatory = $true)]$Catalog
    )

    $paths = Get-Slim8Paths $Asset $ResolvedProjectRoot $Catalog
    $sourceRoot = [IO.Path]::GetFullPath((Join-Path $RepositoryPath $Asset.bundledSkillsPath))
    $targets = foreach ($target in @($paths.targets)) {
        $manifest = Get-Slim8Manifest $target.manifestPath
        $items = foreach ($name in $script:Slim8SkillNames) {
            $sourcePath = [IO.Path]::GetFullPath((Join-Path $sourceRoot $name))
            $targetPath = [IO.Path]::GetFullPath((Join-Path $target.skillsRoot $name))
            if (-not (Test-Path -LiteralPath (Join-Path $sourcePath 'SKILL.md') -PathType Leaf)) {
                throw "Pinned Slim8 skill source is missing SKILL.md: $sourcePath"
            }
            $entryProperty = if ($manifest) { $manifest.skills.PSObject.Properties[$name] } else { $null }
            $entry = if ($entryProperty) { $entryProperty.Value } else { $null }
            $state = 'absent'
            if (Test-Path -LiteralPath $targetPath) {
                $existing = Get-Item -LiteralPath $targetPath -Force
                if (-not $existing.PSIsContainer -or ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                    $state = 'conflict'
                }
                else {
                    $matchesSource = (Get-DirectoryContentFingerprint $targetPath) -eq (Get-DirectoryContentFingerprint $sourcePath)
                    if ($entry -and $entry.status -eq 'managed' -and $matchesSource) {
                        $state = 'managed-unchanged'
                    }
                    elseif ($entry) {
                        $state = 'customized'
                    }
                    else {
                        $state = 'unowned'
                    }
                }
            }
            [pscustomobject]@{
                name = $name
                state = $state
                sourcePath = $sourcePath
                targetPath = $targetPath
            }
        }
        $targetTombstonesReady = $null -ne $manifest
        foreach ($name in $script:Slim8SkillNames) {
            $property = if ($manifest) { $manifest.skills.PSObject.Properties[$name] } else { $null }
            if (-not $property -or $property.Value.status -ne 'deleted') { $targetTombstonesReady = $false }
        }
        [pscustomobject]@{
            slug = $target.slug
            runtimes = @($target.runtimes)
            skillsRoot = $target.skillsRoot
            manifestPath = $target.manifestPath
            tombstonesReady = $targetTombstonesReady
            items = @($items)
        }
    }
    $resolvedTargets = @($targets)
    return [pscustomobject]@{
        backupRoot = $paths.backupRoot
        tombstonesReady = @($resolvedTargets | Where-Object { -not $_.tombstonesReady }).Count -eq 0
        targets = $resolvedTargets
        items = @($resolvedTargets | ForEach-Object { $_.items })
    }
}

function Set-Slim8DeletedTombstones {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)][string]$ManifestPath
    )

    $manifest = Get-Slim8Manifest $ManifestPath
    if (-not $manifest) {
        $manifest = [pscustomobject]@{ schemaVersion = 1; updatedAt = ''; skills = [pscustomobject]@{} }
    }
    $now = [DateTimeOffset]::UtcNow.ToString('o')
    foreach ($name in $script:Slim8SkillNames) {
        $property = $manifest.skills.PSObject.Properties[$name]
        $entry = if ($property) { $property.Value } else {
            [pscustomobject]@{
                status = 'deleted'
                packageVersion = [string]$Asset.packageVersion
                sourceHash = ''
                lastManagedHash = ''
                lastSeenHash = ''
                updatedAt = $now
            }
        }
        Set-ObjectProperty $entry 'status' 'deleted'
        if (-not $entry.PSObject.Properties['packageVersion']) { Set-ObjectProperty $entry 'packageVersion' ([string]$Asset.packageVersion) }
        foreach ($hashName in @('sourceHash', 'lastManagedHash', 'lastSeenHash')) {
            if (-not $entry.PSObject.Properties[$hashName]) { Set-ObjectProperty $entry $hashName '' }
        }
        Set-ObjectProperty $entry 'updatedAt' $now
        if ($property) { $property.Value = $entry } else { Set-ObjectProperty $manifest.skills $name $entry }
    }
    Set-ObjectProperty $manifest 'updatedAt' $now
    Save-JsonAtomic $ManifestPath $manifest
}

function Invoke-Slim8MigrationApply {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)]$Plan,
        [switch]$RejectUnsafe
    )

    $existingItems = @($Plan.items | Where-Object state -ne 'absent')
    $unsafeItems = @($existingItems | Where-Object state -notin @('managed-unchanged'))
    $conflicts = @($existingItems | Where-Object state -eq 'conflict')
    if ($conflicts.Count -gt 0) {
        throw "Refusing to migrate Slim8 file, symlink, or reparse-point conflicts: $(@($conflicts.name) -join ', ')"
    }
    if ($RejectUnsafe -and $unsafeItems.Count -gt 0) {
        throw "Slim8 global skills include customized or unowned copies ($(@($unsafeItems.name) -join ', ')). Run slim8-migration -MigrationMode plan, then slim8-migration -MigrationMode apply before installing the project asset."
    }
    if ($existingItems.Count -eq 0 -and $Plan.tombstonesReady) {
        return [pscustomobject]@{ changed = $false; backupPath = $null; migrated = @() }
    }

    $backupPath = Join-Path $Plan.backupRoot "$([DateTimeOffset]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))-$([guid]::NewGuid().ToString('N'))"
    $metadataPath = Join-Path $backupPath 'backup.json'
    $targetRecords = [Collections.Generic.List[object]]::new()
    foreach ($target in @($Plan.targets)) {
        $targetBackupRoot = Join-Path $backupPath $target.slug
        $backupSkillsRoot = Join-Path $targetBackupRoot 'skills'
        New-Item -ItemType Directory -Path $backupSkillsRoot -Force | Out-Null
        $manifestExisted = Test-Path -LiteralPath $target.manifestPath
        if ($manifestExisted) {
            Copy-Item -LiteralPath $target.manifestPath -Destination (Join-Path $targetBackupRoot 'skills-manifest.json') -Force
        }
        $backupItems = [Collections.Generic.List[object]]::new()
        foreach ($item in @($target.items | Where-Object state -ne 'absent')) {
            $skillBackup = Join-Path $backupSkillsRoot $item.name
            Copy-Item -LiteralPath $item.targetPath -Destination $skillBackup -Recurse -Force
            $sourceHash = Get-DirectoryContentFingerprint $item.targetPath
            if ((Get-DirectoryContentFingerprint $skillBackup) -ne $sourceHash) {
                throw "Slim8 migration backup verification failed for $($item.name): $skillBackup"
            }
            $backupItems.Add([pscustomobject]@{
                name = $item.name
                state = $item.state
                originalPath = $item.targetPath
                backupPath = $skillBackup
                contentHash = $sourceHash
            })
        }
        $targetRecords.Add([pscustomobject]@{
            slug = $target.slug
            runtimes = @($target.runtimes)
            skillsRoot = $target.skillsRoot
            manifestPath = $target.manifestPath
            manifestExisted = $manifestExisted
            manifestAfterHash = ''
            skills = @($backupItems)
        })
    }
    $metadata = [pscustomobject]@{
        schemaVersion = 2
        createdAt = [DateTimeOffset]::UtcNow.ToString('o')
        targets = @($targetRecords)
    }
    Save-JsonAtomic $metadataPath $metadata

    foreach ($record in $targetRecords) {
        foreach ($item in @($record.skills)) {
            Remove-Item -LiteralPath $item.originalPath -Recurse -Force
        }
        Set-Slim8DeletedTombstones $Asset $record.manifestPath
        $record.manifestAfterHash = (Get-FileHash -LiteralPath $record.manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    Save-JsonAtomic $metadataPath $metadata
    return [pscustomobject]@{
        changed = $true
        backupPath = $backupPath
        migrated = @($targetRecords | ForEach-Object {
            $runtimes = @($_.runtimes)
            $_.skills | Select-Object name, state, originalPath, @{ Name = 'runtimes'; Expression = { $runtimes } }
        })
    }
}

function Get-Slim8BackupTargets {
    param(
        [Parameter(Mandatory = $true)]$Metadata,
        [Parameter(Mandatory = $true)][string]$BackupPath
    )

    if ($Metadata.schemaVersion -eq 2) {
        return @($Metadata.targets | ForEach-Object {
            [pscustomobject]@{
                root = [IO.Path]::GetFullPath((Join-Path $BackupPath $_.slug))
                skillsRoot = [string]$_.skillsRoot
                manifestPath = [string]$_.manifestPath
                manifestExisted = [bool]$_.manifestExisted
                manifestAfterHash = [string]$_.manifestAfterHash
                skills = @($_.skills)
            }
        })
    }
    # Backup schema 1 predates multi-runtime isolation and holds one target at the
    # backup root, identified by its recorded manifest path.
    if ($Metadata.schemaVersion -eq 1) {
        return @([pscustomobject]@{
            root = [IO.Path]::GetFullPath($BackupPath)
            skillsRoot = $null
            manifestPath = [string]$Metadata.manifestPath
            manifestExisted = [bool]$Metadata.manifestExisted
            manifestAfterHash = [string]$Metadata.manifestAfterHash
            skills = @($Metadata.skills)
        })
    }
    throw "Unsupported Slim8 migration backup schema: $($Metadata.schemaVersion)"
}

function Invoke-Slim8MigrationRestore {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot,
        [Parameter(Mandatory = $true)][string]$ResolvedBackupPath,
        [Parameter(Mandatory = $true)]$Catalog
    )

    $paths = Get-Slim8Paths $Asset $ResolvedProjectRoot $Catalog
    $fullBackupPath = [IO.Path]::GetFullPath($ResolvedBackupPath)
    if (-not (Test-PathWithinRoot $fullBackupPath $paths.backupRoot)) {
        throw "Slim8 restore path must be inside $($paths.backupRoot)"
    }
    $metadataPath = Join-Path $fullBackupPath 'backup.json'
    if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
        throw "Slim8 migration backup metadata not found: $metadataPath"
    }
    $metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
    $backupTargets = @(Get-Slim8BackupTargets $metadata $fullBackupPath)
    $restorePlan = [Collections.Generic.List[object]]::new()
    foreach ($backupTarget in $backupTargets) {
        $current = @($paths.targets | Where-Object {
            [string]::Equals($_.manifestPath, $backupTarget.manifestPath, [StringComparison]::OrdinalIgnoreCase)
        }) | Select-Object -First 1
        if (-not $current) {
            throw "Slim8 migration backup targets a manifest that no runtime resolves to: $($backupTarget.manifestPath)"
        }
        if (-not (Test-Path -LiteralPath $current.manifestPath -PathType Leaf) -or
            (Get-FileHash -LiteralPath $current.manifestPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $backupTarget.manifestAfterHash) {
            throw "Refusing to restore over a changed Slim8 skills manifest: $($current.manifestPath)"
        }
        if ($backupTarget.manifestExisted -and -not (Test-Path -LiteralPath (Join-Path $backupTarget.root 'skills-manifest.json') -PathType Leaf)) {
            throw "Slim8 migration manifest backup is missing: $($backupTarget.root)"
        }
        foreach ($item in @($backupTarget.skills)) {
            $expectedOriginalPath = [IO.Path]::GetFullPath((Join-Path $current.skillsRoot $item.name))
            $expectedBackupPath = [IO.Path]::GetFullPath((Join-Path (Join-Path $backupTarget.root 'skills') $item.name))
            if (@($script:Slim8SkillNames) -notcontains $item.name -or
                -not [string]::Equals([IO.Path]::GetFullPath($item.originalPath), $expectedOriginalPath, [StringComparison]::OrdinalIgnoreCase) -or
                -not [string]::Equals([IO.Path]::GetFullPath($item.backupPath), $expectedBackupPath, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Invalid skill path in Slim8 migration backup: $($item.originalPath)"
            }
            if (Test-Path -LiteralPath $item.originalPath) {
                throw "Refusing to restore over an existing global skill: $($item.originalPath)"
            }
            if (-not (Test-Path -LiteralPath $item.backupPath -PathType Container) -or
                (Get-DirectoryContentFingerprint $item.backupPath) -ne $item.contentHash) {
                throw "Slim8 migration backup is missing or changed: $($item.backupPath)"
            }
        }
        $restorePlan.Add([pscustomobject]@{ backup = $backupTarget; current = $current })
    }
    foreach ($step in $restorePlan) {
        foreach ($item in @($step.backup.skills)) {
            $parent = Split-Path -Parent $item.originalPath
            if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
            Copy-Item -LiteralPath $item.backupPath -Destination $item.originalPath -Recurse -Force
        }
        if ($step.backup.manifestExisted) {
            Copy-Item -LiteralPath (Join-Path $step.backup.root 'skills-manifest.json') -Destination $step.current.manifestPath -Force
        }
        else {
            Remove-Item -LiteralPath $step.current.manifestPath -Force
        }
    }
    return [pscustomobject]@{
        backupPath = $fullBackupPath
        targets = @($restorePlan | ForEach-Object {
            [pscustomobject]@{
                runtimes = @($_.current.runtimes)
                skillsRoot = $_.current.skillsRoot
                manifestPath = $_.current.manifestPath
                restored = @($_.backup.skills | ForEach-Object { $_.name })
            }
        })
    }
}

function Install-NpmFrameworkConfig {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)][string]$StagingRoot,
        [Parameter(Mandatory = $true)][string]$TargetRoot,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot
    )

    if (-not $Asset.PSObject.Properties['configOverlay']) {
        return $null
    }

    $overlay = $Asset.configOverlay
    $sourcePath = [IO.Path]::GetFullPath((Join-Path $StagingRoot $overlay.sourcePath))
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Framework config overlay not found: $sourcePath"
    }
    $sourceConfig = Get-JsonConfig $sourcePath
    $targetPath = Resolve-TargetPath $overlay.targetPath 'project' $ResolvedProjectRoot
    $targetConfig = Get-JsonConfig $targetPath
    $permissionKey = ((Join-Path $TargetRoot 'gsd-core\*') -replace '\\', '/')
    $permission = Get-OrAddObjectProperty $targetConfig 'permission'
    foreach ($sectionName in @($overlay.permissionSections)) {
        $section = Get-OrAddObjectProperty $permission $sectionName
        Set-ObjectProperty $section $permissionKey 'allow'
    }

    $mcp = Get-OrAddObjectProperty $targetConfig 'mcp'
    $sourceMcp = $sourceConfig.mcp.PSObject.Properties[$overlay.mcpKey].Value
    $mcpValue = $sourceMcp | ConvertTo-Json -Depth 50 | ConvertFrom-Json
    [string[]]$command = @($mcpValue.command)
    for ($index = 0; $index -lt $command.Count; $index++) {
        if ($command[$index] -eq $Asset.package) {
            $command[$index] = "$($Asset.package)@$($Asset.packageVersion)"
        }
    }
    $mcpValue.command = @($command)
    Set-ObjectProperty $mcp $overlay.mcpKey $mcpValue
    Save-JsonConfig $targetPath $targetConfig

    return [pscustomobject]@{
        configPath = $targetPath
        permissionKey = $permissionKey
        permissionSections = @($overlay.permissionSections)
        mcpKey = $overlay.mcpKey
        mcpValue = $mcpValue
    }
}

function Test-NpmFrameworkConfigOwnership {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)][string]$TargetRoot,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot,
        [Parameter(Mandatory = $true)][bool]$PreviouslyOwned
    )

    if ($PreviouslyOwned -or -not $Asset.PSObject.Properties['configOverlay']) {
        return
    }
    $overlay = $Asset.configOverlay
    $targetPath = Resolve-TargetPath $overlay.targetPath 'project' $ResolvedProjectRoot
    if (-not (Test-Path -LiteralPath $targetPath)) {
        return
    }
    $config = Get-JsonConfig $targetPath
    $permissionKey = ((Join-Path $TargetRoot 'gsd-core\*') -replace '\\', '/')
    if ($config.PSObject.Properties['permission']) {
        foreach ($sectionName in @($overlay.permissionSections)) {
            $section = $config.permission.PSObject.Properties[$sectionName]
            if ($section -and $section.Value.PSObject.Properties[$permissionKey]) {
                throw "Refusing to overwrite unmanaged framework permission: $sectionName.$permissionKey"
            }
        }
    }
    if ($config.PSObject.Properties['mcp'] -and $config.mcp.PSObject.Properties[$overlay.mcpKey]) {
        throw "Refusing to overwrite unmanaged framework MCP config: $($overlay.mcpKey)"
    }
}

function Get-LockedPluginConfig {
    param([AllowNull()]$PreviousEntry)

    if (-not $PreviousEntry) {
        return @()
    }
    if ($PreviousEntry.PSObject.Properties['pluginConfig'] -and @($PreviousEntry.pluginConfig).Count -gt 0) {
        return @($PreviousEntry.pluginConfig | ForEach-Object {
            [pscustomobject]@{ key = [string]$_.key; specs = @($_.specs | ForEach-Object { [string]$_ }) }
        })
    }
    # Lock schema 1 and 2 recorded only the V1-shaped `plugin` array.
    if ($PreviousEntry.PSObject.Properties['pluginSpecs'] -and @($PreviousEntry.pluginSpecs).Count -gt 0) {
        return @([pscustomobject]@{
            key = 'plugin'
            specs = @($PreviousEntry.pluginSpecs | ForEach-Object { [string]$_ })
        })
    }
    return @()
}

function Set-ManagedPluginSpec {
    param(
        [Parameter(Mandatory = $true)]$Config,
        [Parameter(Mandatory = $true)][string]$PluginSpec,
        [AllowNull()]$PreviousEntry,
        [Parameter(Mandatory = $true)][string]$ConfigPath,
        [Parameter(Mandatory = $true)][object[]]$TargetRuntimes
    )

    # V1 reads the singular `plugin` array and ignores `plugins`. V2 reads the
    # native `plugins` array and prefers it over a normalized `plugin` value.
    # Writing the spec under each selected runtime's own key is therefore the only
    # shape that installs on both runtimes from one shared project config.
    $previous = @(Get-LockedPluginConfig $PreviousEntry)
    $desiredKeys = @($TargetRuntimes | ForEach-Object { $_.pluginConfigKey } | Select-Object -Unique)
    if ($desiredKeys.Count -eq 0) {
        throw "No runtime plugin config key resolved for $ConfigPath."
    }
    foreach ($key in $desiredKeys) {
        $entries = if ($Config.PSObject.Properties[$key]) { @($Config.PSObject.Properties[$key].Value) } else { @() }
        $owned = @($previous | Where-Object { $_.key -eq $key } | ForEach-Object { $_.specs })
        # Object entries belong to hand-written V2 `{ package, options }` values; keep them untouched.
        $kept = @($entries | Where-Object {
            -not (($_ -is [string]) -and ($owned -contains $_) -and ($_ -ne $PluginSpec))
        })
        if (@($kept | Where-Object { ($_ -is [string]) -and ($_ -eq $PluginSpec) }).Count -eq 0) {
            $kept += $PluginSpec
        }
        Set-ObjectProperty $Config $key @($kept)
    }
    foreach ($staleKey in @($previous | Where-Object { $desiredKeys -notcontains $_.key })) {
        if (-not $Config.PSObject.Properties[$staleKey.key]) {
            continue
        }
        $specs = @($staleKey.specs)
        $kept = @(@($Config.PSObject.Properties[$staleKey.key].Value) | Where-Object {
            -not (($_ -is [string]) -and ($specs -contains $_))
        })
        if ($kept.Count -eq 0) {
            $Config.PSObject.Properties.Remove($staleKey.key)
        }
        else {
            Set-ObjectProperty $Config $staleKey.key @($kept)
        }
    }
    return @($desiredKeys | ForEach-Object {
        [pscustomobject]@{ key = $_; specs = @($PluginSpec) }
    })
}

function Install-OpenCodePluginAsset {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)][string]$ResolvedScope,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot,
        [Parameter(Mandatory = $true)]$ExistingLock,
        [Parameter(Mandatory = $true)][object[]]$TargetRuntimes,
        [Parameter(Mandatory = $true)]$Catalog
    )

    if ($ResolvedScope -ne 'project') {
        throw "OpenCode plugin asset $($Asset.id) is project-only."
    }
    $previousEntry = @($ExistingLock.assets | Where-Object id -eq $Asset.id) | Select-Object -First 1
    if ($Asset.id -ne 'oh-my-opencode-slim') {
        $configPath = Resolve-TargetPath $Asset.configPath $ResolvedScope $ResolvedProjectRoot
        $config = Get-JsonConfig $configPath
        $pluginConfig = Set-ManagedPluginSpec $config $Asset.pluginSpec $previousEntry $configPath $TargetRuntimes
        Save-JsonConfig $configPath $config
        return [pscustomobject]@{
            id = $Asset.id
            channel = $Asset.channel
            revision = $Asset.revision
            packageVersion = $Asset.packageVersion
            skills = @()
            installedPaths = @()
            installedPathHashes = @()
            configPath = $configPath
            pluginConfig = @($pluginConfig)
        }
    }

    $checkout = New-PinnedRepositoryCheckout $Asset
    try {
        $paths = Get-Slim8Paths $Asset $ResolvedProjectRoot $Catalog
        $sourceRoot = [IO.Path]::GetFullPath((Join-Path $checkout.repositoryPath $Asset.bundledSkillsPath))
        $ownedPaths = if ($previousEntry) { @($previousEntry.installedPaths) } else { @() }
        if ($previousEntry) { Assert-LockedPathsUnchanged $previousEntry }
        $mappings = [Collections.Generic.List[object]]::new()
        foreach ($name in $script:Slim8SkillNames) {
            $source = [IO.Path]::GetFullPath((Join-Path $sourceRoot $name))
            $target = [IO.Path]::GetFullPath((Join-Path $paths.projectSkillsRoot $name))
            if (-not (Test-Path -LiteralPath (Join-Path $source 'SKILL.md') -PathType Leaf)) {
                throw "Pinned Slim8 skill source is missing SKILL.md: $source"
            }
            if (Test-Path -LiteralPath $target) {
                if ($ownedPaths -notcontains $target) {
                    throw "Refusing to overwrite an unmanaged project skill: $target"
                }
            }
            $mappings.Add([pscustomobject]@{ name = $name; source = $source; target = $target })
        }

        $migrationPlan = Get-Slim8GlobalMigrationPlan $Asset $checkout.repositoryPath $ResolvedProjectRoot $Catalog
        $migration = Invoke-Slim8MigrationApply $Asset $migrationPlan -RejectUnsafe
        foreach ($mapping in @($mappings)) {
            Copy-ManagedPath $mapping.source $mapping.target ($ownedPaths -contains $mapping.target)
        }

        $configPath = Resolve-TargetPath $Asset.configPath $ResolvedScope $ResolvedProjectRoot
        $config = Get-JsonConfig $configPath
        $pluginConfig = Set-ManagedPluginSpec $config $Asset.pluginSpec $previousEntry $configPath $TargetRuntimes
        Save-JsonConfig $configPath $config
        $installedPaths = @($mappings | ForEach-Object { $_.target })

        return [pscustomobject]@{
            id = $Asset.id
            channel = $Asset.channel
            revision = $Asset.revision
            packageVersion = $Asset.packageVersion
            skills = @($script:Slim8SkillNames)
            installedPaths = $installedPaths
            installedPathHashes = (Get-InstalledPathHashes $installedPaths)
            configPath = $configPath
            pluginConfig = @($pluginConfig)
            globalMigrationBackupPath = $migration.backupPath
        }
    }
    finally {
        Remove-Item -LiteralPath $checkout.tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Install-OpenCodeMcpAsset {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)][string]$ResolvedScope,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot,
        [Parameter(Mandatory = $true)]$ExistingLock
    )

    if ($ResolvedScope -ne 'project') {
        throw "OpenCode MCP asset $($Asset.id) is project-only."
    }
    $configPath = Resolve-TargetPath $Asset.configPath $ResolvedScope $ResolvedProjectRoot
    $managedConfigRoot = [IO.Path]::GetFullPath((Join-Path $ResolvedProjectRoot '.opencode'))
    if (-not (Test-PathWithinRoot $configPath $managedConfigRoot)) {
        throw "OpenCode MCP config must be inside the project .opencode directory: $configPath"
    }
    $previousEntry = @($ExistingLock.assets | Where-Object { $_.id -eq $Asset.id }) | Select-Object -First 1
    if ($previousEntry) {
        $entryMatches = $previousEntry.channel -eq 'opencode-mcp' -and
            $previousEntry.PSObject.Properties['configPath'] -and
            $previousEntry.PSObject.Properties['mcpKey'] -and
            $previousEntry.PSObject.Properties['mcpValue'] -and
            [string]::Equals([IO.Path]::GetFullPath($previousEntry.configPath), $configPath, [StringComparison]::OrdinalIgnoreCase) -and
            $previousEntry.mcpKey -eq $Asset.mcpKey
        if (-not $entryMatches) {
            throw "Refusing to update MCP $($Asset.mcpKey): lock ownership metadata does not match."
        }
    }

    $config = Get-JsonConfig $configPath
    $mcp = if ($config.PSObject.Properties['mcp']) { $config.mcp } else { $null }
    if ($null -ne $mcp -and $mcp -isnot [pscustomobject]) {
        throw "OpenCode MCP config must be a JSON object: $configPath"
    }
    $currentProperty = if ($mcp) { $mcp.PSObject.Properties[$Asset.mcpKey] } else { $null }
    if ($previousEntry) {
        if (-not $currentProperty -or -not (Test-JsonValueEqual $currentProperty.Value $previousEntry.mcpValue)) {
            throw "Refusing to update drifted MCP config: mcp.$($Asset.mcpKey)"
        }
    }
    elseif ($currentProperty) {
        throw "Refusing to overwrite unmanaged MCP config: mcp.$($Asset.mcpKey)"
    }

    if (-not $mcp) { $mcp = Get-OrAddObjectProperty $config 'mcp' }
    $mcpValue = $Asset.mcpValue | ConvertTo-Json -Depth 50 | ConvertFrom-Json
    Set-ObjectProperty $mcp $Asset.mcpKey $mcpValue
    Save-JsonConfig $configPath $config

    return [pscustomobject]@{
        id = $Asset.id
        channel = $Asset.channel
        revision = $Asset.revision
        skills = @()
        installedPaths = @()
        configPath = $configPath
        mcpKey = $Asset.mcpKey
        mcpValue = $mcpValue
    }
}

function Install-NpmFrameworkAsset {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)][string]$ResolvedScope,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot,
        [Parameter(Mandatory = $true)]$ExistingLock
    )

    if ($ResolvedScope -ne 'project') {
        throw "NPM framework asset $($Asset.id) is project-only."
    }
    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) "opencode-assets-$([guid]::NewGuid())"
    $stagingProject = Join-Path $tempRoot 'project'
    $stagingHome = Join-Path $tempRoot 'home'
    $stagingRoot = Join-Path $stagingProject $Asset.configRoot
    $targetRoot = Resolve-TargetPath $Asset.configRoot $ResolvedScope $ResolvedProjectRoot
    $previousEntry = @($ExistingLock.assets | Where-Object { $_.id -eq $Asset.id }) | Select-Object -First 1
    $ownedPaths = if ($previousEntry) { @($previousEntry.installedPaths) } else { @() }
    $copyItems = [Collections.Generic.List[object]]::new()
    $frameworkConfig = $null
    New-Item -ItemType Directory -Path $stagingProject | Out-Null
    New-Item -ItemType Directory -Path $stagingHome | Out-Null
    try {
        $packageSpec = "$($Asset.package)@$($Asset.packageVersion)"
        $arguments = @('-y', $packageSpec) + @($Asset.installArguments)
        Invoke-CheckedCommand 'npx' $arguments "Failed to stage $($Asset.id)" $stagingProject @{
            HOME = $stagingHome
            USERPROFILE = $stagingHome
        }

        $versionPath = Join-Path $stagingRoot $Asset.versionFile
        if (-not (Test-Path -LiteralPath $versionPath)) {
            throw "Framework version marker not found: $versionPath"
        }
        $actualVersion = (Get-Content -LiteralPath $versionPath -Raw).Trim()
        if ($actualVersion -ne $Asset.expectedVersion) {
            throw "Framework version mismatch for $($Asset.id): expected $($Asset.expectedVersion), got $actualVersion"
        }

        if ($Asset.PSObject.Properties['frameworkProfile']) {
            $profilePath = Join-Path $stagingRoot '.gsd-profile'
            $actualProfile = if (Test-Path -LiteralPath $profilePath) { (Get-Content -LiteralPath $profilePath -Raw).Trim() } else { '<missing>' }
            if ($actualProfile -ne $Asset.frameworkProfile) {
                throw "Framework profile mismatch for $($Asset.id): expected $($Asset.frameworkProfile), got $actualProfile"
            }
        }

        $manifestPath = Join-Path $stagingRoot $Asset.manifestFile
        if (-not (Test-Path -LiteralPath $manifestPath)) {
            throw "Framework file manifest not found: $manifestPath"
        }
        $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        if ($manifest.version -ne $Asset.expectedVersion) {
            throw "Framework manifest version mismatch for $($Asset.id): expected $($Asset.expectedVersion), got $($manifest.version)"
        }
        $relativePaths = @($manifest.files.PSObject.Properties | ForEach-Object { $_.Name }) + @($Asset.metadataFiles)
        foreach ($relativePath in @($relativePaths | Select-Object -Unique)) {
            $source = [IO.Path]::GetFullPath((Join-Path $stagingRoot $relativePath))
            if (-not (Test-PathWithinRoot $source $stagingRoot) -or -not (Test-Path -LiteralPath $source -PathType Leaf)) {
                throw "Framework manifest contains an invalid file path: $relativePath"
            }
            $copyItems.Add([pscustomobject]@{
                source = $source
                target = [IO.Path]::GetFullPath((Join-Path $targetRoot $relativePath))
            })
        }

        Test-NpmFrameworkConfigOwnership $Asset $targetRoot $ResolvedProjectRoot ($null -ne $previousEntry)
        $newPaths = @($copyItems.target)
        foreach ($newPath in $newPaths) {
            if ((Test-Path -LiteralPath $newPath) -and $ownedPaths -notcontains $newPath) {
                throw "Refusing to overwrite an unmanaged framework path: $newPath"
            }
        }
        foreach ($stalePath in @($ownedPaths | Where-Object { $newPaths -notcontains $_ })) {
            if (-not (Test-PathWithinRoot $stalePath $targetRoot)) {
                throw "Refusing to remove stale framework path outside target root: $stalePath"
            }
            if (Test-Path -LiteralPath $stalePath) {
                Remove-Item -LiteralPath $stalePath -Recurse -Force
            }
        }
        foreach ($item in @($copyItems)) {
            Copy-ManagedPath $item.source $item.target ($ownedPaths -contains $item.target)
        }
        $frameworkConfig = Install-NpmFrameworkConfig $Asset $stagingRoot $targetRoot $ResolvedProjectRoot
    }
    finally {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    $entry = [pscustomobject]@{
        id = $Asset.id
        channel = $Asset.channel
        revision = $Asset.revision
        packageVersion = $Asset.packageVersion
        skills = @()
        installedPaths = @($copyItems.target)
    }
    if ($frameworkConfig) {
        $entry | Add-Member -NotePropertyName frameworkConfig -NotePropertyValue $frameworkConfig
    }
    return $entry
}

function Install-MarketplaceAsset {
    param(
        [Parameter(Mandatory = $true)]$Catalog,
        [Parameter(Mandatory = $true)]$Asset
    )

    $command = $Catalog.installers.claudeCode.command
    Invoke-CheckedCommand $command @('plugin', 'marketplace', 'add', $Asset.source) "Failed to add Claude marketplace $($Asset.marketplace)"
    return [pscustomobject]@{
        id = $Asset.id
        channel = $Asset.channel
        revision = $null
        skills = @()
        installedPaths = @()
    }
}

function Get-OverlayTargetPath {
    param(
        [Parameter(Mandatory = $true)]$Overlay,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot
    )

    if ($Overlay.targetAssetId -ne 'oh-my-opencode-slim' -or $Overlay.targetKind -ne 'agent-prompt') {
        throw "Unsupported overlay target: $($Overlay.targetAssetId)/$($Overlay.targetKind)"
    }
    if ([string]::IsNullOrWhiteSpace($Overlay.targetName) -or $Overlay.targetName -notmatch '^[a-zA-Z0-9_-]+$') {
        throw "Invalid overlay target name: $($Overlay.targetName)"
    }
    return [IO.Path]::GetFullPath((Join-Path $ResolvedProjectRoot ".opencode\oh-my-opencode-slim\$($Overlay.targetName)_append.md"))
}

function Get-OverlayOutputContent {
    param([Parameter(Mandatory = $true)][object[]]$ResolvedOverlays)

    $sections = [Collections.Generic.List[string]]::new()
    $sections.Add('<!-- Generated by opencode-assets.ps1. Edit Overlay sources, not this file. -->')
    foreach ($overlay in @($ResolvedOverlays | Sort-Object @{ Expression = { [int]$_.priority } }, id)) {
        $source = [IO.Path]::GetFullPath((Resolve-HomePath $overlay.sourcePath))
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
            throw "Overlay source not found: $source"
        }
        $sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
        $body = (Get-Content -LiteralPath $source -Raw).Trim()
        $sections.Add("<!-- opencode-overlay:start id=$($overlay.id) source-sha256=$sourceHash -->`n$body`n<!-- opencode-overlay:end id=$($overlay.id) -->")
    }
    return ($sections -join "`n`n") + "`n"
}

function Test-ManagedOverlayOutput {
    param([Parameter(Mandatory = $true)]$Output)

    if (-not (Test-Path -LiteralPath $Output.targetPath)) { return }
    $actualHash = (Get-FileHash -LiteralPath $Output.targetPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $Output.contentHash) {
        throw "Refusing to overwrite drifted Overlay output: $($Output.targetPath)"
    }
}

function Test-SelectedOverlays {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$ResolvedOverlays,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot,
        [Parameter(Mandatory = $true)]$ExistingLock
    )

    $existingOutputs = @($ExistingLock.overlayOutputs)
    $groups = @($ResolvedOverlays | Group-Object { Get-OverlayTargetPath $_ $ResolvedProjectRoot })
    $desiredPaths = @($groups | ForEach-Object { $_.Name })
    foreach ($group in $groups) {
        $targetPath = [string]$group.Name
        $previousOutput = @($existingOutputs | Where-Object targetPath -eq $targetPath) | Select-Object -First 1
        if ((Test-Path -LiteralPath $targetPath) -and -not $previousOutput) {
            throw "Refusing to overwrite an unmanaged Overlay output: $targetPath"
        }
        if ($previousOutput) { Test-ManagedOverlayOutput $previousOutput }
        [void](Get-OverlayOutputContent @($group.Group))
    }
    foreach ($staleOutput in @($existingOutputs | Where-Object { $desiredPaths -notcontains $_.targetPath })) {
        Test-ManagedOverlayOutput $staleOutput
    }
}

function Install-SelectedOverlays {
    param(
        [Parameter(Mandatory = $true)]$Catalog,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$ResolvedOverlays,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot,
        [Parameter(Mandatory = $true)]$ExistingLock
    )

    $existingOutputs = @($ExistingLock.overlayOutputs)
    Test-SelectedOverlays $ResolvedOverlays $ResolvedProjectRoot $ExistingLock
    $groups = @($ResolvedOverlays | Group-Object {
        Get-OverlayTargetPath $_ $ResolvedProjectRoot
    })
    $desiredPaths = @($groups | ForEach-Object { $_.Name })

    foreach ($staleOutput in @($existingOutputs | Where-Object { $desiredPaths -notcontains $_.targetPath })) {
        Test-ManagedOverlayOutput $staleOutput
        if (Test-Path -LiteralPath $staleOutput.targetPath) {
            Remove-Item -LiteralPath $staleOutput.targetPath -Force
        }
    }

    $overlayEntries = [Collections.Generic.List[object]]::new()
    $outputEntries = [Collections.Generic.List[object]]::new()
    foreach ($group in $groups) {
        $targetPath = [string]$group.Name
        $previousOutput = @($existingOutputs | Where-Object targetPath -eq $targetPath) | Select-Object -First 1
        if (Test-Path -LiteralPath $targetPath) {
            if (-not $previousOutput) {
                throw "Refusing to overwrite an unmanaged Overlay output: $targetPath"
            }
            Test-ManagedOverlayOutput $previousOutput
        }
        $parent = Split-Path -Parent $targetPath
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
        $content = Get-OverlayOutputContent @($group.Group)
        Set-Content -LiteralPath $targetPath -Value $content -Encoding utf8 -NoNewline
        $contentHash = (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash.ToLowerInvariant()
        $overlayIds = @($group.Group | Sort-Object @{ Expression = { [int]$_.priority } }, id | ForEach-Object { [string]$_.id })
        $outputEntries.Add([pscustomobject]@{
            targetPath = $targetPath
            overlayIds = $overlayIds
            contentHash = $contentHash
        })
        foreach ($overlay in @($group.Group)) {
            $source = [IO.Path]::GetFullPath((Resolve-HomePath $overlay.sourcePath))
            $overlayEntries.Add([pscustomobject]@{
                id = $overlay.id
                targetAssetId = $overlay.targetAssetId
                targetPath = $targetPath
                sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
            })
        }
    }
    return [pscustomobject]@{ overlays = @($overlayEntries); outputs = @($outputEntries) }
}

function Get-OverlayStatus {
    param(
        [Parameter(Mandatory = $true)]$Selection,
        [Parameter(Mandatory = $true)]$Lock
    )

    $rows = foreach ($overlay in @($Selection.overlays)) {
        $entry = @($Lock.overlays | Where-Object id -eq $overlay.id) | Select-Object -First 1
        $output = if ($entry) { @($Lock.overlayOutputs | Where-Object targetPath -eq $entry.targetPath) | Select-Object -First 1 } else { $null }
        $missing = -not $output -or -not (Test-Path -LiteralPath $entry.targetPath)
        $contentChanged = $false
        if ($entry) {
            $source = [IO.Path]::GetFullPath((Resolve-HomePath $overlay.sourcePath))
            $sourceChanged = -not (Test-Path -LiteralPath $source) -or
                (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.sourceHash
            $outputChanged = -not $missing -and
                (Get-FileHash -LiteralPath $entry.targetPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $output.contentHash
            $contentChanged = $sourceChanged -or $outputChanged
        }
        [pscustomobject]@{
            id = $overlay.id
            kind = 'overlay'
            channel = 'generated-append'
            state = if (-not $entry) { 'not-managed' } elseif ($missing -or $contentChanged) { 'drifted' } else { 'installed' }
            missingPaths = if ($missing -and $entry) { @($entry.targetPath) } else { @() }
            contentChanged = $contentChanged
        }
    }
    return @($rows)
}

function Remove-LockedAsset {
    param(
        [Parameter(Mandatory = $true)]$Catalog,
        [Parameter(Mandatory = $true)]$Entry,
        [Parameter(Mandatory = $true)][string]$ResolvedScope,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot
    )

    if ($Entry.channel -eq 'opencode-mcp') {
        $managedConfigRoot = [IO.Path]::GetFullPath((Join-Path $ResolvedProjectRoot '.opencode'))
        if (-not (Test-PathWithinRoot $Entry.configPath $managedConfigRoot)) {
            throw "Refusing to remove MCP config outside the project .opencode directory: $($Entry.configPath)"
        }
        $config = Get-JsonConfig $Entry.configPath
        $mcpProperty = if ($config.PSObject.Properties['mcp'] -and $config.mcp -is [pscustomobject]) {
            $config.mcp.PSObject.Properties[$Entry.mcpKey]
        }
        else { $null }
        if (-not $mcpProperty -or -not (Test-JsonValueEqual $mcpProperty.Value $Entry.mcpValue)) {
            throw "Refusing to remove drifted MCP config: mcp.$($Entry.mcpKey). Restore the locked value first."
        }
        $config.mcp.PSObject.Properties.Remove($Entry.mcpKey)
        Save-JsonConfig $Entry.configPath $config
        return
    }

    if ($Entry.channel -eq 'opencode-plugin') {
        Assert-LockedPathsUnchanged $Entry
        $managedRoot = [IO.Path]::GetFullPath((Join-Path $ResolvedProjectRoot '.opencode'))
        foreach ($path in @($Entry.installedPaths)) {
            if (-not (Test-PathWithinRoot $path $managedRoot)) {
                throw "Refusing to remove plugin path outside the project .opencode directory: $path"
            }
        }
        $config = Get-JsonConfig $Entry.configPath
        foreach ($pluginKey in @(Get-LockedPluginConfig $Entry)) {
            if (-not $config.PSObject.Properties[$pluginKey.key]) {
                continue
            }
            $specs = @($pluginKey.specs)
            $kept = @(@($config.PSObject.Properties[$pluginKey.key].Value) | Where-Object {
                -not (($_ -is [string]) -and ($specs -contains $_))
            })
            if ($kept.Count -eq 0) {
                $config.PSObject.Properties.Remove($pluginKey.key)
            }
            else {
                Set-ObjectProperty $config $pluginKey.key @($kept)
            }
        }
        Save-JsonConfig $Entry.configPath $config
        foreach ($path in @($Entry.installedPaths)) {
            if (Test-Path -LiteralPath $path) {
                Remove-Item -LiteralPath $path -Recurse -Force
            }
        }
        return
    }

    if ($Entry.channel -eq 'npm-framework' -and $Entry.PSObject.Properties['frameworkConfig']) {
        $frameworkConfig = $Entry.frameworkConfig
        $config = Get-JsonConfig $frameworkConfig.configPath
        if ($config.PSObject.Properties['permission']) {
            foreach ($sectionName in @($frameworkConfig.permissionSections)) {
                $sectionProperty = $config.permission.PSObject.Properties[$sectionName]
                if ($sectionProperty) {
                    $permissionProperty = $sectionProperty.Value.PSObject.Properties[$frameworkConfig.permissionKey]
                    if ($permissionProperty -and $permissionProperty.Value -eq 'allow') {
                        $sectionProperty.Value.PSObject.Properties.Remove($frameworkConfig.permissionKey)
                    }
                }
            }
        }
        if ($config.PSObject.Properties['mcp']) {
            $mcpProperty = $config.mcp.PSObject.Properties[$frameworkConfig.mcpKey]
            if ($mcpProperty -and (Test-JsonValueEqual $mcpProperty.Value $frameworkConfig.mcpValue)) {
                $config.mcp.PSObject.Properties.Remove($frameworkConfig.mcpKey)
            }
        }
        Save-JsonConfig $frameworkConfig.configPath $config
    }

    if ($Entry.channel -eq 'skills-cli' -and @($Entry.skills).Count -gt 0) {
        $installer = $Catalog.installers.skillsCli
        $arguments = @('-y', "$($installer.package)@$($installer.version)", 'remove')
        if ($ResolvedScope -eq 'global') {
            $arguments += '--global'
        }
        $arguments += @('--yes', '--skill') + @($Entry.skills)
        Invoke-CheckedCommand 'npx' $arguments "Failed to remove $($Entry.id)" $ResolvedProjectRoot
        return
    }

    $allowedRoots = @(Get-ManagedRoots $Catalog $ResolvedScope $ResolvedProjectRoot)
    foreach ($path in @($Entry.installedPaths)) {
        if (-not (@($allowedRoots | Where-Object { Test-PathWithinRoot (Get-CanonicalPath $path) $_ }).Count -gt 0)) {
            throw "Refusing to remove locked path outside managed roots: $path"
        }
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Recurse -Force
        }
    }
}

function Test-Catalog {
    param([Parameter(Mandatory = $true)]$Catalog)

    $errors = [Collections.Generic.List[string]]::new()
    $warnings = [Collections.Generic.List[string]]::new()
    $ids = @($Catalog.assets.id)
    $runtimeIds = @(Get-RuntimeTable $Catalog | ForEach-Object { $_.id })
    foreach ($defaultRuntime in @($Catalog.defaultRuntimes)) {
        if ($runtimeIds -notcontains $defaultRuntime) {
            $errors.Add("defaultRuntimes references unknown runtime $defaultRuntime")
        }
    }
    foreach ($duplicate in @($ids | Group-Object | Where-Object Count -gt 1)) {
        $errors.Add("Duplicate asset id: $($duplicate.Name)")
    }
    foreach ($asset in @($Catalog.assets)) {
        if ([string]::IsNullOrWhiteSpace($asset.id) -or [string]::IsNullOrWhiteSpace($asset.channel)) {
            $errors.Add('Every asset requires id and channel.')
            continue
        }
        foreach ($profile in @($asset.profiles)) {
            if (-not $Catalog.profiles.PSObject.Properties[$profile]) {
                $errors.Add("Asset $($asset.id) references unknown profile $profile")
            }
        }
        $assetRuntimes = @(Get-AssetRuntimeIds $asset $Catalog)
        if ($assetRuntimes.Count -eq 0) {
            $errors.Add("Asset $($asset.id) must support at least one runtime.")
        }
        foreach ($runtimeId in $assetRuntimes) {
            if ($runtimeIds -notcontains $runtimeId) {
                $errors.Add("Asset $($asset.id) references unknown runtime $runtimeId")
            }
        }
        if ($asset.PSObject.Properties['runtimeBlocked']) {
            foreach ($property in $asset.runtimeBlocked.PSObject.Properties) {
                if ($runtimeIds -notcontains $property.Name) {
                    $errors.Add("Asset $($asset.id) blocks unknown runtime $($property.Name)")
                }
                elseif ($assetRuntimes -contains $property.Name) {
                    $errors.Add("Asset $($asset.id) both supports and blocks runtime $($property.Name)")
                }
                elseif ([string]::IsNullOrWhiteSpace([string]$property.Value)) {
                    $errors.Add("Asset $($asset.id) needs a non-empty reason for blocked runtime $($property.Name)")
                }
            }
        }
        foreach ($runtimeId in @($runtimeIds | Where-Object { $assetRuntimes -notcontains $_ })) {
            if (-not (Get-AssetRuntimeBlockReason $asset $runtimeId)) {
                $warnings.Add("Asset $($asset.id) excludes runtime $runtimeId without a runtimeBlocked reason.")
            }
        }
        foreach ($sourceField in @('sourcePath', 'repositoryRoot')) {
            if ($asset.PSObject.Properties[$sourceField] -and
                (Test-RuntimeToken ([string]$asset.PSObject.Properties[$sourceField].Value))) {
                $errors.Add("Asset $($asset.id) must not use the {configRoot} token in $sourceField")
            }
        }
        if ($asset.channel -in @('skills-cli', 'git-allowlist', 'opencode-plugin', 'opencode-mcp', 'npm-framework') -and [string]::IsNullOrWhiteSpace($asset.revision)) {
            $errors.Add("Network asset $($asset.id) requires a pinned revision.")
        }
        if ($asset.channel -in @('opencode-plugin', 'npm-framework') -and [string]::IsNullOrWhiteSpace($asset.packageVersion)) {
            $errors.Add("Package asset $($asset.id) requires a pinned packageVersion.")
        }
        if ($asset.id -eq 'oh-my-opencode-slim') {
            foreach ($propertyName in @('bundledSkillsPath', 'projectSkillsPath', 'globalSkillsPath', 'globalSkillsManifestPath', 'globalSkillsBackupPath')) {
                if (-not $asset.PSObject.Properties[$propertyName] -or [string]::IsNullOrWhiteSpace($asset.PSObject.Properties[$propertyName].Value)) {
                    $errors.Add("Slim8 asset requires $propertyName.")
                }
            }
            $configuredSkills = @($asset.skills | Sort-Object)
            $expectedSkills = @($script:Slim8SkillNames | Sort-Object)
            if ($configuredSkills.Count -ne $expectedSkills.Count -or
                @(Compare-Object $configuredSkills $expectedSkills).Count -gt 0) {
                $errors.Add("Slim8 asset must contain exactly these bundled skills: $($script:Slim8SkillNames -join ', ')")
            }
            if (@($asset.scopes).Count -ne 1 -or @($asset.scopes) -notcontains 'project' -or $asset.defaultScope -ne 'project') {
                $errors.Add('Slim8 asset must use project scope only.')
            }
        }
        if ($asset.PSObject.Properties['frontmatter']) {
            if ($asset.channel -ne 'skills-cli') {
                $errors.Add("Asset $($asset.id) can use managed frontmatter only with the skills-cli channel.")
            }
            if (@($asset.skills) -contains '*') {
                $errors.Add("Asset $($asset.id) cannot combine wildcard skills with managed frontmatter.")
            }
            foreach ($propertyName in @('sourcePath', 'skillRoot')) {
                if (-not $asset.frontmatter.PSObject.Properties[$propertyName] -or [string]::IsNullOrWhiteSpace($asset.frontmatter.$propertyName)) {
                    $errors.Add("Asset $($asset.id) frontmatter requires $propertyName.")
                }
            }
        }
        if ($asset.channel -eq 'npm-framework') {
            foreach ($propertyName in @('installArguments', 'manifestFile', 'versionFile', 'expectedVersion')) {
                if (-not $asset.PSObject.Properties[$propertyName]) {
                    $errors.Add("NPM framework asset $($asset.id) requires $propertyName.")
                }
            }
        }
        if ($asset.channel -eq 'opencode-mcp') {
            foreach ($propertyName in @('configPath', 'mcpKey', 'mcpValue', 'revision')) {
                if (-not $asset.PSObject.Properties[$propertyName]) {
                    $errors.Add("OpenCode MCP asset $($asset.id) requires $propertyName.")
                }
            }
            if ([string]::IsNullOrWhiteSpace($asset.configPath) -or [string]::IsNullOrWhiteSpace($asset.mcpKey) -or $null -eq $asset.mcpValue) {
                $errors.Add("OpenCode MCP asset $($asset.id) requires non-empty configPath, mcpKey, and mcpValue values.")
            }
            if (@($asset.scopes).Count -ne 1 -or @($asset.scopes) -notcontains 'project' -or $asset.defaultScope -ne 'project') {
                $errors.Add("OpenCode MCP asset $($asset.id) must use project scope only.")
            }
        }
        if ($asset.PSObject.Properties['dependsOn']) {
            foreach ($dependency in @($asset.dependsOn)) {
                if ($ids -notcontains $dependency) {
                    $errors.Add("Asset $($asset.id) depends on unknown asset $dependency")
                }
            }
        }
        if ($asset.channel -eq 'copy-template') {
            $hasSinglePath = $asset.PSObject.Properties['sourcePath'] -and $asset.PSObject.Properties['targetPath']
            $hasFiles = $asset.PSObject.Properties['files'] -and @($asset.files).Count -gt 0
            if (-not $hasSinglePath -and -not $hasFiles) {
                $errors.Add("Copy template asset $($asset.id) requires sourcePath/targetPath or files.")
            }
            if ($hasFiles) {
                foreach ($file in @($asset.files)) {
                    if (-not $file.PSObject.Properties['source'] -or -not $file.PSObject.Properties['target']) {
                        $errors.Add("Copy template asset $($asset.id) has an invalid file mapping.")
                    }
                }
            }
        }
        if ($asset.channel -eq 'provenance-only') {
            $warnings.Add("Asset $($asset.id) is provenance-only and cannot be applied.")
        }
    }
    $overlayIds = @($Catalog.overlays | ForEach-Object { $_.id })
    foreach ($duplicate in @($overlayIds | Group-Object | Where-Object Count -gt 1)) {
        $errors.Add("Duplicate overlay id: $($duplicate.Name)")
    }
    foreach ($overlay in @($Catalog.overlays)) {
        foreach ($propertyName in @('id', 'name', 'targetAssetId', 'targetKind', 'targetName', 'sourcePath', 'priority')) {
            if (-not $overlay.PSObject.Properties[$propertyName]) {
                $errors.Add("Overlay requires ${propertyName}: $($overlay.id)")
            }
        }
        if ($ids -notcontains $overlay.targetAssetId) {
            $errors.Add("Overlay $($overlay.id) targets unknown asset $($overlay.targetAssetId)")
        }
        if ($overlay.targetAssetId -ne 'oh-my-opencode-slim' -or $overlay.targetKind -ne 'agent-prompt') {
            $errors.Add("Overlay $($overlay.id) uses unsupported target $($overlay.targetAssetId)/$($overlay.targetKind)")
        }
        if ($overlay.PSObject.Properties['dependsOn']) {
            foreach ($dependency in @($overlay.dependsOn)) {
                if ($ids -notcontains $dependency) {
                    $errors.Add("Overlay $($overlay.id) depends on unknown asset $dependency")
                }
            }
        }
        if (@($overlay.scopes) -notcontains 'project' -or @($overlay.scopes) -contains 'global') {
            $errors.Add("Overlay $($overlay.id) must use project scope only.")
        }
        $source = [IO.Path]::GetFullPath((Resolve-HomePath $overlay.sourcePath))
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
            $errors.Add("Overlay $($overlay.id) source not found: $source")
        }
    }
    return [pscustomobject]@{ errors = @($errors); warnings = @($warnings) }
}

function Get-Status {
    param(
        [Parameter(Mandatory = $true)]$Selection,
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)]$Catalog
    )

    $rows = foreach ($asset in @($Selection.assets)) {
        $entry = @($Lock.assets | Where-Object { $_.id -eq $asset.id }) | Select-Object -First 1
        $paths = if ($entry) { @($entry.installedPaths) } else { @() }
        $missing = @($paths | Where-Object { -not (Test-Path -LiteralPath $_) })
        $fingerprintChanged = $false
        $pluginChanged = $false
        $mcpChanged = $false
        $frameworkConfigChanged = $false
        $isolationChanged = $false
        if ($entry -and $entry.channel -eq 'opencode-plugin') {
            try {
                $projectConfig = Get-JsonConfig $entry.configPath
                foreach ($pluginKey in @(Get-LockedPluginConfig $entry)) {
                    $configuredPlugins = if ($projectConfig.PSObject.Properties[$pluginKey.key]) {
                        @($projectConfig.PSObject.Properties[$pluginKey.key].Value)
                    }
                    else { @() }
                    if (@($pluginKey.specs | Where-Object { $configuredPlugins -notcontains $_ }).Count -gt 0) {
                        $pluginChanged = $true
                    }
                }
            }
            catch {
                $pluginChanged = $true
            }
        }
        if ($entry -and $entry.channel -eq 'opencode-mcp') {
            try {
                $mcpConfig = Get-JsonConfig $entry.configPath
                $mcpProperty = if ($mcpConfig.PSObject.Properties['mcp'] -and $mcpConfig.mcp -is [pscustomobject]) {
                    $mcpConfig.mcp.PSObject.Properties[$entry.mcpKey]
                }
                else { $null }
                $mcpChanged = -not $mcpProperty -or -not (Test-JsonValueEqual $mcpProperty.Value $entry.mcpValue)
            }
            catch {
                $mcpChanged = $true
            }
        }
        if ($entry -and $entry.channel -eq 'npm-framework' -and $entry.PSObject.Properties['frameworkConfig']) {
            try {
                $frameworkConfig = $entry.frameworkConfig
                $frameworkProjectConfig = Get-JsonConfig $frameworkConfig.configPath
                foreach ($sectionName in @($frameworkConfig.permissionSections)) {
                    $sectionProperty = if ($frameworkProjectConfig.PSObject.Properties['permission']) {
                        $frameworkProjectConfig.permission.PSObject.Properties[$sectionName]
                    }
                    else { $null }
                    $permissionProperty = if ($sectionProperty) {
                        $sectionProperty.Value.PSObject.Properties[$frameworkConfig.permissionKey]
                    }
                    else { $null }
                    if (-not $permissionProperty -or $permissionProperty.Value -ne 'allow') {
                        $frameworkConfigChanged = $true
                    }
                }
                $mcpProperty = if ($frameworkProjectConfig.PSObject.Properties['mcp']) {
                    $frameworkProjectConfig.mcp.PSObject.Properties[$frameworkConfig.mcpKey]
                }
                else { $null }
                if (-not $mcpProperty -or -not (Test-JsonValueEqual $mcpProperty.Value $frameworkConfig.mcpValue)) {
                    $frameworkConfigChanged = $true
                }
            }
            catch {
                $frameworkConfigChanged = $true
            }
        }
        if ($entry -and $asset.id -eq 'oh-my-opencode-slim') {
            try {
                $slim8Paths = Get-Slim8Paths $asset ([IO.Path]::GetFullPath($ProjectRoot)) $Catalog
                foreach ($slim8Target in @($slim8Paths.targets)) {
                    $slim8Manifest = Get-Slim8Manifest $slim8Target.manifestPath
                    if ($null -eq $slim8Manifest -or
                        @($script:Slim8SkillNames | Where-Object {
                            Test-Path -LiteralPath (Join-Path $slim8Target.skillsRoot $_)
                        }).Count -gt 0) {
                        $isolationChanged = $true
                    }
                    foreach ($name in $script:Slim8SkillNames) {
                        $property = if ($slim8Manifest) { $slim8Manifest.skills.PSObject.Properties[$name] } else { $null }
                        if (-not $property -or $property.Value.status -ne 'deleted') { $isolationChanged = $true }
                    }
                }
            }
            catch {
                $isolationChanged = $true
            }
        }
        if ($entry -and $missing.Count -eq 0 -and $entry.PSObject.Properties['contentHash'] -and $entry.contentHash) {
            $fingerprintChanged = (Get-PathsFingerprint $paths) -ne $entry.contentHash
        }
        $targetRuntimeIds = @(Get-AssetTargetRuntimes $Selection $asset | ForEach-Object { $_.id })
        $lockedRuntimeIds = if ($entry) { @(Get-LockedRuntimeIds $entry $Catalog) } else { @() }
        $missingRuntimes = @($targetRuntimeIds | Where-Object { $lockedRuntimeIds -notcontains $_ })
        $runtimeChanged = $entry -and $missingRuntimes.Count -gt 0
        $driftReasons = [Collections.Generic.List[string]]::new()
        if ($missing.Count -gt 0) { $driftReasons.Add('missing-paths') }
        if ($fingerprintChanged) { $driftReasons.Add('content') }
        if ($pluginChanged) { $driftReasons.Add('plugin-config') }
        if ($mcpChanged) { $driftReasons.Add('mcp-config') }
        if ($frameworkConfigChanged) { $driftReasons.Add('framework-config') }
        if ($isolationChanged) { $driftReasons.Add('global-skill-isolation') }
        if ($runtimeChanged) { $driftReasons.Add('runtime-coverage') }
        [pscustomobject]@{
            id = $asset.id
            kind = 'asset'
            channel = $asset.channel
            state = if (-not $entry) { 'not-managed' } elseif ($driftReasons.Count -gt 0) { 'drifted' } else { 'installed' }
            driftReasons = @($driftReasons)
            runtimes = $targetRuntimeIds
            lockedRuntimes = $lockedRuntimeIds
            missingRuntimes = $missingRuntimes
            missingPaths = $missing
            contentChanged = $fingerprintChanged -or $pluginChanged -or $mcpChanged -or $frameworkConfigChanged -or $isolationChanged
            isolationChanged = $isolationChanged
        }
    }
    return @($rows)
}

function Get-RuntimeEnvironmentReport {
    param([Parameter(Mandatory = $true)]$Catalog)

    $table = @(Get-RuntimeTable $Catalog)
    $rows = foreach ($runtime in $table) {
        $shared = foreach ($other in @($table | Where-Object { $_.id -ne $runtime.id })) {
            if ([string]::Equals($runtime.canonicalConfigRoot, $other.canonicalConfigRoot, [StringComparison]::OrdinalIgnoreCase)) {
                $other.id
            }
        }
        [pscustomobject]@{
            id = $runtime.id
            name = $runtime.name
            command = $runtime.command
            commandAvailable = $runtime.commandAvailable
            configRoot = $runtime.configRoot
            canonicalConfigRoot = $runtime.canonicalConfigRoot
            configRootExists = $runtime.configRootExists
            pluginConfigKey = $runtime.pluginConfigKey
            sharesConfigRootWith = @($shared)
        }
    }
    return @($rows)
}

function Get-RuntimeSharedPathReport {
    param([Parameter(Mandatory = $true)]$Catalog)

    $table = @(Get-RuntimeTable $Catalog)
    $names = @('agent', 'agents', 'commands', 'command', 'skills', 'plugins', 'plugin', '.oh-my-opencode-slim', 'opencode.json')
    $rows = foreach ($name in $names) {
        $resolved = foreach ($runtime in $table) {
            $path = Join-Path $runtime.configRoot $name
            [pscustomobject]@{
                runtime = $runtime.id
                path = $path
                exists = Test-Path -LiteralPath $path
                canonicalPath = Get-CanonicalPath $path
            }
        }
        $present = @($resolved | Where-Object exists)
        if ($present.Count -eq 0) {
            continue
        }
        $canonicalPaths = @($present | ForEach-Object { $_.canonicalPath.ToLowerInvariant() } | Select-Object -Unique)
        [pscustomobject]@{
            name = $name
            shared = $present.Count -gt 1 -and $canonicalPaths.Count -eq 1
            runtimes = @($present | ForEach-Object { $_.runtime })
            paths = @($present | ForEach-Object { $_.canonicalPath } | Select-Object -Unique)
        }
    }
    return @($rows)
}

function Wait-TuiContinue {
    Write-Host
    Write-Host '按任意鍵返回主畫面...' -ForegroundColor DarkGray
    [void][Console]::ReadKey($true)
}

function Invoke-AssetManagerAction {
    param([Parameter(Mandatory = $true)]$ResolvedCatalog)

    $script:AssetActionExitCode = 0
    $catalog = $ResolvedCatalog
$projectRootResolved = [IO.Path]::GetFullPath($ProjectRoot)
$catalogCheck = Test-Catalog $catalog

if ($Action -eq 'profiles') {
    $rows = foreach ($property in $catalog.profiles.PSObject.Properties) {
        [pscustomobject]@{
            name = $property.Name
            defaultScope = $property.Value.defaultScope
            description = $property.Value.description
        }
    }
    Write-Result @($rows)
    return
}

if ($Action -eq 'list') {
    $runtimeIds = @(Get-RuntimeTable $catalog | ForEach-Object { $_.id })
    $assetRows = @($catalog.assets | ForEach-Object {
        $asset = $_
        $supported = @(Get-AssetRuntimeIds $asset $catalog)
        $_ | Select-Object id, @{ Name = 'kind'; Expression = { 'asset' } }, type, channel, profiles, scopes, defaultScope, revision,
            @{ Name = 'runtimes'; Expression = { $supported } },
            @{ Name = 'unsupportedRuntimes'; Expression = {
                @($runtimeIds | Where-Object { $supported -notcontains $_ } | ForEach-Object {
                    $reason = Get-AssetRuntimeBlockReason $asset $_
                    [pscustomobject]@{
                        runtime = $_
                        reason = if ($reason) { $reason } else { "$($asset.id) does not declare support for $_." }
                    }
                })
            } },
            description, recommendation, prerequisites
    })
    $overlayRows = @($catalog.overlays | Select-Object id, @{ Name = 'kind'; Expression = { 'overlay' } }, targetKind, targetAssetId, targetName, profiles, scopes, priority)
    Write-Result @($assetRows + $overlayRows)
    return
}

if ($catalogCheck.errors.Count -gt 0) {
    throw "Invalid asset catalog:`n$($catalogCheck.errors -join "`n")"
}

if ($Action -eq 'slim8-migration') {
    $slim8Asset = Get-Slim8Asset $catalog
    if ($MigrationMode -eq 'restore') {
        if ([string]::IsNullOrWhiteSpace($BackupPath)) {
            throw 'slim8-migration restore requires -BackupPath.'
        }
        Write-Result (Invoke-Slim8MigrationRestore $slim8Asset $projectRootResolved $BackupPath $catalog)
        return
    }
    $checkout = New-PinnedRepositoryCheckout $slim8Asset
    try {
        $migrationPlan = Get-Slim8GlobalMigrationPlan $slim8Asset $checkout.repositoryPath $projectRootResolved $catalog
        if ($MigrationMode -eq 'plan') {
            Write-Result $migrationPlan
        }
        else {
            Write-Result (Invoke-Slim8MigrationApply $slim8Asset $migrationPlan)
        }
    }
    finally {
        Remove-Item -LiteralPath $checkout.tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    return
}

$selection = Get-Selections $catalog $Scope $projectRootResolved
$lockPath = Get-LockPath $Scope $projectRootResolved
$lock = Get-AssetLock $lockPath
if ($Scope -eq 'project' -and -not $script:OverlaySelectionExplicit -and
    -not ($Action -eq 'remove' -and $script:AssetSelectionExplicit) -and
    $selection.overlays.Count -eq 0 -and $lock.overlays.Count -gt 0) {
    $selection.overlayIds = @($lock.overlays | ForEach-Object { $_.id })
    $selection.overlays = @($catalog.overlays | Where-Object { $selection.overlayIds -contains $_.id })
}

if ($Action -eq 'plan') {
    Write-Result ([pscustomobject]@{
        action = 'apply'
        scope = $Scope
        runtimes = $selection.runtimeIds
        projectRoot = if ($Scope -eq 'project') { $projectRootResolved } else { $null }
        profiles = $selection.profiles
        assets = @($selection.assets | ForEach-Object {
            $_ | Select-Object id, type, channel, revision, description, recommendation, prerequisites,
                @{ Name = 'runtimes'; Expression = { @(Get-AssetTargetRuntimes $selection $_ | ForEach-Object { $_.id }) } }
        })
        blocked = @($selection.blocked)
        overlays = @($selection.overlays | ForEach-Object {
            [pscustomobject]@{
                id = $_.id
                targetAssetId = $_.targetAssetId
                targetPath = Get-OverlayTargetPath $_ $projectRootResolved
                priority = $_.priority
            }
        })
        lockPath = $lockPath
    })
    return
}

if ($Action -eq 'status') {
    $unsupportedRows = @($selection.blocked | ForEach-Object {
        [pscustomobject]@{
            id = $_.id
            kind = 'asset'
            channel = $_.channel
            state = 'unsupported'
            runtimes = @()
            lockedRuntimes = @()
            missingRuntimes = @()
            missingPaths = @()
            contentChanged = $false
            isolationChanged = $false
            blocked = @($_.blocked)
        }
    })
    Write-Result @(@(Get-Status $selection $lock $catalog) + $unsupportedRows + @(Get-OverlayStatus $selection $lock))
    return
}

if ($Action -eq 'doctor') {
    $status = @(@(Get-Status $selection $lock $catalog) + @(Get-OverlayStatus $selection $lock))
    $drift = @($status | Where-Object state -eq 'drifted')
    $runtimeReport = @(Get-RuntimeEnvironmentReport $catalog)
    $doctorWarnings = [Collections.Generic.List[string]]::new()
    foreach ($warning in @($catalogCheck.warnings)) { $doctorWarnings.Add([string]$warning) }
    foreach ($runtime in @($runtimeReport | Where-Object { -not $_.configRootExists })) {
        $doctorWarnings.Add("Runtime $($runtime.id) config root does not exist: $($runtime.configRoot)")
    }
    foreach ($runtime in @($runtimeReport | Where-Object { -not $_.commandAvailable })) {
        $doctorWarnings.Add("Runtime $($runtime.id) command is not on PATH: $($runtime.command)")
    }
    foreach ($blockedAsset in @($selection.blocked)) {
        $doctorWarnings.Add("Asset $($blockedAsset.id) supports none of the selected runtimes: $(Get-RuntimeBlockSummary $blockedAsset.blocked)")
    }
    $result = [pscustomobject]@{
        valid = $catalogCheck.errors.Count -eq 0 -and $drift.Count -eq 0
        errors = $catalogCheck.errors
        warnings = @($doctorWarnings)
        drift = $drift
        selectedRuntimes = $selection.runtimeIds
        runtimes = $runtimeReport
        sharedPaths = @(Get-RuntimeSharedPathReport $catalog)
        blocked = @($selection.blocked)
        catalog = $CatalogPath
        lock = $lockPath
    }
    Write-Result $result
    if (-not $result.valid) { $script:AssetActionExitCode = 1 }
    return
}

if ($Action -eq 'remove') {
    $selectedIds = @($selection.assets | ForEach-Object { $_.id })
    $selectedOverlayIds = @($selection.overlayIds)
    $selectedOverlayIds += @($lock.overlays | Where-Object {
        $catalogOverlay = @($catalog.overlays | Where-Object id -eq $_.id) | Select-Object -First 1
        $dependencies = if ($catalogOverlay -and $catalogOverlay.PSObject.Properties['dependsOn']) { @($catalogOverlay.dependsOn) } else { @() }
        ($selectedIds -contains $_.targetAssetId) -or
            (@($dependencies | Where-Object { $selectedIds -contains $_ }).Count -gt 0)
    } | ForEach-Object { $_.id })
    $selectedOverlayIds = @($selectedOverlayIds | Select-Object -Unique)
    $remainingOverlayIds = @($lock.overlays | Where-Object { $selectedOverlayIds -notcontains $_.id } | ForEach-Object { $_.id })
    $remainingOverlays = @($catalog.overlays | Where-Object { $remainingOverlayIds -contains $_.id })
    $remainingDependencies = @($remainingOverlays | ForEach-Object {
        if ($_.PSObject.Properties['dependsOn']) { @($_.dependsOn) }
    } | Select-Object -Unique)
    $removedOverlayDependencies = @($catalog.overlays | Where-Object { $selectedOverlayIds -contains $_.id } | ForEach-Object {
        if ($_.PSObject.Properties['dependsOn']) { @($_.dependsOn) }
    } | Where-Object { $remainingDependencies -notcontains $_ })
    $selectedIds = @($selectedIds + $removedOverlayDependencies | Select-Object -Unique)
    if ($selectedIds.Count -eq 0 -and $selectedOverlayIds.Count -eq 0) {
        throw 'No managed assets or Overlays selected for removal.'
    }
    Test-SelectedOverlays $remainingOverlays $projectRootResolved $lock
    $remaining = [Collections.Generic.List[object]]::new()
    foreach ($entry in @($lock.assets)) {
        if ($selectedIds -contains $entry.id) {
            Remove-LockedAsset $catalog $entry $Scope $projectRootResolved
        }
        else {
            $remaining.Add($entry)
        }
    }
    $lock.assets = @($remaining)
    $overlayResult = Install-SelectedOverlays $catalog $remainingOverlays $projectRootResolved $lock
    $lock.overlays = @($overlayResult.overlays)
    $lock.overlayOutputs = @($overlayResult.outputs)
    $lock.profiles = @($lock.profiles | Where-Object { $selection.profiles -notcontains $_ })
    Save-AssetLock $lockPath $lock
    if ($Scope -eq 'project') {
        $manifest = Get-ProjectManifest $projectRootResolved
        if ($manifest) {
            $manifestProfiles = @($manifest.profiles)
            $profileAssetIds = @($catalog.assets | Where-Object {
                @($_.profiles | Where-Object { $manifestProfiles -contains $_ }).Count -gt 0
            } | ForEach-Object { $_.id })
            $manifestExclude = @($manifest.exclude)
            $manifestExclude += @($selectedIds | Where-Object { $profileAssetIds -contains $_ })
            Save-ProjectManifest $projectRootResolved ([pscustomobject]@{
                profiles = $manifestProfiles
                assetIds = @($manifest.assets | Where-Object { $selectedIds -notcontains $_ })
                exclude = @($manifestExclude | Select-Object -Unique)
                overlayIds = @($manifest.overlays | Where-Object { $selectedOverlayIds -notcontains $_ })
                runtimeIds = @($manifest.runtimes)
            })
        }
    }
    Write-Result ([pscustomobject]@{ removed = $selectedIds; removedOverlays = $selectedOverlayIds; lockPath = $lockPath })
    return
}

if ($Action -ne 'apply') {
    throw "Unsupported action: $Action"
}

$selectedIds = @($selection.assets | ForEach-Object { $_.id })
$managedIds = @($lock.assets | ForEach-Object { $_.id })
foreach ($asset in @($selection.assets)) {
    if (-not $asset.PSObject.Properties['conflictsWith']) {
        continue
    }
    foreach ($conflict in @($asset.conflictsWith)) {
        if (($selectedIds -contains $conflict) -or (($managedIds -contains $conflict) -and ($selectedIds -notcontains $conflict))) {
            throw "Asset $($asset.id) conflicts with managed asset $conflict. Remove it first."
        }
    }
}

if ($selection.assets.Count -eq 0 -and $selection.overlays.Count -eq 0) {
    throw 'No assets selected. Supply -Profiles/-Assets or create .opencode/assets.json.'
}

foreach ($overlay in @($selection.overlays)) {
    if ($selectedIds -notcontains $overlay.targetAssetId -and $managedIds -notcontains $overlay.targetAssetId) {
        throw "Overlay $($overlay.id) requires managed asset $($overlay.targetAssetId)."
    }
}
Test-SelectedOverlays @($selection.overlays) $projectRootResolved $lock

$updatedEntries = [Collections.Generic.List[object]]::new()
foreach ($entry in @($lock.assets)) {
    if ($selectedIds -notcontains $entry.id) {
        $updatedEntries.Add($entry)
    }
}

foreach ($asset in @($selection.assets)) {
    $targetRuntimes = @(Get-AssetTargetRuntimes $selection $asset)
    $targetRuntimeIds = @($targetRuntimes | ForEach-Object { $_.id })
    Write-Host "Applying asset: $($asset.id) [$($asset.channel)] -> runtimes: $($targetRuntimeIds -join ', ')"
    $entry = switch ($asset.channel) {
        'skills-cli' { Install-SkillsCliAsset $catalog $asset $Scope $projectRootResolved; break }
        'copy-template' { Install-CopyTemplateAsset $asset $Scope $projectRootResolved $lock $targetRuntimes $catalog; break }
        'junction' { Install-JunctionAsset $asset $projectRootResolved $lock; break }
        'git-allowlist' { Install-GitAllowlistAsset $asset $projectRootResolved $lock; break }
        'opencode-plugin' { Install-OpenCodePluginAsset $asset $Scope $projectRootResolved $lock $targetRuntimes $catalog; break }
        'opencode-mcp' { Install-OpenCodeMcpAsset $asset $Scope $projectRootResolved $lock; break }
        'npm-framework' { Install-NpmFrameworkAsset $asset $Scope $projectRootResolved $lock; break }
        'claude-marketplace' { Install-MarketplaceAsset $catalog $asset; break }
        'provenance-only' { throw "Asset $($asset.id) is provenance-only and cannot be applied." }
        default { throw "Unsupported asset channel: $($asset.channel)" }
    }
    $entry | Add-Member -NotePropertyName runtimes -NotePropertyValue $targetRuntimeIds -Force
    $entry | Add-Member -NotePropertyName contentHash -NotePropertyValue (Get-PathsFingerprint @($entry.installedPaths)) -Force
    $updatedEntries.Add($entry)
}

$overlayResult = Install-SelectedOverlays $catalog @($selection.overlays) $projectRootResolved $lock

$runtimeRoots = [pscustomobject]@{}
foreach ($runtime in @(Get-RuntimeTable $catalog)) {
    Set-ObjectProperty $runtimeRoots $runtime.id $runtime.configRoot
}
$lock.scope = $Scope
$lock.projectRoot = if ($Scope -eq 'project') { $projectRootResolved } else { $null }
$lock.runtimeRoots = $runtimeRoots
$lock.profiles = @($selection.profiles)
$lock.assets = @($updatedEntries)
$lock.overlays = @($overlayResult.overlays)
$lock.overlayOutputs = @($overlayResult.outputs)
Save-AssetLock $lockPath $lock
if ($Scope -eq 'project') { Save-ProjectManifest $projectRootResolved $selection }
Write-Result ([pscustomobject]@{
    applied = @($selection.assets | ForEach-Object { $_.id })
    profiles = $selection.profiles
    overlays = @($selection.overlays | ForEach-Object { $_.id })
    scope = $Scope
    runtimes = $selection.runtimeIds
    skipped = @($selection.blocked | ForEach-Object {
        [pscustomobject]@{ id = $_.id; reason = Get-RuntimeBlockSummary $_.blocked }
    })
    lockPath = $lockPath
})
}

function Start-AssetManagerSession {
    param([Parameter(Mandatory = $true)]$ResolvedCatalog)

    while ($true) {
        if (-not (Start-AssetManagerTui $ResolvedCatalog)) { return }
        try {
            Invoke-AssetManagerAction $ResolvedCatalog
        }
        catch {
            $script:AssetActionExitCode = 1
            Write-Host
            Write-Host "操作失敗：$($_.Exception.Message)" -ForegroundColor Red
        }
        Wait-TuiContinue
    }
}

$catalog = Get-Catalog
$actionWasProvided = $PSBoundParameters.ContainsKey('Action')
if (-not $actionWasProvided -and -not $Json -and (Test-InteractiveTerminal)) {
    Start-AssetManagerSession $catalog
    exit 0
}

if (-not $actionWasProvided) { $Action = 'status' }
Invoke-AssetManagerAction $catalog
exit $script:AssetActionExitCode
