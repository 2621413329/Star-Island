# Architecture

给人审核「启动、进页、主岛怎么画完」时，先读 [`docs/CLIENT_SYSTEMS.md`](./docs/CLIENT_SYSTEMS.md) 第 1–4 节。本文留给改代码的人查依赖方向和文件。

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
  -> initializeDateFormatting('zh_CN')
  -> CompanionBaseAssetCatalog.load          （不等待）
  -> StoryReminderService.initialize
  -> IslandWidgetService.initialize
  -> SharedPreferences.getInstance
  -> AppBootstrap(token)
  -> ProviderScope(overrides: appBootstrapProvider)
  -> MemberLifecycleHost
  -> IapLifecycleHost
  -> ReminderLifecycleHost
  -> IslandWidgetDayRolloverHost
  -> WidgetDeepLinkHost
  -> StdayApp
  -> appRouterProvider
```

启动中的关键点：

- token 从 `SharedPreferences` 读取，经 `appBootstrapProvider` 注入。
- `authProvider` 创建后注册 `ApiSessionCallbacks`。
- `dioProvider` 通过 `api_session.dart` 读 token。`core/api` 不 import `authProvider`。
- 会员状态由 `MemberLifecycleHost` 跟着登录刷新。iOS 内购由 `IapLifecycleHost` 在登录后初始化。
- 本地提醒由 `ReminderLifecycleHost` 和 `StoryReminderService` 管理。
- 小组件跨日刷新在 `IslandWidgetDayRolloverHost`。`stday://` 由 `WidgetDeepLinkHost` 消费，不让 GoRouter 解析自定义 scheme 的路径。

## 路由流程

路由入口：

```text
lib/router/app_router.dart
```

`initialLocation` 是 `/welcome`。`WelcomePage` 的界面是 `LandingPage`。

公开路由（未登录可停留）：

```text
/welcome
/auth
/auth/register
/legal/terms
/legal/privacy
/debug/*          仅 kDebugMode，例如 /debug/growth-island
```

需要登录的路由：

```text
/onboarding/gender
/onboarding/companion
/onboarding/arrival?mood=
/island            IslandHomePage，内部嵌入 HomePage
/records           RecordPage
/insights          MoodStatusPage
/more              MorePage
/more/my-level
/more/reminders
/more/audio
/more/companion
/more/membership
/more/about
```

主 Tab 使用 `StatefulShellRoute.indexedStack`，顺序是岛屿、记录、洞察、我的。每个路由包在 `_AudioRouteHost` 里切换 BGM。

守卫：

- 未登录访问主 Tab、onboarding、`/more/*` 去 `/auth`；其它非公开路径去 `/welcome`。
- 已登录且已选陪伴角色时，欢迎/登录/注册去 `/island`；还没有角色则去 `/onboarding/gender`。
- 资料拉取失败时，主功能页回到 `/welcome`。
- `/today` → `/records`，`/status` → `/insights`。
- `stday://`：未登录 `/auth`，已登录 `/island`。

会员门槛、故事岛和音频的行为见 [`docs/CLIENT_SYSTEMS.md`](./docs/CLIENT_SYSTEMS.md)。

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

Repository facade 在 `lib/data/repositories/app_repository_facades.dart`（`part of` `app_repository.dart`）。HTTP 实现仍是同一个文件里的 `StdayApiDatasource`。

现行 facade：`AuthRepository`、`ProfileRepository`、`MomentRepository`、`StoryIslandRepository`、`VoiceRepository`、`MoodRepository`、`GrowthRepository`、`IslandConfigRepository`、`AppLocalizationRepository`、`UserPreferencesRepository`、`MemberRepository`、`IapRepository`。接口对照见 [`docs/BACKEND_API.md`](../docs/BACKEND_API.md)。

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

主岛：

```text
IslandHomePage
  -> GrowthWorldViewport
  -> WorldStateCache
  -> IslandBuildService / GrowthWorldEngine
  -> WorldState（IslandGenerator 产出 WorldStateV2）
  -> WorldScene
```

`WorldScene.onLoad` 的完整层序是：

```text
SkyLayer
CloudLayer
DistantLayer
OceanLayer
IslandLayer
DecorLayer
BuildingLayer
GrassForegroundLayer
CharacterLayer
EffectLayer
UIOverlayLayer
MainIslandDebugOverlayLayer   仅 debug 且打开调试开关
```

`islandOnly` 时只保留岛体、装饰、建筑、角色和调试层。前景草画在建筑之后、角色之前。同一层内部的前后关系用 `SceneDepthPriority`：归一化 y 越大越靠前。

HUD、建筑气泡、陪伴台词是 Flutter overlay，不在这条 Flame 层序里。

副岛和首页群岛不重建这套引擎。它们用 `StoryIslandWorldBuilder` 生成 `WorldState` 快照，再交给预览 widget 或静态详情视口。字段和改动入口见 [`GAME_ENGINE.md`](./GAME_ENGINE.md)。

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
