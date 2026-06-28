# Cursor Architecture Context

## 总体链路

```text
main.dart
  -> ProviderScope
  -> ReminderLifecycleHost
  -> StdayApp
  -> appRouterProvider
  -> Feature Page
  -> Provider / Notifier
  -> Repository facade
  -> StdayApiDatasource
  -> Dio
  -> Backend API
```

岛屿链路：

```text
IslandHomePage
  -> GrowthWorldViewport
  -> IslandBuildService / GrowthWorldEngine
  -> WorldState
  -> WorldScene
  -> Scene Layers
  -> Renderer / Painter
```

## 启动重点

文件：

```text
lib/main.dart
lib/app.dart
lib/router/app_router.dart
```

启动流程：

```text
WidgetsFlutterBinding.ensureInitialized
initializeDateFormatting
CompanionBaseAssetCatalog.load
StoryReminderService.initialize
SharedPreferences.getInstance
AppBootstrap(token)
ProviderScope(overrides)
ReminderLifecycleHost
StdayApp
```

## 路由重点

路由文件：

```text
lib/router/app_router.dart
```

主 tab：

```text
/island -> IslandHomePage
/records -> RecordPage
/insights -> MoodStatusPage
/more -> MorePage
```

重定向：

```text
/today -> /records
/status -> /insights
```

## API / Auth

API client：

```text
lib/core/api/api_client.dart
```

会话抽象：

```text
lib/core/api/api_session.dart
```

Auth 注册回调：

```text
lib/providers/auth_provider.dart
```

链路：

```text
authProvider
  -> registerApiSession

dioProvider
  -> readAccessToken
  -> Authorization header
  -> forceReloginIfNeeded(401)
```

禁止让 `core/api` 直接 import `authProvider`。

## Repository

Repository facade/provider：

```text
lib/data/repositories/app_repository_facades.dart
```

HTTP endpoint 实现：

```text
lib/data/repositories/app_repository.dart
```

当前 facade：

```text
AuthRepository
ProfileRepository
MomentRepository
VoiceRepository
MoodRepository
GrowthRepository
IslandConfigRepository
AppLocalizationRepository
UserPreferencesRepository
```

页面应该依赖这些 repository provider，不要直接 new datasource 或 Dio。

## Provider

当前全局 provider：

```text
lib/providers/
```

岛屿 provider：

```text
lib/island/providers/
```

规则：

- 页面状态可以用 provider/notifier。
- provider 可以依赖 repository facade。
- provider 不应依赖 UI。
- `design_system` 不应依赖 provider。

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
```

禁止：

```text
core -> providers
core -> data/repositories
core -> features
design_system -> providers
design_system -> data/repositories
world -> features
world -> data/repositories
data -> features
```

## 当前过渡层

```text
lib/common/island_contracts/
```

这是为了避免 `world/` 直接 import `island/` 实现路径。

不要删除，除非已经完成正式迁移。

## 后续架构方向

长期目标：

```text
features/ -> feature/
world/ -> game/world/
island/ -> feature/island + game/island
design_system/ -> common/component
providers/ -> feature/provider + app/provider
```

迁移时必须保留兼容 export wrapper，避免一次性大改。
