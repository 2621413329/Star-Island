@echo off
chcp 65001 >nul
REM Do not open .ps1 with Notepad. Run this .bat instead.
cd /d "%~dp0"
echo Starting stday (PowerShell script)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_windows.ps1" %*
set EXITCODE=%ERRORLEVEL%
if not "%EXITCODE%"=="0" (
  echo.
  echo Failed with exit code %EXITCODE%.
  echo If "flutter" is not found, install Flutter and add it to PATH.
  pause
)
exit /b %EXITCODE%
