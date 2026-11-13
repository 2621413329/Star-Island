# 知识库

知识库只在本目录维护。`stday/.cursor/`、`stday/AI_GUIDE.md`、`stday/docs/CLIENT_SYSTEMS.md`、`stday/DIRECTORY.md`、`docs/KNOWLEDGE.md`、`docs/BACKEND_API.md` 只有迁移说明。

仓库根目录的 `AGENTS.md` 只指向本页。阅读路由和「改完要回写哪一份」只写在这里，其它文档不要再列一份。

路径从仓库根目录算。Flutter 命令先 `cd stday`。后端在 `backend/`。

产品做不做，看 [`stday/THE_BOOK_OF_STAR_ISLAND.md`](../stday/THE_BOOK_OF_STAR_ISLAND.md)。`stday/PROJECT.md`、`stday/ARCHITECTURE.md`、`stday/GAME_ENGINE.md` 是项目说明。和本目录冲突时，以本目录为准。`docs/archive/`、`stday/architecture_plan.md`、`stday/architecture_review.md`、`stday/refactor_phase_1.md` 是历史材料。

## 文档一览

| 编号 | 文档 | 回答的问题 | 不负责 |
|---|---|---|---|
| KB-01 | [`ai/project_context.md`](ai/project_context.md) | 项目是什么、技术栈、哪些数字不能单独改 | 文件清单、接口字段 |
| KB-02 | [`ai/architecture.md`](ai/architecture.md) | 启动、路由、repository、依赖方向 | 每个页面的控件 |
| KB-03 | [`ai/feature_map.md`](ai/feature_map.md) | 一条业务经过哪些页面、provider、接口 | 目录里的全部文件 |
| KB-04 | [`ai/code_index.md`](ai/code_index.md) | 每个源文件在哪；新文件放哪 | 业务怎么串 |
| KB-05 | [`ai/game_system.md`](ai/game_system.md) | 主岛和副岛怎么画、层序、改哪条世界 | 页面跳转 |
| KB-06 | [`ai/widget_architecture.md`](ai/widget_architecture.md) | 桌面小组件的 Flutter / iOS / Android 拆分 | 岛内任务规则 |
| KB-07 | [`ai/backend.md`](ai/backend.md) | 改 Python 从哪个服务进，哪份必须和客户端对齐 | 每个 URL 的字段 |
| KB-08 | [`ai/coding_rules.md`](ai/coding_rules.md) | 命名、依赖禁区和验证命令 | 业务说明 |
| KB-09 | [`ai/AI_GUIDE.md`](ai/AI_GUIDE.md) | 新增一类能力时按什么步骤改 | 现行行为 |
| KB-10 | [`review/CLIENT_SYSTEMS.md`](review/CLIENT_SYSTEMS.md) | 给人审：动作现在怎么走完，和之前差在哪 | 文件全表 |
| KB-11 | [`BACKEND_API.md`](BACKEND_API.md) | 现行 HTTP 路径 | 客户端怎么弹窗 |

每份文档开头有同一张表：编号、回答的问题、不负责什么、何时更新。

## 任务路由

按任务打开，不要默认读完所有文档。

| 要做的事 | 打开 | 改完回写 |
|---|---|---|
| 先确认能不能做 | `stday/THE_BOOK_OF_STAR_ISLAND.md`，再 KB-01 | 不改知识库，除非产品边界变了 |
| 改一条已有业务的行为 | KB-03 里该业务一节，KB-08 | KB-10 对应节：旧动作写入差异，再写新动作链 |
| 找不到文件，或新增、移动源文件 | KB-04 | KB-04 里该目录的文件行 |
| 改主岛或副岛画面 | KB-05 | 用户能看出变化时，同步 KB-10 第 4 或第 5 节 |
| 改桌面小组件 | KB-06 | 点击或同步方式变了，同步 KB-10 第 8、20 节 |
| 改接口路径、字段或状态码 | KB-11，再 KB-07 | KB-11；客户端 facade 变了再改 KB-03 |
| 新增一类能力 | KB-09 里对应的「如果新增」 | KB-03、KB-04，以及 KB-10 新的一节 |
| 只改内部实现，用户看不出差别 | KB-08 | 不改 KB-10 |

等级表、副岛建筑名、内购商品 ID 在客户端和后端各有一份。改其中一边时，按 KB-07 的对照表改另一边。

## 边界

KB-04 标到文件和类型名，不展开函数内部。`stday/lib/features/island/island_home_page.dart` 有四千行以上，建岛、完成任务、种子动画和深链都在这个文件里，先搜函数名。

层序和 `WorldState` 以 KB-05 为准。KB-10 第 4、5 节写给人看的动作，两边都要改时先改 KB-05。

## 仓库形状

```text
knowledge/          本知识库
  README.md         本页：目录、任务路由、回写约定
  ai/               给改代码用
  review/           给人审动作链
  BACKEND_API.md    现行接口
stday/              Flutter 客户端
backend/            FastAPI
docs/               部署与历史归档
```
