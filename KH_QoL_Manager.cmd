@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0KH_QoL_Manager.ps1"
if errorlevel 1 pause
endlocal
