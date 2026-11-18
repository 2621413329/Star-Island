@echo off
cd /d "%~dp0"
echo 学生端 Release 构建, API 指向公网服务器...
call flutter pub get
if errorlevel 1 goto :fail
call flutter build windows --release --dart-define=API_BASE_URL=https://api.lcxxingyu.fun
if errorlevel 1 goto :fail
echo.
echo 产物: build\windows\x64\runner\Release\stday.exe
pause
exit /b 0
:fail
echo 构建失败.
pause
exit /b 1
