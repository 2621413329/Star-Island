# 后端 API

| | |
|---|---|
| 编号 | KB-11 |
| 回答的问题 | 现行 HTTP 方法、路径和作用 |
| 不负责 | 客户端怎么弹窗、Python 内部实现 |
| 何时更新 | 路径、方法、字段或状态码变了 |
| 路由 | 只在 `knowledge/README.md` |


审核客户端是否打对接口时读本文。动作链和会员门槛在 `knowledge/review/CLIENT_SYSTEMS.md`。

和之前的差异：旧 `backend/README.md` 只写了 `/auth` 和 `/profile` 两类。下面的故事岛、心情周期、会员、内购、标签和国际化都是现行路由，不是计划。

服务：`backend/`，FastAPI。路由装配在 `backend/app/api/v1/api.py`。除单独注明外，成功响应包在 `ResponseModel` 里，业务数据在 `data`。需要登录的接口读 `Authorization: Bearer <token>`。

健康检查：`GET /health`。交互式文档：`GET /docs`。

下面路径都已经带 `/api/v1`。

## 目录

- [认证 auth.py](#kb-认证-auth-py)
- [资料、记录、故事岛 profile.py](#kb-资料-记录-故事岛-profile-py)
  - [资料与陪伴](#kb-资料与陪伴)
  - [成长与主岛解锁](#kb-成长与主岛解锁)
  - [故事岛与今日任务](#kb-故事岛与今日任务)
  - [日常](#kb-日常)
  - [心情与洞察](#kb-心情与洞察)
- [心情岛屿样式](#kb-心情岛屿样式)
- [成长标签](#kb-成长标签)
- [国际化](#kb-国际化)
- [会员](#kb-会员)
- [内购](#kb-内购)
- [客户端 repository 对照](#kb-客户端-repository-对照)

<a id="kb-认证-auth-py"></a>

## 认证 `auth.py`

| 方法 | 路径 | 作用 |
|---|---|---|
| POST | `/auth/entry` | 用户名 + 密码，已注册则登录，否则走注册入口 |
| POST | `/auth/register` | 注册，返回 token |
| POST | `/auth/login` | 登录，返回 token |
| POST | `/auth/token` | OAuth2 风格取 token，响应体是裸 `Token`，没有 `ResponseModel` 外壳 |
| GET | `/auth/me` | 当前用户 |
| DELETE | `/auth/me` | 删除账号。客户端 `AuthRepository.deleteAccount()` |

登录/注册有 Nginx 与 Redis 限流，配置见 `backend/.env.example` 的 `REDIS_*`、`AUTH_*`。

<a id="kb-资料-记录-故事岛-profile-py"></a>

## 资料、记录、故事岛 `profile.py`

前缀 `/profile`。

<a id="kb-资料与陪伴"></a>

### 资料与陪伴

| 方法 | 路径 | 作用 |
|---|---|---|
| GET | `/profile` | 当前资料 |
| PATCH | `/profile/nickname` | 昵称 |
| GET | `/profile/companion-roles` | 可选陪伴角色 |
| PATCH | `/profile/companion-role` | 选定角色 |
| PATCH | `/profile/gender` | 性别 |
| PATCH | `/profile/companion` | 陪伴样式 |
| PATCH | `/profile/mood` | 当前心情 |
| POST | `/profile/onboarding/complete` | 完成新手引导 |
| PATCH | `/profile/app-preferences` | 提醒等应用偏好。客户端 `UserPreferencesRepository` |

<a id="kb-成长与主岛解锁"></a>

### 成长与主岛解锁

| 方法 | 路径 | 客户端 |
|---|---|---|
| GET | `/profile/growth-summary` | `GrowthRepository.getGrowthSummary` |
| GET | `/profile/building-unlocks` | `GrowthRepository.listBuildingUnlocks` |
| GET | `/profile/emotion-fragments` | `GrowthRepository.getEmotionFragments` |
| GET | `/profile/growth-observation` | `GrowthRepository.getWeeklySummary`。周观察，VIP 才请求 |

成长值规则在 `backend/app/services/growth_points_service.py`，与客户端 `GrowthSystem` 对齐：当日心情 10、认真记录（去空白后至少 10 字）5、AI 小结 5，另有连续天数里程碑。等级 Lv1–Lv20，累计上限 2700，满级阈值 2480。

<a id="kb-故事岛与今日任务"></a>

### 故事岛与今日任务

| 方法 | 路径 | 作用 |
|---|---|---|
| GET | `/profile/story-islands` | 按分类分组的故事岛 |
| POST | `/profile/story-islands` | 创建。body：`category_id`、`name`、`size_kind` |
| PATCH | `/profile/story-islands/{island_id}` | 改名、尺寸、排序、背景、封面、归档 |
| GET | `/profile/growth-main-island` | 成长主岛那条故事岛记录 |
| POST | `/profile/story-islands/{island_id}/tasks` | 新建任务 |
| PATCH | `/profile/story-islands/{island_id}/tasks/{task_id}` | 改标题或是否每日 |
| DELETE | `/profile/story-islands/{island_id}/tasks/{task_id}` | 删除任务 |
| POST | `.../tasks/{task_id}/complete` | 完成，返回整座岛 |
| POST | `.../tasks/{task_id}/uncomplete` | 取消完成，返回整座岛 |

建筑名与 10 级阈值在 `backend/app/config/story_island_buildings.py`，必须与 `stday/lib/core/constants/story_island_building_catalog.dart` 保持一致。每级 30 成长值，满级 300。

<a id="kb-日常"></a>

### 日常

| 方法 | 路径 | 作用 |
|---|---|---|
| GET | `/profile/moments/dates` | 有记录的日期 |
| GET | `/profile/moments/today` | 今天 |
| GET | `/profile/moments` | 按天或近期列表 |
| POST | `/profile/moments` | 文字日常 |
| POST | `/profile/moments/voice` | 语音日常 |
| PATCH | `/profile/moments/{moment_id}` | 改正文与标签 |
| PATCH | `/profile/moments/{moment_id}/tags` | 只改标签 |
| PATCH | `/profile/moments/{moment_id}/voice` | 替换语音 |
| PATCH | `/profile/moments/{moment_id}/story-island` | 把这条日常安放到某座岛 |
| DELETE | `/profile/moments/{moment_id}` | 删除 |
| POST | `/profile/moments/{moment_id}/photos` | 上传照片，只存储，不参与 AI 分析 |
| DELETE | `/profile/moments/{moment_id}/photos/{photo_id}` | 删除照片 |
| POST | `/profile/moments/voice/transcribe` | 语音转写 |
| POST | `/profile/speech/transcribe` | 同上的另一条入口。客户端 `VoiceRepository.transcribeSpeechNote` |

<a id="kb-心情与洞察"></a>

### 心情与洞察

| 方法 | 路径 | 作用 |
|---|---|---|
| GET | `/profile/mood-report/check-in` | 心情打卡 |
| GET | `/profile/mood-period-summary` | 月/年周期小结。query：`period=month\|year`，可选 `category_filter` |
| GET | `/profile/moments/mood-period` | 月/年记录分页。`page_size` 1–50，默认 10 |
| GET | `/profile/mood-reports` | 日报列表 |
| POST | `/profile/mood-report/upload` | 上报当日心情日报 |

<a id="kb-心情岛屿样式"></a>

## 心情岛屿样式

前缀在路由上已经是 `/profile/island-styles`。

| 方法 | 路径 | 作用 |
|---|---|---|
| GET | `/profile/island-styles` | 全部样式。`IslandConfigRepository.listIslandStyles` |
| GET | `/profile/island-styles/{mood_id}` | 某心情 |
| PATCH | `/profile/island-styles/{mood_id}` | 更新样式 |

<a id="kb-成长标签"></a>

## 成长标签

| 方法 | 路径 | 谁用 |
|---|---|---|
| GET | `/growth-tags` | 客户端 `GrowthRepository.listGrowthTags` |
| GET | `/admin/growth-tags` | 管理员 |
| POST | `/admin/growth-tags/categories` | 新建一级标签 |
| PATCH | `/admin/growth-tags/categories/{category_id}` | 改一级 |
| POST | `/admin/growth-tags/categories/{category_id}/tags` | 新建二级 |
| PATCH | `/admin/growth-tags/tags/{tag_id}` | 改二级 |
| DELETE | `/admin/growth-tags/tags/{tag_id}` | 删二级 |

<a id="kb-国际化"></a>

## 国际化

| 方法 | 路径 | 客户端 |
|---|---|---|
| GET | `/i18n/config` | `AppLocalizationRepository.fetchI18nConfig` |
| GET | `/i18n/bundle` | `fetchI18nBundle(locale)` |
| GET | `/admin/i18n/strings` | 管理员 |
| POST | `/admin/i18n/strings` | 管理员 |
| PATCH | `/admin/i18n/strings/{string_id}` | 管理员 |

Flutter 生成文案在 `stday/lib/l10n/`，不要手改生成文件。服务端 bundle 是另一层动态文案。

<a id="kb-会员"></a>

## 会员

用户接口：

| 方法 | 路径 | 客户端 |
|---|---|---|
| GET | `/member/me` | `MemberRepository.fetchMemberMe`。`isVip` 来自这里 |
| POST | `/member/redeem` | `redeemActivationCode`。激活码 |

管理接口，需要管理员：

| 方法 | 路径 |
|---|---|
| POST | `/admin/member/activation-codes` |
| POST | `/admin/member/activation-codes/batch` |
| PATCH | `/admin/member/activation-codes/{code_id}/disable` |
| PATCH | `/admin/member/activation-codes/{code_id}/expire` |
| GET | `/admin/member/activation-codes` |
| POST | `/admin/member/gift` |
| POST | `/admin/member/cancel` |
| GET | `/admin/member/records` |

客户端会员门槛见 `knowledge/review/CLIENT_SYSTEMS.md`。服务端不要假设客户端蒙版就是权限，写接口时仍要按会员校验。

<a id="kb-内购"></a>

## 内购

| 方法 | 路径 | 作用 |
|---|---|---|
| POST | `/iap/verify` | 校验 Apple 签名交易。`IapRepository.verifyPurchase` |
| POST | `/iap/restore` | 恢复购买，返回真正记到当前账号的笔数 |
| GET | `/iap/me` | 当前内购权益 |
| POST | `/iap/apple/notification` | App Store 服务器通知 |

商品 ID 必须与 `member_products.product_id` 以及客户端 `IapProductIds` 一致：

```text
com.xiaoerlcx.app.vip.monthly
com.xiaoerlcx.app.vip.quarterly
com.xiaoerlcx.app.vip.yearly
```

<a id="kb-客户端-repository-对照"></a>

## 客户端 repository 对照

全部 facade 在 `stday/lib/data/repositories/app_repository_facades.dart`（`part of app_repository.dart`）。HTTP 实现仍集中在 `app_repository.dart` 的 `StdayApiDatasource`。

```text
AuthRepository              authRepositoryProvider
ProfileRepository           profileRepositoryProvider
MomentRepository            momentRepositoryProvider
StoryIslandRepository       storyIslandRepositoryProvider
VoiceRepository             voiceRepositoryProvider
MoodRepository              moodRepositoryProvider
GrowthRepository            growthRepositoryProvider
IslandConfigRepository      islandConfigRepositoryProvider
AppLocalizationRepository   appLocalizationRepositoryProvider
UserPreferencesRepository   userPreferencesRepositoryProvider
MemberRepository            memberRepositoryProvider
IapRepository               iapRepositoryProvider
```

页面不要 new Dio，不要自己拼 baseUrl。
