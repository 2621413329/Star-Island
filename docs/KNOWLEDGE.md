# 知识库索引

仓库同时维护两套知识库。两边描述同一套代码，分工不同。

| 读者 | 读什么 | 怎么用 |
|---|---|---|
| 人 | 先读 [`stday/docs/CLIENT_SYSTEMS.md`](../stday/docs/CLIENT_SYSTEMS.md) | 审核 AI 改完之后的实现：每条链路怎么走完，和之前差在哪 |
| AI / Cursor | `stday/.cursor/` 与 `stday/AI_GUIDE.md` | 改代码前定位文件、依赖方向和禁止项 |

冲突时的优先级：

1. 当前代码。
2. `stday/THE_BOOK_OF_STAR_ISLAND.md` 的产品宪法（决定做不做，不决定文件放哪）。
3. 本索引指向的现行文档。
4. `docs/archive/`、`architecture_plan.md`、`architecture_review.md`、`refactor_phase_1.md` 是历史审计和迁移备忘，不能当现行接口或目录说明。

## 给人看的文档

| 文档 | 内容 |
|---|---|
| [`stday/docs/CLIENT_SYSTEMS.md`](../stday/docs/CLIENT_SYSTEMS.md) | **先读这份。** 审核动作链和与之前的差异。改了用户能感知的行为就要改对应节。 |
| [`stday/THE_BOOK_OF_STAR_ISLAND.md`](../stday/THE_BOOK_OF_STAR_ISLAND.md) | 产品为什么存在。功能取舍先过宪法。 |
| [`docs/BACKEND_API.md`](BACKEND_API.md) | 核对请求有没有打到现行接口。旧 README 只列了认证和资料。 |
| [`stday/PROJECT.md`](../stday/PROJECT.md) | 仓库是什么、怎么跑起来。 |
| [`stday/ARCHITECTURE.md`](../stday/ARCHITECTURE.md) | 查启动、路由和依赖方向时的附图。审核动作看 CLIENT_SYSTEMS 第 1–4 节。 |
| [`stday/GAME_ENGINE.md`](../stday/GAME_ENGINE.md) | 查渲染文件时的附图。审核层序和副岛坐标看 CLIENT_SYSTEMS 第 4–5 节。 |
| [`stday/DIRECTORY.md`](../stday/DIRECTORY.md) | 目录职责和新文件放哪。 |
| [`stday/CONVENTION.md`](../stday/CONVENTION.md) | 命名和编码约定。 |
| [`stday/docs/STORY_ISLAND_WORLD_SPEC.md`](../stday/docs/STORY_ISLAND_WORLD_SPEC.md) | 副岛美术与建筑名。坐标以 `StoryIslandLayout` 为准。 |
| [`backend/README.md`](../backend/README.md) | 后端怎么在本地跑起来。 |
| [`stday/ROADMAP.md`](../stday/ROADMAP.md) | 尚未承诺的长期方向，避免误删扩展点。 |
| [`docs/DEPLOYMENT.md`](DEPLOYMENT.md)、[`docs/DEPLOYMENT_LINUX_BACKEND.md`](DEPLOYMENT_LINUX_BACKEND.md) | 部署。 |

## 给 AI 看的文档

编码前按这个顺序读：

```text
stday/THE_BOOK_OF_STAR_ISLAND.md
stday/.cursor/project_context.md
stday/.cursor/architecture.md
stday/.cursor/feature_map.md
stday/.cursor/game_system.md      （改岛屿、建筑、装饰、角色、相机时）
stday/.cursor/widget_architecture.md （改桌面小组件时）
stday/.cursor/coding_rules.md
stday/AI_GUIDE.md
```

| 文档 | 内容 |
|---|---|
| `.cursor/project_context.md` | 第一上下文：定位、技术栈、风险、验证命令。 |
| `.cursor/architecture.md` | 启动链、路由、repository、依赖方向。 |
| `.cursor/feature_map.md` | 每个业务模块的页面、provider、repository、接口。 |
| `.cursor/game_system.md` | 渲染链路、层顺序、`WorldState`、主岛/副岛改动入口。 |
| `.cursor/widget_architecture.md` | 桌面小组件的 Flutter / iOS / Android 拆分。 |
| `.cursor/coding_rules.md` | 写代码时的硬约束。 |
| `AI_GUIDE.md` | 「如果要新增 X，改哪些文件、不要碰哪些文件」。 |

## 仓库形状

```text
stday/          Flutter 客户端（包名 stday，对外名称星屿 / 成长小岛）
backend/        FastAPI 服务，前缀 /api/v1
docs/           跨端文档、部署、本索引
```

客户端通过 `stday/lib/core/config/app_config.dart` 访问后端。Release 默认 `https://api.lcxxingyu.fun`。Debug 默认 `http://127.0.0.1:9000`。可用 `--dart-define=API_BASE_URL=...` 覆盖。
