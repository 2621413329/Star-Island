# Cursor Coding Rules

本文件是 Cursor 写代码时必须遵守的规则。

## 修改前必须读

```text
.cursor/project_context.md
.cursor/architecture.md
.cursor/game_system.md
.cursor/coding_rules.md
.cursor/feature_map.md
```

## 总规则

- 不改业务行为。
- 不改 UI 效果。
- 不改 API path、payload、response parse。
- 不改本地存储 key。
- 不随意删除 assets。
- 一次只处理一个模块或一个强相关文件族。
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

新增页面：

```text
lib/features/<module>/<xxx>_page.dart
```

新增 feature widget：

```text
lib/features/<module>/widgets/<xxx>.dart
```

新增纯 UI：

```text
lib/design_system/<xxx>.dart
```

新增业务 wrapper：

```text
lib/features/<module>/widgets/<xxx>.dart
```

新增 API：

```text
lib/data/repositories/app_repository_facades.dart
lib/data/repositories/app_repository.dart
```

新增游戏渲染：

```text
lib/world/
```

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
lib/core/config/app_config.dart
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
unused_assets.md
cleanup_report.md
```

## 验证规则

通用：

```powershell
flutter analyze
```

API 配置：

```powershell
flutter test test/app_config_test.dart
```
