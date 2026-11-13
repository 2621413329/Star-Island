# 知识库

这是仓库根目录下单独维护的知识库，不放在 `stday/` 或 `backend/` 里面。改知识库只改这个目录。`stday/.cursor/`、`stday/AI_GUIDE.md`、`stday/docs/CLIENT_SYSTEMS.md`、`docs/KNOWLEDGE.md`、`docs/BACKEND_API.md` 只保留迁移说明，不要再往那里写正文。

仓库根目录的 `AGENTS.md` 是给后续 AI 的入口，里面只有阅读顺序，规则正文在这里。

## 谁读哪份

| 读者 | 先读 | 用途 |
|---|---|---|
| 人 | [`review/CLIENT_SYSTEMS.md`](review/CLIENT_SYSTEMS.md) | 审 AI 改完之后：动作怎么走完，和之前差在哪 |
| AI | 下面的阅读顺序 | 改代码前定位文件、依赖和禁区 |

接口表：[`BACKEND_API.md`](BACKEND_API.md)。

产品取舍仍看 [`stday/THE_BOOK_OF_STAR_ISLAND.md`](../stday/THE_BOOK_OF_STAR_ISLAND.md)。`stday/PROJECT.md`、`ARCHITECTURE.md`、`GAME_ENGINE.md`、`DIRECTORY.md` 是项目说明。行为和文件落点以本目录为准，那几份落后时不要拿它们覆盖这里。

`docs/archive/`、`stday/architecture_plan.md`、`stday/architecture_review.md`、`stday/refactor_phase_1.md` 是历史材料。

## AI 阅读顺序

工作区是仓库根目录。下面的代码路径都从根目录算，客户端在 `stday/`，服务端在 `backend/`。Flutter 命令先 `cd stday`。

1. `stday/THE_BOOK_OF_STAR_ISLAND.md`（做不做）
2. `knowledge/ai/project_context.md`
3. `knowledge/ai/architecture.md`
4. `knowledge/ai/feature_map.md`
5. 改岛屿、建筑、装饰、角色、相机：`knowledge/ai/game_system.md`
6. 改桌面小组件：`knowledge/ai/widget_architecture.md`
7. 改后端：`knowledge/ai/backend.md`
8. `knowledge/ai/coding_rules.md`
9. 要新增一类能力时再读 `knowledge/ai/AI_GUIDE.md`

改了用户能感知的行为，必须改 `knowledge/review/CLIENT_SYSTEMS.md` 对应节：旧动作写进「和之前的差异」，再写新的动作链。只改 `knowledge/ai/` 不算完成。

## 对后续开发有帮助的部分

这些能直接减少改错文件：

- `feature_map.md` 把页面、provider、repository、接口放在一起，并区分「按住说话」和「语音日常」。
- `architecture.md` 写了真实启动 Host 顺序、路由守卫和 12 个 repository。依赖方向写了禁止项。
- `game_system.md` 把主岛 Flame 世界和副岛快照分成两条，并写明副岛不要改 `stday/lib/island/placement/`。
- `coding_rules.md` 要求行为变更回写审核稿，避免知识库再和代码分开漂。
- `backend.md` 告诉改 Python 时路由、成长数值和副岛建筑名要和客户端哪份文件对齐。
- 审核稿第 14–21 节把转写回退、照片差量、任务完成的两条反馈、天气延迟请求、小组件落地和注销写到了函数名。

## 不要指望它代替读代码的部分

- `stday/lib/features/island/island_home_page.dart` 有四千多行。知识库只标了建岛、点岛、完成任务、种子动画和深链消费的函数，没有覆盖这个文件里的每一种局部状态。
- 层序、`WorldState` 字段在 `game_system.md` 和审核稿里各有一份。改渲染时以 `knowledge/ai/game_system.md` 为准，并同步审核稿第 4、5 节。不要再去改 `stday/ARCHITECTURE.md` 里的旧层序当唯一事实。
- 后端业务规则的细节仍在 `backend/app/services/`。`backend.md` 只负责把人带到正确的服务和必须对齐的常量。

## 仓库形状

```text
knowledge/      本知识库（唯一维护处）
stday/          Flutter 客户端
backend/        FastAPI
docs/           部署与历史归档，不再放现行知识库
```
