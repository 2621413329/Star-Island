# Flutter V1 页面与接口契约（陪伴型 · 修正版）

> 与 `student_app_ui_ue_design.md` V2.0 对齐。  
> Flutter 端只负责展示、陪伴态 UI 与轻量录入；不承载规则匹配、Prompt 构造或 LLM 调用。

## 产品主路径

```text
欢迎 → 登录 → 今日故事（首页）→ 添加故事 → 记录 → 生成故事 → 故事卡 / 阅读器
                                    ↘ 今日状态（今日列表 + 心情胶囊）
```

## 页面拆解（3 Tab）

### Tab1：今日故事 `/today`（首页，非记录页）

**职责**

- 顶栏日期、成长伙伴（小星）、动态欢迎文案（随机池，见 UI 文档 §5.2）
- **主体**：今日故事横向卡带（≥60% 区域），空态大卡片 `+ 添加故事`
- 调用 `GET /api/v1/story/daily?student_id={uuid}`
- 若需展示「仅有 record、尚无 story」：`GET /api/v1/timeline` 过滤当日 + `type=record`，显示「正在酝酿」占位（可选）

**不包含**：首屏情绪环、FAB、时间线全量列表。

### 记录流程 `RecordMomentSheet`（全局 Bottom Sheet）

**触发**：`+ 添加故事`（首页空卡或故事带末尾）

**步骤（顺序固定）**

1. **事件** → `event_type`（学习 / 朋友 / 运动 / 家庭 / 兴趣 / 其它 — 与后端 string 映射表见 UI 文档）
2. **心情** → `emotion_tag`
3. **一句话** → `event_content`（≤50 字）；`event_title` 可由客户端根据事件类型 + 摘要在前端生成，或取 `event_content` 前 20 字

**提交**

- `POST /api/v1/record`
- 建议紧接着 `POST /api/v1/story/generate`（`observation_record_id` = 返回的 record id）
- 成功：刷新 `todayStoriesProvider`，首页插入故事卡（Fade 250ms）

### Tab2：今日状态 `/status`

**职责**

- 纵向列表：当日故事类目 + 标题（`GET /api/v1/story/daily` 或当日 timeline）
- **今日心情占比**：客户端按当日 records/stories 的 `emotion_tag` 计数 → 胶囊条（无图表库、无折线）
- **禁止**：统计图、折线图、分析仪表盘

### Tab3：更多 `/more`

- `GET /api/v1/auth/me`
- 主题、隐私说明、退出（`清除 Token`）

### Onboarding：欢迎 `/welcome`

- 纯本地 UI + 动画；完成后路由至 `/auth`
- 无 API

### Story Viewer `/story/:id`

- 故事标题、正文、`sections`、温柔化展示的 `emotion_flow`（标签串联，非图表）
- `scene_prompt` 作副文案/顶栏字幕
- 调用 `GET /api/v1/story/{id}`

### V1 不包含的页面（勿按旧契约实现）

- ~~独立 Timeline Tab~~
- ~~Gallery Tab~~
- ~~Home 情绪快捷录入~~

## 事件类型与后端映射

客户端展示 → `POST /record` 的 `event_type` 建议值：

| UI 标签 | `event_type` 建议值 |
|---------|---------------------|
| 📚 学习 | `学习` |
| 👫 朋友 | `朋友` |
| 🏃 运动 | `运动` |
| 🏠 家庭 | `家庭` |
| 🎨 兴趣 | `兴趣` |
| ✨ 其它 | `其它` |

`emotion_tag` 建议值：`happy` `calm` `thinking` `sad` `angry`（展示层用表情 + 中文）。

## visual_payload 约定（故事小人）

```json
{
  "companion_scene": "friendship_grass",
  "companion_image_url": null,
  "fallback": true
}
```

- `companion_scene`：枚举，与 UI 文档 §2.3 场景一致  
- 无 URL 时 Flutter 用 `CompanionSceneCatalog` 本地插画  
- 后端可在 Story 生成后写入；V1 允许全前端回退  

## 核心接口

### 认证

