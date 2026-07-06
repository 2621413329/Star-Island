# Island Quick Task Widget — Cursor 拆分架构

> 桌面小组件 = **App 真源 + Widget 只读快照**。严格 **岛屿上下文隔离**：只展示 `currentIslandId` 对应岛屿的今日任务。

## 一、总览

```text
Flutter 业务层
  ↓ currentIslandProvider + storyIslandGroupsProvider
IslandWidgetSync（事件驱动刷新）
  ↓ IslandWidgetService.syncPayload()
共享存储（桥）
  ├─ iOS: App Group UserDefaults
  └─ Android: home_widget SharedPreferences
原生 Widget
  ├─ iOS: WidgetKit + SwiftUI
  └─ Android: AppWidgetProvider + RemoteViews
用户点击
  ↓ stday:// deep link
WidgetDeepLinkHost → IslandHomePage 消费
```

## 二、iOS 拆分

| 模块 | 职责 | 文件 |
|------|------|------|
| **WidgetKit Extension** | 独立 target，随 App 打包 | `ios/IslandWidget/` |
| **App Group 数据共享** | Flutter ↔ Widget 读写同一 UserDefaults | `group.com.xiaoerlcx.app.island` |
| **Timeline Provider** | 读快照、生成 Timeline（5min 弱刷新） | `IslandQuickTaskWidget.swift` → `IslandProvider` |
| **SwiftUI Widget View** | Medium 布局：岛名 / 状态 / 任务 / 快速记录 | `IslandQuickTaskWidgetEntryView` |
| **Entry Model + 解析** | JSON → `IslandEntry` | `IslandWidgetShared.swift` |
| **Entitlements** | Runner + Extension 均声明 App Group | `Runner.entitlements`, `IslandWidget.entitlements` |

关键常量：

```text
App Group ID : group.com.xiaoerlcx.app.island
Payload Key  : island_widget_payload
Widget Kind  : IslandQuickTaskWidget
Min iOS      : 17.0（多区域 Link 交互）
```

刷新：

```swift
// Flutter 侧 home_widget 触发
WidgetCenter.shared.reloadAllTimelines()
```

交互（Link → deep link）：

```text
stday://widget/island?islandId=
stday://widget/task?islandId=&taskId=
stday://widget/quick-record?islandId=
```

## 三、Android 拆分

| 模块 | 职责 | 文件 |
|------|------|------|
| **AppWidgetProvider** | 更新入口、解析 JSON、驱动 RemoteViews | `IslandWidgetProvider.kt` |
| **RemoteViews Layout** | 4×2 布局，最多 3 条任务 | `res/layout/widget_island.xml` |
| **SharedPreferences 存储** | 读 `island_widget_payload`（home_widget 写入） | `HomeWidgetProvider.onUpdate(widgetData)` |
| **PendingIntent 交互** | 任务 / 岛屿 / 快速记录点击 | `HomeWidgetLaunchIntent.getActivity()` |
| **Widget 配置** | 尺寸、5min 弱刷新 | `res/xml/widget_island_info.xml` |
| **Manifest 注册** | Receiver + deep link intent-filter | `AndroidManifest.xml` |

关键常量：

```text
Provider Class : com.stday.stday.IslandWidgetProvider
Payload Key    : island_widget_payload
Deep Link      : stday://（与 iOS 一致）
```

RemoteViews 限制 → **方案 A**：固定 `task1/task2/task3` 三个 TextView，超出截断在 Flutter 侧完成。

刷新：

```kotlin
// Flutter 侧 home_widget 发广播
AppWidgetManager.ACTION_APPWIDGET_UPDATE
```

## 四、Flutter 拆分

