@echo off
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PLUGIN_DIR=%SCRIPT_DIR%plugin"
set "PLUGIN_NAME=claude-devline"

if not exist "%PLUGIN_DIR%\.claude-plugin\plugin.json" (
    echo Error: Plugin manifest not found at %PLUGIN_DIR%\.claude-plugin\plugin.json
    exit /b 1
)

:: Detect PowerShell profile path
set "PS_PROFILE="
where powershell >nul 2>&1
if %errorlevel%==0 (
    for /f "delims=" %%p in ('powershell -NoProfile -Command "$PROFILE"') do set "PS_PROFILE=%%p"
)

:: Create the alias function for PowerShell
set "ALIAS_MARKER=# %PLUGIN_NAME%"
set "ALIAS_LINE=function claude { claude.exe --plugin-dir '%PLUGIN_DIR%' @args }"

if defined PS_PROFILE (
    :: Ensure profile directory exists
    for %%d in ("%PS_PROFILE%") do (
        if not exist "%%~dpd" mkdir "%%~dpd"
    )

    :: Remove old entry if present
    if exist "%PS_PROFILE%" (
        powershell -NoProfile -Command "(Get-Content '%PS_PROFILE%') | Where-Object { $_ -notmatch '%PLUGIN_NAME%' -and $_ -notmatch 'claude.exe --plugin-dir.*%PLUGIN_NAME%' } | Set-Content '%PS_PROFILE%'"
    )

    :: Append alias
    echo.>> "%PS_PROFILE%"
    echo %ALIAS_MARKER%>> "%PS_PROFILE%"
    echo %ALIAS_LINE%>> "%PS_PROFILE%"

    echo Added plugin alias to %PS_PROFILE%:
    echo   %ALIAS_LINE%
    echo.
    echo Reload your profile or open a new terminal, then start claude.
    echo Updates from git pull take effect on next claude restart — no reinstall needed.
) else (
    echo Could not detect PowerShell profile.
    echo.
    echo Launch directly with:
    echo   claude --plugin-dir "%PLUGIN_DIR%"
    echo.
    echo Or add this to your PowerShell profile manually:
    echo   %ALIAS_LINE%
)
