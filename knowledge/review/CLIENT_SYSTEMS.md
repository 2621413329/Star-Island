# 实现审核

| | |
|---|---|
| 编号 | KB-10 |
| 回答的问题 | 给人审：这条链路现在怎么走完，和之前差在哪 |
| 不负责 | 文件全表和接口字段 |
| 何时更新 | 用户能感知的行为变了 |
| 路由 | 只在 `knowledge/README.md` |


这份文档给人看。AI 改完代码后，用它核对两件事：这条链路现在怎样一步步走完，以及和改之前的文档或结构差在哪里。

文件在 KB-04，禁区在 KB-08，接口在 KB-11。这里只写动作和差异。

对照口径：

- **现在**：当前代码里实际走完的动作。
- **之前**：上一版行为。这份稿第一次补齐时，「之前」指当时旧知识库里的说法。以后再改行为，把本节原来的「现在怎么走完」挪进差异表的「之前」，再写新的动作链。

改了一条用户能感知的行为，就改对应这一节，不要只改 `knowledge/ai/`。AI 的硬性要求写在 `knowledge/ai/coding_rules.md`。

## 目录

- [1. 应用启动](#kb-1-应用启动)
- [2. 打开应用后去哪一页](#kb-2-打开应用后去哪一页)
- [3. 岛屿首页](#kb-3-岛屿首页)
- [4. 主岛画面](#kb-4-主岛画面)
- [5. 副岛画面](#kb-5-副岛画面)
- [6. 写一条日常并放到岛上](#kb-6-写一条日常并放到岛上)
- [7. 新建一座副岛](#kb-7-新建一座副岛)
- [8. 今日任务和桌面小组件](#kb-8-今日任务和桌面小组件)
- [9. 用户等级和副岛等级](#kb-9-用户等级和副岛等级)
- [10. 会员](#kb-10-会员)
- [11. 音频](#kb-11-音频)
- [12. 协议页](#kb-12-协议页)
- [13. 和后端文档的差异](#kb-13-和后端文档的差异)
- [14. 按住说话，转成文字](#kb-14-按住说话-转成文字)
- [15. 照片](#kb-15-照片)
- [16. 陪伴对话从哪来、点开说什么](#kb-16-陪伴对话从哪来-点开说什么)
- [17. 升级庆祝、经验飘字、种子动画](#kb-17-升级庆祝-经验飘字-种子动画)
- [18. 完成或撤销一条今日任务](#kb-18-完成或撤销一条今日任务)
- [19. 天气什么时候才去请求](#kb-19-天气什么时候才去请求)
- [20. 从桌面小组件点进来](#kb-20-从桌面小组件点进来)
- [21. 注销账号](#kb-21-注销账号)

<a id="kb-1-应用启动"></a>

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

<a id="kb-2-打开应用后去哪一页"></a>

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
| 欢迎页被当成独立的 `WelcomePage` 布局 | 欢迎页的区块在 `stday/lib/features/landing/` |

审核时看 `stday/lib/router/app_router.dart` 的 `redirect`。主 Tab 仍是 `/island`、`/records`、`/insights`、`/more`。

<a id="kb-3-岛屿首页"></a>

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

群岛槽位：第一槽固定是主岛。后面最多 5 座副岛，按等级、成长值、名字取前 5，槽位 id 是 `rank_0` 到 `rank_4`。坐标在 `stday/lib/world/preview/world_island_layout.dart`。

<a id="kb-4-主岛画面"></a>

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

<a id="kb-5-副岛画面"></a>

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
| 新增建筑的文档只指向主岛 `building_config` 和 `BuildingLayer` | 副岛换图走 catalog、Python 配置和 `stday/assets/images/islands/<分类>/buildings/lv01.png`–`lv10.png` |

审核时确认没有去改 `stday/lib/island/placement/`。那是主岛的房子和大树。副岛每级 30 成长值、满级 300，和用户 Lv1–Lv20 不是同一套数。

分类目录：`work`、`study`、`health`、`social`、`life`、`finance`、`milestone`、`inspiration`、`creation`、`emotion`、`achievement`。建筑中文名改动时，Dart catalog 和 `backend/app/config/story_island_buildings.py` 要一起改。

<a id="kb-6-写一条日常并放到岛上"></a>

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

审核时看 `write_story_page.dart` 的 `_selectInputMode`、`record_page.dart` 的补记入口、`moment_mood_picker.dart` 开头的日期判断。按住说话转成文字、照片上传、保存后的升级庆祝和种子动画，见第 14、15、17 节。文字模式里的「按住说话」不走语音日常那道会员门。

<a id="kb-7-新建一座副岛"></a>

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

<a id="kb-8-今日任务和桌面小组件"></a>

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

<a id="kb-9-用户等级和副岛等级"></a>

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

<a id="kb-10-会员"></a>

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
| 后端 README 只写了认证和资料 | 会员和内购是独立路由，见 `knowledge/BACKEND_API.md` |

审核时沿这张表点一次非会员路径，确认被拦住的是动作本身，而不是把免费的第一座岛、当天第一条对话也拦住。

<a id="kb-11-音频"></a>

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

<a id="kb-12-协议页"></a>

## 12. 协议页

现在怎么走完：

1. `/legal/terms` 和 `/legal/privacy` 打开 `LegalDocumentPage`。
2. 正文在 `stday/lib/core/legal/legal_documents.dart`，不从接口拉。
3. 未登录也能打开。对外名称是「星屿」，协议里的产品名是「成长小岛（星屿）」。

和之前的差异：旧路由表没有这两条，feature map 也没有 `features/legal/`。

<a id="kb-13-和后端文档的差异"></a>

## 13. 和后端文档的差异

之前 `PROJECT.md` 写仓库里没有 `backend/`。`backend/README.md` 只列了认证和资料两类接口。

现在客户端所有 HTTP 仍从一个 `StdayApiDatasource` 出去，但对外已经拆成 12 个 repository。故事岛、任务、心情周期、会员、内购、成长标签、国际化都在 `knowledge/BACKEND_API.md`。审核接口时以那份表为准，不要用旧 README 的两行前缀判断「这个接口不存在」。

<a id="kb-14-按住说话-转成文字"></a>

## 14. 按住说话，转成文字

这和「语音日常」不是同一条路。语音日常会把一段录音当成这条记录本身，切到该模式前要会员。按住说话只把转写插进正在写的文字，文字模式里 `MomentNoteField` 的 `enableSpeechInput` 在非 Web 上开着，不查 `isVipProvider`。

现在怎么走完：

1. 按住输入框上的语音按钮。先要麦克风权限，没有就停，不请求转写。
2. 松开后 `StoryVoiceRecorder.stop`。没有结果或时间太短，提示「说话时间太短」，不上传。
3. `VoiceRepository.transcribeSpeechNote` 先 `POST /profile/speech/transcribe`。只有 404 才改试 `POST /profile/moments/voice/transcribe`。两条都 404 时，才临时建一条语音日常、轮询今天的记录直到拿到转写、然后删掉这条临时日常。其它接口错误直接失败，不往下试。
4. 本地临时录音文件随即删掉，不管转写成功与否。
5. 空文本提示「未识别到语音」。有文本时按松开前的光标或选区插入：光标前一个字符不是空白，就先补一个空格。正文最长 500 字，超出从末尾截掉。光标落到插入文本末尾。
6. 这时还没保存日常。之后仍走文字保存 `POST /profile/moments`。

和之前的差异：

| 之前 | 现在 |
|---|---|
| 知识库把语音收成一个能力，和会员绑在一起 | 录音成日常要会员。按住转写插进正文不查会员 |
| 没有写转写结果怎么进正文 | 按选区插入，不覆盖整段；超长截到 500 字 |

审核时看 `moment_form_widgets.dart` 的 `_finishTranscription`、`speech_note_merge.dart` 的 `insertSpeechAtSelection`，以及 `StdayApiDatasource.transcribeSpeechNote` 的 404 回退。成功的按住说话不应在今日列表里留下 `speech-note-temp` 那条临时日常。

<a id="kb-15-照片"></a>

## 15. 照片

现在怎么走完：

1. 写日常页里，非会员点添加照片会进 `showVipRequiredDialog`，选图面板不打开。会员最多 6 张，常量 `momentMaxPhotos`。
2. 先保存文字或语音日常，拿到 moment id。
3. `_syncPhotos` 先对已去掉的远程照片逐个 `DELETE /profile/moments/{id}/photos/{photo_id}`，再对还在本地的新照片逐个 `POST /profile/moments/{id}/photos`。
4. 后端只存文件，不把照片送去 AI 分析。

和之前的差异：

| 之前 | 现在 |
|---|---|
| 日常能力列表里「照片」没有先后顺序 | 先有日常，再按增删差量同步照片 |
| 没有张数上限 | 最多 6 张 |

审核时看 `write_story_page.dart` 的 `_syncPhotos`。添加按钮的会员判断在照片区 `addPhotosEnabled`，不在上传函数里。上传函数本身不再看 VIP。

<a id="kb-16-陪伴对话从哪来-点开说什么"></a>

## 16. 陪伴对话从哪来、点开说什么

现在怎么走完：

1. 保存日常后，后端分析把台词写进这条 moment 的 `visual_payload`。详情页用的是 `story_summary_lines`，等待时用 `waiting_lines`。模板里称呼用户必须写 `{nickname}`，不要写死昵称。生成在 `backend/app/services/companion_action_ai_service.py`。
2. 客户端不自己编这 3 句。`storySummaryLinesFor` 读 payload，把 `{nickname}` 换成当前昵称。没有台词时用标签和心情拼一套兜底模板。
3. 岛屿页把当前这批日常的两类台词收成列表，随机从其中一句开始显示，定时换下一句。
4. 记录卡片或详情里点小人：是会员，或者这是当天创建时间最早的那条，就展示一句。否则弹出会员框。

和之前的差异：

| 之前 | 现在 |
|---|---|
| 陪伴被写成画在岛上的角色外观 | 外观在 `CharacterLayer`。气泡台词来自每条日常的分析结果，不是世界引擎算出来的 |
| 会员只被理解成统计和语音 | 当天第 2 条及以后的点按对话也要会员。岛上自动冒出的那句不走这道门 |

审核时看 `profile_models.dart` 的 `storySummaryLinesFor`，以及 `today_story_card.dart` / `moment_detail_page.dart` 里的 `canUseFreeCompanionDialogue`。改 AI 提示词时，称呼仍必须是 `{nickname}`。

<a id="kb-17-升级庆祝-经验飘字-种子动画"></a>

## 17. 升级庆祝、经验飘字、种子动画

现在怎么走完：

1. 调用方先记下动作前的 `GrowthSummary`。保存日常、上报心情、在副岛详情里补记、完成或撤销主岛任务之后，调用 `showGrowthRewardsAfterAction`。
2. 它再拉一次 `GET /profile/growth-summary`。接口失败就用近 365 天的日常在本地 `GrowthSystem.compute` 兜底。两次都失败就什么都不弹。
3. 动作前的摘要是空的，也不弹。
4. 等级变高：播升级音效，弹出 `showLevelUnlockCelebration`，并记下已确认等级。连续天数跨过 2/3/7/14/30/60/100/365 之一：强提示「连续成长 N 天」，然后结束，不再叠经验飘字。否则经验增加：`GrowthValueOverlay` 加上成长音效。
5. 另外，岛屿页第一次拿到非游客的成长摘要时，`maybeShowDailyLevelUnlockPrompt` 看本地上次确认的等级。当前等级更高就补弹一次解锁庆祝。这只补弹，不对比这一次动作的经验差。
6. 文字保存后如果用户把这条日常安放到岛上：先走上面的成长庆祝，再把 `pendingStorySeedAnimationProvider` 设上目标岛，然后 `go('/island')`。岛屿页看到这个请求就打开那座岛的详情并播放种子动画。动画结束且副岛成长值增加时，再提示「岛屿成长值 +N」。
7. 已经站在某座副岛详情里补记时，不绕回首页。保存成功后本地设 `_showSeedAnimation`，刷新这只岛，同样在动画结束后提示岛屿成长值。

和之前的差异：

| 之前 | 现在 |
|---|---|
| 成长文档停在「等级和建筑解锁」 | 一次保存可能依次出现升级庆祝或经验飘字，再到岛上的种子动画 |
| 升级弹窗被理解成只在动作当下出现 | 进岛时如果本地确认等级落后，还会补弹一次 |

审核时看 `growth_reward_actions.dart`。等级弹窗和连续天数提示不会同时出。种子动画的请求在 `pendingStorySeedAnimationProvider`，消费它的是 `IslandHomePage.build`。

<a id="kb-18-完成或撤销一条今日任务"></a>

## 18. 完成或撤销一条今日任务

现在怎么走完：

1. 任务已经完成，或这个 task id 正在 `_busyTaskIds` 里，完成请求直接返回。撤销则要求当前是已完成。
2. 成长主岛：直接 `StoryIslandRepository.completeTask` 或 `uncompleteTask`，再 `growthMainIslandProvider.patchIsland`，并让 `growthSummaryProvider` 失效。完成后用动作前的成长摘要走第 17 节的庆祝。撤销且 `growthDelta > 0` 时，先强提示「经验值 -N」，再走同一套庆祝函数。
3. 普通副岛：走 `storyIslandGroupsProvider` 里的完成或撤销。完成后用任务上的 `growthDelta` 强提示「岛屿成长值 +N」，并播任务完成音效。撤销时提示减去同样的数。当前打开的就是这座岛时，用返回的岛替换 `_activeStoryIsland`。
4. 改标题、是否每日、删除任务，也按「是不是成长主岛」分这两条 repository 路径，然后刷新对应的岛。这些操作不弹成长庆祝。

和之前的差异：

| 之前 | 现在 |
|---|---|
| 小组件文档写了任务来自当前岛，没写 App 里点完成之后发生什么 | 主岛任务回馈用户经验并可能升级。副岛任务只回馈这座岛的成长值 |
| 完成被写成单一的 `completeTask` | 主岛走 repository 再 patch 主岛 provider。副岛走分组 provider |

审核时看 `island_home_page.dart` 的 `_completeStoryIslandTask` 和 `_uncompleteStoryIslandTask`。两条路径的反馈文案不同，不要合成一次提示。

<a id="kb-19-天气什么时候才去请求"></a>

## 19. 天气什么时候才去请求

现在怎么走完：

1. `islandWeatherFetchEnabledProvider` 初始是 false。这时 `islandWeatherProvider` 直接返回 null，岛用心情氛围，不读定位、不请求 Open-Meteo。
2. 岛屿页首屏先画出已有数据。静默刷新末尾调用 `scheduleDeferredIslandWeatherFetch`，800 毫秒后才把开关设为 true。
3. 下拉刷新走 `_refresh`，立刻 `enableIslandWeatherFetch`，再 `invalidate(islandWeatherProvider)` 并等待它。
4. 拉取失败同样是 null，画面退回心情氛围，不保留上一次的天气对象。

和之前的差异：

| 之前 | 现在 |
|---|---|
| 天气被写成岛屿页一打开就由 provider 去拉 | 开关关上时 provider 不发请求。首屏至少晚 800 毫秒 |
| 失败时的画面没有写 | 失败和未开启是同一种空结果，都回心情氛围 |

审核时看 `island_weather_provider.dart`。不要在 `WorldScene` 或 layer 里打开这个开关。

<a id="kb-20-从桌面小组件点进来"></a>

## 20. 从桌面小组件点进来

现在怎么走完：

1. `WidgetDeepLinkHost` 读启动链接和后续的 `stday://`。`parseWidgetDeepLink` 认这几条：`widget/island`、`widget/task`、`widget/quick-record`、`widget/cycle`（也认不带 `widget/` 的同名路径）。缺 `islandId` 或任务缺 `taskId` 时意图是 null，不导航。
2. 未登录只把意图留在 `pendingWidgetDeepLinkProvider`。登录且 ready 之后才处理。
3. `cycle` 不打开详情。它在已有岛列表里按 prev/next 改 `currentIslandProvider`，并立刻 `syncIslandWidget`。列表还空就先刷新，等 300 毫秒再试。
4. 其余动作先按 id 找岛，最多试 8 次。找到就写成当前岛，把动作放进 `pendingIslandWidgetNavigationProvider`，切到岛屿 Tab，`go('/island')`。
5. 岛屿页在首帧和每次这个 provider 变化时消费它：打开该岛详情，等 420 毫秒。`openIsland` 到此结束。`openTask` 把岛 id 写进 `pendingTaskDockIslandIdProvider`，让任务坞展开。`quickRecord` 打开写日常，并带上这座岛的 id 和名字，保存时不用再选岛。

和之前的差异：

| 之前 | 现在 |
|---|---|
| 小组件文档停在「深链落到岛页，由 Host 消费」 | Host 只解析并切到 `/island`。打开详情、任务坞和快速记录发生在 `handlePendingIslandWidgetNavigation` |
| `cycle` 没有出现在给人看的动作里 | 左右切岛只改当前岛并刷新小组件，不进详情 |

审核时看 `widget_deep_link_handler.dart` 的 `_handleIntent` 和 `handlePendingIslandWidgetNavigation`。路由层仍把任意 `stday://` 先送到 `/island` 或 `/auth`，真正的任务参数不要靠 GoRouter 的 path。

<a id="kb-21-注销账号"></a>

## 21. 注销账号

现在怎么走完：

1. 「我的」页点注销。第一遍说明账号、成长记录、会员权益会被永久删除。取消就停。
2. 第二遍再确认。取消就停。两次都确认后才请求。
3. `AuthRepository.deleteAccount` 打 `DELETE /api/v1/auth/me`。
4. 成功后本地 `logout`，并让资料、今日日常、会员三份状态失效，弱提示「账号已注销」，`go('/welcome')`。
5. 接口或网络失败只出 SnackBar。不登出，不跳欢迎页。

和之前的差异：

| 之前 | 现在 |
|---|---|
| 给人看的链路里没有注销 | 两次确认后删除服务端账号，再清本地登录态 |
| 容易理解成和普通退出一样，只清 token | 退出登录不调 `DELETE /auth/me`。注销会 |

审核时看 `more_page.dart` 的 `_confirmDeleteAccount`。成功路径的顺序是先删服务端，再 `logout`。请求失败时 token 还在。
