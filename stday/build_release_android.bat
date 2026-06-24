@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo 学生端 Android APK 构建，API 指向公网服务器...
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://api.lcxxingyu.fun
echo.
echo 产物: build\app\outputs\flutter-apk\app-release.apk
pause
