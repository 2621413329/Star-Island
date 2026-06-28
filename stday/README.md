# 成长小岛

面向个人用户的成长记录 Flutter 客户端（Flame 2D 岛屿 + 今日记录 + 成长轨迹）。

## 运行

```powershell
flutter pub get
.\run_windows.bat
```

API 地址通过 `--dart-define=API_BASE_URL=...` 配置，也可以拆分使用
`API_SCHEME` / `API_HOST` / `API_PORT`。后续 HTTP 切 HTTPS 时可直接传
`--dart-define=API_SCHEME=https`，详见 `lib/core/config/app_config.dart`。
