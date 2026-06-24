@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo 学生端 Android APK（临时：公网 IP + HTTP 80 端口）
echo 服务器须已部署 deploy/nginx/conf.d/stday-api.ip-http.conf
echo.
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=http://39.106.134.222
echo.
echo 产物: build\app\outputs\flutter-apk\app-release.apk
echo 安装后可在 更多 - 应用说明 底部查看 API 地址并点「检测连接」
pause
