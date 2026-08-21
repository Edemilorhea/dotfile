param(
    [Parameter(Position = 0)]
    [ValidateSet('list', 'profiles', 'plan', 'apply', 'status', 'remove', 'doctor')]
    [string]$Action,

    [ValidateSet('global', 'project')]
    [string]$Scope = 'project',

    [string[]]$Profiles = @(),
    [string[]]$Assets = @(),
    [string[]]$Exclude = @(),
    [string[]]$Overlays = @(),
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$CatalogPath = (Join-Path $HOME '.config\opencode\config\external-assets.json'),
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$script:ManagerVersion = '1.5.0'
$script:TuiExplicitSelection = $false
$script:AssetSelectionExplicit = $PSBoundParameters.ContainsKey('Assets')
$script:OverlaySelectionExplicit = $PSBoundParameters.ContainsKey('Overlays')
$script:TuiBackValue = '__tui_back__'
$script:TuiProjectRoot = [IO.Path]::GetFullPath((Get-Location).Path)

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
        [bool]$Installed = $false
    )

    return [pscustomobject]@{ label = $Label; value = $Value; description = $Description; installed = $Installed }
}

function Format-TuiItemList {
    param([object[]]$Items, [int]$Maximum = 4)

    $values = @($Items | Where-Object { $_ } | ForEach-Object { [string]$_ })
    if ($values.Count -le $Maximum) { return $values -join ', ' }
    return "$(@($values | Select-Object -First $Maximum) -join ', ') 等 $($values.Count) 項"
}

function Get-TuiItemKind {
    param([Parameter(Mandatory = $true)]$Item)

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
            '↑/↓：移動  Space：選取  Enter：繼續  x：已安裝在目前位置'
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
            $marker = if ($MultiSelect) {
                if ($selected.Contains([string]$option.value)) { '[x]' } else { '[ ]' }
            }
            else { '   ' }
            $installedMarker = if ($option.installed) { 'x' } else { ' ' }
            $color = if ($index -eq $current) { 'Yellow' } else { 'Gray' }
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
                if ($MultiSelect) {
                    $value = [string]$Options[$current].value
                    if (-not $selected.Remove($value)) { [void]$selected.Add($value) }
                }
            }
            'Enter' {
                if (-not $MultiSelect) { return $Options[$current].value }
                if ($selected.Count -gt 0 -or $AllowEmpty) {
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
            $globalItemCount = @($Catalog.assets | Where-Object { @($_.scopes) -contains 'global' }).Count
            $projectItemCount = @($Catalog.assets | Where-Object { @($_.scopes) -contains 'project' }).Count
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
            $suggestedProfiles = if ($manifest) { @($manifest.profiles) }
                elseif (@($tuiLock.profiles).Count -gt 0) { @($tuiLock.profiles) }
                elseif ($Scope -eq 'global') { @($Catalog.defaultProfiles) }
                else { @() }
            $availableItems = @($Catalog.assets | Where-Object { @($_.scopes) -contains $Scope })
            $profileOptions = @($Catalog.profiles.PSObject.Properties | ForEach-Object {
                $profileName = $_.Name
                $profileAssets = @($availableItems | Where-Object { @($_.profiles) -contains $profileName })
                $profileItems = @($profileAssets | ForEach-Object {
                    $installedPrefix = if ($installedIds -contains $_.id) { 'x ' } else { '  ' }
                    "$installedPrefix$(Get-TuiItemKind $_)：$($_.id)"
                })
                if ($profileItems.Count -gt 0) {
                    $profileInstalled = @($profileAssets | Where-Object { $installedIds -notcontains $_.id }).Count -eq 0
                    New-TuiOption $profileName $profileName "包含：$(Format-TuiItemList $profileItems 10)" $profileInstalled
                }
            })
            $availableProfileNames = @($profileOptions | ForEach-Object { $_.value })
            $suggestedProfiles = @($suggestedProfiles | Where-Object { $availableProfileNames -contains $_ })
            $itemOptions = @($availableItems | ForEach-Object {
                New-TuiOption "[$(Get-TuiItemKind $_)] $($_.id)" $_.id (Get-TuiItemDescription $_) ($installedIds -contains $_.id)
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
                if ($selectionMode -eq $script:TuiBackValue) { continue scope }
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
                $resolvedSelection = Get-Selections $Catalog $Scope $resolvedRoot
                $availableOverlays = if ($Scope -eq 'project') {
                    @($Catalog.overlays | Where-Object {
                        @($_.scopes) -contains $Scope -and @($resolvedSelection.assets.id) -contains $_.targetAssetId
                    })
                }
                else { @() }
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
                    if (-not (Confirm-TuiAction "確定要將選取內容套用到${scopeLabel}嗎？")) { continue selection }
                }
                return $true
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

function Resolve-TargetPath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ResolvedScope,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot
    )

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
    if ($schemaVersion -ne 4) {
        throw "Unsupported asset catalog schema: $schemaVersion"
    }
    return $catalog
}

function Get-ProjectManifest {
    param([Parameter(Mandatory = $true)][string]$ResolvedProjectRoot)

    $path = Join-Path $ResolvedProjectRoot '.opencode\assets.json'
    if (-not (Test-Path -LiteralPath $path)) {
        return $null
    }
    $manifest = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    $schemaVersion = if ($manifest.PSObject.Properties['schemaVersion']) { $manifest.schemaVersion } else { '<missing>' }
    if ($schemaVersion -notin @(1, 2)) {
        throw "Unsupported project asset manifest schema: $schemaVersion"
    }
    foreach ($propertyName in @('profiles', 'assets', 'exclude', 'overlays')) {
        if (-not $manifest.PSObject.Properties[$propertyName]) {
            $manifest | Add-Member -NotePropertyName $propertyName -NotePropertyValue @()
        }
    }
    $manifest.schemaVersion = 2
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
            schemaVersion = 2
            profiles = @()
            assets = @()
            exclude = @()
            overlays = @()
        }
    }
    Set-ObjectProperty $manifest 'schemaVersion' 2
    Set-ObjectProperty $manifest 'profiles' @($Selection.profiles)
    Set-ObjectProperty $manifest 'assets' @($Selection.assetIds)
    Set-ObjectProperty $manifest 'exclude' @($Selection.exclude)
    Set-ObjectProperty $manifest 'overlays' @($Selection.overlayIds)
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
        return Join-Path $HOME '.config\opencode\config\assets.lock.json'
    }
    return Join-Path $ResolvedProjectRoot '.opencode\assets.lock.json'
}

