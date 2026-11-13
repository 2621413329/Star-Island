# Star Island / 成长小岛

> 进入项目请先阅读 [`THE_BOOK_OF_STAR_ISLAND.md`](./THE_BOOK_OF_STAR_ISLAND.md)。  
> 人审核 AI 的实现时读 [`docs/CLIENT_SYSTEMS.md`](./docs/CLIENT_SYSTEMS.md)：每一节写现在怎么走完，以及和之前差在哪。接口表在 [`docs/BACKEND_API.md`](../docs/BACKEND_API.md)。文档地图在 [`docs/KNOWLEDGE.md`](../docs/KNOWLEDGE.md)。

## 项目定位

Star Island（对外名称「星屿」）是一个温暖陪伴型成长记录 App。Flutter 包名是 `stday`。

- 用岛屿承载个人成长：主岛随用户等级变化，副岛随某一类生活记录生长。
- 用日常记录沉淀文字、语音、照片、心情和标签，再安放到一座岛上。
- 用陪伴人物、天气、等级称号和本地提醒，让人愿意回到这个世界。
- 会员（星屿会员）打开语音、照片、历史补记、统计和额外岛屿等能力。免费路径仍然可以记录和拥有每个分类的第一座岛。

## 仓库

```text
stday/      Flutter 客户端
backend/    FastAPI + SQLAlchemy + PostgreSQL
docs/       跨端文档与部署
```

后端就在本仓库的 `backend/`。客户端不内嵌服务，通过 HTTP 访问。地址由 `lib/core/config/app_config.dart` 决定：

- Release 默认 `https://api.lcxxingyu.fun`。
- Debug 默认 `http://127.0.0.1:9000`。
- `--dart-define=API_BASE_URL=...` 覆盖完整地址。
- `--dart-define=API_SCHEME` / `API_HOST` / `API_PORT` 分段覆盖。
- `--dart-define=MEDIA_BASE_URL` 单独指定图片和语音的公网域名，空则跟随 API。

## 主要功能

- 岛屿首页：`/island` 是 `IslandHomePage`，内部嵌入滚动的 `HomePage`（等级、群岛、今日故事）。点一座岛进入主岛 Flame 世界或副岛详情。
- 故事岛：11 个生活分类，每座岛 10 级建筑、今日任务、桌面小组件只看当前岛。
- 日常记录：文字、语音、照片、心情、标签、编辑、删除、安放到岛。
- 用户成长：Lv1–Lv20、连续天数、主岛建筑解锁、等级称号。规则与后端 `growth_points_service` 对齐。
- 情绪与洞察：心情统计、月/年分析、成长观察。统计和周观察对非会员做蒙版或空数据。
- 陪伴人物：小星仔、小光宝免费；小愿、小梦是会员角色。
- 提醒：本地通知，设置在 `/more/reminders`。
- 音频：按路由切换 BGM，岛和欢迎页分昼夜。设置在 `/more/audio`。
- 会员与内购：`/more/membership`，Apple 订阅加激活码。
- 法律：用户协议和隐私政策写在客户端，未登录可打开。
- 本地化：Flutter l10n 生成物加服务端 i18n bundle。

审核动作和差异见 [`docs/CLIENT_SYSTEMS.md`](./docs/CLIENT_SYSTEMS.md)。

## 技术栈

客户端：

- Flutter / Dart（SDK `>=3.3.0 <4.0.0`）
- Riverpod、GoRouter、Dio、SharedPreferences
- Flame 2D 组织主岛场景；副岛预览用 `WorldState` 快照
- flutter_local_notifications、geolocator、Open-Meteo
- record、just_audio、audio_session、image_picker
- home_widget、app_links（桌面小组件与 `stday://`）
- in_app_purchase

后端：

- Python 3.10+、FastAPI、SQLAlchemy 2 Async、Pydantic v2、Alembic
- PostgreSQL、JWT
- Redis 做登录限流（可选）
- 千问 DashScope 做心情与陪伴相关生成（可选）

## 运行客户端

```powershell
cd stday
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:9000
```

Windows 也可以 `.\run_windows.bat`。

## 运行后端

见 [`backend/README.md`](../backend/README.md)。健康检查 `http://127.0.0.1:9000/health`。

## 当前架构状态

已经做完的：

- P0 反向依赖已处理。`design_system/` 不读业务 provider。
- 页面走按职责拆开的 repository provider。HTTP 仍集中在 `StdayApiDatasource`。
- `world/` 通过 `common/island_contracts/` 使用岛屿契约，避免直接依赖 `island/` 实现。
- API baseUrl 只从 `AppConfig` 来。

仍在迁移中的：

- `features/`、`world/`、`island/`、`providers/` 还不是目标目录名（目标见 `ROADMAP.md`）。
- `StdayApiDatasource` 还没拆成多个 remote datasource。
- 多个超过 500 行的页面和 layer 还没拆。

## 文档

给人审核实现：先读 `docs/CLIENT_SYSTEMS.md`（动作链和与之前的差异）。`PROJECT.md`、`ARCHITECTURE.md`、`DIRECTORY.md`、`GAME_ENGINE.md` 是查目录和文件时的附图。

给 AI 改代码看：`.cursor/` 与 `AI_GUIDE.md`。先读产品圣经，再读 `.cursor/project_context.md`。
