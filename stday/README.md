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

默认 `http://127.0.0.1:8000`。Android 模拟器请使用：

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

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
