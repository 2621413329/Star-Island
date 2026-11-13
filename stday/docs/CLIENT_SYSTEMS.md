# 客户端现行系统

本文描述已经在跑的产品行为。产品取舍以 `THE_BOOK_OF_STAR_ISLAND.md` 为准。文件落点以 `.cursor/feature_map.md` 为准。接口以 `docs/BACKEND_API.md` 为准。

## 首页实际由两层组成

`/island` 的路由页面是 `IslandHomePage`（`lib/features/island/island_home_page.dart`）。它自己不把滚动首页写死在路由里，而是在没有打开详情时嵌入 `HomePage`。

`HomePage`（`lib/features/home/home_page.dart`）是一条可下拉刷新的滚动页：

1. `HomeGrowthLevelCard`：等级、天气。
2. `WorldSection`：群岛预览。点主岛或某座副岛，回调交给 `IslandHomePage` 打开详情。
3. 可选的主岛今日任务区，由岛屿页传入。
4. `StoryEntryCard`：开始记一条日常，打开 `showAddMomentFlow`。
5. `TodayStoryList`：今日故事。数据用 `homeStoryFeedMomentsProvider`，只拉近 21 天。没有结果时回退 `todayMomentsProvider`。点「全部记录」去 `/records`。

`recentStoryMomentsProvider` 拉近 365 天，给重页面用。首页不要 watch 它。

群岛槽位 `homeIslandSlotsProvider`：

- 第一槽永远是主岛，`slotId == main`，等级来自 `growthSummaryProvider`。
- 后面最多 5 个副岛槽 `rank_0` … `rank_4`，按 `currentLevel`、成长值、名字排序后取前 5。
- 坐标在 `lib/world/preview/world_island_layout.dart`。

打开副岛详情或主岛详情时，`IslandHomePage` 把 Flame 引擎暂停（离开岛屿 Tab、App 不在前台也会暂停），详情用静态视口 `story_island_static_detail_viewport.dart`，主岛详情仍走 `GrowthWorldViewport`。

当前选中的岛写入 `currentIslandProvider`，SharedPreferences 键：

```text
stday_current_island_id
stday_current_island_id_name
stday_current_island_id_growth_main
```

桌面小组件只展示这座岛的今日任务。拆分见 `.cursor/widget_architecture.md`。启动时还有 `IslandWidgetDayRolloverHost` 做跨日刷新。

## 两条世界

### 主岛：可交互 Flame 世界

```text
IslandHomePage
  -> GrowthWorldViewport
  -> WorldStateCache（lib/world/rendering/world_state_cache.dart）
  -> IslandBuildService / GrowthWorldEngine
  -> WorldState
  -> WorldScene
```

`GrowthWorldEngine` 把资料、记录、解锁、天气收成 `WorldState`。`IslandGenerator` 产出的是子类 `WorldStateV2`，渲染层仍按 `WorldState` 读。

层、字段、Y 排序见 `GAME_ENGINE.md`。layer 和 renderer 里面不要再读 provider 或 repository。

### 副岛：预览快照

副岛不走主岛的解锁建筑表。`StoryIslandWorldBuilder`（`lib/world/preview/story_island_world_builder.dart`）拿一份 `WorldState` 基座，按岛屿等级换成副岛建筑和站位。首页卡片、群岛、详情静态视口都吃这个快照。

建筑锚点只在 `StoryIslandLayout.buildingAnchor`（`lib/core/constants/story_island_layout.dart`）：

- Lv10 在岛心。
- Lv1–Lv9 分三环，每环 3 座。环半径 0.48、0.32、0.18，再夹到岛缘内。
- 详情视口缩放 1.58，小人站位 `(0.50, 0.56)`。
- 这些数字只影响副岛。主岛布局在 `lib/island/placement/`。

美术名称和资源路径见 `docs/STORY_ISLAND_WORLD_SPEC.md`。改建筑名要同时改 Dart catalog 和 `backend/app/config/story_island_buildings.py`。

## 故事岛数据

模型：`lib/data/models/story_island_models.dart`。

一座岛的关键字段：

| 字段 | 含义 |
|---|---|
| `categoryId` | 人生维度，与建筑 catalog 的 key 相同 |
| `growthValue` / `growthTarget` | 岛自己的成长。每级 30，满级目标 300 |
| `currentLevel` | 0 表示还没到 Lv1。有成长值或有记录算「已开启」 |
| `storyCount` | 安放到这座岛的日常数 |
| `todayTasks` | 今日任务。小组件最多展示 3 条 |
| `rewardsUserGrowth` 或 `backgroundConfig.is_growth_main` | 这是成长主岛，完成任务可以回馈用户成长 |
| `isArchived` | 归档后不计入「每个分类免费 1 座」 |

分类（与资源目录 `assets/images/islands/<id>/` 一致）：

```text
work study health social life finance
milestone inspiration creation emotion achievement
```

状态：

```text
storyIslandGroupsProvider     GET /profile/story-islands
growthMainIslandProvider      GET /profile/growth-main-island
StoryIslandRepository         创建、改岛、任务增删改、完成、取消完成
MomentRepository.updateMomentStoryIsland
                              PATCH /profile/moments/{id}/story-island
```

写完一条日常后，用户在 `story_island_placement_sheet.dart` 把它安放到某座岛。安放改变的是这条 moment 的岛，不是直接改建筑坐标。