function Get-AssetLock {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{
            schemaVersion = 2
            managerVersion = $script:ManagerVersion
            generatedAt = $null
            scope = $Scope
            projectRoot = if ($Scope -eq 'project') { $ProjectRoot } else { $null }
            profiles = @()
            assets = @()
            overlays = @()
            overlayOutputs = @()
        }
    }
    $lock = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    $schemaVersion = if ($lock.PSObject.Properties['schemaVersion']) { $lock.schemaVersion } else { '<missing>' }
    if ($schemaVersion -notin @(1, 2)) {
        throw "Unsupported asset lock schema: $schemaVersion"
    }
    $defaults = [ordered]@{
        managerVersion = $script:ManagerVersion
        generatedAt = $null
        scope = $Scope
        projectRoot = if ($Scope -eq 'project') { $ProjectRoot } else { $null }
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
    $lock.schemaVersion = 2
    return $lock
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
    $Lock.schemaVersion = 2
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

    return [pscustomobject]@{
        profiles = $selectedProfiles
        assetIds = $selectedAssets
        exclude = $excludedAssets
        assets = @($resolved)
        overlayIds = $selectedOverlays
        overlays = @($resolvedOverlays)
    }
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

function Install-CopyTemplateAsset {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)][string]$ResolvedScope,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot,
        [Parameter(Mandatory = $true)]$ExistingLock
    )

    $ownedPaths = @($ExistingLock.assets | Where-Object { $_.id -eq $Asset.id } | ForEach-Object { $_.installedPaths })
    $mappings = [Collections.Generic.List[object]]::new()
    if ($Asset.PSObject.Properties['files']) {
        foreach ($file in @($Asset.files)) {
            $source = [IO.Path]::GetFullPath((Resolve-HomePath $file.source))
            $target = Resolve-TargetPath $file.target $ResolvedScope $ResolvedProjectRoot
            $mappings.Add([pscustomobject]@{ source = $source; target = $target })
        }
    }
    else {
        $source = [IO.Path]::GetFullPath((Resolve-HomePath $Asset.sourcePath))
        $target = Resolve-TargetPath $Asset.targetPath $ResolvedScope $ResolvedProjectRoot
        $mappings.Add([pscustomobject]@{ source = $source; target = $target })
    }
    foreach ($mapping in @($mappings)) {
        if (-not (Test-Path -LiteralPath $mapping.source)) {
            throw "Managed asset source not found: $($mapping.source)"
        }
        if ((Test-Path -LiteralPath $mapping.target) -and $ownedPaths -notcontains $mapping.target) {
            throw "Refusing to overwrite an unmanaged asset path: $($mapping.target)"
        }
    }
    foreach ($mapping in @($mappings)) {
        Copy-ManagedPath $mapping.source $mapping.target ($ownedPaths -contains $mapping.target)
    }
    return [pscustomobject]@{
        id = $Asset.id
        channel = $Asset.channel
        revision = $null
        skills = @()
        installedPaths = @($mappings.target)
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

function Install-OpenCodePluginAsset {
    param(
        [Parameter(Mandatory = $true)]$Asset,
        [Parameter(Mandatory = $true)][string]$ResolvedScope,
        [Parameter(Mandatory = $true)][string]$ResolvedProjectRoot
    )

    if ($ResolvedScope -ne 'project') {
        throw "OpenCode plugin asset $($Asset.id) is project-only."
    }
    $configPath = Resolve-TargetPath $Asset.configPath $ResolvedScope $ResolvedProjectRoot
    $config = Get-JsonConfig $configPath
    [string[]]$plugins = @()
    if ($config.PSObject.Properties['plugin']) {
        $plugins = @($config.plugin)
    }
    if ($plugins -notcontains $Asset.pluginSpec) {
        $plugins += $Asset.pluginSpec
    }
    if ($config.PSObject.Properties['plugin']) {
        $config.plugin = @($plugins)
    }
    else {
        $config | Add-Member -NotePropertyName plugin -NotePropertyValue @($plugins)
    }
    Save-JsonConfig $configPath $config

    return [pscustomobject]@{
        id = $Asset.id
        channel = $Asset.channel
        revision = $Asset.revision
        packageVersion = $Asset.packageVersion
        skills = @()
        installedPaths = @()
        configPath = $configPath
        pluginSpecs = @($Asset.pluginSpec)
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

    if ($Entry.channel -eq 'opencode-plugin') {
        $config = Get-JsonConfig $Entry.configPath
        [string[]]$plugins = @()
        if ($config.PSObject.Properties['plugin']) {
            $plugins = @($config.plugin)
        }
        $config.plugin = @($plugins | Where-Object { @($Entry.pluginSpecs) -notcontains $_ })
        Save-JsonConfig $Entry.configPath $config
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

    $allowedRoots = if ($ResolvedScope -eq 'global') {
        @((Join-Path $HOME '.config\opencode'), (Join-Path $HOME '.agents'))
    }
    else {
        @((Join-Path $ResolvedProjectRoot '.opencode'), (Join-Path $ResolvedProjectRoot '.agents'))
    }
    foreach ($path in @($Entry.installedPaths)) {
        if (-not (@($allowedRoots | Where-Object { Test-PathWithinRoot $path $_ }).Count -gt 0)) {
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
        if ($asset.channel -in @('skills-cli', 'git-allowlist', 'opencode-plugin', 'npm-framework') -and [string]::IsNullOrWhiteSpace($asset.revision)) {
            $errors.Add("Network asset $($asset.id) requires a pinned revision.")
        }
        if ($asset.channel -in @('opencode-plugin', 'npm-framework') -and [string]::IsNullOrWhiteSpace($asset.packageVersion)) {
            $errors.Add("Package asset $($asset.id) requires a pinned packageVersion.")
        }
        if ($asset.channel -eq 'npm-framework') {
            foreach ($propertyName in @('installArguments', 'manifestFile', 'versionFile', 'expectedVersion')) {
                if (-not $asset.PSObject.Properties[$propertyName]) {
                    $errors.Add("NPM framework asset $($asset.id) requires $propertyName.")
                }
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
    $overlayIds = @($Catalog.overlays.id)
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
        [Parameter(Mandatory = $true)]$Lock
    )

    $rows = foreach ($asset in @($Selection.assets)) {
        $entry = @($Lock.assets | Where-Object { $_.id -eq $asset.id }) | Select-Object -First 1
        $paths = if ($entry) { @($entry.installedPaths) } else { @() }
        $missing = @($paths | Where-Object { -not (Test-Path -LiteralPath $_) })
        $fingerprintChanged = $false
        $pluginChanged = $false
        $frameworkConfigChanged = $false
        if ($entry -and $entry.channel -eq 'opencode-plugin') {
            try {
                $pluginConfig = Get-JsonConfig $entry.configPath
                [string[]]$configuredPlugins = @()
                if ($pluginConfig.PSObject.Properties['plugin']) {
                    $configuredPlugins = @($pluginConfig.plugin)
                }
                $pluginChanged = @($entry.pluginSpecs | Where-Object { $configuredPlugins -notcontains $_ }).Count -gt 0
            }
            catch {
                $pluginChanged = $true
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
        if ($entry -and $missing.Count -eq 0 -and $entry.PSObject.Properties['contentHash'] -and $entry.contentHash) {
            $fingerprintChanged = (Get-PathsFingerprint $paths) -ne $entry.contentHash
        }
        [pscustomobject]@{
            id = $asset.id
            kind = 'asset'
            channel = $asset.channel
            state = if (-not $entry) { 'not-managed' } elseif ($missing.Count -gt 0 -or $fingerprintChanged -or $pluginChanged -or $frameworkConfigChanged) { 'drifted' } else { 'installed' }
            missingPaths = $missing
            contentChanged = $fingerprintChanged -or $pluginChanged -or $frameworkConfigChanged
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
    $assetRows = @($catalog.assets | Select-Object id, @{ Name = 'kind'; Expression = { 'asset' } }, type, channel, profiles, scopes, defaultScope, revision)
    $overlayRows = @($catalog.overlays | Select-Object id, @{ Name = 'kind'; Expression = { 'overlay' } }, targetKind, targetAssetId, targetName, profiles, scopes, priority)
    Write-Result @($assetRows + $overlayRows)
    return
}

if ($catalogCheck.errors.Count -gt 0) {
    throw "Invalid asset catalog:`n$($catalogCheck.errors -join "`n")"
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
        projectRoot = if ($Scope -eq 'project') { $projectRootResolved } else { $null }
        profiles = $selection.profiles
        assets = @($selection.assets | Select-Object id, type, channel, revision)
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
    Write-Result @(@(Get-Status $selection $lock) + @(Get-OverlayStatus $selection $lock))
    return
}

if ($Action -eq 'doctor') {
    $status = @(@(Get-Status $selection $lock) + @(Get-OverlayStatus $selection $lock))
    $drift = @($status | Where-Object state -eq 'drifted')
    $result = [pscustomobject]@{
        valid = $catalogCheck.errors.Count -eq 0 -and $drift.Count -eq 0
        errors = $catalogCheck.errors
        warnings = $catalogCheck.warnings
        drift = $drift
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
    Write-Host "Applying asset: $($asset.id) [$($asset.channel)]"
    $entry = switch ($asset.channel) {
        'skills-cli' { Install-SkillsCliAsset $catalog $asset $Scope $projectRootResolved; break }
        'copy-template' { Install-CopyTemplateAsset $asset $Scope $projectRootResolved $lock; break }
        'junction' { Install-JunctionAsset $asset $projectRootResolved $lock; break }
        'git-allowlist' { Install-GitAllowlistAsset $asset $projectRootResolved $lock; break }
        'opencode-plugin' { Install-OpenCodePluginAsset $asset $Scope $projectRootResolved; break }
        'npm-framework' { Install-NpmFrameworkAsset $asset $Scope $projectRootResolved $lock; break }
        'claude-marketplace' { Install-MarketplaceAsset $catalog $asset; break }
        'provenance-only' { throw "Asset $($asset.id) is provenance-only and cannot be applied." }
        default { throw "Unsupported asset channel: $($asset.channel)" }
    }
    $entry | Add-Member -NotePropertyName contentHash -NotePropertyValue (Get-PathsFingerprint @($entry.installedPaths)) -Force
    $updatedEntries.Add($entry)
}

$overlayResult = Install-SelectedOverlays $catalog @($selection.overlays) $projectRootResolved $lock

$lock.scope = $Scope
$lock.projectRoot = if ($Scope -eq 'project') { $projectRootResolved } else { $null }
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
