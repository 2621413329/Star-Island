@echo off
cd /d "%~dp0"
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000
