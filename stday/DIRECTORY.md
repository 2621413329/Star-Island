# Directory Guide

本文用于告诉 Cursor：每个目录负责什么，新文件应该放哪里，哪些目录不能放业务逻辑。

## 当前目录

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

当前目录仍处于迁移期。不要假设所有目录都已经是最终架构。

## 当前目录职责

| 目录 | 当前职责 | 注意事项 |
|---|---|---|
| `lib/core/` | 基础能力：API、配置、存储、通知、天气、主题、工具、成长计算等 | 不应依赖 feature、provider、data repository。 |
| `lib/common/` | 跨模块共享 contract 或过渡导出 | `common/island_contracts` 是过渡层，不是最终实现目录。 |
| `lib/data/` | 数据模型、repository facade、datasource 实现 | 不放页面、不放 UI、不放 game layer。 |
| `lib/design_system/` | 纯 UI、纯绘制、纯展示组件 | 不允许读取 Riverpod provider，不允许调用 repository。 |
| `lib/features/` | 业务页面与 feature 级 widget/action | 新业务页面优先放这里。 |
| `lib/island/` | 当前岛屿 feature、provider、service、widget、旧 config 的混合目录 | 迁移期目录，新增文件要谨慎。 |
| `lib/providers/` | 当前全局 provider 池 | 后续应逐步迁到 feature/provider 或 app/provider。 |
| `lib/router/` | GoRouter 路由表与 shell tab | 不放业务计算。 |
| `lib/world/` | 岛屿世界、引擎、状态、系统、渲染、场景 layer | 不读业务 provider，不调用 repository。 |
| `lib/l10n/` | Flutter l10n 生成物 | 生成文件不要手改。 |

## 推荐目标目录

后续长期目标：

```text
lib/
  app/
  core/
  common/
  feature/
  game/
  domain/
  data/
  service/
  provider/
  router/
  config/
```

目标职责：

| 目标目录 | 职责 |
|---|---|
| `app/` | 应用入口、bootstrap、全局 provider、全局 l10n、router 装配。 |
| `core/` | 无业务方向的基础设施：配置、错误、平台、权限、存储、主题、工具。 |
| `common/` | 纯展示组件、通用 widget、通用 painter、通用 contract。 |
| `feature/` | 用户可感知的业务模块：auth、story、record、status、island、achievement 等。 |
| `game/` | 岛屿世界、角色、建筑、装饰、相机、动画、渲染、碰撞。 |
| `domain/` | 领域模型、repository 抽象、usecase、领域服务。 |
| `data/` | remote/local datasource、dto、mapper、repository 实现。 |
| `service/` | 平台服务封装：通知、天气、语音、资源加载。 |
| `provider/` | 跨 feature 的 provider 绑定。 |
| `router/` | 路由表和路由守卫。 |
| `config/` | 应用级静态配置。 |

## Feature 文件放置规则

新增页面：

```text
lib/features/<module>/<xxx>_page.dart
```

新增 feature widget：

```text
lib/features/<module>/widgets/<xxx>_widget.dart
```

新增业务 action / usecase：

```text
lib/features/<module>/<xxx>_actions.dart
```

或未来目标：

```text
lib/feature/<module>/usecase/<xxx>_usecase.dart
```

示例：

- 成长奖励业务编排：`lib/features/achievement/growth_reward_actions.dart`
- 心情状态页面：`lib/features/status/mood_status_page.dart`
- 岛屿首页：`lib/features/island/island_home_page.dart`

## UI 组件放置规则

纯展示、无业务依赖：

```text
lib/design_system/<xxx>.dart
```

或未来目标：

```text
lib/common/component/<xxx>/<xxx>.dart
```

允许：

- 接收参数。
- 使用 theme。
- 使用 painter。
- 展示动画。

禁止：

- `ref.watch`
- `ref.read`
- `WidgetRef`
- import `providers/`
- import `data/repositories/`

如果组件需要 provider 数据，应拆为：

```text
feature wrapper
  -> 读取 provider
  -> 把普通参数传给 design_system 纯组件
```

当前示例：

```text
lib/features/shared/widgets/mood_companion_loading.dart
  -> 读取 provider
  -> 调用 design_system/companion_loading.dart
```

## Game / World 文件放置规则

当前世界目录：

```text
lib/world/
  behaviors/
  engine/
  island/
  rendering/
  scene/
  systems/
```

职责：

- `engine/`：输入到 `WorldState` 的计算。
- `systems/`：天气、心情环境、繁荣度、建筑解析等系统。
- `scene/`：场景、手势、layer 编排。
- `scene/layers/`：天空、海洋、岛屿、草地、装饰、建筑、角色等层。
- `rendering/`：低层绘制 helper、缓存、角色渲染器。
- `world/island/`：岛屿几何、视觉配置、renderer、placement。

禁止：

- 直接 import feature page。
- 直接读 Riverpod provider。
- 直接调用 repository。
- 为了新增建筑去改 `IslandGround` 或大面积改 `IslandRenderer`。

## Data 文件放置规则

当前：

```text
lib/data/models/
lib/data/repositories/
```

当前 repository facade/provider：

```text
lib/data/repositories/app_repository_facades.dart
```

当前 HTTP endpoint 实现：

```text
lib/data/repositories/app_repository.dart
```

后续拆分目标：

```text
lib/data/datasource/remote/auth_remote_datasource.dart
lib/data/datasource/remote/profile_remote_datasource.dart
lib/data/datasource/remote/moment_remote_datasource.dart
lib/data/repository/auth_repository_impl.dart
```

原则：

- endpoint path 只放 datasource。
- repository facade 不拼 URL。
- provider 只负责装配依赖。
- model/dto 不 import UI。

## Provider 文件放置规则

当前全局 provider 位于：

```text
lib/providers/
```

新增 provider 时优先判断：

- 只属于一个页面或 feature：放到对应 `features/<module>/`。
- 多个 feature 共享：暂放 `lib/providers/`。
- repository/service 装配：暂放 data/provider 或现有 repository facade provider。

不要把页面局部状态塞进全局 provider。

## Assets 目录

```text
assets/images/buildings/
assets/images/decor/
assets/images/story_categories/
assets/images/story_tags/
assets/images/moment_details/
assets/images/mood_faces/
assets/images/companion/
assets/images/auth/
assets/images/titles/
```

注意：

- 不要仅凭静态搜索删除 assets。
- 很多资源通过 AssetManifest、catalog 或服务端字段动态引用。
- 删除资源前必须对照 `unused_assets.md`。

## 不建议新增的位置

除非正在做专门迁移，否则不要新增：

- `lib/design_system/` 中带业务 provider 的文件。
- `lib/world/` 中直接依赖 `lib/island/` 实现的文件。
- `lib/core/` 中依赖 data/repository/provider 的文件。
- 继续扩张 `app_repository.dart` 的 repository facade。

## 快速决策

新增页面：放 `features/<module>/xxx_page.dart`。

新增纯 UI：放 `design_system/`，但不得读 provider。

新增业务读取 wrapper：放 `features/<module>/widgets/` 或 `features/shared/widgets/`。

新增 API 方法：先加到对应 repository facade，再由 datasource 实现；不要页面直接调用 Dio。

新增岛屿视觉元素：优先找 config/layer/renderer，不要直接改 `IslandHomePage`。
