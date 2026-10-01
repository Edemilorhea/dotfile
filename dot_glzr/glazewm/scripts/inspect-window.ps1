param(
  [ValidateRange(0, 60)]
  [int]$DelaySeconds = 3
)

$glazewm = Get-Command glazewm -ErrorAction Stop

if ($DelaySeconds -gt 0) {
  Write-Host "Focus the target window within $DelaySeconds second(s)..."
  Start-Sleep -Seconds $DelaySeconds
}

$response = & $glazewm.Source query focused | ConvertFrom-Json
if (-not $response.success -or -not $response.data.focused) {
  throw "GlazeWM did not return a focused window."
}

$window = $response.data.focused
if ($window.type -ne 'window') {
  throw "The focused GlazeWM container is not a window."
}

$window | Select-Object `
  title,
  className,
  processName,
  width,
  height,
  handle,
  id | Format-List

Write-Host 'Suggested window rule match:'
@"
      - window_process: { equals: '$($window.processName)' }
        window_title: { equals: '$($window.title.Replace("'", "''"))' }
        window_class: { equals: '$($window.className.Replace("'", "''"))' }
"@
