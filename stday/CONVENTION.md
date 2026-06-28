# Convention

本文定义项目命名、文件职责、依赖边界和修改规则。后续 AI Coding 必须优先遵守本文。

## 文件命名

统一使用小写蛇形命名：

```text
xxx_page.dart
xxx_widget.dart
xxx_dialog.dart
xxx_sheet.dart
xxx_provider.dart
xxx_notifier.dart
xxx_repository.dart
xxx_datasource.dart
xxx_service.dart
xxx_controller.dart
xxx_manager.dart
xxx_renderer.dart
xxx_painter.dart
xxx_layer.dart
xxx_model.dart
xxx_entity.dart
xxx_config.dart
xxx_resolver.dart
xxx_mapper.dart
xxx_usecase.dart
```

不要新增宽泛文件名：

```text
utils.dart
helpers.dart
manager.dart
service.dart
repository.dart
common.dart
app_repository.dart
app_providers.dart
```

除非它们是已有兼容文件或 barrel/part 文件。

## 类命名

| 类型 | 命名 |
|---|---|
| 页面 | `XxxPage` |
| 普通 Widget | `XxxWidget` / `XxxView` |
| Dialog | `XxxDialog` |
| BottomSheet | `XxxSheet` |
| Riverpod provider | `xxxProvider` |
| Riverpod Notifier | `XxxNotifier` |
| Repository facade | `XxxRepository` |
| Repository 实现 | `XxxRepositoryImpl` |
| Datasource | `XxxRemoteDatasource` / `XxxLocalDatasource` |
| Service | `XxxService` |
| Controller | `XxxController` |
| Manager | `XxxManager`，仅用于运行时对象集合管理 |
| Resolver | `XxxResolver`，只做纯映射或查找 |
| Mapper | `XxxMapper`，只做 model/dto 转换 |
| Renderer | `XxxRenderer` |
| Painter | `XxxPainter` |
| Layer | `XxxLayer` |
| Model | `XxxModel` |
| Entity | `XxxEntity` |
| Config | `XxxConfig` |

## Widget 规范

页面：

```text
features/<module>/<xxx>_page.dart
```

纯展示组件：

```text
design_system/<xxx>.dart
```

或未来：

```text
common/component/<xxx>/<xxx>.dart
```

规则：

- 纯展示组件只能接收普通参数。
- 纯展示组件不得读取 Riverpod。
- 纯展示组件不得调用 repository。
- 业务 wrapper 可以读取 provider，然后把数据传给纯组件。
- `BuildContext` 不要跨 async gap 使用；`await` 后使用 context 前必须检查 `mounted` 或提前缓存文案。

示例：

```text
features/shared/widgets/mood_companion_loading.dart
  -> 读取 moodPaletteProvider / userCompanionProvider
  -> 调用 design_system/companion_loading.dart
```

## Provider 规范

Provider 命名：

```dart
final xxxProvider = Provider<Xxx>((ref) { ... });
final xxxNotifierProvider = StateNotifierProvider<XxxNotifier, XxxState>((ref) { ... });
```

规则：

- provider 文件名按业务命名，如 `growth_tag_provider.dart`。
- 页面只通过 provider 读取状态或 repository facade。
- provider 可以依赖 repository facade。
- provider 不应依赖具体 datasource。
- provider 不应承担复杂 UI 布局。

禁止：

- 在 `design_system/` 里使用 `WidgetRef`。
- 在 `core/` 里 import `providers/`。
- 在 renderer/layer 里读取 provider。

## Repository 规范

Repository facade：

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

规则：

- Repository facade 对外暴露业务语义方法。
- Datasource 负责 endpoint path、Dio、payload、response parse。
- 页面不要直接使用 Dio。
- 页面不要拼 URL。
- 新增 API 时优先放到对应 repository，不要继续扩张不相关仓库。

当前兼容结构：

```text
lib/data/repositories/app_repository_facades.dart
lib/data/repositories/app_repository.dart
```

后续目标：

```text
lib/data/datasource/remote/<module>_remote_datasource.dart
lib/data/repository/<module>_repository_impl.dart
lib/domain/repository/<module>_repository.dart
```

## Service / Controller / Manager 规范

Service：

- 负责平台能力、外部能力或跨模块业务服务。
- 示例：通知、天气、语音、资源加载。
- 不直接持有页面 UI 状态。

Controller：

- 负责一个流程的状态推进。
- 示例：写日常提交流程、照片同步流程、语音录制流程。
- 不负责底层 API path。

Manager：

- 只用于运行时对象集合管理。
- 示例：装饰对象集合、缓存集合、组件实例集合。
- 不要把业务编排随意命名为 Manager。

Resolver：

- 只做纯映射或查找。
- 输入相同，输出应稳定。

Mapper：

- 只做 DTO/model/entity 转换。

## Game 命名规范

Renderer：

- 绘制策略或绘制 helper。
- 不持有 Flutter widget 生命周期。

Painter：

- 接 Flutter `CustomPainter` 生命周期。
- 可以调用 renderer。

Layer：

- 场景层，负责组合、排序、交互入口。
- 不直接调用 API。

System：

- 纯计算系统。
- 示例：天气环境、繁荣度、建筑解析。

Behavior：

- 角色行为或交互策略。
- 示例：主角移动、点击命中。

Cache：

- 缓存 Picture、WorldState 或资源。
- 不应知道业务 provider。

## Import 规范

允许：

```text
features -> design_system
features -> providers
features -> data/repositories
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
data -> design_system
```

## API 配置规范

统一使用：

```text
lib/core/config/app_config.dart
```

不要在业务代码中写死 baseUrl。

支持：

```powershell
--dart-define=API_BASE_URL=https://api.example.com
--dart-define=API_SCHEME=https
--dart-define=API_HOST=api.example.com
--dart-define=API_PORT=443
```

规则：

- API path 可以在 datasource 中写相对路径。
- 图片、语音等服务端相对路径拼接必须复用 `AppConfig.apiBaseUrl`。
- HTTP 切 HTTPS 优先改 dart-define，不要到处改字符串。

## 资源规范

资源目录：

```text
assets/images/buildings/
assets/images/decor/
assets/images/companion/
assets/images/mood_faces/
assets/images/story_categories/
assets/images/story_tags/
assets/images/titles/
```

规则：

- 不要随意删除看似未使用资源。
- 资源可能通过 AssetManifest 或服务端字段动态引用。
- 删除前必须参考 `unused_assets.md`。
- 新增资源后必须检查 `pubspec.yaml` 是否已包含目录。

## 异步与 BuildContext

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

或提前缓存本地化文案：

```dart
final message = context.l10n.xxx;
await doSomething();
showMessage(message);
```

## 重构规范

每次重构必须遵守：

- 不改业务逻辑。
- 不改 UI 效果。
- 不改接口路径。
- 不改 payload。
- 不改 response parse。
- 不改存储 key。
- 不改资源路径。
- 一次只处理一个模块或一个强相关文件族。
- 每次完成后运行 `flutter analyze`。

## 提交前检查

```powershell
flutter analyze
```

如果改了 API 配置：

```powershell
flutter test test/app_config_test.dart
```
