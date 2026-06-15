# 成长小岛

面向职场人士、大学生等个人用户的成长记录产品：FastAPI 后端 + PostgreSQL + Flutter 客户端。

## 项目结构

```text
stday/                    # 本仓库根目录
├── backend/              # FastAPI 后端 API
├── stday/                # Flutter 客户端（成长小岛）
├── config/               # 客户端环境变量参考
├── docs/                 # 部署与设计文档
└── README.md
```

## 快速开始（本机开发）

### 1. 后端

```powershell
cd backend
copy .env.example .env          # 编辑数据库密码、JWT、千问 Key
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
alembic upgrade head
.\run_dev.ps1
```

健康检查：`http://127.0.0.1:8000/health`，API 文档：`/docs`。

### 2. 客户端

```powershell
cd stday
flutter pub get
.\run_windows.bat
```

## 部署

| 场景 | 文档 |
|------|------|
| Linux 服务器部署后端 | [docs/DEPLOYMENT_LINUX_BACKEND.md](docs/DEPLOYMENT_LINUX_BACKEND.md) |
| Windows 全量 / 客户端打包 | [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) |

## 环境变量

| 文件 | 用途 |
|------|------|
| [backend/.env.example](backend/.env.example) | 后端全部可配置项 |
| [config/client.env.example](config/client.env.example) | Flutter `API_BASE_URL` 说明 |

## 技术栈

| 层级 | 技术 |
|------|------|
| 后端 | Python 3.10+、FastAPI、SQLAlchemy 2.0 Async、Alembic、JWT |
| 数据库 | PostgreSQL 14+ |
| AI | 千问 DashScope（可选，心情小结等） |
| 客户端 | Flutter 3.3+、Riverpod、Flame 2D |

## 接口概览

- 认证：`/api/v1/auth/*`
- 个人档案与心情：`/api/v1/profile/*`

完整接口见 `http://127.0.0.1:8000/docs`。

## 历史文档

双端时代的审计与设计文档已移至 [docs/archive/](docs/archive/)。