- `POST /api/v1/auth/entry` — **登录即注册**（MVP 主入口）
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`

### 学生资料与今日瞬间（MVP）

- `GET /api/v1/profile`
- `PATCH /api/v1/profile/gender` — `male` | `female` | `other`
- `PATCH /api/v1/profile/companion` — `chibi` | `normal`
- `PATCH /api/v1/profile/mood` — `happy` | `calm` | `thinking` | `sad` | `angry`
- `POST /api/v1/profile/onboarding/complete`
- `POST /api/v1/profile/moments` — 标签 + 心情 + 可选 note
- `GET /api/v1/profile/moments/today`

### 创建记录（记录 Sheet 完成后）

`POST /api/v1/record`

```json
{
  "student_id": "uuid",
  "event_type": "朋友",
  "event_title": "友谊故事",
  "event_content": "今天和同学一起完成了活动。",
  "emotion_tag": "happy",
  "growth_dimension": null
}
```

> V1 学生自录可将 `growth_dimension` 置空；`event_title` 可由客户端按类目模板生成（如「友谊故事」）。

### 生成故事

`POST /api/v1/story/generate`

```json
{
  "observation_record_id": "uuid"
}
```

### 今日故事列表

`GET /api/v1/story/daily?student_id={uuid}&target_date=YYYY-MM-DD`（`target_date` 可选，默认今天）

### 今日状态（可选聚合接口）

优先 **客户端聚合**：

- 列表：`GET /api/v1/story/daily?student_id=`
- 补充未生成 story 的 record：当日 `GET /api/v1/timeline?student_id=&page_size=50` 过滤 `type=record` 且 `occurred_at` 为今天
- 心情胶囊：对当日所有 `emotion_tag` 计数

### 故事详情

`GET /api/v1/story/{id}`

```json
{
  "id": "uuid",
  "student_id": "uuid",
  "source_record_id": "uuid",
  "title": "友谊故事",
  "body": "……",
  "emotion_flow": [],
  "sections": [],
  "scene_prompt": "……",
  "image_style": "soft cartoon",
  "visual_payload": {
    "companion_scene": "friendship_grass"
  }
}
```

## UI 模型建议（客户端）

```dart
class TodayStoryCardModel {
  final String id;
  final String categoryLabel; // 友谊故事
  final String summary;
  final String moodLabel;     // 开心
  final String? companionScene;
  final bool isGenerating;
}
```

## 状态管理建议

| State | 职责 |
|-------|------|
| `AuthState` | Token、`me`、`student_id` |
| `CompanionState` | 伙伴动画态、欢迎文案索引 |
| `TodayStoriesState` | daily stories、空态、横向列表 |
| `RecordMomentState` | Sheet 三步、提交、自动触发生成 |
| `TodayStatusState` | 当日列表、心情胶囊百分比 |
| `StoryState` | 阅读器加载、生成中/失败（温柔文案） |

**生成故事状态机**

```text
idle → submittingRecord → recordSuccess → generatingStory → success | failure
```

失败文案示例：「故事还没写好，稍后再来看看？」— 禁止「生成失败 Error」。

## 路由表示例（go_router）

```text
/welcome
/auth/login
/today          # Tab1
/status         # Tab2
/more           # Tab3
/story/:id
```

ShellRoute 底部 3 Tab 挂载 `/today`、`/status`、`/more`。

## 与旧版契约差异摘要

| 旧版 | V1 修正版 |
|------|-----------|
| Home = 记录 + 时间线预览 | Home = **今日故事** + 伙伴 |
| 4 Tab | **3 Tab** |
| 情绪优先记录 | **事件 → 心情 → 50 字** |
| Timeline / Gallery 独立页 | 并入今日故事 / 今日状态，无分析图 |
| MoodRing 首屏 | **故事大卡** 首屏 |

## 成长伙伴 visual_payload（V1.1 扩展）

`POST /api/v1/profile/moments` 返回的 `visual_payload` 含 AI/规则 情境化字段：

| 字段 | 说明 |
|------|------|
| `expression` | `happy` \| `sad` \| `calm` \| `angry` \| `thinking` \| `hurt` |
| `prop` | `none` \| `workbook` \| `ball` \| `friends` \| `home` \| `music` \| `stars` \| `umbrella` |
| `animation_type` | `slump_read` \| `celebrate` \| `wave` \| `think` \| `shake` \| `hug` \| `sit` \| `look_down` \| `cheer` |
| `companion_tint` | `#RRGGBB`，融合事件+心情 |
| `scene_title` | 场景标题，如「练习册前的片刻」 |
| `performance_hint` | 演出提示文案 |
| `waiting_lines` | 生成等待轮播句 |

Flutter：`CompanionSpec.fromPayload(visualPayload)` → `CompanionAvatar(spec: …)`。

## 心情岛屿样式（数据互通、交互独立）

| 方法 | 路径 |
|------|------|
| GET | `/api/v1/profile/island-styles` |
| GET | `/api/v1/profile/island-styles/{mood_id}` |
| PATCH | `/api/v1/profile/island-styles/{mood_id}` |

`config` JSON：`sky_top`、`sky_bottom`、`sea`、`sand`、`accent`、`wave_intensity`、`rain`、`wind`、`label`。

Flutter：`moodIslandRegistryProvider` → `GrowthIslandScene(islandConfig: registry.resolve(todayMood))`。各心情岛屿视觉可独立 PATCH 编辑，moment/用户数据仍走 profile API。
