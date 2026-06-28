# Star Island / 成长小岛

## 项目定位

Star Island 是一个温暖陪伴型成长记录 App，核心体验是：

- 用“岛屿养成”承载个人成长反馈。
- 用“日常记录”沉淀当天故事、心情、照片和语音。
- 用“成长系统”把连续记录、等级、建筑解锁、情绪碎片和周/月分析串起来。
- 用“陪伴人物”和岛屿视觉反馈提升记录动力。

本项目当前 Flutter 包名为 `stday`。

## 主要功能

- 岛屿首页：展示成长岛、角色、建筑、天气、HUD、等级和解锁反馈。
- 日常记录：文字、语音、照片、心情、标签、编辑、删除。
- 成长系统：成长值、等级、连续天数、建筑解锁、等级称号。
- 情绪与洞察：心情统计、周期分析、AI 情绪片段、成长观察。
- 陪伴人物：形象、性别、角色设定、加载动画、互动气泡。
- 提醒系统：日常记录提醒、本地通知、生命周期恢复。
- 本地化：动态 i18n 配置与 Flutter l10n。
- API 通信：Dio + Riverpod provider，支持 token 注入与 401 强制重新登录。

## 技术栈

- Flutter
- Dart
- Riverpod
- GoRouter
- Dio
- Flame 2D / Canvas 渲染思路
- SharedPreferences
- Flutter local notifications
- Geolocator / Open-Meteo 天气
- record / just_audio 语音能力
- image_picker 图片能力

当前项目没有独立 `backend/` 目录。后端通过 HTTP API 访问，客户端 API baseUrl 统一由 `lib/core/config/app_config.dart` 管理。

## 运行入口

```text
lib/main.dart
  -> ProviderScope
  -> ReminderLifecycleHost
  -> StdayApp
  -> GoRouter
```

API 配置：

```powershell
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:9000
```

后续 HTTP 切 HTTPS 时：

```powershell
flutter run --dart-define=API_SCHEME=https
```

或直接覆盖完整地址：

```powershell
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

## 当前根目录说明

```text
lib/
assets/
test/
android/
ios/
macos/
windows/
web/
```

- `lib/`：Flutter 客户端主代码。
- `assets/`：图片、建筑、装饰、角色、心情、称号等资源。
- `test/`：Flutter 测试，目前包含 API 配置测试等。
- `android/`、`ios/`、`macos/`、`windows/`、`web/`：平台工程。

## 重要文档

- `PROJECT.md`：项目介绍。
- `ARCHITECTURE.md`：启动、依赖、运行流程。
- `DIRECTORY.md`：目录职责。
- `CONVENTION.md`：命名和编码约定。
- `GAME_ENGINE.md`：岛屿、世界、角色、建筑、渲染说明。
- `AI_GUIDE.md`：给 Cursor / AI 的修改指南。
- `ROADMAP.md`：未来规划和保留方向。
- `architecture_plan.md`：架构治理详细方案。
- `future_refactor_notes.md`：后续重构备忘。

## 当前架构状态

已经完成的关键治理：

- P0 反向依赖已处理。
- `design_system/` 已清理业务 provider 依赖。
- `AppRepository` 已降级为内部 `StdayApiDatasource`，外部使用按职责拆分的 repository provider。
- `AppConfig` 已预留 HTTP/HTTPS 快速切换口子。

仍在后续治理中的内容：

- `StdayApiDatasource` endpoint 实现仍可继续拆分。
- `common/island_contracts/` 仍是过渡 contract export。
- 部分超过 500 行文件尚未拆分。
- 当前目录仍保留 `features/`、`world/`、`island/` 等历史结构，最终目标见 `architecture_plan.md`。
