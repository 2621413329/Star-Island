# Cursor Project Context

本文件是 Cursor 编码前的第一上下文。开始修改代码前，请先阅读：

```text
.cursor/project_context.md
.cursor/architecture.md
.cursor/game_system.md
.cursor/coding_rules.md
.cursor/feature_map.md
```

更完整文档：

```text
PROJECT.md
ARCHITECTURE.md
DIRECTORY.md
CONVENTION.md
GAME_ENGINE.md
AI_GUIDE.md
ROADMAP.md
```

## 项目定位

Star Island / 成长小岛是一个 Flutter 成长记录 App：

```text
日常记录
  -> 成长值
  -> 等级
  -> 岛屿变化
  -> 建筑/装饰解锁
  -> 陪伴人物反馈
  -> 心情与成长洞察
```

核心功能：

- 岛屿首页。
- 日常记录。
- 心情与成长分析。
- 陪伴人物。
- 建筑和装饰解锁。
- 本地提醒。
- 语音、照片、AI 分析相关能力。

## 技术栈

- Flutter
- Dart
- Riverpod
- GoRouter
- Dio
- Flame 2D / Canvas 渲染思路
- SharedPreferences
- flutter_local_notifications
- record / just_audio
- image_picker

## 当前真实目录

```text
lib/
  core/
  common/
  data/
  design_system/
  features/
  island/
  providers/
  router/
  world/
  l10n/
```

注意：项目仍处于架构迁移期。不要假设已经完全迁移到 `feature/`、`game/`、`domain/`。

## 当前已完成的架构治理

- P0 反向依赖已处理。
- `design_system/` 已清理业务 provider 依赖。
- `AppRepository` 已降级为内部 `StdayApiDatasource`。
- 外部使用按职责拆分的 repository provider。
- API baseUrl 统一由 `AppConfig.apiBaseUrl` 管理。
- 已预留 HTTP -> HTTPS 快速切换配置。

## API 配置

配置文件：

```text
lib/core/config/app_config.dart
```

支持：

```powershell
--dart-define=API_BASE_URL=https://api.example.com
--dart-define=API_SCHEME=https
--dart-define=API_HOST=api.example.com
--dart-define=API_PORT=443
```

不要在业务代码中写死 API baseUrl。

## 当前重点风险

不要随意改：

- API path、payload、response parse。
- 本地存储 key。
- 资源路径。
- UI 动画参数。
- 岛屿绘制参数。
- `WorldState` 结构。
- token / 401 强制登出逻辑。

## 仍待后续治理

- `StdayApiDatasource` endpoint 实现仍可继续拆分。
- `common/island_contracts/` 仍是过渡 export。
- 多个超过 500 行文件仍待拆分。
- `world/` 和 `island/` 最终还需要迁到 `game/` / `feature/island/`。

## 默认验证

修改 Dart 后运行：

```powershell
flutter analyze
```

修改 API 配置后运行：

```powershell
flutter test test/app_config_test.dart
```
