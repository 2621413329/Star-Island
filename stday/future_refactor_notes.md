# 后续重构备忘

本文档用于记录当前已暂缓的架构治理项，方便后续继续修改时快速接上上下文。

## 当前状态

- P0 架构问题已处理完成。
- `design_system/` 已清理业务依赖，不再直接依赖 Riverpod、provider、repository 或 `WidgetRef`。
- API baseUrl 已集中在 `AppConfig.apiBaseUrl`。
- 已预留 HTTP 切 HTTPS 的配置口子。
- `app_repository.dart` 的 Repository facade/provider 已拆到 `app_repository_facades.dart`。
- 当前验证结果：
  - `flutter analyze`：`No issues found!`
  - `flutter test test/app_config_test.dart`：`All tests passed!`

## HTTP / HTTPS 切换口子

当前 API 配置位于：

```text
lib/core/config/app_config.dart
```

支持两种方式：

```powershell
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

或只切协议：

```powershell
flutter run --dart-define=API_SCHEME=https
```

也可以组合使用：

```powershell
flutter run --dart-define=API_SCHEME=https --dart-define=API_HOST=api.example.com
```

当前默认开发地址仍为：

```text
http://127.0.0.1:9000
```

## 后续暂缓项

### 1. 拆分 `StdayApiDatasource`

当前文件：

```text
lib/data/repositories/app_repository.dart
```

现状：

- 外部已不再使用 God Repository。
- Repository facade/provider 已拆到：

```text
lib/data/repositories/app_repository_facades.dart
```

后续可继续把 `StdayApiDatasource` 里的 endpoint 实现按领域拆分：

- auth datasource
- profile datasource
- moment datasource
- voice datasource
- mood datasource
- growth datasource
- island config datasource
- i18n datasource
- user preferences datasource

建议顺序：

1. 先拆 auth/profile。
2. 再拆 moment/voice。
3. 再拆 mood/growth。
4. 最后拆 island config/i18n/preferences。

原则：

- 不改 endpoint path。
- 不改 payload。
- 不改 response parse。
- 不改 repository 对外方法名。
- 每拆一组运行一次 `flutter analyze`。

### 2. 处理 `common/island_contracts/*`

当前目录：

```text
lib/common/island_contracts/
```

现状：

- 这是过渡 export contract。
- 目的是避免 `world/` 直接 import `island/` 实现路径。

后续目标：

- 将背后的 decor/building/growth 实现正式迁到 `game/`、`domain/` 或更合适的稳定模块。
- 迁移完成后再删除过渡 export。

建议：

- 不要一次性移动全部 island 相关实现。
- 先移动纯配置、纯模型。
- 再移动 renderer/manager/factory。

### 3. 超过 500 行文件拆分

后续继续按 `architecture_plan.md` 的拆分方案推进。

优先建议：

1. 先拆纯 UI 页面中的局部 widget。
2. 再拆 renderer/painter 的纯绘制 helper。
3. 最后拆带状态、provider、service 依赖的文件。

拆分原则：

- 不改 UI 效果。
- 不改动画参数。
- 不改业务流程。
- 每次只拆一个文件或一个强相关模块。
- 拆完立即运行 `flutter analyze`。

## 后续继续时建议命令

```powershell
flutter analyze
```

```powershell
flutter test test/app_config_test.dart
```

如继续处理 API 配置相关变更，优先补充或更新：

```text
test/app_config_test.dart
```

## 注意事项

- 不要回退当前已经完成的 P0/P1 结构调整。
- 旧 import 路径如果仍被大量使用，优先保留 export wrapper 作为过渡。
- 如果后续要正式从 HTTP 切 HTTPS，优先通过 `API_SCHEME=https` 或 `API_BASE_URL=https://...` 验证，再考虑修改默认值。
