# AI成长观察系统

基于 FastAPI + SQLAlchemy 2.0 Async + PostgreSQL 的后端脚手架，面向班主任、德育老师、年级组长记录学生成长观察事件，并为后续 AI 分析、RAG、Agent 能力预留扩展目录。

## 产品方向（学生端 Flutter）

学生端（14–22 岁）定位为 **温暖陪伴型成长伙伴**，而非 Daylio 式「记录 → 统计 → 回顾」工具。

```text
进入 App → 感受陪伴 → 记录今天 → 温柔反馈 → 成长故事
```

情感关键词：**像冬天晒太阳** — 舒服、轻松、治愈、被接纳、温暖。

设计原则：**先故事，后记录 · 先陪伴，后分析 · 先温暖，后功能 · 先事件，后情绪**。

| 文档 | 说明 |
|------|------|
| [backend/docs/student_app_ui_ue_design.md](backend/docs/student_app_ui_ue_design.md) | 学生端 UI/UE 设计（V2 修正版） |
| [backend/docs/flutter_v1_1_contract.md](backend/docs/flutter_v1_1_contract.md) | Flutter 页面与 API 契约（3 Tab · 陪伴型） |

## 技术栈

- Python 3.12
- FastAPI / SQLAlchemy 2.0 Async / Pydantic V2 / Alembic
- PostgreSQL（本地安装，不使用 Docker）
- JWT：python-jose；密码加密：passlib[bcrypt]
- 千问：DashScope OpenAI 兼容模式
- 日志：Loguru；测试：Pytest

## 项目结构

```text
backend/
|-- alembic/
|-- app/
|   |-- agents/
|   |-- api/v1/
|   |-- core/
|   |-- database/
|   |-- exceptions/
|   |-- middleware/
|   |-- models/
|   |-- prompts/
|   |-- rag/
|   |-- repositories/
|   |-- schemas/
|   |-- services/
|   |-- tests/
|   |-- utils/
|   `-- main.py
|-- logs/
|-- .env
|-- alembic.ini
`-- requirements.txt
```

## PostgreSQL 准备

Windows 可从 https://www.postgresql.org/download/windows/ 安装 PostgreSQL。创建数据库：

```sql
CREATE DATABASE ai_growth;
```

修改 `backend/.env` 中的 PostgreSQL 密码，生产环境必须替换 `JWT_SECRET_KEY`。

千问配置：

```env
QWEN_API_KEY=你的千问APIKey
QWEN_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
QWEN_CHAT_MODEL=qwen-plus
QWEN_EMBEDDING_MODEL=text-embedding-v4
```

## 启动

```bash
cd backend
python -m venv .venv
pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload
```

Windows PowerShell 激活虚拟环境：

```powershell
.\.venv\Scripts\Activate.ps1
```

文档地址：`/docs`、`/redoc`。健康检查：`/health`。

## Alembic

```bash
alembic revision --autogenerate -m "your message"
alembic upgrade head
alembic downgrade -1
```

## 接口

统一返回：

```json
{"code": 200, "message": "success", "data": {}}
```

异常返回：

```json
{"code": 500, "message": "错误信息", "data": null}
```

认证：`POST /api/v1/auth/register`、`POST /api/v1/auth/login`、`GET /api/v1/auth/me`。

AI（均需 Bearer Token）：
- 文生文：`POST /api/v1/ai/text/chat`（兼容 `POST /api/v1/ai/chat`）
- 文生图：`POST /api/v1/ai/text-to-image`（异步，返回 `task_id`）
- 图生视频：`POST /api/v1/ai/image-to-video`（异步，需公网可访问的 `image_url`）
- 任务查询：`GET /api/v1/ai/tasks/{task_id}`

规则系统：`POST /api/v1/rules/create`、`GET /api/v1/rules/list`。

记录入口：`POST /api/v1/record`，作为观察记录提交的产品级入口。

成长故事：`POST /api/v1/story/generate`、`GET /api/v1/story/{id}`、`GET /api/v1/story/daily`、`GET /api/v1/story/week`。

时间线：`GET /api/v1/timeline`，混合返回观察记录与故事。

学生：`POST /api/v1/students`、`PUT /api/v1/students/{id}`、`DELETE /api/v1/students/{id}`、`GET /api/v1/students/{id}`、`GET /api/v1/students`。

成长观察：`POST /api/v1/observations`、`PUT /api/v1/observations/{id}`、`DELETE /api/v1/observations/{id}`、`GET /api/v1/observations/{id}`、`GET /api/v1/observations?student_id={student_id}&keyword=课堂`。

## 分层架构

严格遵循 `Controller(API) -> Service -> Repository -> Database`，API 层不直接操作数据库。

## 日志与测试

日志输出到 `backend/logs/app.log` 和 `backend/logs/error.log`，自动轮转。运行测试：

```bash
pytest
```

## AI 能力预留

已预留 `app/agents/BaseAgent`、`app/rag/BaseLLMProvider`、`app/rag/BaseEmbeddingProvider`、`app/prompts/`，并新增 `app/rag/qwen_provider.py` 作为千问 Provider 实现。

## Story Engine V1.1

V1.1 新增产品级 Story Engine 闭环：

```text
Record -> Rule -> Plan -> Prompt -> LLM -> Story -> Store -> API
```

核心目录：

- `app/story_engine/`：规则匹配、故事规划、Prompt 构建、LLM 网关和编排器。
- `app/models/rule.py`：`story_rules`、`story_templates`。
- `app/models/story.py`：`stories`、`story_generation_runs`。
- `app/prompts/story_prompts.py`：版本化 Prompt 模板和强约束 JSON 输出结构。
- `docs/flutter_v1_1_contract.md`：Flutter 页面与接口契约（陪伴型 V1）。
- `docs/student_app_ui_ue_design.md`：学生端 UI/UE 与成长伙伴、Gentle Motion 规范。
