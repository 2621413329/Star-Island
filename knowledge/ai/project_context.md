# Cursor Project Context

| | |
|---|---|
| 编号 | KB-01 |
| 回答的问题 | 项目是什么、技术栈、哪些数字不能单独改 |
| 不负责 | 文件清单、接口字段、动作链 |
| 何时更新 | 技术栈、风险项或验证命令变了 |
| 路由 | 只在 `knowledge/README.md` |


产品做不做先看 `stday/THE_BOOK_OF_STAR_ISLAND.md`。接下来读哪一份，只按 `knowledge/README.md` 的任务路由，不在这里再列。

## 项目定位

Star Island / 星屿 / 成长小岛。包名 `stday`。仓库是 `stday/` 客户端 + `backend/` FastAPI。

一句话：**把看不见的人生，变成一个可以回去的世界。**

```text
日常记录
  -> 安放到主岛或一座故事岛
  -> 用户等级 Lv1–Lv20，副岛各自 Lv1–Lv10
  -> 世界变化（主岛 Flame 世界，副岛预览快照）
  -> 用户 Return
```

已经在跑的能力：岛屿首页、故事岛与今日任务、日常（文字/语音/照片）、心情洞察、陪伴人物、主岛建筑装饰、本地提醒、音频、会员与 Apple 内购、法律页、桌面小组件、动态 i18n。

## 技术栈

Flutter、Dart、Riverpod、GoRouter、Dio、Flame、SharedPreferences、flutter_local_notifications、geolocator、record、just_audio、audio_session、image_picker、home_widget、app_links、in_app_purchase。

后端：FastAPI、SQLAlchemy 2 Async、PostgreSQL、Alembic、JWT。Redis 限流和千问为可选。

## 当前真实目录

```text
stday/lib/
  core/            api、config、audio、membership、legal、growth、语音、天气、通知
  common/          island_contracts 过渡导出
  data/            models、repository facade、StdayApiDatasource
  design_system/   纯 UI
  features/        页面
  island/          主岛建筑、装饰、放置、视口、HUD
  providers/       跨页面状态
  services/        小组件快照
  router/
  world/           引擎、场景、主岛几何、preview 副岛快照
  l10n/            生成物，不要手改
```

不要假设已经迁到 `feature/`、`game/`、`domain/`。

## API

只从 `stday/lib/core/config/app_config.dart` 取 baseUrl。

- Release 默认 `https://api.lcxxingyu.fun`。
- Debug 默认 `http://127.0.0.1:9000`。本机、localhost、10.0.2.2 走 HTTP。
- `--dart-define=API_BASE_URL` 覆盖全部。
- `API_SCHEME` / `API_HOST` / `API_PORT` 分段覆盖。
- `MEDIA_BASE_URL` 空则跟随 API。

不要在业务代码里写死域名。

## 当前重点风险

不要随手改：

- API path、payload、response parse。对照 `knowledge/BACKEND_API.md`。
- 本地存储 key。当前岛是 `stday_current_island_id` 及 `_name`、`_growth_main`。
- 资源路径，尤其 `stday/assets/images/islands/<分类>/buildings/lv01.png`–`lv10.png`。
- UI 动画参数、主岛绘制参数、副岛 `StoryIslandLayout` 数字。
- `WorldState` 字段。新增字段要有默认值，旧快照仍能画。
- token / 401 强制登出。`core/api` 不能 import `authProvider`。
- 成长数值。`GrowthSystem` 与 `backend/app/services/growth_points_service.py` 必须一致。
- 副岛建筑名。Dart catalog 与 `backend/app/config/story_island_buildings.py` 必须一致。
- 内购商品 ID：`com.xiaoerlcx.app.vip.monthly|quarterly|yearly`。

## 仍待后续治理

- `StdayApiDatasource` 仍是一个文件。
- `common/island_contracts/` 仍是过渡 export。
- 多个超过 500 行的文件还没拆，`island_home_page.dart` 是其中最大的编排页。
- `world/` 与 `island/` 还没迁到 `game/` / `feature/island/`。

## 默认验证

改 Dart 后：

```powershell
cd stday
flutter analyze
```

改 API 配置后：

```powershell
cd stday
flutter test test/app_config_test.dart
```

改副岛布局、建筑 catalog、小组件 payload 时，跑对应的 `stday/test/story_island_*`、`stday/test/island_widget_models_test.dart`。
