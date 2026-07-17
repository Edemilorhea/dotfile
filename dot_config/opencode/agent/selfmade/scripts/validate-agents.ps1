#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deterministic health check for opencode agent/command prompt files.

.DESCRIPTION
    Fast, free, no-LLM static validation inspired by the plugin-eval pattern used by
    popular multi-harness agent repos (wshobson/agents). Catches the exact bug classes
    found during the 2026-07 OpenCode agent audit:

      1. NameCollision          - two agent files declare the same frontmatter `name:`
                                   (opencode keys agents by name; duplicates silently
                                   overwrite one another with no error at load time)
      2. GhostOpencodeJsonAgent - opencode.json's `agent: {}` model-assignment block
                                   references a name with no matching agent file
                                   (the model config becomes a silent no-op)
      3. GhostSubagentReference - a `task(subagent_type="X", ...)` call references a
                                   name that doesn't match any real registered agent
                                   (e.g. the old `BatchExecutor` ghost reference)
      4. UnbalancedTag          - a structural pseudo-XML tag (<workflow>, <stage>,
                                    <critical_rules>, etc.) opens without a matching
                                    close, usually from a botched copy-paste merge
      5. ReviewRoutingBoundary  - review command or terminal reviewer violates the
                                   single-primary-routing contract

    This is a heuristic static scan, not a full parser. False positives are possible
    (rare in this codebase) — treat findings as "look here", not gospel.

.PARAMETER Root
    opencode config root. Defaults to the current directory.

.EXAMPLE
    pwsh agent/selfmade/scripts/validate-agents.ps1
    pwsh agent/selfmade/scripts/validate-agents.ps1 -Root ~/.config/opencode
#>

