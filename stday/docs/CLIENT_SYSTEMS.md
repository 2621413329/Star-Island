# 实现审核

这份文档给人看。AI 改完代码后，用它核对两件事：这条链路现在怎样一步步走完，以及和改之前的文档或结构差在哪里。

文件路径和禁区仍以 `stday/.cursor/` 为准。接口表在 `docs/BACKEND_API.md`。这里不重复那两份清单，只写动作和差异。

对照口径：

- **之前**：本轮改知识库之前，`PROJECT.md`、`ARCHITECTURE.md`、`GAME_ENGINE.md`、`.cursor/` 里写的那套。
- **现在**：当前代码里实际走完的动作。

## 1. 应用启动

现在怎么走完：

1. `main.dart` 初始化绑定和中文日期格式。
2. 陪伴图集在后台加载，不挡住后面的步骤。
3. 初始化本地提醒，再初始化桌面小组件。
4. 从 SharedPreferences 读出 token，放进 `AppBootstrap`。
5. `ProviderScope` 包住一串 Host，从外到内是：会员、内购、提醒、小组件跨日、深链，最里面才是 `StdayApp`。
6. 登录态变化时，会员 Host 刷新 `/member/me`，内购 Host 在 iOS 上开始监听 App Store。

和之前的差异：

| 之前 | 现在 |
|---|---|
| 文档停在 `ReminderLifecycleHost` → `StdayApp` | 会员、内购、小组件跨日、深链都包在提醒外面 |
| 启动步骤里没有 `IslandWidgetService.initialize()` | 提醒初始化之后就会初始化小组件 |

审核时看 `stday/lib/main.dart` 的 `runApp`。Host 顺序反了，登录后的会员和内购就不会跟着走。

## 2. 打开应用后去哪一页

现在怎么走完：

1. 路由初始页是 `/welcome`。`WelcomePage` 不画自己的界面，直接画出 `LandingPage`。
2. 未登录可以留在欢迎、登录、注册、用户协议、隐私政策。Debug 下 `/debug/*` 也可以。
3. 未登录去四个主 Tab、新手引导或 `/more/*`，会被送到 `/auth`。其它非公开地址送到 `/welcome`。
4. 已登录、资料还没拿到或拉取失败，主功能页回到 `/welcome`。
5. 已登录且已经选过陪伴角色，再进欢迎、登录、注册，进 `/island`。
6. 已登录但还没有陪伴角色，进 `/onboarding/gender`。在那里选完角色后去 `/records`。
7. `/today` 改去 `/records`，`/status` 改去 `/insights`。
8. `stday://` 不按路径解析。未登录去 `/auth`，已登录去 `/island`，具体任务交给 `WidgetDeepLinkHost`。

和之前的差异：

| 之前 | 现在 |
|---|---|
| 路由表写到 `/more/about`，没有音频、会员、法律页 | `/more/audio`、`/more/membership`、`/legal/terms`、`/legal/privacy` 都已注册 |
| 已登录离开欢迎页一律理解成回岛 | 没有陪伴角色时去选角色，选完去记录页，不是岛页 |
| 欢迎页被当成独立的 `WelcomePage` 布局 | 欢迎页的区块在 `lib/features/landing/` |

审核时看 `lib/router/app_router.dart` 的 `redirect`。主 Tab 仍是 `/island`、`/records`、`/insights`、`/more`。

## 3. 岛屿首页

现在怎么走完：

1. `/island` 挂的是 `IslandHomePage`，不是 `HomePage`。
2. 没有打开主岛或副岛详情时，岛屿页把 `HomePage` 嵌在里面。
3. 滚动页从上到下是：等级和天气、群岛、可选的主岛今日任务、写日常入口、今日故事。
4. 今日故事用近 21 天的 `homeStoryFeedMomentsProvider`。这份没有数据时，才用今天的 `todayMomentsProvider`。
5. 点「全部记录」去 `/records`。点写日常打开 `showAddMomentFlow`。
6. 点群岛上的一座岛，回调回到 `IslandHomePage`，打开对应详情，并暂停主岛 Flame 引擎。离开岛屿 Tab 或 App 不在前台时同样暂停。
7. 副岛详情用静态视口。主岛详情仍用 `GrowthWorldViewport`。

和之前的差异：

