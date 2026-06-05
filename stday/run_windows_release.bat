@echo off
chcp 65001 >nul
REM Release build - smoothest UI, first compile takes longer.
cd /d "%~dp0"
echo Starting stday in RELEASE mode...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_windows.ps1" -Mode release %*
set EXITCODE=%ERRORLEVEL%
if not "%EXITCODE%"=="0" pause
exit /b %EXITCODE%
