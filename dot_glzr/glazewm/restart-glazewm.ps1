$ErrorActionPreference = 'Stop'

$mutex = [Threading.Mutex]::new($false, 'Local\GlazeWMFullRestart')
$hasLock = $false
$logDirectory = Join-Path $env:LOCALAPPDATA 'glazewm'
$logPath = Join-Path $logDirectory 'restart.log'

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class ZebarBar
{
    public IntPtr Handle;
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}

public static class ZebarAppBar
{
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int left, top, right, bottom; }

    [StructLayout(LayoutKind.Sequential)]
    public struct APPBARDATA
    {
        public int cbSize;
        public IntPtr hWnd;
        public uint uCallbackMessage;
        public uint uEdge;
        public RECT rc;
        public int lParam;
    }

    [DllImport("shell32.dll")]
    private static extern UIntPtr SHAppBarMessage(uint message, ref APPBARDATA data);

    [DllImport("user32.dll")]
    private static extern bool SetProcessDpiAwarenessContext(IntPtr context);

    private delegate bool EnumProc(IntPtr window, IntPtr param);

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(EnumProc callback, IntPtr param);

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr window, out uint processId);

    [DllImport("user32.dll")]
    private static extern bool GetWindowRect(IntPtr window, out RECT rect);

    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr window);

    private const uint ABE_TOP = 1;
    private const uint ABM_SETPOS = 0x00000003;
    private static readonly IntPtr DPI_AWARENESS_PER_MONITOR_V2 = new IntPtr(-4);

    // Monitor and window rectangles must be read in physical pixels so mixed-DPI
    // setups are not virtualized into the primary monitor's scale.
    public static void UsePerMonitorDpi()
    {
        SetProcessDpiAwarenessContext(DPI_AWARENESS_PER_MONITOR_V2);
    }

    private static List<ZebarBar> _found;
    private static uint[] _processIds;

    private static bool Collect(IntPtr window, IntPtr param)
    {
        uint processId;
        GetWindowThreadProcessId(window, out processId);
        if (Array.IndexOf(_processIds, processId) < 0) return true;
        if (!IsWindowVisible(window)) return true;

        RECT rect;
        if (!GetWindowRect(window, out rect)) return true;

        ZebarBar bar = new ZebarBar();
        bar.Handle = window;
        bar.Left = rect.left;
        bar.Top = rect.top;
        bar.Right = rect.right;
        bar.Bottom = rect.bottom;
        _found.Add(bar);
        return true;
    }

    public static ZebarBar[] Bars(uint[] processIds)
    {
        _processIds = processIds;
        _found = new List<ZebarBar>();
        EnumWindows(Collect, IntPtr.Zero);
        return _found.ToArray();
    }

    // Re-issues ABM_SETPOS for an app bar the shell already knows about.
    // Returns false when no app bar is registered for the given handle.
    public static bool Reserve(IntPtr window, int left, int top, int right, int bottom)
    {
        APPBARDATA data = new APPBARDATA();
        data.cbSize = Marshal.SizeOf(typeof(APPBARDATA));
        data.hWnd = window;
        data.uEdge = ABE_TOP;
        data.rc.left = left;
        data.rc.top = top;
        data.rc.right = right;
        data.rc.bottom = bottom;
        return SHAppBarMessage(ABM_SETPOS, ref data) != UIntPtr.Zero;
    }
}
'@

[ZebarAppBar]::UsePerMonitorDpi()

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

# Zebar registers each monitor's AppBar once while the widget is created, never
# answers `ABN_POSCHANGED`, and never confirms the result. When that initial
# `ABM_SETPOS` does not take effect on a monitor, the bar stays visible but
# Windows keeps the whole screen as work area, so applications cover the bar.
# Restarting Zebar repeats the same unreliable registration, while re-issuing
# `ABM_SETPOS` against Zebar's own window handle restores the reservation in
# milliseconds without restarting GlazeWM or Zebar.
#
# Returns true when every monitor reserves a top work area afterwards.
function Repair-ZebarAppBar {
  param(
    [string]$GlazeWmPath,
    [int]$ExpectedMonitorCount
  )

  $monitors = Get-MonitorState -GlazeWmPath $GlazeWmPath -ExpectedMonitorCount $ExpectedMonitorCount
  if ($null -eq $monitors) {
    return $false
  }

  $zebarIds = @(Get-Process -Name 'zebar' -ErrorAction SilentlyContinue |
    ForEach-Object { [uint32]$_.Id })
  if ($zebarIds.Count -eq 0) {
    return $false
  }

  $bars = [ZebarAppBar]::Bars($zebarIds)
  if ($bars.Count -eq 0) {
    return $false
  }

  # Pair every monitor with the Zebar window docked to its top edge.
  $pairs = @(foreach ($monitor in $monitors) {
    $bar = $bars | Where-Object {
      $_.Top -eq $monitor.y -and
      $_.Left -ge $monitor.x -and
      $_.Left -lt ($monitor.x + $monitor.width)
    } | Select-Object -First 1

    if (-not $bar) {
      continue
    }

    [pscustomobject]@{
      Monitor = $monitor
      Bar = $bar
      BarHeight = $bar.Bottom - $bar.Top
      Reserved = $monitor.workingRect.top - $monitor.y
    }
  })

  # A monitor without a bar needs Zebar itself, not a reservation repair.
  if ($pairs.Count -ne $monitors.Count) {
    return $false
  }

  $broken = @($pairs | Where-Object { $_.Reserved -le 0 })
  if ($broken.Count -eq 0) {
    return $true
  }

  # A monitor that still reserves space reveals the margin Zebar adds on top of
  # the bar height. Match on bar height so mixed-DPI monitors keep their own
  # scaled values instead of borrowing another monitor's pixel count.
  $healthy = @($pairs | Where-Object { $_.Reserved -gt 0 })

  $reissued = $false
  foreach ($entry in $broken) {
    $reference = $healthy |
      Where-Object { $_.BarHeight -eq $entry.BarHeight } |
      Select-Object -First 1

    $margin = 0
    if ($reference) {
      $margin = $reference.Reserved - $reference.BarHeight
    }

    $length = $entry.BarHeight + $margin
    if ($length -le 0) {
      continue
    }

    $monitor = $entry.Monitor
    $accepted = [ZebarAppBar]::Reserve(
      $entry.Bar.Handle,
      [int]$monitor.x,
      [int]$monitor.y,
      [int]($monitor.x + $monitor.width),
      [int]($monitor.y + $length)
    )

    if ($accepted) {
      $reissued = $true
    }
  }

  if (-not $reissued) {
    return $false
  }

  return Wait-Until -TimeoutSeconds 5 -Condition {
    Test-WorkAreaReserved -GlazeWmPath $GlazeWmPath -ExpectedMonitorCount $ExpectedMonitorCount
  }
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

  # Fast path: re-seat the missing reservations in place. This also succeeds
  # immediately when every monitor is already correct, so the full restart below
  # only runs when the cheap repair cannot fix the work areas.
  if (Repair-ZebarAppBar -GlazeWmPath $glazeWmPath -ExpectedMonitorCount $expectedMonitorCount) {
    exit 0
  }

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
    $workAreaReserved = Repair-ZebarAppBar -GlazeWmPath $glazeWmPath -ExpectedMonitorCount $expectedMonitorCount
  }

  if (-not $workAreaReserved) {
    throw 'Zebar did not reserve a top work area on every monitor after 3 repair attempts.'
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