| 之前 | 现在 |
|---|---|
| 文档把 `HomePage` 写成一个新的路由首页 | 它只是 `/island` 里面的滚动内容 |
| 岛屿链路被写成打开页就进 `GrowthWorldViewport` | 先看群岛滚动页，点开详情才进主岛引擎或副岛静态视口 |
| 首页会被理解成拉取长历史 | 首页故事只看 21 天。近 365 天的 `recentStoryMomentsProvider` 不给首页 watch |

审核时看 `island_home_page.dart` 里创建 `HomePage` 的位置，以及 `home_page.dart` 的滚动顺序。

群岛槽位：第一槽固定是主岛。后面最多 5 座副岛，按等级、成长值、名字取前 5，槽位 id 是 `rank_0` 到 `rank_4`。坐标在 `lib/world/preview/world_island_layout.dart`。

## 4. 主岛画面

现在怎么走完：

1. 资料、今日记录、解锁和天气收成 `WorldState`。`IslandGenerator` 产出的是子类 `WorldStateV2`，层仍然只读 `WorldState`。
2. `WorldStateCache` 能复用就复用，再交给 `GrowthWorldViewport` 和 `WorldScene`。
3. 完整层序：天空、云、远景、海洋、岛体、装饰、建筑、前景草、角色、特效、UI 覆盖层。Debug 打开时最后加调试层。
4. 只要岛、不要天空海洋时，只留岛体、装饰、建筑、角色和调试层。
5. 地面上的建筑、装饰、角色按归一化 y 排序，y 越大越后画、越靠前。前景草用固定优先级 9600，压在这些地面物体之上，不跟它们比 y。
6. 等级条、建筑气泡、陪伴台词是 Flutter 叠层，不在 Flame 层序里。

和之前的差异：

| 之前 | 现在 |
|---|---|
| 层序写成天空、海洋、岛、前景草、装饰、建筑、角色 | 云和远景在海洋前；装饰和建筑在前景草前；草之后才是角色、特效、UI 层 |
| `WorldState` 只列了岛、角色、建筑、植物、环境、性别 | 还有区域、装饰、路径、特效、锚点和 `schemaVersion`。带 `cameraFocus` 的锚点会拉动视口中心 |
| 相机只写在视口和 `WorldScene` | 主岛还有 `island_view_camera.dart`。首页群岛用另一份 `world_preview_camera.dart` |

审核时看 `world_scene.dart` 的 `onLoad`。层序改错时，草会盖不住建筑脚，或者角色被草挡住。

## 5. 副岛画面

现在怎么走完：

1. 故事岛数据来自 `storyIslandGroupsProvider`（分组列表）和 `growthMainIslandProvider`（成长主岛那一条）。
2. `StoryIslandWorldBuilder` 拿一份 `WorldState` 基座，按这座岛的等级换成副岛建筑和站位。
3. 首页卡片和群岛吃这个快照。详情页吃静态视口，不把主岛引擎再跑一遍。
4. 建筑点位只从 `StoryIslandLayout.buildingAnchor` 来。Lv10 在岛心。Lv1 到 Lv9 是三环，每环 3 座，半径 0.48、0.32、0.18，再夹进岛缘。
5. 详情比主岛默认视口放大 1.58 倍。小人站在 `(0.50, 0.56)`，不用主岛前缘那个点。

和之前的差异：

| 之前 | 现在 |
|---|---|
| 副岛规范写锚点在 `StoryIslandWorldBuilder._buildingAnchor`，岛屿页里还有同名函数 | 这两个函数都不存在。坐标只在 `story_island_layout.dart` |
| 规范里的示意图把 Lv1、Lv2、Lv3 画成最外一排的左中右 | 代码是外环 Lv1–Lv3、中环 Lv4–Lv6、内环 Lv7–Lv9、中心 Lv10 |
| 新增建筑的文档只指向主岛 `building_config` 和 `BuildingLayer` | 副岛换图走 catalog、Python 配置和 `assets/images/islands/<分类>/buildings/lv01.png`–`lv10.png` |

审核时确认没有去改 `lib/island/placement/`。那是主岛的房子和大树。副岛每级 30 成长值、满级 300，和用户 Lv1–Lv20 不是同一套数。

分类目录：`work`、`study`、`health`、`social`、`life`、`finance`、`milestone`、`inspiration`、`creation`、`emotion`、`achievement`。建筑中文名改动时，Dart catalog 和 `backend/app/config/story_island_buildings.py` 要一起改。

## 6. 写一条日常并放到岛上

现在怎么走完：

