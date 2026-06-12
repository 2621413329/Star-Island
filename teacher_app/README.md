# 成长伙伴 · 教师端

独立 Flutter 应用，视觉主基调与学生端一致（暖色岛屿渐变）。

## 运行

1. 启动后端：`cd backend` → `uvicorn app.main:app --reload`
2. 执行迁移：`alembic upgrade head`
3. 教师端：

```bat
cd teacher_app
run_windows.bat
```

Android 模拟器请将 `API_BASE_URL` 设为 `http://10.0.2.2:8000`。公网服务器见 [../config/server.env](../config/server.env)。

```powershell
flutter run -d windows --dart-define=API_BASE_URL=http://39.106.134.222:8000
# 或直接运行 build_release_server.bat
flutter build windows --release --dart-define=API_BASE_URL=http://39.106.134.222:8000
```

## Android 打包

```bat
build_release_android.bat
```

产物：`build/app/outputs/flutter-apk/app-release.apk`

完整部署指南：[../docs/DEPLOYMENT.md](../docs/DEPLOYMENT.md)。

## 注册

- 注册时需选择**班级**（默认「测试班」）；仅可查看本班学生数据
- 注册密钥与 `backend/.env` 中 `TEACHER_REGISTRATION_SECRET` 一致（模板见 `backend/.env.example`，生产环境勿用默认 `root`）

## 功能

- Tab **成长关注**：AI 成长观察列表（中性文案 + 关注方向）
- Tab **心情**：班级心情一览 → 进入**成长观察档案**
- 档案含：AI 总结、趋势、关注标签、成长记录时间轴、教师关注记录
- Tab **更多**：退出登录
