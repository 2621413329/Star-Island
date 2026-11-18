@echo off
cd /d "%~dp0"
echo 学生端 Android APK 构建, API: https://api.lcxxingyu.fun
call flutter pub get
if errorlevel 1 goto :fail
call flutter build apk --release --dart-define=API_BASE_URL=https://api.lcxxingyu.fun
if errorlevel 1 goto :fail
echo.
echo 产物: build\app\outputs\flutter-apk\app-release.apk
pause
exit /b 0
:fail
echo 构建失败.
pause
exit /b 1
