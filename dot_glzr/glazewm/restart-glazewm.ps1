$ErrorActionPreference = 'Stop'

$mutex = [Threading.Mutex]::new($false, 'Local\GlazeWMFullRestart')
$hasLock = $false
$logDirectory = Join-Path $env:LOCALAPPDATA 'glazewm'
$logPath = Join-Path $logDirectory 'restart.log'

function Get-ProcessRecords {
  param([string[]]$Names)

  foreach ($name in $Names) {
    foreach ($process in Get-Process -Name $name -ErrorAction SilentlyContinue) {
      [pscustomobject]@{
        Id = $process.Id
        Name = $process.ProcessName
        StartTimeUtc = $process.StartTime.ToUniversalTime().Ticks
      }
    }
  }
}

function Test-ProcessRecord {
  param($Record)

  try {
    $process = Get-Process -Id $Record.Id -ErrorAction Stop
    return $process.ProcessName -eq $Record.Name -and
      $process.StartTime.ToUniversalTime().Ticks -eq $Record.StartTimeUtc
  } catch {
    return $false
  }
}

function Wait-Until {
  param(
    [scriptblock]$Condition,
    [int]$TimeoutSeconds
  )

  $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
  do {
    if (& $Condition) {
      return $true
    }
    Start-Sleep -Milliseconds 250
  } while ([DateTime]::UtcNow -lt $deadline)

  return $false
}

function Get-MonitorState {
  param(
    [string]$GlazeWmPath,
    [int]$ExpectedMonitorCount
  )

  if (-not (Get-Process -Name 'zebar' -ErrorAction SilentlyContinue)) {
    return $null
  }

  try {
    $json = (& $GlazeWmPath query monitors 2>$null | Out-String)
    if ($LASTEXITCODE -ne 0) {
      return $null
    }

    $monitors = ($json | ConvertFrom-Json).data.monitors
    if (-not $monitors -or $monitors.Count -ne $ExpectedMonitorCount) {
      return $null
    }

    return $monitors
  } catch {
    return $null
  }
}

function Test-MonitorsReady {
  param(
    [string]$GlazeWmPath,
    [int]$ExpectedMonitorCount
  )

  $monitors = Get-MonitorState -GlazeWmPath $GlazeWmPath -ExpectedMonitorCount $ExpectedMonitorCount
  return $null -ne $monitors
}

function Test-WorkAreaReserved {
  param(
    [string]$GlazeWmPath,
    [int]$ExpectedMonitorCount
  )

  $monitors = Get-MonitorState -GlazeWmPath $GlazeWmPath -ExpectedMonitorCount $ExpectedMonitorCount
  if ($null -eq $monitors) {
    return $false
  }

  return -not ($monitors | Where-Object { $_.workingRect.top -le $_.y })
}

# Zebar registers each monitor's AppBar reservation once while the widget is
# created and never verifies the result, so the reservation is occasionally
# dropped on one monitor even though `SHAppBarMessage` reported success.
# Restarting Zebar alone re-runs the registration without touching GlazeWM.
function Restart-Zebar {
  $zebarPath = (Get-Command zebar -CommandType Application -ErrorAction SilentlyContinue).Source
  if (-not $zebarPath) {
    return $false
  }

  $zebarProcesses = @(Get-ProcessRecords -Names 'zebar')
  foreach ($record in $zebarProcesses) {
    Stop-Process -Id $record.Id -Force -ErrorAction SilentlyContinue
  }

  $zebarStopped = Wait-Until -TimeoutSeconds 5 -Condition {
    -not ($zebarProcesses | Where-Object { Test-ProcessRecord $_ })
  }
  if (-not $zebarStopped) {
    return $false
  }

  [void](Start-Process -FilePath $zebarPath -WindowStyle Hidden)
  return $true
}

try {
  try {
    $hasLock = $mutex.WaitOne(0)
  } catch [Threading.AbandonedMutexException] {
    $hasLock = $true
  }

  if (-not $hasLock) {
    exit 0
  }

  $glazeWmPath = (Get-Command glazewm -CommandType Application -ErrorAction Stop).Source
  $currentState = (& $glazeWmPath query monitors 2>$null | Out-String) | ConvertFrom-Json
  if ($LASTEXITCODE -ne 0 -or -not $currentState.success) {
    throw 'GlazeWM monitor state could not be read before restart.'
  }
  $expectedMonitorCount = $currentState.data.monitors.Count
  $oldProcesses = @(Get-ProcessRecords -Names 'glazewm', 'glazewm-watcher', 'zebar')

  & $glazeWmPath command wm-exit | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "GlazeWM rejected wm-exit with exit code $LASTEXITCODE."
  }

  $stoppedCleanly = Wait-Until -TimeoutSeconds 10 -Condition {
    -not ($oldProcesses | Where-Object { Test-ProcessRecord $_ })
  }

  if (-not $stoppedCleanly) {
    foreach ($record in $oldProcesses) {
      if (Test-ProcessRecord $record) {
        Stop-Process -Id $record.Id -Force -ErrorAction SilentlyContinue
      }
    }

    $forcedProcessesStopped = Wait-Until -TimeoutSeconds 5 -Condition {
      -not ($oldProcesses | Where-Object { Test-ProcessRecord $_ })
    }
    if (-not $forcedProcessesStopped) {
      throw 'Old GlazeWM or Zebar processes did not stop.'
    }
  }

  [void](Start-Process -FilePath $glazeWmPath -ArgumentList 'start' -PassThru)
  $restartReady = Wait-Until -TimeoutSeconds 30 -Condition {
    Test-MonitorsReady -GlazeWmPath $glazeWmPath -ExpectedMonitorCount $expectedMonitorCount
  }
  if (-not $restartReady) {
    throw 'The restarted GlazeWM did not report the expected monitor count with Zebar running.'
  }

  $workAreaReserved = Wait-Until -TimeoutSeconds 15 -Condition {
    Test-WorkAreaReserved -GlazeWmPath $glazeWmPath -ExpectedMonitorCount $expectedMonitorCount
  }

  for ($attempt = 1; -not $workAreaReserved -and $attempt -le 3; $attempt++) {
    if (-not (Restart-Zebar)) {
      break
    }

    $workAreaReserved = Wait-Until -TimeoutSeconds 20 -Condition {
      Test-WorkAreaReserved -GlazeWmPath $glazeWmPath -ExpectedMonitorCount $expectedMonitorCount
    }
  }

  if (-not $workAreaReserved) {
    throw 'Zebar did not reserve a top work area on every monitor after 3 retries.'
  }
} catch {
  [void](New-Item -ItemType Directory -Path $logDirectory -Force)
  $message = '{0:o} {1}' -f [DateTimeOffset]::Now, $_.Exception.Message
  Add-Content -LiteralPath $logPath -Value $message -Encoding utf8
  exit 1
} finally {
  if ($hasLock) {
    $mutex.ReleaseMutex()
  }
  $mutex.Dispose()
}