1. 首页或记录页打开写日常。文字直接写。切到语音前先看 `isVipProvider`，不是会员就弹出开通框，不进入录音。
2. 加照片同样先看是不是会员。非会员走 `onAddBlocked`。
3. 保存走 `MomentRepository`：文字 `POST /profile/moments`，语音 `POST /profile/moments/voice`。
4. 写完后用安放面板把这条日常放上一座岛，请求是 `PATCH /profile/moments/{id}/story-island`。
5. 这一步改的是这条记录属于哪座岛，不改建筑坐标。
6. 补写过去某一天，从记录页进入，非会员会被拦住。修改过去某一天的心情，从心情选择进入，非会员同样被拦住。当天的心情仍可改。
7. 点开小人对话时，这一天按创建时间最早的那条免费。同一天更晚的记录要会员。

和之前的差异：

| 之前 | 现在 |
|---|---|
| 日常文档只写文字、语音、照片、标签，没有安放岛 | 安放是单独的 moment 接口，repository 方法是 `updateMomentStoryIsland` |
| 语音和照片被写成所有登录用户都能用 | 这两项在客户端先被会员挡住，请求发不出去 |
| 记录页被当成今日列表 | 补历史日期也从这里进，并且要会员 |

审核时看 `write_story_page.dart` 的 `_selectInputMode`、`record_page.dart` 的补记入口、`moment_mood_picker.dart` 开头的日期判断。

## 7. 新建一座副岛

现在怎么走完：

1. 全部岛屿面板里选一个分类。
2. `IslandHomePage._createStoryIsland` 数这个分类里还没归档的岛。
3. 不是会员，而且这个分类已经有 1 座，就弹出「继续创建需要开通 VIP」，不请求后端。
4. 否则弹出命名框。确认后 `StoryIslandRepository.createStoryIsland`，`POST /profile/story-islands`。
5. 分组列表刷新，首页槽位按新等级重排。

和之前的差异：

| 之前 | 现在 |
|---|---|
| 知识库没有 `StoryIslandRepository`，岛相关请求被写成成长和建筑解锁 | 建岛、改岛、任务的增删改和完成都在这个 repository |
| 没有「每分类免费一座」 | 常量 `nonVipStoryIslandLimitPerCategory` 等于 1。归档的岛不计数 |

审核时看创建函数里的比较是「已经有的数量 ≥ 1」才拦截，避免把第一座也拦住。

## 8. 今日任务和桌面小组件

现在怎么走完：

1. 用户选中的岛写进 `currentIslandProvider`。本地键是 `stday_current_island_id`、同名加 `_name`、同名加 `_growth_main`。
2. 小组件同步监听这座岛、故事岛分组、成长主岛和登录态。登出会清空快照。
3. Flutter 侧把这座岛的今日任务截成最多 3 条，写入 `island_widget_payload`。
4. iOS 用 App Group，Android 用 `home_widget` 的 SharedPreferences。原生端只读快照，不算任务。
5. 点击走 `stday://widget/island`、`task` 或 `quick-record`。App 落到岛页后由深链 Host 打开任务或记录。
6. 跨过一天时，`IslandWidgetDayRolloverHost` 再同步一次。

和之前的差异：

| 之前 | 现在 |
|---|---|
| 小组件文档已经比较接近实现，但启动链没写跨日 Host | 跨日刷新在 `main.dart` 的 Host 链里，不在小组件文档原来的那张表上 |
| 容易理解成小组件汇总全部岛的任务 | `todayTasks` 必须属于 `currentIslandId` |

审核时看 `island_widget_sync_provider.dart` 监听了谁，以及 payload 里有没有别的岛的任务。

## 9. 用户等级和副岛等级

现在怎么走完：

1. 用户等级看 `growthSummaryProvider`，规则在客户端 `GrowthSystem`，用来离线兜底。
2. 后端同一套数在 `growth_points_service.py`。当天心情 10，认真记录（去掉空白至少 10 字）5，AI 小结 5。连续 2/3/7/14/30/60/100/365 天再加 5/10/20/30/50/100/150/500。
3. 用户 Lv1–Lv20，累计上限 2700，Lv20 的门槛是 2480。称号从「初心者」到「岛屿传说」。
4. 主岛建筑解锁走 `buildingUnlocksProvider`，和副岛的 10 张等级图无关。
5. 升级庆祝的业务在 `growth_reward_actions.dart`，对话框只收普通参数。

和之前的差异：

