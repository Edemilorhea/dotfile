#Requires -Version 7.0
<#
.SYNOPSIS
    Switch every OpenCode agent model to one subscription provider in a single step.

.DESCRIPTION
    Agent models live in three places: the global default and the `agent` block of
    opencode.json, the `model:` front matter of agent Markdown files, and the
    cross-provider failover lists in fallback.json.

    config/model-tiers.json records which agent belongs to which tier and which
    model each provider uses for that tier. This script rewrites all three places
    from that registry, so one command moves the whole set to a different provider.

    Edits are written to the chezmoi source state first and then applied to the
    live configuration, which keeps chezmoi authoritative.

.PARAMETER Provider
    'openai', 'anthropic', or 'status'. Default is 'status'.

.PARAMETER Tier
    Optional tier names to switch, for example T1 and T3. Default is every tier.

.PARAMETER NoApply
    Write the chezmoi source state but do not run `chezmoi apply`.

.EXAMPLE
    ./oc-model.ps1 status

.EXAMPLE
    ./oc-model.ps1 anthropic

.EXAMPLE
    ./oc-model.ps1 anthropic -Tier T1,T2
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Provider = 'status',

    [string[]]$Tier,

    [switch]$NoApply
)

$ErrorActionPreference = 'Stop'

# --- locate chezmoi source state -------------------------------------------

if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
    throw 'chezmoi was not found on PATH. This script edits the chezmoi source state.'
}

$targetRoot = Join-Path $HOME '.config/opencode'
$sourceRoot = (& chezmoi source-path $targetRoot | Select-Object -First 1).Trim()
if (-not (Test-Path -LiteralPath $sourceRoot)) {
    throw "chezmoi source path was not resolved: $sourceRoot"
}

$registryRel = 'config/model-tiers.json'
$registryPath = Join-Path $sourceRoot $registryRel
$registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json

$tierNames = @($registry.tiers.PSObject.Properties.Name)
$providers = @($registry.providers)

# --- helpers ----------------------------------------------------------------

function Read-Text([string]$Path) {
    return [System.IO.File]::ReadAllText($Path)
}

