Option Explicit

Dim shell
Set shell = CreateObject("WScript.Shell")
WScript.Quit shell.Run("taskkill.exe /IM zebar.exe /F", 0, True)
