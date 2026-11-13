# Cursor Architecture Context

人读版是 `ARCHITECTURE.md`。这里只保留改代码要用的链路。

## 总体链路

```text
main.dart
  -> ProviderScope
  -> MemberLifecycleHost
  -> IapLifecycleHost
  -> ReminderLifecycleHost
  -> IslandWidgetDayRolloverHost
  -> WidgetDeepLinkHost
  -> StdayApp
  -> appRouterProvider
  -> Feature Page
  -> Provider / Notifier
  -> Repository facade
  -> StdayApiDatasource
  -> Dio
  -> Backend /api/v1
```

主岛渲染：

```text
IslandHomePage
  -> GrowthWorldViewport
  -> WorldStateCache
  -> IslandBuildService / GrowthWorldEngine
  -> WorldState
  -> WorldScene
  -> Scene Layers
```

副岛与首页群岛：

```text
storyIslandGroupsProvider / growthMainIslandProvider
  -> HomePage / WorldSection 或故事岛详情
  -> StoryIslandWorldBuilder
  -> 预览 widget 或 story_island_static_detail_viewport
```

`/island` 的路由 widget 是 `IslandHomePage`。滚动首页 `HomePage` 由它嵌入，不是单独路由。

## 启动

`stday/lib/main.dart` 顺序：日期格式化 zh_CN、不等待地加载陪伴图、初始化提醒、初始化小组件、读 SharedPreferences token、`AppBootstrap`、上面的 Host 链。

`stday/lib/app.dart` 接 `appRouterProvider`。

## 路由

文件：`stday/lib/router/app_router.dart`。`initialLocation` 是 `/welcome`。`WelcomePage` 返回 `LandingPage`。

主 Tab：

```text
/island    IslandHomePage
/records   RecordPage
/insights  MoodStatusPage
/more      MorePage
```

其它：

```text
/welcome
/auth
/auth/register
/onboarding/gender
/onboarding/companion
/onboarding/arrival
/more/my-level
/more/reminders
/more/audio
/more/companion
/more/membership
/more/about
/legal/terms
/legal/privacy
/debug/growth-island     仅 kDebugMode
```

重定向：`/today` → `/records`，`/status` → `/insights`。`stday://` 未登录去 `/auth`，已登录去 `/island`，具体任务由 `WidgetDeepLinkHost` 消费。

未登录能留在欢迎、登录、注册、两条法律页，以及 debug 路由。主 Tab、onboarding、`/more/*` 未登录去 `/auth`。已登录且已有陪伴角色时，欢迎/登录/注册去 `/island`；没有角色去 `/onboarding/gender`。

每条路由包着 `_AudioRouteHost`。

## API / Auth

```text
stday/lib/core/api/api_client.dart
stday/lib/core/api/api_session.dart
stday/lib/providers/auth_provider.dart
stday/lib/core/config/app_config.dart
```

```text
authProvider
  -> registerApiSession
dioProvider
  -> readAccessToken
  -> Authorization header
  -> forceReloginIfNeeded(401)
```

禁止 `core/api` 直接 import `authProvider`。删账号走 `AuthRepository.deleteAccount()` → `DELETE /api/v1/auth/me`。

## Repository

Facade 与 provider 在 `stday/lib/data/repositories/app_repository_facades.dart`。HTTP 在 `app_repository.dart` 的 `StdayApiDatasource`。

```text
AuthRepository                 authRepositoryProvider
ProfileRepository              profileRepositoryProvider
MomentRepository               momentRepositoryProvider
StoryIslandRepository          storyIslandRepositoryProvider
VoiceRepository                voiceRepositoryProvider
MoodRepository                 moodRepositoryProvider
GrowthRepository               growthRepositoryProvider
IslandConfigRepository         islandConfigRepositoryProvider
AppLocalizationRepository      appLocalizationRepositoryProvider
UserPreferencesRepository      userPreferencesRepositoryProvider
MemberRepository               memberRepositoryProvider
IapRepository                  iapRepositoryProvider
```

新接口加到对应 facade，再在 datasource 实现。不要把故事岛方法塞进 `MomentRepository`，安放日常除外：`MomentRepository.updateMomentStoryIsland`。

## Provider

全局在 `stday/lib/providers/`。岛屿世界输入在 `stday/lib/island/providers/`。首页槽位和问候在 `stday/lib/features/home/providers/`。

首页不要 watch `recentStoryMomentsProvider`（365 天）。首页故事列表用 `homeStoryFeedMomentsProvider`（21 天）。

规则：页面状态可以用 provider。provider 可以依赖 repository。provider 不依赖具体 UI widget。`design_system` 不依赖 provider。

## 依赖方向

允许：

```text
features -> providers
features -> data/repositories
features -> design_system
features -> core
providers -> data/repositories
data -> core
world -> core
world -> common/island_contracts
world -> world/island
world/preview 可读 data/models 来组装快照
```

禁止：

```text
core -> providers
core -> data/repositories
core -> features
design_system -> providers
design_system -> data/repositories
world 的 scene/layer/renderer -> features
world 的 scene/layer/renderer -> data/repositories
data -> features
```

`IslandHomePage` 可以 import repository 和 provider，因为它是 feature 编排页。`WorldScene` 不可以。

## 过渡层

`stday/lib/common/island_contracts/` 让 `world/` 不必直接 import `island/` 的实现。不要删，除非调用方已经改完。

长期目标仍是 `features/` → `feature/`、`world/` → `game/world/`、`island/` 拆到 feature 与 game。迁移必须留 export wrapper。

## 桌面小组件

见 `knowledge/ai/widget_architecture.md`。刷新监听 `currentIslandProvider`、`storyIslandGroupsProvider`、`growthMainIslandProvider`、登录态。
