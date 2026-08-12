param(
    [Parameter(Position = 0)]
    [ValidateSet('list', 'profiles', 'plan', 'apply', 'status', 'remove', 'doctor')]
    [string]$Action = 'status',

    [ValidateSet('global', 'project')]
    [string]$Scope = 'project',

    [string[]]$Profiles = @(),
    [string[]]$Assets = @(),
    [string[]]$Exclude = @(),
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$CatalogPath = (Join-Path $HOME '.config\opencode\config\external-assets.json'),
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$script:ManagerVersion = '1.2.0'

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
    if ($schemaVersion -ne 3) {
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
    if ($schemaVersion -ne 1) {
        throw "Unsupported project asset manifest schema: $schemaVersion"
    }
    return $manifest
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
            schemaVersion = 1
            managerVersion = $script:ManagerVersion
            generatedAt = $null
            scope = $Scope
            projectRoot = if ($Scope -eq 'project') { $ProjectRoot } else { $null }
            profiles = @()
            assets = @()
        }
    }
    $lock = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    $schemaVersion = if ($lock.PSObject.Properties['schemaVersion']) { $lock.schemaVersion } else { '<missing>' }
    if ($schemaVersion -ne 1) {
        throw "Unsupported asset lock schema: $schemaVersion"
    }
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

    if ($selectedProfiles.Count -eq 0 -and $manifest) {
        $selectedProfiles = @($manifest.profiles)
    }
    if ($selectedAssets.Count -eq 0 -and $manifest) {
        $selectedAssets = @($manifest.assets)
    }
    if ($excludedAssets.Count -eq 0 -and $manifest) {
        $excludedAssets = @($manifest.exclude)
    }
    if ($selectedProfiles.Count -eq 0 -and $ResolvedScope -eq 'global') {
        $selectedProfiles = @($Catalog.defaultProfiles)
    }

    $selectedProfiles = @($selectedProfiles | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique)
    $selectedAssets = @($selectedAssets | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique)
    $excludedAssets = @($excludedAssets | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique)

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

    $pendingDependencies = [Collections.Generic.Queue[string]]::new()
    foreach ($asset in @($resolved)) {
        if ($asset.PSObject.Properties['dependsOn']) {
            foreach ($dependency in @($asset.dependsOn)) {
                $pendingDependencies.Enqueue($dependency)
            }
        }
    }
    while ($pendingDependencies.Count -gt 0) {
        $dependency = $pendingDependencies.Dequeue()
        if (@($resolved.id) -contains $dependency) {
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
        $arguments += @('--yes', '--skill') + @($Asset.skills)
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

    $source = [IO.Path]::GetFullPath((Resolve-HomePath $Asset.sourcePath))
    $target = Resolve-TargetPath $Asset.targetPath $ResolvedScope $ResolvedProjectRoot
    $owned = @($ExistingLock.assets | Where-Object { $_.id -eq $Asset.id }).Count -gt 0
    Copy-ManagedPath $source $target $owned
    return [pscustomobject]@{
        id = $Asset.id
        channel = $Asset.channel
        revision = $null
        skills = @($Asset.id)
        installedPaths = @($target)
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
        if ($asset.channel -eq 'provenance-only') {
            $warnings.Add("Asset $($asset.id) is provenance-only and cannot be applied.")
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
            channel = $asset.channel
            state = if (-not $entry) { 'not-managed' } elseif ($missing.Count -gt 0 -or $fingerprintChanged -or $pluginChanged -or $frameworkConfigChanged) { 'drifted' } else { 'installed' }
            missingPaths = $missing
            contentChanged = $fingerprintChanged -or $pluginChanged -or $frameworkConfigChanged
        }
    }
    return @($rows)
}

$catalog = Get-Catalog
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
    exit 0
}

if ($Action -eq 'list') {
    Write-Result @($catalog.assets | Select-Object id, type, channel, profiles, scopes, defaultScope, revision)
    exit 0
}

if ($catalogCheck.errors.Count -gt 0) {
    throw "Invalid asset catalog:`n$($catalogCheck.errors -join "`n")"
}

$selection = Get-Selections $catalog $Scope $projectRootResolved
$lockPath = Get-LockPath $Scope $projectRootResolved
$lock = Get-AssetLock $lockPath

if ($Action -eq 'plan') {
    Write-Result ([pscustomobject]@{
        action = 'apply'
        scope = $Scope
        projectRoot = if ($Scope -eq 'project') { $projectRootResolved } else { $null }
        profiles = $selection.profiles
        assets = @($selection.assets | Select-Object id, type, channel, revision)
        lockPath = $lockPath
    })
    exit 0
}

if ($Action -eq 'status') {
    Write-Result (Get-Status $selection $lock)
    exit 0
}

if ($Action -eq 'doctor') {
    $status = @(Get-Status $selection $lock)
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
    if (-not $result.valid) { exit 1 }
    exit 0
}

if ($Action -eq 'remove') {
    $selectedIds = @($selection.assets.id)
    if ($selectedIds.Count -eq 0) {
        throw 'No managed assets selected for removal.'
    }
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
    $lock.profiles = @($lock.profiles | Where-Object { $selection.profiles -notcontains $_ })
    Save-AssetLock $lockPath $lock
    Write-Result ([pscustomobject]@{ removed = $selectedIds; lockPath = $lockPath })
    exit 0
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

if ($selection.assets.Count -eq 0) {
    throw 'No assets selected. Supply -Profiles/-Assets or create .opencode/assets.json.'
}

$updatedEntries = [Collections.Generic.List[object]]::new()
foreach ($entry in @($lock.assets)) {
    if (@($selection.assets.id) -notcontains $entry.id) {
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

$lock.scope = $Scope
$lock.projectRoot = if ($Scope -eq 'project') { $projectRootResolved } else { $null }
$lock.profiles = @($selection.profiles)
$lock.assets = @($updatedEntries)
Save-AssetLock $lockPath $lock
Write-Result ([pscustomobject]@{
    applied = @($selection.assets.id)
    profiles = $selection.profiles
    scope = $Scope
    lockPath = $lockPath
})
