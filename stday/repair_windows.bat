@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo Repairing Flutter Windows ephemeral files (fixes C1083)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_windows.ps1" -Mode release -RepairOnly
if errorlevel 1 pause
exit /b %ERRORLEVEL%
