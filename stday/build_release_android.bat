@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo 学生端 Android APK 构建，API: http://api.lcxxingyu.fun
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=http://api.lcxxingyu.fun
echo.
echo 产物: build\app\outputs\flutter-apk\app-release.apk
pause
