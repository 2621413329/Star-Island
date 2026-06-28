# Architecture

本文用于让 Cursor 快速理解项目怎么启动、数据怎么流动、岛屿怎么渲染，以及哪些依赖方向不能反转。

## 总体架构

当前项目采用 Flutter + Riverpod + GoRouter + Dio 的应用结构，岛屿世界由 Flutter/Canvas 风格的渲染层组织。

推荐理解为：

```text
App
  -> Router
  -> Feature Page
  -> Provider / Notifier
  -> Repository facade
  -> StdayApiDatasource
  -> Dio
  -> Backend API
```

岛屿渲染链路：

```text
IslandHomePage
  -> GrowthWorldViewport
  -> IslandBuildService / GrowthWorldEngine
  -> WorldState
  -> WorldScene
  -> Scene Layers
  -> Canvas / Painter / Renderer
```

## 启动流程

```text
main.dart
  -> WidgetsFlutterBinding.ensureInitialized
  -> initializeDateFormatting
  -> CompanionBaseAssetCatalog.load
  -> StoryReminderService.initialize
  -> SharedPreferences.getInstance
  -> AppBootstrap(token)
  -> ProviderScope(overrides)
  -> ReminderLifecycleHost
  -> StdayApp
  -> appRouterProvider
```

启动中的关键点：

- token 从 `SharedPreferences` 读取。
- token 通过 `appBootstrapProvider` 注入。
- `authProvider` 创建 `AuthNotifier` 后注册 `ApiSessionCallbacks`。
- `dioProvider` 通过 `api_session.dart` 读取 token，不直接依赖 `authProvider`。
- 本地提醒由 `ReminderLifecycleHost` 和 `StoryReminderService` 管理。

## 路由流程

路由入口：

```text
lib/router/app_router.dart
```

主要路由：

```text
/welcome
/auth
/auth/register
/onboarding/gender
/onboarding/companion
/onboarding/arrival
/island
/records
/insights
/more
/more/my-level
/more/reminders
/more/companion
/more/about
```

主 Tab 使用 `StatefulShellRoute.indexedStack`：

```text
IslandHomePage
RecordPage
MoodStatusPage
MorePage
```

路由守卫规则：

- 未登录访问主功能页会跳转到 `/auth`。
- 已登录访问欢迎页、登录页、注册页会回到 `/island`。
- `/today` 会重定向到 `/records`。
- `/status` 会重定向到 `/insights`。

## 数据流

标准数据流：

```text
Widget / Page
  -> ref.watch / ref.read
  -> Provider / Notifier
  -> Repository facade
  -> StdayApiDatasource
  -> Dio
  -> API
```

示例：

```text
RecordPage
  -> todayMomentsProvider / storyDayViewProvider
  -> MomentRepository
  -> StdayApiDatasource
  -> /api/v1/profile/moments
```

Repository facade 当前位于：

```text
lib/data/repositories/app_repository_facades.dart
```

HTTP endpoint 实现当前位于：

```text
lib/data/repositories/app_repository.dart
```

注意：

- 页面不要直接创建 Dio。
- 页面不要直接拼 API baseUrl。
- 页面应通过 repository provider 或 feature provider 访问数据。

## API 会话流程

```text
authProvider
  -> registerApiSession(ApiSessionCallbacks)

dioProvider
  -> readAccessToken()
  -> Authorization: Bearer <token>
  -> forceReloginIfNeeded(statusCode: 401)
```

相关文件：

```text
lib/core/api/api_client.dart
lib/core/api/api_session.dart
lib/providers/auth_provider.dart
```

原则：

- `core/api` 不直接 import `authProvider`。
- 强制登出属于应用鉴权层，通过 callback 注入。

## 岛屿世界流程

```text
IslandHomePage
  -> watch profile / moments / growth / weather / unlocks
  -> GrowthWorldViewport
  -> resolve WorldState
  -> WorldScene
  -> SkyLayer
  -> OceanLayer
  -> IslandLayer
  -> GrassForegroundLayer
  -> DecorLayer
  -> BuildingLayer
  -> CharacterLayer
  -> HUD / Bubble overlay
```

`WorldState` 是渲染输入快照，包含：

- island
- characters
- buildings
- flora
- environment
- companionGender

`GrowthWorldEngine` 负责把成长输入转成 `WorldState` 的核心数据。

## 依赖方向

允许：

```text
feature -> provider -> repository facade -> datasource -> Dio
feature -> common/design_system
feature -> core
world -> world/island
world -> common/island_contracts
data -> core
```

禁止：

```text
core -> feature
core -> providers
core -> data/repositories
design_system -> providers
design_system -> repositories
world -> features
world -> external island implementation path
data -> feature page
router -> business logic
```

## 当前过渡结构

项目仍处于架构迁移中，存在以下过渡目录：

- `features/`：当前业务页面目录，未来可统一为 `feature/`。
- `world/`：当前岛屿世界与渲染目录，未来可迁到 `game/world/`。
- `island/`：当前混合了岛屿 feature、service、provider、widget 和部分旧配置，未来需要拆到 `feature/island/` 与 `game/`。
- `common/island_contracts/`：过渡 contract export，用于减少 `world -> island` 直接实现依赖。

## 修改原则

- 不为了“整理”修改业务行为。
- 不在 `core` 中读取 provider。
- 不在 `design_system` 中读取 provider。
- 不在 renderer/layer 中调用 repository。
- 不在页面里直接创建网络客户端。
- 涉及 API、存储 key、资源路径、动画参数时必须保持兼容。

## 验证命令

```powershell
flutter analyze
```

```powershell
flutter test test/app_config_test.dart
```