非 VIP 每个分类只能有 1 座未归档岛，常量 `nonVipStoryIslandLimitPerCategory`。超出时 `IslandHomePage._createStoryIsland` 弹出 VIP 对话框。

## 用户成长（主岛等级）

`GrowthSystem`（`lib/core/growth/growth_system.dart`）是离线兜底，数字必须和 `growth_points_service.py` 一致。

- 等级 Lv1–Lv20，称号从「初心者」到「岛屿传说」。
- 累计成长值上限 2700，Lv20 门槛 2480。
- 当日：心情 10，认真记录（至少 10 字）5，AI 小结 5。
- 连续天数里程碑：2/3/7/14/30/60/100/365 天分别加 5/10/20/30/50/100/150/500。
- 建筑解锁走 `buildingUnlocksProvider` 和 `island_unlock_catalog.dart`。
- 升级庆祝在 `features/achievement/growth_reward_actions.dart`，对话框 UI 在 `design_system/growth_reward_dialog.dart`。对话框不读 provider。

副岛等级和用户等级是两套数。副岛满级是 10，用户满级是 20。

## 会员

会员快照 `memberProvider`，10 分钟内复用。`isVipProvider` 为真才算 VIP。购买走 `iapCatalogProvider`：iOS 上 `IapLifecycleHost` 在登录后初始化 `in_app_purchase`，验单打 `/iap/verify`，恢复打 `/iap/restore`。激活码打 `/member/redeem`。页面是 `/more/membership`。

商品与展示价在 `lib/core/membership/iap_product_ids.dart`，和后台 `member_products` 对齐：月卡 12 元、季卡 28 元、年卡 98 元。商品 ID 见 `docs/BACKEND_API.md`。界面优先显示这套人民币标价。

当前客户端拦住非 VIP 的地方：

| 能力 | 位置 |
|---|---|
| 每个分类第 2 座及以后的故事岛 | `island_home_page.dart` |
| 回顾一座岛的全部日常 | `story_island_moments_dialog.dart` |
| 语音记录 | `write_story_page.dart` 切换到语音模式 |
| 给日常加照片 | `MomentPhotoSection.addPhotosEnabled` |
| 补写历史日期 | `record_page.dart` |
| 修改历史日期的心情 | `moment_mood_picker.dart` |
| 当日第 2 条及以后的小人对话 | `canUseFreeCompanionDialogue`：当天按创建时间最早的那条免费 |
| 心情统计、标签统计、周期 AI 小结 | `mood_status_page.dart` 用 `VipFeatureMask`；非 VIP 的 `moodPeriodSummaryProvider` 直接返回空小结 |
| 周成长观察 | `weeklySummaryProvider` 对非 VIP 返回空文案 |
| 角色「小愿」「小梦」 | `CompanionRoles.premiumRoleIds`，选择器锁定 |

蒙版和对话框在 `lib/core/membership/vip_guard.dart`。对话框只负责跳到 `/more/membership`，不自己发购买请求。

## 音频

`AppAudioController` 由 `appAudioControllerProvider` 持有。设置页 `/more/audio`，状态 `appAudioSettingsProvider`。

路由用 `_AudioRouteHost` 按页面切换 BGM：

| `AppBgmContext` | 路由 |
|---|---|
| `welcome` | `/welcome`、`/auth`、注册、全部 onboarding |
| `island` | 主壳岛屿（在岛屿页内切换） |
| `insights` | `/insights` |
| `more` | `/more` 及其子页 |

岛和欢迎页按本地时间分昼夜：6:00–19:00 用 `bgm_island_day_loop.mp3`，其余用 `bgm_island_night_loop.mp3`。洞察和「我的」按文件名在 `AssetManifest` 里找带 `insights` / `more` 的音频，找不到用 fallback。文件可以先缺着，播放失败会被吞掉。

音效 `AppSfx`：点击、任务完成、成长、升级、日常保存、VIP 成功。资源在 `assets/audio/`。

## 法律与欢迎页

`/welcome` 的页面类是 `WelcomePage`，它的 `build` 直接返回 `LandingPage`。欢迎页的区块在 `lib/features/landing/`。

协议正文写在客户端 `lib/core/legal/legal_documents.dart`，不是接口拉下来的。

```text
/legal/terms     用户协议 userAgreement
/legal/privacy   隐私政策 privacyPolicy
```

这两条路由未登录也能打开。对外名称是「星屿」，协议里的产品名是「成长小岛（星屿）」。

## 登录后的去向

`appRouterProvider` 的 `initialLocation` 是 `/welcome`。

- 未登录访问四个主 Tab、onboarding、`/more/*` → `/auth`。
- 未登录访问其它非公开页 → `/welcome`。公开页还有注册和两条法律页。Debug 下 `/debug/*` 也公开。
- 已登录但资料拉取失败，主功能页回到 `/welcome`。
- 已登录且已有陪伴角色，再进欢迎/登录/注册 → `/island`。
- 已登录但还没有陪伴角色 → `/onboarding/gender`。性别页选定角色后去 `/records`。
- `/today` → `/records`，`/status` → `/insights`。
- `stday://` 不交给 GoRouter 解析路径：未登录去 `/auth`，已登录去 `/island`，再由 `WidgetDeepLinkHost` 消费。

主 Tab：`/island`、`/records`、`/insights`、`/more`，`StatefulShellRoute.indexedStack`。
