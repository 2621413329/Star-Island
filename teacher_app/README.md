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

Android 模拟器请将 `API_BASE_URL` 设为 `http://10.0.2.2:8000`。

## 注册

- 注册时需选择**班级**（默认「家人测试班」）；仅可查看本班学生数据
- 注册密钥默认 `root`，生产环境在 `backend/.env` 设置 `TEACHER_REGISTRATION_SECRET`

## 功能

- Tab **成长关注**：AI 成长观察列表（中性文案 + 关注方向）
- Tab **心情**：班级心情一览 → 进入**成长观察档案**
- 档案含：AI 总结、趋势、关注标签、成长记录时间轴、教师关注记录
- Tab **更多**：退出登录
