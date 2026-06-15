# 成长小岛 — 后端 API

面向个人成长记录的 FastAPI 服务：用户认证、今日记录、心情上报、成长岛屿与轨迹。

## 技术栈

- Python 3.10+
- FastAPI / SQLAlchemy 2.0 Async / Pydantic V2 / Alembic
- PostgreSQL
- JWT 认证；千问 DashScope（可选，用于心情 AI 小结）

## 快速开始

```powershell
cd backend
copy .env.example .env
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
.\scripts\init_local_db.ps1   # 本机库 island，与远程 stday 隔离
.\run_dev.ps1
```

健康检查：`http://127.0.0.1:9000/health`  
API 文档：`http://127.0.0.1:9000/docs`

> **数据库**：本机开发默认连接 `island` 库；远程 Linux 服务器可继续使用 `stday` 库，互不影响。

## 主要 API

| 前缀 | 说明 |
|------|------|
| `/api/v1/auth/*` | 注册、登录 |
| `/api/v1/profile/*` | 资料、今日瞬间、心情上报、成长数据 |

## 环境变量

见 [`.env.example`](.env.example)。生产环境务必修改 `JWT_SECRET_KEY` 与 `DATABASE_URL`。

## 数据库迁移

```powershell
alembic upgrade head
```

consumer-only 改造后，全新库直接迁移即可；从旧双端 schema 升级请先备份。

## 部署

- Windows / 全量：[docs/DEPLOYMENT.md](../docs/DEPLOYMENT.md)
- Linux 后端：[docs/DEPLOYMENT_LINUX_BACKEND.md](../docs/DEPLOYMENT_LINUX_BACKEND.md)
