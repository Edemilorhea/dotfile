$ErrorActionPreference = 'Stop'

$mutex = [Threading.Mutex]::new($false, 'Local\ZebarGlazeWorkAreaRefresh')
$hasLock = $false

try {
  $hasLock = $mutex.WaitOne(0)
  if (-not $hasLock) {
    exit 0
  }

  Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class GlazeWorkAreaRefresh
{
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr FindWindow(string className, string windowName);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd,
        uint message,
        UIntPtr wParam,
        IntPtr lParam,
        uint flags,
        uint timeout,
        out UIntPtr result);
}
'@

  $windowHandle = [GlazeWorkAreaRefresh]::FindWindow('MessageWindow', 'MessageWindow')
  if ($windowHandle -eq [IntPtr]::Zero) {
    throw 'GlazeWM message window was not found.'
  }

  [uint32]$processId = 0
  [void][GlazeWorkAreaRefresh]::GetWindowThreadProcessId($windowHandle, [ref]$processId)
  if ((Get-Process -Id $processId).ProcessName -ne 'glazewm') {
    throw 'The matched message window does not belong to GlazeWM.'
  }

  # Multi-monitor widgets are created independently. Refresh once while they
  # are registering and once after the full group has had time to settle.
  foreach ($delay in 1000, 3000) {
    Start-Sleep -Milliseconds $delay
    $result = [UIntPtr]::Zero
    $sendResult = [GlazeWorkAreaRefresh]::SendMessageTimeout(
      $windowHandle,
      0x001A,
      [UIntPtr]0x002F,
      [IntPtr]::Zero,
      0x0002,
      1000,
      [ref]$result
    )

    if ($sendResult -eq [IntPtr]::Zero) {
      throw 'GlazeWM did not process the work-area refresh message.'
    }
  }
} finally {
  if ($hasLock) {
    $mutex.ReleaseMutex()
  }
  $mutex.Dispose()
}
