# 给后续 AI

仓库根目录是工作区。知识库不在 `stday/` 里面，单独维护在 `knowledge/`。

改代码前读 `knowledge/README.md` 里的阅读顺序。最短路径：

1. `knowledge/ai/project_context.md`
2. `knowledge/ai/architecture.md`
3. `knowledge/ai/feature_map.md`
4. 要定位任意源文件时读 `knowledge/ai/code_index.md`
5. 动到岛屿渲染再读 `knowledge/ai/game_system.md`
6. 动到后端再读 `knowledge/ai/backend.md`
7. `knowledge/ai/coding_rules.md`

产品做不做，看 `stday/THE_BOOK_OF_STAR_ISLAND.md`。

人用来审实现的稿是 `knowledge/review/CLIENT_SYSTEMS.md`。改了用户能感知的行为，要改这篇里对应的动作链和差异，不要只改 `knowledge/ai/`。

`stday/.cursor/`、`stday/AI_GUIDE.md`、`stday/DIRECTORY.md`、`docs/KNOWLEDGE.md` 只有迁移说明，不是现行规则。

Flutter 命令在 `stday/` 下执行。后端在 `backend/`。
