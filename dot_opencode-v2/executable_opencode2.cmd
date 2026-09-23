@echo off
setlocal
set "OC2_ROOT=%~dp0"
set "XDG_CONFIG_HOME=%USERPROFILE%\.config\opencodev2"
set "XDG_DATA_HOME=%OC2_ROOT%xdg\data"
set "XDG_STATE_HOME=%OC2_ROOT%xdg\state"
set "XDG_CACHE_HOME=%OC2_ROOT%xdg\cache"
rem Anthropic gates model access on the Claude Code version the
rem @ex-machina/opencode-anthropic-auth plugin reports. Override its bundled
rem 2.1.275 until a plugin release catches up; see .chezmanga/CHANGELOG.md.
set "ANTHROPIC_CLAUDE_CODE_VERSION=2.1.280"
"%OC2_ROOT%bin\opencode.exe" %*
exit /b %errorlevel%
