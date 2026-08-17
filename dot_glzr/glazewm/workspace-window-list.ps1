Add-Type -AssemblyName PresentationFramework

$response = & glazewm query workspaces | ConvertFrom-Json
if (-not $response.success) {
  [System.Windows.MessageBox]::Show($response.error, 'GlazeWM workspace windows')
  exit 1
}

$workspace = $response.data.workspaces | Where-Object hasFocus | Select-Object -First 1
if (-not $workspace) {
  [System.Windows.MessageBox]::Show('No focused workspace.', 'GlazeWM workspace windows')
  exit 1
}

function Get-WorkspaceWindow {
  param([object]$Container)

  if ($Container.type -eq 'window') {
    $Container
    return
  }

  foreach ($child in $Container.children) {
    Get-WorkspaceWindow $child
  }
}

$windows = @(Get-WorkspaceWindow $workspace)
if ($windows.Count -eq 0) {
  [System.Windows.MessageBox]::Show('No windows.', "Workspace $($workspace.name)")
  exit
}

$items = $windows | ForEach-Object {
  $focus = if ($_.hasFocus) { '> ' } else { '  ' }
  $title = if ($_.title) { $_.title } else { '(untitled)' }
  [PSCustomObject]@{
    Display = "$focus$($_.processName)  [$($_.state.type)]`n    $title"
    Id = $_.id
    State = $_.state.type
  }
}

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Workspace windows" Width="760" Height="420"
        WindowStartupLocation="CenterScreen" Topmost="True"
        Background="#161821" Foreground="#F1F3F9">
  <Grid Margin="16">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto" />
      <RowDefinition Height="*" />
      <RowDefinition Height="Auto" />
    </Grid.RowDefinitions>
    <TextBlock Name="Heading" FontSize="18" FontWeight="SemiBold" Margin="4,0,4,12" />
    <ListBox Name="WindowList" Grid.Row="1" FontFamily="Consolas" FontSize="14"
             Background="#202330" Foreground="#F1F3F9" BorderBrush="#3B82F6"
             Padding="6" DisplayMemberPath="Display" />
    <TextBlock Grid.Row="2" Margin="4,10,4,0" Foreground="#A8B0C2"
               Text="Enter or double-click: switch    Esc: close" />
  </Grid>
</Window>
'@

$reader = [System.Xml.XmlNodeReader]::new($xaml)
$dialog = [Windows.Markup.XamlReader]::Load($reader)
$list = $dialog.FindName('WindowList')
$dialog.FindName('Heading').Text = "Workspace $($workspace.name) - $($windows.Count) windows"
$list.ItemsSource = $items
$list.SelectedIndex = 0

$activateSelected = {
  $item = $list.SelectedItem
  if (-not $item) { return }

  if ($item.State -eq 'minimized') {
    & glazewm command --id $item.Id toggle-minimized | Out-Null
  }
  & glazewm command focus --container-id $item.Id | Out-Null
  $dialog.Close()
}

$list.Add_MouseDoubleClick($activateSelected)
$dialog.Add_KeyDown({
  if ($_.Key -eq 'Escape') {
    $dialog.Close()
  } elseif ($_.Key -eq 'Enter') {
    & $activateSelected
  }
})
$dialog.Add_ContentRendered({ $list.Focus() })
$dialog.ShowDialog() | Out-Null