| 之前 | 现在 |
|---|---|
| 「成长 → 岛屿变化」被写成一条等级 | 用户 20 级管主岛。每座副岛自己 10 级，满级成长值 300 |
| 周观察被写成洞察页的普通数据 | 非会员的 `weeklySummaryProvider` 直接返回空文案，不请求接口 |

审核时对一下 Dart 和 Python 的等级表、连续天数表是否仍是同一组数字。

## 10. 会员

现在怎么走完：

1. 登录后会员 Host 拉 `GET /member/me`。结果在 `memberProvider`，10 分钟内复用。`isVipProvider` 只看这份快照。
2. 开通页是 `/more/membership`。Apple 购买走 `iapCatalogProvider`，验单 `POST /iap/verify`，恢复 `POST /iap/restore`。激活码走 `POST /member/redeem`。
3. 标价写在 `iap_product_ids.dart`：月卡 12 元、季卡 28 元、年卡 98 元。商品 ID 是 `com.xiaoerlcx.app.vip.monthly`、`quarterly`、`yearly`。
4. 被拦住时弹出 `showVipRequiredDialog`，确认后 `push` 到会员页。统计类页面用 `VipFeatureMask` 盖住内容。

当前会拦住非会员的动作：

| 动作 | 拦住的位置 |
|---|---|
| 同一分类的第 2 座未归档副岛 | 岛屿页创建函数 |
| 看一座岛的全部日常 | `story_island_moments_dialog.dart` |
| 语音记录、给日常加照片 | 写日常页 |
| 补写历史日期 | 记录页 |
| 改历史日期的心情 | 心情选择 |
| 当天第 2 条及以后的小人对话 | `canUseFreeCompanionDialogue` |
| 心情统计、标签统计、周期小结 | 洞察页蒙版；非会员的周期小结 provider 返回空 |
| 周成长观察 | `weeklySummaryProvider` |
| 角色「小愿」「小梦」 | `CompanionRoles.premiumRoleIds` |

和之前的差异：

| 之前 | 现在 |
|---|---|
| `.cursor` 的 repository 列表没有会员和内购 | `MemberRepository`、`IapRepository` 已挂在同一个 datasource 上 |
| 洞察、语音、照片没有会员分支 | 上面这张表里的入口都会先看 `isVipProvider` |
| 后端 README 只写了认证和资料 | 会员和内购是独立路由，见 `docs/BACKEND_API.md` |

审核时沿这张表点一次非会员路径，确认被拦住的是动作本身，而不是把免费的第一座岛、当天第一条对话也拦住。

## 11. 音频

现在怎么走完：

1. 每条路由包在 `_AudioRouteHost` 里，按页面选 `AppBgmContext`。
2. 欢迎、登录、注册、全部新手引导用 `welcome`。洞察用 `insights`。「我的」和它的子页用 `more`。岛屿页用 `island`。
3. `welcome` 和 `island` 看本地时间。6:00 到 19:00 播白天循环，其余播夜间循环。
4. 洞察和「我的」先在资源清单里按文件名找带 `insights` 或 `more` 的音频，找不到再用 fallback。
5. 设置页是 `/more/audio`。音效包括点击、任务完成、成长、升级、保存日常、开通会员。文件缺失时播放失败会被吃掉，不弹错误。

和之前的差异：

| 之前 | 现在 |
|---|---|
| 技术栈把 `just_audio` 写成语音播放 | 语音录制仍用 `record`。`just_audio` 现在还负责 BGM 和音效 |
| 路由文档没有音频 Host | 换页就会换 BGM 上下文 |

审核时不要把 BGM 的 6:00–19:00 和世界光照配置当成同一个开关。改画面昼夜不必改曲目时段。

## 12. 协议页

现在怎么走完：

1. `/legal/terms` 和 `/legal/privacy` 打开 `LegalDocumentPage`。
2. 正文在 `lib/core/legal/legal_documents.dart`，不从接口拉。
3. 未登录也能打开。对外名称是「星屿」，协议里的产品名是「成长小岛（星屿）」。

和之前的差异：旧路由表没有这两条，feature map 也没有 `features/legal/`。

## 13. 和后端文档的差异

之前 `PROJECT.md` 写仓库里没有 `backend/`。`backend/README.md` 只列了认证和资料两类接口。

现在客户端所有 HTTP 仍从一个 `StdayApiDatasource` 出去，但对外已经拆成 12 个 repository。故事岛、任务、心情周期、会员、内购、成长标签、国际化都在 `docs/BACKEND_API.md`。审核接口时以那份表为准，不要用旧 README 的两行前缀判断「这个接口不存在」。
