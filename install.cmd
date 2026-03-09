@echo off
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PLUGIN_DIR=%SCRIPT_DIR%plugin"
set "PLUGINS_DIR=%USERPROFILE%\.claude\plugins"
set "INSTALLED_FILE=%PLUGINS_DIR%\installed_plugins.json"
set "PLUGIN_NAME=marlon-claude-plugin"

if not exist "%PLUGINS_DIR%" (
    echo Error: %PLUGINS_DIR% does not exist. Is Claude Code installed?
    exit /b 1
)

where python3 >nul 2>&1
if %errorlevel%==0 (
    python3 -c "import json, os, datetime; f='%INSTALLED_FILE%'.replace('\\', '/'); data=json.load(open(f)) if os.path.exists(f) else {'version':2,'plugins':{}}; t=datetime.datetime.utcnow().strftime('%%Y-%%m-%%dT%%H:%%M:%%S.000Z'); data['plugins']['%PLUGIN_NAME%']=[{'scope':'user','installPath':'%PLUGIN_DIR%'.replace('\\','/'), 'version':'0.1.0','installedAt':t,'lastUpdated':t}]; json.dump(data,open(f,'w'),indent=2)"
    echo Registered %PLUGIN_NAME% in %INSTALLED_FILE%
) else (
    echo Error: python3 is required. Please install Python 3.
    exit /b 1
)

echo Done! Restart Claude Code to load the plugin.
