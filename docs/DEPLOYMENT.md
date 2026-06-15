# 成长小岛 — 环境部署指南

本文档说明如何将 **成长小岛**（FastAPI 后端 + PostgreSQL + Flutter 客户端 `stday/`）部署到 Windows 开发机或内网环境。

> Linux 服务器仅部署后端：见 **[DEPLOYMENT_LINUX_BACKEND.md](DEPLOYMENT_LINUX_BACKEND.md)**。

## 1. 系统架构

```text
┌─────────────────────────────────────────┐
│  PostgreSQL :5432  ◄──  FastAPI :8000  │
│                              ▲          │
│                         Flutter stday   │
└─────────────────────────────────────────┘
```

| 组件 | 目录 | 技术 | 默认端口 |
|------|------|------|----------|
| 后端 API | `backend/` | Python 3.10+ / FastAPI | 8000 |
| 数据库 | 系统安装 | PostgreSQL 14+ | 5432 |
| 客户端 | `stday/` | Flutter 3.3+ | — |

## 2. 环境要求

| 软件 | 版本 | 用途 |
|------|------|------|
| Python | 3.10+（推荐 3.12） | 后端 |
| PostgreSQL | 14+ | 数据库 |
| Flutter SDK | 3.3+ | 编译客户端 |
| Visual Studio 2022 | 含「使用 C++ 的桌面开发」 | Windows 桌面客户端 |
| Git | 较新版本 | 获取代码 |

验证：

```powershell
python --version
psql --version
flutter doctor -v
```

## 3. 获取代码

```powershell
git clone <仓库地址> stday
cd stday
```

> `backend/.env` 含密钥，勿提交版本库；迁移时用安全渠道单独传递。

## 4. PostgreSQL

创建数据库：

```sql
CREATE DATABASE stday ENCODING 'UTF8';
```

远程访问时配置 `postgresql.conf` 的 `listen_addresses` 与 `pg_hba.conf`，并重启服务。

## 5. 后端

### 5.1 配置

```powershell
cd backend
copy .env.example .env
notepad .env
```

**必改项：**

| 变量 | 说明 |
|------|------|
| `DATABASE_URL` | PostgreSQL 连接串 |
| `JWT_SECRET_KEY` | 生产环境随机长字符串（≥32 字符） |
| `QWEN_API_KEY` | 千问 DashScope Key（AI 心情小结等，可选） |

完整说明见 [`backend/.env.example`](../backend/.env.example)。

### 5.2 安装与迁移

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
alembic upgrade head
```

> 全新库请直接 `alembic upgrade head`；旧库升级前请备份。

### 5.3 启动

开发（本机）：

```powershell
.\run_dev.ps1
```

局域网访问：

```powershell
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

验证：

```powershell
curl http://127.0.0.1:8000/health
```

API 文档：`http://127.0.0.1:8000/docs`

### 5.4 生产注意

| 项目 | 建议 |
|------|------|
| `DEBUG` | 生产设为 `false` |
| 防火墙 | 开放 TCP 8000 |
| 进程守护 | NSSM / systemd（Linux）/ 容器编排 |

## 6. Flutter 客户端（stday）

```powershell
cd stday
flutter pub get
```

本机运行（默认 API `http://127.0.0.1:8000`）：

```powershell
.\run_windows.bat
```

指定远程后端：

```powershell
powershell -File .\run_windows.ps1 -ApiBaseUrl http://39.106.134.222:8000
```

Release 构建：

```powershell
flutter build windows --release --dart-define=API_BASE_URL=http://39.106.134.222:8000
```

产物：`stday\build\windows\x64\runner\Release\stday.exe`

Windows 编译报 C1083 时运行 `.\repair_windows.bat`。

## 7. 环境变量速查

### 后端（`backend/.env`）

| 变量 | 必填 | 说明 |
|------|------|------|
| `DATABASE_URL` | 是 | PostgreSQL 异步连接串 |
| `JWT_SECRET_KEY` | 是 | JWT 签名 |
| `JWT_EXPIRE_MINUTES` | 否 | Token 有效期（分钟） |
| `PROJECT_NAME` | 否 | 默认「成长小岛」 |
| `DEBUG` | 否 | 开发 `true`，生产 `false` |
| `QWEN_API_KEY` | AI 功能 | 千问 API Key |
| `QWEN_FAST_MODEL` | 否 | 短交互模型，默认 `qwen-flash` |

### 客户端（编译时 `--dart-define`）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `API_BASE_URL` | `http://127.0.0.1:8000` | 后端根地址 |

详见 [`config/client.env.example`](../config/client.env.example)。

## 8. 部署检查清单

- [ ] PostgreSQL 库 `stday` 已创建
- [ ] `backend/.env` 已配置
- [ ] `alembic upgrade head` 成功
- [ ] `GET /health` 正常
- [ ] 客户端能注册（`POST /api/v1/auth/register`）并登录
- [ ] Release exe 的 `API_BASE_URL` 指向正确后端

## 9. 常见场景

**单机开发**：PostgreSQL + 后端 `127.0.0.1:8000` + 客户端默认 API。

**后端集中、客户端分发**：服务器 `uvicorn --host 0.0.0.0`，客户端构建时注入公网/内网 IP。

**仅迁移数据库**：`pg_dump` / `pg_restore` 后更新 `.env` 与客户端 API 地址。

## 10. 故障排查

| 现象 | 处理 |
|------|------|
| 客户端连接超时 | 后端改用 `--host 0.0.0.0`，检查防火墙 |
| 数据库连接失败 | 核对 `DATABASE_URL` 与库名 |
| AI 报错 | 检查 `QWEN_API_KEY` |
| Flutter C1083 | 运行 `repair_windows.bat` |

## 11. 相关文档

- [Linux 后端部署](DEPLOYMENT_LINUX_BACKEND.md)
- [项目 README](../README.md)
- [后端 README](../backend/README.md)
- [客户端 README](../stday/README.md)
- [历史审计报告（已归档）](archive/audit/README.md)
