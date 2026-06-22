@echo off
setlocal
cd /d "%~dp0.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync_decor_from_local.ps1" %*
exit /b %ERRORLEVEL%
