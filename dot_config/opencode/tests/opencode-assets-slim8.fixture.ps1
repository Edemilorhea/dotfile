param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$script:SkillNames = @(
    'simplify',
    'codemap',
    'clonedeps',
    'deepwork',
    'verification-planning',
    'reflect',
    'oh-my-opencode-slim',
    'worktrees'
)

function Assert-True {
    param([Parameter(Mandatory = $true)][bool]$Condition, [Parameter(Mandatory = $true)][string]$Message)

    if (-not $Condition) { throw $Message }
}

function Invoke-Manager {
    param(
        [Parameter(Mandatory = $true)][string]$ManagerPath,
        [Parameter(Mandatory = $true)][string]$FixtureHome,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $quotedHome = $FixtureHome.Replace("'", "''")
    $quotedManager = $ManagerPath.Replace("'", "''")
    $quotedArguments = @($Arguments | ForEach-Object {
        if ($_.StartsWith('-')) { $_ } else { "'$($_.Replace("'", "''"))'" }
    })
    $command = "Set-Variable -Name HOME -Value '$quotedHome' -Force; & '$quotedManager' $($quotedArguments -join ' ')"
    $output = @(& pwsh -NoLogo -NoProfile -NonInteractive -Command $command 2>&1)
    return [pscustomobject]@{ exitCode = $LASTEXITCODE; output = $output }
}

$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) "opencode-slim8-fixture-$([guid]::NewGuid())"
$fixtureHome = Join-Path $fixtureRoot 'home'
$repository = Join-Path $fixtureRoot 'repository'
$project = Join-Path $fixtureRoot 'project'
$catalogPath = Join-Path $fixtureRoot 'catalog.json'
$managerPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\scripts\opencode-assets.ps1'))

New-Item -ItemType Directory -Path $fixtureHome, $repository, $project | Out-Null
try {
    foreach ($name in $script:SkillNames) {
        $skillPath = Join-Path $repository "src\skills\$name"
        New-Item -ItemType Directory -Path $skillPath -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $skillPath 'SKILL.md') -Value "---`nname: $name`ndescription: Fixture skill.`n---`n" -Encoding utf8 -NoNewline
    }
    & git init --quiet $repository
    & git -C $repository config user.email fixture@example.invalid
    & git -C $repository config user.name Fixture
    & git -C $repository add src
    & git -C $repository commit --quiet -m fixture
    $revision = (& git -C $repository rev-parse HEAD).Trim()

    $overlaySource = Join-Path $fixtureHome '.config\opencode\config\assets\fixture-overlay.md'
    New-Item -ItemType Directory -Path (Split-Path -Parent $overlaySource) -Force | Out-Null
    Set-Content -LiteralPath $overlaySource -Value 'fixture overlay' -Encoding utf8
    $catalog = [ordered]@{
        schemaVersion = 4
        managerVersion = '1.7.0'
        defaultProfiles = @()
        installers = [ordered]@{}
        profiles = [ordered]@{
            'oh-my-opencode-slim' = [ordered]@{ description = 'Fixture'; defaultScope = 'project' }
        }
        overlays = @([ordered]@{
            id = 'fixture-overlay'
            name = 'Fixture overlay'
            description = 'Fixture'
            targetAssetId = 'oh-my-opencode-slim'
            targetKind = 'agent-prompt'
            targetName = 'orchestrator'
            profiles = @()
            scopes = @('project')
            sourcePath = '~/.config/opencode/config/assets/fixture-overlay.md'
            priority = 1
        })
        assets = @([ordered]@{
            id = 'oh-my-opencode-slim'
            type = 'opencode-framework'
            channel = 'opencode-plugin'
            profiles = @('oh-my-opencode-slim')
            scopes = @('project')
            defaultScope = 'project'
            repository = $repository
            revision = $revision
            package = 'oh-my-opencode-slim'
            packageVersion = '2.2.10'
            pluginSpec = 'oh-my-opencode-slim@2.2.10'
            skills = @($script:SkillNames)
            bundledSkillsPath = 'src/skills'
            projectSkillsPath = '.opencode/skills'
            globalSkillsPath = '~/.config/opencode/skills'
            globalSkillsManifestPath = '~/.config/opencode/.oh-my-opencode-slim/skills-manifest.json'
            globalSkillsBackupPath = '~/.local/state/opencode/slim8-skills-isolation-backups'
            configPath = '.opencode/opencode.json'
            conflictsWith = @('gsd')
        })
    }
    $catalog | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $catalogPath -Encoding utf8

    $globalSkills = Join-Path $fixtureHome '.config\opencode\skills'
    New-Item -ItemType Directory -Path $globalSkills -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repository 'src\skills\simplify') -Destination (Join-Path $globalSkills 'simplify') -Recurse
    $customPath = Join-Path $globalSkills 'codemap'
    New-Item -ItemType Directory -Path $customPath | Out-Null
    Set-Content -LiteralPath (Join-Path $customPath 'SKILL.md') -Value 'customized' -Encoding utf8
    $manifestPath = Join-Path $fixtureHome '.config\opencode\.oh-my-opencode-slim\skills-manifest.json'
    New-Item -ItemType Directory -Path (Split-Path -Parent $manifestPath) -Force | Out-Null
    [ordered]@{
        schemaVersion = 1
        updatedAt = '2026-01-01T00:00:00.000Z'
        skills = [ordered]@{
            simplify = [ordered]@{
                status = 'managed'
                packageVersion = '2.2.10'
                sourceHash = ''
                lastManagedHash = ''
                lastSeenHash = ''
                updatedAt = '2026-01-01T00:00:00.000Z'
            }
        }
    } | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $manifestPath -Encoding utf8

    $migration = Invoke-Manager $managerPath $fixtureHome @(
        'slim8-migration', '-MigrationMode', 'apply', '-CatalogPath', $catalogPath, '-ProjectRoot', $project, '-Json'
    )
    Assert-True ($migration.exitCode -eq 0) "Migration failed: $($migration.output -join "`n")"
    foreach ($name in $script:SkillNames) {
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $globalSkills $name))) "Global skill was not removed: $name"
    }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    foreach ($name in $script:SkillNames) {
        Assert-True ($manifest.skills.PSObject.Properties[$name].Value.status -eq 'deleted') "Missing tombstone: $name"
    }
    $backupRoot = Join-Path $fixtureHome '.local\state\opencode\slim8-skills-isolation-backups'
    $backups = @(Get-ChildItem -LiteralPath $backupRoot -Directory)
    Assert-True ($backups.Count -eq 1) 'Expected exactly one migration backup.'
    $backupPath = $backups[0].FullName
    Assert-True (Test-Path -LiteralPath (Join-Path $backupPath 'skills\simplify\SKILL.md')) 'Managed skill backup is missing.'
    Assert-True (Test-Path -LiteralPath (Join-Path $backupPath 'skills\codemap\SKILL.md')) 'Customized skill backup is missing.'

    $apply = Invoke-Manager $managerPath $fixtureHome @(
        'apply', '-Scope', 'project', '-Assets', 'oh-my-opencode-slim', '-CatalogPath', $catalogPath, '-ProjectRoot', $project, '-Json'
    )
    Assert-True ($apply.exitCode -eq 0) "Project apply failed: $($apply.output -join "`n")"
    foreach ($name in $script:SkillNames) {
        Assert-True (Test-Path -LiteralPath (Join-Path $project ".opencode\skills\$name\SKILL.md")) "Project skill is missing: $name"
    }
    $lockPath = Join-Path $project '.opencode\assets.lock.json'
    $lock = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
    $entry = @($lock.assets | Where-Object id -eq 'oh-my-opencode-slim')[0]
    Assert-True (@($entry.installedPaths).Count -eq 8) 'Lock does not record all installed paths.'
    Assert-True (@($entry.installedPathHashes).Count -eq 8) 'Lock does not record all installed path hashes.'

    Add-Content -LiteralPath (Join-Path $project '.opencode\skills\simplify\SKILL.md') -Value 'drift'
    $status = Invoke-Manager $managerPath $fixtureHome @(
        'status', '-Scope', 'project', '-Assets', 'oh-my-opencode-slim', '-CatalogPath', $catalogPath, '-ProjectRoot', $project, '-Json'
    )
    Assert-True ($status.exitCode -eq 0) "Status failed: $($status.output -join "`n")"
    $statusJson = ($status.output -join "`n") | ConvertFrom-Json
    Assert-True ($statusJson.state -eq 'drifted') 'Status did not report project skill drift.'
    $removeDrifted = Invoke-Manager $managerPath $fixtureHome @(
        'remove', '-Scope', 'project', '-Assets', 'oh-my-opencode-slim', '-CatalogPath', $catalogPath, '-ProjectRoot', $project, '-Json'
    )
    Assert-True ($removeDrifted.exitCode -ne 0) 'Removal unexpectedly deleted a drifted project skill.'
    Assert-True (Test-Path -LiteralPath (Join-Path $project '.opencode\skills\simplify')) 'Drifted project skill was removed.'

    Remove-Item -LiteralPath (Join-Path $project '.opencode\skills\simplify') -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $repository 'src\skills\simplify') -Destination (Join-Path $project '.opencode\skills\simplify') -Recurse
    $remove = Invoke-Manager $managerPath $fixtureHome @(
        'remove', '-Scope', 'project', '-Assets', 'oh-my-opencode-slim', '-CatalogPath', $catalogPath, '-ProjectRoot', $project, '-Json'
    )
    Assert-True ($remove.exitCode -eq 0) "Removal failed: $($remove.output -join "`n")"
    foreach ($name in $script:SkillNames) {
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $project ".opencode\skills\$name"))) "Owned project skill was not removed: $name"
    }

    $restore = Invoke-Manager $managerPath $fixtureHome @(
        'slim8-migration', '-MigrationMode', 'restore', '-BackupPath', $backupPath, '-CatalogPath', $catalogPath, '-ProjectRoot', $project, '-Json'
    )
    Assert-True ($restore.exitCode -eq 0) "Restore failed: $($restore.output -join "`n")"
    Assert-True (Test-Path -LiteralPath (Join-Path $globalSkills 'simplify\SKILL.md')) 'Managed global skill was not restored.'
    Assert-True ((Get-Content -LiteralPath (Join-Path $globalSkills 'codemap\SKILL.md') -Raw).Trim() -eq 'customized') 'Customized global skill was not restored.'
    $restoredManifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    Assert-True ($restoredManifest.skills.simplify.status -eq 'managed') 'Original manifest was not restored.'
    Write-Output 'PASS: Slim8 project isolation fixture'
}
finally {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
}
