# Cursor Coding Rules

| | |
|---|---|
| 编号 | KB-08 |
| 回答的问题 | 命名、依赖禁区和验证命令 |
| 不负责 | 业务说明和文件全表 |
| 何时更新 | 出现新的禁止项或验证命令变了 |
| 路由 | 只在 `knowledge/README.md` |


写代码时遵守下面的规则。先读哪一份文档，按 `knowledge/README.md` 的任务路由，不要把小组件或渲染文档当成每次必读。

## 总规则

- 不改业务行为。
- 不改 UI 效果。
- 不改 API path、payload、response parse。
- 不改本地存储 key。
- 不随意删除 assets。
- 一次只处理一个模块或一个强相关文件族。
- 改了用户能感知的行为时，同步改 `knowledge/review/CLIENT_SYSTEMS.md` 对应节：把原来的「现在怎么走完」写进「和之前的差异」，再写新的动作链。只改 `knowledge/ai/` 不算把审核稿补上。
- 修改后优先运行 `flutter analyze`。

## 命名规则

```text
页面：xxx_page.dart / XxxPage
Widget：xxx_widget.dart / XxxWidget
Dialog：xxx_dialog.dart / XxxDialog
Sheet：xxx_sheet.dart / XxxSheet
Provider：xxx_provider.dart / xxxProvider
Notifier：XxxNotifier
Repository：xxx_repository.dart / XxxRepository
Datasource：xxx_datasource.dart / XxxRemoteDatasource
Service：xxx_service.dart / XxxService
Controller：xxx_controller.dart / XxxController
Renderer：xxx_renderer.dart / XxxRenderer
Painter：xxx_painter.dart / XxxPainter
Layer：xxx_layer.dart / XxxLayer
Model：xxx_model.dart / XxxModel
Config：xxx_config.dart / XxxConfig
Resolver：xxx_resolver.dart / XxxResolver
Mapper：xxx_mapper.dart / XxxMapper
```

不要新增宽泛名称：

```text
utils.dart
helpers.dart
manager.dart
service.dart
repository.dart
app_repository.dart
app_providers.dart
```

## 目录放置规则

放置表以 KB-04 开头的「新文件放哪」为准。下面只保留命名形态。

新增页面：

```text
stday/lib/features/<module>/<xxx>_page.dart
```

新增 feature widget：

```text
stday/lib/features/<module>/widgets/<xxx>.dart
```

新增纯 UI：

```text
stday/lib/design_system/<xxx>.dart
```

新增业务 wrapper：

```text
stday/lib/features/<module>/widgets/<xxx>.dart
```

新增 API：

```text
stday/lib/data/repositories/app_repository_facades.dart
stday/lib/data/repositories/app_repository.dart
```

新增游戏渲染：

```text
stday/lib/world/
```

新增副岛分类或副岛建筑图：同时改 Dart catalog、`backend/app/config/story_island_buildings.py`、`stday/assets/images/islands/<分类>/` 和 `stday/pubspec.yaml`。坐标只改 `StoryIslandLayout`。

新增会员判断：读 `isVipProvider`，提示用 `showVipRequiredDialog`。不要在 `design_system` 里判断 VIP。

新增接口：加到 `app_repository_facades.dart` 里对应的 repository，并在 `StdayApiDatasource` 实现。故事岛用 `StoryIslandRepository`，会员用 `MemberRepository`，内购用 `IapRepository`。

## design_system 规则

`design_system/` 只能放纯 UI、纯展示、纯 painter。

禁止：

```text
import flutter_riverpod
import providers/
import data/repositories/
WidgetRef
ref.watch
ref.read
API 调用
```

如果需要 provider 数据：

```text
feature wrapper 读取 provider
  -> 把普通参数传给 design_system
```

## core 规则

`core/` 是基础层。

禁止：

```text
core -> features
core -> providers
core -> data/repositories
```

需要上层行为时，用 callback 或抽象接口注入。

当前例子：

```text
core/api/api_session.dart
  <- providers/auth_provider.dart 注册回调
```

## world/game 规则

`world/` 负责世界状态、场景、layer、renderer、system、behavior。

禁止：

```text
world -> features
world -> data/repositories
world -> providers
world 中弹 Dialog
world 中请求 API
```

world 需要业务数据时，由 feature/provider 组装输入或 `WorldState` 后传入。

## Repository/API 规则

页面不要直接创建 Dio。

页面不要直接拼 API baseUrl。

标准链路：

```text
Page/Widget
  -> Provider/Notifier
  -> Repository facade
  -> StdayApiDatasource
  -> Dio
```

API baseUrl 统一来自：

```text
stday/lib/core/config/app_config.dart
```

HTTP 切 HTTPS 优先用：

```powershell
--dart-define=API_SCHEME=https
```

或：

```powershell
--dart-define=API_BASE_URL=https://api.example.com
```

## BuildContext async 规则

禁止：

```dart
await doSomething();
ScaffoldMessenger.of(context).showSnackBar(...);
```

推荐：

```dart
await doSomething();
if (!context.mounted) return;
ScaffoldMessenger.of(context).showSnackBar(...);
```

或提前缓存文案。

## 资源规则

不要仅凭静态搜索删除 assets。

资源可能通过：

- AssetManifest
- catalog
- 服务端字段
- 动态路径

删除前必须查：

```text
stday/unused_assets.md
stday/cleanup_report.md
```

## 验证规则

通用：

```powershell
cd stday
flutter analyze
```

API 配置：

```powershell
cd stday
flutter test test/app_config_test.dart
```

副岛布局或建筑名：

```powershell
cd stday
flutter test test/story_island_layout_test.dart test/story_island_building_catalog_test.dart test/story_island_names_test.dart
```

小组件 payload：

```powershell
cd stday
flutter test test/island_widget_models_test.dart
```
