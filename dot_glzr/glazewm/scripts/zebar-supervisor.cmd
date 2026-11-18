@echo off
rem Keep Zebar running while GlazeWM runs.
rem
rem Started once by `startup_commands`. `start /wait` blocks until Zebar exits,
rem so waiting costs no CPU. After an exit it waits for Windows to settle, then
rem restarts Zebar unless GlazeWM is gone. A lock file keeps one supervisor
rem alive, so a GlazeWM restart does not create a second one.
setlocal
set "STATE=%LOCALAPPDATA%\glazewm"
if not exist "%STATE%" mkdir "%STATE%"
( call :supervise ) 9>"%STATE%\zebar-supervisor.lock" 2>nul
exit /b 0

:supervise
start "" /wait zebar
rem `ping` is the delay because `timeout` fails when stdin is redirected.
ping -n 6 127.0.0.1 >nul
tasklist /FI "IMAGENAME eq glazewm.exe" /NH | find /I "glazewm.exe" >nul || exit /b 0
goto supervise
