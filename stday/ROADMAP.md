# Roadmap

本文记录项目未来方向。它不是当前开发承诺，而是给 Cursor / AI 的长期上下文，避免后续清理时误删未来要用的结构、资源和扩展点。

## 当前产品核心

Star Island 当前核心是：

```text
日常记录
  -> 成长值
  -> 等级
  -> 岛屿变化
  -> 建筑/装饰解锁
  -> 陪伴人物反馈
  -> 心情与成长洞察
```

任何未来功能都应围绕“陪伴、记录、成长、岛屿反馈”展开。

## 近期架构目标

### 1. 完成目录治理

目标：

```text
features/ -> feature/
world/ -> game/world/
island/ -> feature/island + game/island
design_system/ -> common/component
providers/ -> feature/provider + app/provider
```

原则：

- 小步迁移。
- 保留 export wrapper。
- 不改业务行为。

### 2. 拆分超长文件

优先：

- `lib/world/island/island_renderer.dart`
- `lib/features/today/write_story_page.dart`
- `lib/world/rendering/cozy_hero_renderer.dart`
- `lib/world/scene/layers/building_layer.dart`
- `lib/features/status/mood_status_page.dart`
- `lib/features/today/moment_form_widgets.dart`

目标：

- 页面只负责布局和交互。
- controller/usecase 负责流程。
- renderer/painter 负责绘制。
- datasource 负责 API endpoint。

### 3. 拆分 `StdayApiDatasource`

当前仍集中在：

```text
lib/data/repositories/app_repository.dart
```

未来拆分：

```text
auth_remote_datasource.dart
profile_remote_datasource.dart
moment_remote_datasource.dart
voice_remote_datasource.dart
mood_remote_datasource.dart
growth_remote_datasource.dart
island_config_remote_datasource.dart
i18n_remote_datasource.dart
user_preferences_remote_datasource.dart
```

## 中期产品方向

### 1. 岛屿扩展

可能方向：

- 更多岛屿主题。
- 更多建筑。
- 更多装饰。
- 不同成长阶段的岛屿变化。
- 岛屿天气效果。
- 岛屿昼夜变化。
- 岛屿事件。

保留：

- `assets/images/buildings/`
- `assets/images/decor/`
- `world/systems/config/`
- `common/island_contracts/`
- building/decor/growth 相关配置。

不要因为当前静态引用少就删除这些资源或配置。

### 2. 陪伴人物扩展

可能方向：

- 更多人物外观。
- 更多性别/角色差异。
- 更多表情。
- 更多动作。
- 更多道具。
- 人物成长阶段。
- 人物对日常内容的反馈。

保留：

- `assets/images/companion/base/`
- `assets/images/companion/props/`
- `assets/images/companion/times/`
- `CompanionPainter`
- `CozyHeroRenderer`
- `CharacterLayer`
- `UserCompanionView`

### 3. AI 分析扩展

可能方向：

- 日常总结。
- 情绪片段。
- 周报/月报。
- 成长建议。
- AI 陪伴回复。
- AI 语音总结。
- AI 任务推荐。

相关现有能力：

- mood report。
- growth observation。
- speech transcribe。
- moment story summary。
- emotion fragments。

不要删除看似暂时空闲的 mood/growth/report 模型和 API。

### 4. 任务与成就

可能方向：

- 每日任务。
- 连续记录任务。
- 主题挑战。
- 成就徽章。
- 等级奖励。
- 建筑解锁。
- 称号系统。

保留：

- `core/growth/`
- `features/achievement/`
- `assets/images/titles/`
- building unlock 模型。
- growth summary/provider。

### 5. 好友与社交

可能方向：

- 好友岛屿访问。
- 点赞/留言。
- 互赠装饰。
- 共同成长挑战。
- 岛屿名片分享。

提前注意：

- 不要把用户 profile 模型设计得无法扩展好友关系。
- 不要把岛屿状态强绑定为“只能本地当前用户”。
- 后续可能需要 userId 维度的 world snapshot。

### 6. 宠物 / NPC

可能方向：

- 岛屿宠物。
- NPC 访客。
- 不同 NPC 的小任务。
- 宠物互动。

相关未来目录：

```text
game/character/
game/animation/
game/behavior/
feature/npc/
feature/pet/
```

不要把角色系统写死为只有 protagonist。

### 7. 天气与环境

可能方向：

- 城市天气。
- 岛屿天气。
- 天气影响环境色。
- 天气触发特殊装饰。
- 节日/季节事件。

保留：

- `core/weather/`
- `world/systems/config/weather_atmosphere_config.dart`
- `mood_environment_controller.dart`
- `island_weather_provider`

### 8. 多端与离线

可能方向：

- 离线记录。
- 本地队列。
- 后台同步。
- 多设备同步。
- 冲突合并。

已有基础：

- `ClientEventId`
- SharedPreferences。
- user app preferences sync。

不要删除 sync 相关工具。

## 长期产品方向

### 好友

好友系统可能包含：

- 好友列表。
- 好友岛屿。
- 互访。
- 互动消息。
- 共同任务。

### 天气

天气系统可能包含：

- 用户所在地天气。
- 岛屿天气映射。
- 天气动画。
- 天气与心情结合的环境反馈。

### 宠物

宠物系统可能包含：

- 宠物领养。
- 宠物成长。
- 宠物动作。
- 宠物与日常记录互动。

### 多人

多人系统可能包含：

- 共享岛屿。
- 家庭/小组成长。
- 多人任务。
- 多角色同屏。

### NPC

NPC 系统可能包含：

- 访客。
- 引导任务。
- 剧情推进。
- 情绪反馈。

### 交易 / 收集

交易和收集系统可能包含：

- 装饰收集。
- 建筑皮肤。
- 主题解锁。
- 道具背包。

### 剧情

剧情系统可能包含：

- 成长章节。
- 岛屿事件。
- 人物关系。
- 节日剧情。

### AI 助手

AI 助手可能包含：

- 记录引导。
- 情绪陪伴。
- 成长建议。
- 回顾总结。
- 主动提醒。

## 不要轻易删除的内容

以下内容即使当前静态引用少，也可能服务未来扩展：

- assets 下的 building、decor、companion、titles、mood、story tag 资源。
- `core/growth/`。
- `core/weather/`。
- `core/sync/`。
- `world/systems/config/`。
- `common/island_contracts/`。
- building unlock、growth summary、mood report、emotion fragment 模型。
- reminder、notification、voice 相关服务。

## 未来修改优先级

P0：

- 编译错误。
- 登录/token/API 会话问题。
- 数据丢失风险。
- 主流程崩溃。

P1：

- 目录依赖反转。
- design_system 业务依赖。
- repository/provider 职责混乱。
- 岛屿渲染阻塞或严重性能问题。

P2：

- 超长文件拆分。
- 文件命名统一。
- 目录最终迁移。
- renderer/helper 细分。

## 每次继续前建议

先读：

```text
future_refactor_notes.md
architecture_plan.md
AI_GUIDE.md
```

再运行：

```powershell
flutter analyze
```

涉及 API 配置时运行：

```powershell
flutter test test/app_config_test.dart
```
