@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%uninstall.ps1"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
"Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoExit -NoProfile -ExecutionPolicy Bypass -File ""%PS_SCRIPT%""'"

endlocal