param(
    [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

# Built-in / hidden agents that never have a corresponding user-authored .md file.
$KnownBuiltinNames = @("build", "plan", "general", "explore", "compaction", "title", "summary")

# Structural container tags worth balance-checking. Keep this list scoped to actual
# section-level tags used in this config, not every inline tag (e.g. <rule>, <condition>
# are frequently self-closed or single-line and would produce noisy false positives).
$TagsToCheck = @(
    "critical_rules", "critical_context_requirement", "workflow", "stage", "step",
    "delegation_rules", "execution_priority", "execution_paths", "constraints",
    "principles", "execution_philosophy"
)

function Get-FrontmatterName {
    param([string]$Content, [string]$FileBaseName)
    if ($Content -match '(?s)^---\r?\n(.*?)\r?\n---') {
        $fm = $Matches[1]
        if ($fm -match '(?m)^name:\s*(.+)$') {
            return $Matches[1].Trim().Trim('"')
        }
    }
    # opencode falls back to the filename when frontmatter omits `name:`.
    return $FileBaseName
}

function Strip-JsonComments {
    param([string]$Raw)
    # Only strip `// ...` when preceded by whitespace, so URLs like "https://x" (no
    # space before `//`) are left untouched. Good enough for this repo's JSONC style.
    return ($Raw -split "`n" | ForEach-Object { $_ -replace '(?<=\s)//.*$', '' }) -join "`n"
}

Write-Host "Scanning agent/command files under: $Root" -ForegroundColor Cyan

$agentFiles = Get-ChildItem -Path (Join-Path $Root "agent") -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '\.md(\.tmpl)?$' }
$commandFiles = Get-ChildItem -Path (Join-Path $Root "command") -Recurse -Filter *.md -File -ErrorAction SilentlyContinue
$allMdFiles = @($agentFiles) + @($commandFiles)

$issues = [System.Collections.Generic.List[PSCustomObject]]::new()
$nameMap = @{}  # name -> list of file paths

foreach ($f in $agentFiles) {
    $content = Get-Content -Raw -LiteralPath $f.FullName
    $name = Get-FrontmatterName -Content $content -FileBaseName $f.BaseName
    if (-not $nameMap.ContainsKey($name)) { $nameMap[$name] = [System.Collections.Generic.List[string]]::new() }
    $nameMap[$name].Add($f.FullName)
}

# 1. Duplicate names
foreach ($n in $nameMap.Keys) {
    if ($nameMap[$n].Count -gt 1) {
        $issues.Add([PSCustomObject]@{
            Type   = "NameCollision"
            Detail = "name '$n' declared in $($nameMap[$n].Count) files — later-loaded one silently wins"
            Files  = ($nameMap[$n] -join "; ")
        })
    }
}

# 2. opencode.json agent{} keys with no matching real agent
$opencodeJsonPath = Join-Path $Root "opencode.json"
$opencodeAgentKeys = @()
if (Test-Path -LiteralPath $opencodeJsonPath) {
    $jsonRaw = Get-Content -Raw -LiteralPath $opencodeJsonPath
    $jsonClean = Strip-JsonComments -Raw $jsonRaw
    try {
        $json = $jsonClean | ConvertFrom-Json
        if ($json.agent) {
            $opencodeAgentKeys = $json.agent.PSObject.Properties.Name
        }
    } catch {
        $issues.Add([PSCustomObject]@{
            Type   = "JsonParseWarning"
            Detail = "Could not parse opencode.json for cross-checking (agent-key check skipped): $($_.Exception.Message)"
            Files  = $opencodeJsonPath
        })
    }
}

$allRealNames = @($nameMap.Keys) + $KnownBuiltinNames + $opencodeAgentKeys | Select-Object -Unique

foreach ($k in $opencodeAgentKeys) {
    if (-not $nameMap.ContainsKey($k) -and $KnownBuiltinNames -notcontains $k) {
        $issues.Add([PSCustomObject]@{
            Type   = "GhostOpencodeJsonAgent"
            Detail = "opencode.json agent.'$k' has no matching agent file — model assignment is a no-op"
            Files  = $opencodeJsonPath
        })
    }
}

# 3. Ghost subagent_type references
$subagentRefPattern = 'subagent_type\s*=\s*"([^"]+)"'
foreach ($f in $allMdFiles) {
    $content = Get-Content -Raw -LiteralPath $f.FullName
    foreach ($m in [regex]::Matches($content, $subagentRefPattern)) {
        $ref = $m.Groups[1].Value
        if ($ref -match '[\{\[<]') { continue }  # skip illustrative placeholders like "{AgentName}"
        if ($allRealNames -notcontains $ref) {
            $issues.Add([PSCustomObject]@{
                Type   = "GhostSubagentReference"
                Detail = "subagent_type=""$ref"" has no matching real agent"
                Files  = $f.FullName
            })
        }
    }
}

# 4. Unbalanced structural tags
foreach ($f in $agentFiles) {
    $content = Get-Content -Raw -LiteralPath $f.FullName
    foreach ($tag in $TagsToCheck) {
        $openCount = ([regex]::Matches($content, "<$tag(\s[^>]*)?>")).Count
        $closeCount = ([regex]::Matches($content, "</$tag>")).Count
        if ($openCount -ne $closeCount) {
            $issues.Add([PSCustomObject]@{
                Type   = "UnbalancedTag"
                Detail = "<$tag> open=$openCount close=$closeCount"
                Files  = $f.FullName
            })
        }
    }
}

# 5. Review routing boundary. Reviewers are terminal specialists: only a
# primary agent routes work, while TaskManager may plan but never dispatches.
$reviewCommandPath = Join-Path $Root "command\selfmade\review.md"
if (Test-Path -LiteralPath $reviewCommandPath) {
    $reviewCommand = Get-Content -Raw -LiteralPath $reviewCommandPath
    if ($reviewCommand -notmatch '(?m)^agent:\s*OpenAgent\s*$' -or $reviewCommand -notmatch '(?m)^subtask:\s*false\s*$') {
        $issues.Add([PSCustomObject]@{
            Type   = "ReviewCommandRoute"
            Detail = "command/selfmade/review.md must route through OpenAgent with subtask: false"
            Files  = $reviewCommandPath
        })
    }
}

$terminalReviewers = @("CodeReviewer", "dotnet-code-reviewer")
foreach ($reviewerName in $terminalReviewers) {
    if (-not $nameMap.ContainsKey($reviewerName)) {
        $issues.Add([PSCustomObject]@{
            Type   = "TerminalReviewerMissing"
            Detail = "terminal reviewer '$reviewerName' has no matching agent file"
            Files  = (Join-Path $Root "agent")
        })
        continue
    }

    foreach ($reviewerPath in $nameMap[$reviewerName]) {
        $reviewerContent = Get-Content -Raw -LiteralPath $reviewerPath
        if ($reviewerContent -notmatch '(?m)^\s*task:\s*\r?\n\s*"?\*"?\s*:\s*"?deny"?\s*$') {
            $issues.Add([PSCustomObject]@{
                Type   = "SpecialistDelegationLeak"
                Detail = "terminal reviewer '$reviewerName' must deny task delegation"
                Files  = $reviewerPath
            })
        }

        if ($reviewerContent -match '(?i)ALWAYS\s+call\s+ContextScout|task\s*\(') {
            $issues.Add([PSCustomObject]@{
                Type   = "RecursiveRoutingPrompt"
                Detail = "terminal reviewer '$reviewerName' contains a nested discovery or task invocation instruction"
                Files  = $reviewerPath
            })
        }
    }
}

# Report
Write-Host ""
if ($issues.Count -eq 0) {
    Write-Host "PASS - no issues found across $($agentFiles.Count) agent file(s) / $($commandFiles.Count) command file(s)." -ForegroundColor Green
    exit 0
} else {
    Write-Host "FOUND $($issues.Count) issue(s):" -ForegroundColor Yellow
    $issues | Sort-Object Type | Format-Table -AutoSize -Wrap
    exit 1
}