function Write-Text([string]$Path, [string]$Text) {
    # The chezmoi repository normalizes to LF (.gitattributes: * text=auto eol=lf).
    $Text = $Text -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Get-AgentMarkdown([string]$Root) {
    $agentDir = Join-Path $Root 'agent'
    if (-not (Test-Path -LiteralPath $agentDir)) { return @() }
    return @(Get-ChildItem -LiteralPath $agentDir -Recurse -File -Filter '*.md')
}

# --- status -----------------------------------------------------------------

if ($Provider -eq 'status') {
    $active = @(@($tierNames | ForEach-Object { $registry.tiers.$_.active }) | Sort-Object -Unique)
    $summary = if ($active.Count -eq 1) { $active[0] } else { "mixed ($($active -join ' + '))" }

    Write-Host ''
    Write-Host "Active provider: $summary"
    Write-Host ''
    foreach ($name in $tierNames) {
        $t = $registry.tiers.$name
        $flag = if ($t.globalDefault) { ' (global default)' } else { '' }
        Write-Host "$name - $($t.label)$flag"
        Write-Host "  active : $($t.active) -> $($t.models.($t.active))"
        foreach ($p in $providers) {
            if ($p -ne $t.active) { Write-Host "  other  : $p -> $($t.models.$p)" }
        }
        Write-Host "  agents : $($t.agents -join ', ')"
        Write-Host ''
    }
    Write-Host 'Switch with: ./oc-model.ps1 openai   |   ./oc-model.ps1 anthropic'
    Write-Host ''
    return
}

# --- validate ---------------------------------------------------------------

if ($Provider -notin $providers) {
    throw "Unknown provider '$Provider'. Known providers: $($providers -join ', '), or 'status'."
}

$selected = if ($Tier) { @($Tier) } else { $tierNames }
foreach ($name in $selected) {
    if ($name -notin $tierNames) {
        throw "Unknown tier '$name'. Known tiers: $($tierNames -join ', ')."
    }
}

# --- build the rewrite plan -------------------------------------------------

$plan = foreach ($name in $selected) {
    $t = $registry.tiers.$name
    $to = $t.models.$Provider
    if (-not $to) { throw "Tier $name has no model defined for provider '$Provider'." }

    $otherProvider = @($providers | Where-Object { $_ -ne $Provider })[0]
    [pscustomobject]@{
        Name   = $name
        To     = $to
        Other  = $t.models.$otherProvider
        Known  = @($t.models.PSObject.Properties.Value)
        Agents = @($t.agents)
    }
}

$touched = [System.Collections.Generic.List[string]]::new()

# --- opencode.json: global default and the agent block ----------------------

$configPath = Join-Path $sourceRoot 'opencode.json'
$config = Read-Text $configPath
$before = $config
foreach ($p in $plan) {
    foreach ($old in $p.Known) {
        if ($old -ne $p.To) { $config = $config.Replace("`"$old`"", "`"$($p.To)`"") }
    }
}
if ($config -ne $before) {
    Write-Text $configPath $config
    $touched.Add('opencode.json')
}

# --- agent Markdown front matter --------------------------------------------

foreach ($file in Get-AgentMarkdown $sourceRoot) {
    $text = Read-Text $file.FullName
    $before = $text
    foreach ($p in $plan) {
        foreach ($old in $p.Known) {
            if ($old -eq $p.To) { continue }
            $pattern = '(?m)^(model:[ \t]*)' + [regex]::Escape($old) + '[ \t]*$'
            $text = [regex]::Replace($text, $pattern, "`${1}$($p.To)")
        }
    }
    if ($text -ne $before) {
        Write-Text $file.FullName $text
        $rel = $file.FullName.Substring($sourceRoot.Length).TrimStart('\', '/').Replace('\', '/')
        $touched.Add($rel)
    }
}

# --- fallback.json: failover points at the other provider -------------------

$fallbackPath = Join-Path $sourceRoot 'fallback.json'
if (Test-Path -LiteralPath $fallbackPath) {
    $fallback = Read-Text $fallbackPath
    $before = $fallback
    foreach ($p in $plan) {
        $list = if ($p.Other -and $p.Other -ne $p.To) { "[`"$($p.Other)`", `"$($p.To)`"]" } else { "[`"$($p.To)`"]" }
        foreach ($agent in $p.Agents) {
            $pattern = '(?s)("' + [regex]::Escape($agent) + '"\s*:\s*\{\s*"fallback"\s*:\s*)\[[^\]]*\]'
            $fallback = [regex]::Replace($fallback, $pattern, { param($m) $m.Groups[1].Value + $list })
        }
    }
    if ($fallback -ne $before) {
        Write-Text $fallbackPath $fallback
        $touched.Add('fallback.json')
    }
}

# --- record the new active provider per tier --------------------------------

$registryText = Read-Text $registryPath
$before = $registryText
foreach ($p in $plan) {
    $pattern = '(?s)("' + [regex]::Escape($p.Name) + '"\s*:\s*\{.*?"active"\s*:\s*")[^"]*(")'
    $registryText = [regex]::Replace($registryText, $pattern, "`${1}$Provider`${2}")
}
if ($registryText -ne $before) {
    Write-Text $registryPath $registryText
    $touched.Add($registryRel)
}

# --- report and apply -------------------------------------------------------

Write-Host ''
if ($touched.Count -eq 0) {
    Write-Host "Nothing to change. Tier(s) $($selected -join ', ') already use $Provider."
    Write-Host ''
    return
}

Write-Host "Switched tier(s) $($selected -join ', ') to $Provider :"
foreach ($p in $plan) { Write-Host "  $($p.Name) -> $($p.To)   (failover: $($p.Other))" }
Write-Host ''
Write-Host 'Updated chezmoi source files:'
foreach ($f in $touched) { Write-Host "  $f" }

if ($NoApply) {
    Write-Host ''
    Write-Host 'NoApply was set. Run chezmoi apply yourself to update the live configuration.'
    Write-Host ''
    return
}

Write-Host ''
foreach ($f in $touched) {
    $target = Join-Path $targetRoot $f
    & chezmoi apply $target
}
Write-Host 'Applied to the live configuration. Restart OpenCode for the change to take effect.'
Write-Host ''
