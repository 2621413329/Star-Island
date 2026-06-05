# stday 学生端 MVP

温暖陪伴型成长伙伴 Flutter 客户端。

## 环境要求

- Flutter SDK 3.3+
- 后端已启动：`cd backend && uvicorn app.main:app --reload`
- 数据库迁移：`cd backend && alembic upgrade head`

## 首次运行

若缺少 `android/` / `ios/` 平台目录，在项目根执行：

```bash
cd stday
flutter create . --org com.stday
flutter pub get
```

## 配置 API 地址

默认 `http://127.0.0.1:8000`。通过编译参数 `--dart-define=API_BASE_URL=...` 注入。

| 场景 | 地址 |
|------|------|
| 本机 | `http://127.0.0.1:8000` |
| Android 模拟器 | `http://10.0.2.2:8000` |
| 公网服务器 | `http://39.106.134.222:8000` |
| VPC 内网 | `http://172.25.19.38:8000` |

服务器地址见 [../config/server.env](../config/server.env)。Linux 后端部署见 [../docs/DEPLOYMENT_LINUX_BACKEND.md](../docs/DEPLOYMENT_LINUX_BACKEND.md)。

```powershell
# 连接公网服务器运行
powershell -File .\run_windows.ps1 -ApiBaseUrl http://39.106.134.222:8000

# Release 构建（或直接运行 build_release_server.bat）
flutter build windows --release --dart-define=API_BASE_URL=http://39.106.134.222:8000
```

## Android 打包

```bat
build_release_android.bat
```

或手动：

```bash
flutter build apk --release --dart-define=API_BASE_URL=http://39.106.134.222:8000
```

产物：`build/app/outputs/flutter-apk/app-release.apk`，传到手机安装即可。

> 当前使用 debug 签名，可直接安装测试；上架应用商店需配置正式签名。

## 功能流程

1. 欢迎页 → 登录即注册（`/api/v1/auth/entry`）
2. 选择性别 → 选择 Q版/正常版透明小人
3. 弹出今日心情 → 主色调变浅变化
4. 今日故事首页：大卡故事带、标签记录、故事小人
5. 今日状态：列表 + 心情胶囊占比

## 后端新接口

- `POST /api/v1/auth/entry`
- `GET|PATCH /api/v1/profile/*`
- `POST /api/v1/profile/moments`
- `GET /api/v1/profile/moments/today`
