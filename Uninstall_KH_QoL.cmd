@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Uninstall_KH_QoL.ps1"
if errorlevel 1 pause
endlocal
