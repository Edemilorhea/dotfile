@echo off
setlocal
set "OC2_ROOT=%~dp0"
set "XDG_CONFIG_HOME=%OC2_ROOT%xdg\config"
set "XDG_DATA_HOME=%OC2_ROOT%xdg\data"
set "XDG_STATE_HOME=%OC2_ROOT%xdg\state"
set "XDG_CACHE_HOME=%OC2_ROOT%xdg\cache"
"%OC2_ROOT%bin\opencode.exe" %*
exit /b %errorlevel%
