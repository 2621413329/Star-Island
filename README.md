# AI成长观察系统

面向学生成长观察与陪伴的全栈项目：FastAPI 后端 + PostgreSQL + Flutter 学生端 / 教师端。

## 项目结构

```text
stday/                    # 本仓库根目录
├── backend/              # FastAPI 后端 API
├── stday/                # Flutter 学生端（温暖陪伴型成长伙伴）
├── teacher_app/          # Flutter 教师端
├── config/               # 客户端环境变量参考
├── docs/                 # 部署与设计文档
│   ├── DEPLOYMENT.md              # 全量部署（Windows 为主）
│   └── DEPLOYMENT_LINUX_BACKEND.md # ★ Linux 服务器后端部署
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

### 2. 学生端

```powershell
cd stday
flutter pub get
.\run_windows.bat
```

### 3. 教师端

```powershell
cd teacher_app
flutter pub get
.\run_windows.bat
```

## 部署到另一台机器

| 场景 | 文档 |
|------|------|
| **Linux 服务器部署后端**（推荐） | **[docs/DEPLOYMENT_LINUX_BACKEND.md](docs/DEPLOYMENT_LINUX_BACKEND.md)** |
| Windows 全量 / 客户端打包 | [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) |

典型架构：**Linux 跑 PostgreSQL + 后端**，**Windows 本地打包**客户端。

| 地址 | 用途 |
|------|------|
| `http://39.106.134.222:8000` | 公网 API（外网客户端 / 本地打包） |
| `http://172.25.19.38:8000` | VPC 内网 API |

详见 [config/server.env](config/server.env)。**安全组需放行 TCP 8000**。

## 环境变量

| 文件 | 用途 |
|------|------|
| [backend/.env.example](backend/.env.example) | 后端全部可配置项（复制为 `backend/.env`） |
| [config/server.env](config/server.env) | 当前服务器公网/私网 IP 与 API 地址 |
| [config/client.env.example](config/client.env.example) | Flutter 客户端 `API_BASE_URL` 说明 |

**切勿将 `backend/.env` 提交到版本库**（含数据库密码与 API Key）。

## 技术栈

| 层级 | 技术 |
|------|------|
| 后端 | Python 3.10+、FastAPI、SQLAlchemy 2.0 Async、Alembic、JWT |
| 数据库 | PostgreSQL 14+ |
| AI | 千问 DashScope（OpenAI 兼容模式） |
| 学生端 | Flutter 3.3+、Riverpod、Flame |
| 教师端 | Flutter 3.3+、Riverpod |

## 产品文档

| 文档 | 说明 |
|------|------|
| [backend/docs/student_app_ui_ue_design.md](backend/docs/student_app_ui_ue_design.md) | 学生端 UI/UE 设计 |
| [backend/docs/flutter_v1_1_contract.md](backend/docs/flutter_v1_1_contract.md) | Flutter 页面与 API 契约 |

## 子项目说明

- [backend/README.md](backend/README.md) — 后端 API、分层架构、Alembic
- [stday/README.md](stday/README.md) — 学生端功能与运行
- [teacher_app/README.md](teacher_app/README.md) — 教师端功能与注册

## 接口概览

统一响应：`{"code": 200, "message": "success", "data": {}}`

- 认证：`/api/v1/auth/*`
- 学生档案与心情：`/api/v1/profile/*`
- 成长故事：`/api/v1/story/*`
- 教师观察：`/api/v1/observations/*`
- AI：`/api/v1/ai/*`

完整接口见 `http://127.0.0.1:8000/docs`。
