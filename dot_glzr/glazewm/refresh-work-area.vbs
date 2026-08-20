Option Explicit

Dim scriptPath, shell, command
Set shell = CreateObject("WScript.Shell")
scriptPath = shell.ExpandEnvironmentStrings("%USERPROFILE%\.glzr\glazewm\refresh-work-area.ps1")
command = "pwsh.exe -NoLogo -NoProfile -NonInteractive -WindowStyle Hidden -File """ & scriptPath & """"
WScript.Quit shell.Run(command, 0, True)
