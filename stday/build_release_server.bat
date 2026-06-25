@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo 学生端 Release 构建，API 指向公网服务器...
flutter pub get
flutter build windows --release --dart-define=API_BASE_URL=http://api.lcxxingyu.fun
echo.
echo 产物: build\windows\x64\runner\Release\stday.exe
pause
