Option Explicit

Dim direction, scriptPath, shell, command
If WScript.Arguments.Count <> 1 Then WScript.Quit 1

direction = WScript.Arguments(0)
If direction <> "previous" And direction <> "next" Then WScript.Quit 1

Set shell = CreateObject("WScript.Shell")
scriptPath = shell.ExpandEnvironmentStrings("%USERPROFILE%\.glzr\glazewm\cycle-workspace-window.js")
command = "node.exe """ & scriptPath & """ " & direction
WScript.Quit shell.Run(command, 0, True)