| 模块 | 职责 | 文件 |
|------|------|------|
| **数据模型** | 快照 JSON 结构、单岛 payload 构建 | `lib/services/island_widget_models.dart` |
| **统一写入接口** | `syncPayload()` / `clear()` | `lib/services/island_widget_service.dart` |
| **Widget 刷新触发器** | 监听 auth / currentIsland / groups / growthMain | `lib/providers/island_widget_sync_provider.dart` |
| **当前岛屿状态** | `currentIslandId` 持久化 + 选择 | `lib/providers/current_island_provider.dart` |
| **Deep Link 消费** | 解析 URL → 导航 + 打开任务/记录 | `lib/router/widget_deep_link_handler.dart` |
| **岛屿页集成** | 选岛写入 currentIsland、消费 pending 导航 | `lib/features/island/island_home_page.dart` |
| **启动初始化** | `IslandWidgetService.initialize()` | `lib/main.dart` |

### 通信层说明

设计目标为 **MethodChannel 双向通信**；当前实现使用 **`home_widget` 包**（封装原生读写 + 刷新，等价于）：

```text
Flutter                          Native
─────────────────────────────────────────────
HomeWidget.saveWidgetData   →   iOS UserDefaults / Android SharedPreferences
HomeWidget.updateWidget     →   reloadTimelines / APPWIDGET_UPDATE broadcast
HomeWidget.registerInteractivityCallback ← 可选 background URI 回调
```

若需裸 MethodChannel，channel 建议：`island_widget`，method：`updateWidgetData` / `clearWidgetData`。

### 统一 Payload 结构

```json
{
  "currentIslandId": "uuid",
  "islandName": "工作岛屿",
  "islandStatus": "活跃",
  "todayDate": "2026-07-06",
  "completed": 1,
  "total": 2,
  "todayTasks": [
    { "id": "t1", "islandId": "uuid", "title": "写周报", "date": "2026-07-06", "status": "todo" }
  ]
}
```

### 刷新触发时机（必须响应）

```text
currentIslandId 切换
storyIslandGroupsProvider 变化（任务 CRUD / 完成）
growthMainIslandProvider 变化（主岛任务）
auth 登出 → clear()
App 启动 → islandWidgetSyncProvider 首次 sync
```

禁止：缓存跨岛屿任务、聚合全局任务。

## 五、Cursor 修改指南

### 改 Widget UI

```text
iOS     → ios/IslandWidget/IslandQuickTaskWidget.swift
Android → android/.../res/layout/widget_island.xml
          android/.../IslandWidgetProvider.kt
```

### 改数据字段

```text
1. lib/services/island_widget_models.dart（Dart 模型 + buildPayload）
2. ios/IslandWidget/IslandWidgetShared.swift（iOS 解析）
3. android/.../IslandWidgetProvider.kt（Android 解析）
```

### 改交互 / 路由

```text
1. Deep link 常量：lib/services/island_widget_service.dart
2. URL 解析：lib/router/widget_deep_link_handler.dart
3. 落地页：lib/features/island/island_home_page.dart
4. iOS Link URL：IslandWidgetShared.swift → IslandWidgetDataStore
5. Android PendingIntent：IslandWidgetProvider.kt
```

### 改刷新策略

```text
Flutter 事件：lib/providers/island_widget_sync_provider.dart
iOS 弱刷新：IslandProvider.getTimeline policy .after(300s)
Android 弱刷新：res/xml/widget_island_info.xml updatePeriodMillis=300000
```

## 六、设计原则（强制）

1. **Widget ≠ 业务层**：不计算任务逻辑，只消费快照。
2. **App = Single Source of Truth**：任务来自 API + Riverpod，Widget 不写库。
3. **岛屿隔离**：`todayTasks` 必须 `task.islandId == currentIslandId`。
4. **弱更新 + 事件驱动**：系统 5min 兜底；App 内变化立即 `syncPayload()`。
5. **单一主操作**：Widget 上只有一个 Primary CTA「+ 快速记录」。

## 七、测试

```text
test/island_widget_models_test.dart
  - 单岛任务隔离
  - 最多 3 条截断
```

手动验收：

```text
1. App 内选中一座岛屿
2. 添加桌面小组件「岛屿快捷任务」
3. 验证任务列表 / 完成数 / 点击跳转
```
