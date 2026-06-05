# AI成长观察系统 — 环境部署指南

本文档说明如何将整套系统（后端 + PostgreSQL + 学生端 + 教师端）部署到另一台机器。

> **Linux 服务器仅部署后端**：见专用文档 **[DEPLOYMENT_LINUX_BACKEND.md](DEPLOYMENT_LINUX_BACKEND.md)**（含 systemd、防火墙、数据迁移）。客户端仍在 Windows 本地打包。

## 1. 系统架构

```text
┌─────────────────────────────────────────────────────────┐
│                    部署目标机器                          │
│                                                         │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐ │
│  │  PostgreSQL  │◄──│ FastAPI 后端 │◄──│ Flutter 客户端│ │
│  │   :5432      │   │   :8000      │   │ stday /      │ │
│  └──────────────┘   └──────────────┘   │ teacher_app  │ │
│                                         └──────────────┘ │
└─────────────────────────────────────────────────────────┘
```

| 组件 | 目录 | 技术 | 默认端口 |
|------|------|------|----------|
| 后端 API | `backend/` | Python 3.10+ / FastAPI | 8000 |
| 数据库 | 系统安装 | PostgreSQL 14+ | 5432 |
| 学生端 | `stday/` | Flutter 3.3+ | — |
| 教师端 | `teacher_app/` | Flutter 3.3+ | — |

## 2. 目标机器要求

### 硬件（建议）

- CPU：4 核及以上
- 内存：8 GB 及以上（Flutter 编译需要较多内存）
- 磁盘：10 GB 可用空间

### 软件

| 软件 | 版本要求 | 用途 |
|------|----------|------|
| Python | 3.10+（推荐 3.12） | 后端运行时 |
| PostgreSQL | 14+ | 数据存储 |
| Flutter SDK | 3.3+ | 编译客户端 |
| Visual Studio 2022 | 含「使用 C++ 的桌面开发」工作负载 | Windows 桌面客户端编译 |
| Git | 任意较新版本 | 获取代码 |

验证安装：

```powershell
python --version
psql --version
flutter doctor -v
```

## 3. 获取项目代码

### 方式 A：Git 克隆（推荐）

```powershell
git clone <你的仓库地址> stday
cd stday
```

### 方式 B：打包迁移

在源机器打包（排除虚拟环境、构建产物和日志）：

```powershell
# 在源机器项目根目录
Compress-Archive -Path * -DestinationPath stday-deploy.zip
# 手动确认未包含 backend\.venv、build\、backend\logs\、backend\.env
```

将压缩包复制到目标机器后解压。

> **安全提示**：`backend/.env` 含数据库密码和 API Key，请通过安全渠道单独传输，不要放入公开压缩包。

## 4. PostgreSQL 安装与配置

### Windows 安装

1. 从 [PostgreSQL 官方下载页](https://www.postgresql.org/download/windows/) 安装。
2. 安装时记住 `postgres` 用户密码。
3. 默认端口 `5432`，安装 Stack Builder 可跳过。

### 创建数据库

使用 pgAdmin 或 `psql`：

```sql
CREATE DATABASE stday ENCODING 'UTF8';
```

### 允许远程连接（仅当数据库与后端不在同一台机器时需要）

编辑 `postgresql.conf`：

```ini
listen_addresses = '*'
```

编辑 `pg_hba.conf`，添加：

```text
host    stday    postgres    192.168.0.0/16    scram-sha-256
```

将网段改为你的局域网段，然后重启 PostgreSQL 服务。

## 5. 后端部署

### 5.1 配置环境变量

```powershell
cd backend
copy .env.example .env
notepad .env
```

**必须修改的项：**

| 变量 | 说明 |
|------|------|
| `DATABASE_URL` | PostgreSQL 连接串，密码和主机按实际填写 |
| `JWT_SECRET_KEY` | 生产环境随机长字符串 |
| `QWEN_API_KEY` | 千问 DashScope API Key |
| `TEACHER_REGISTRATION_SECRET` | 教师注册密钥（生产环境勿用默认值 `root`） |

完整变量说明见 [`backend/.env.example`](../backend/.env.example)。

### 5.2 安装依赖

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### 5.3 数据库迁移

```powershell
alembic upgrade head
```

若 `alembic.ini` 中 `sqlalchemy.url` 与 `.env` 不一致，以 `.env` 中的 `DATABASE_URL` 为准（应用运行时使用 `.env`）。

### 5.4 启动后端

**开发模式（本机）：**

```powershell
.\run_dev.ps1
# 或
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

**局域网 / 多机访问（其他电脑上的 Flutter 客户端需要连过来）：**

```powershell
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

> 使用 `0.0.0.0` 后，客户端应将 `API_BASE_URL` 设为 `http://<服务器局域网IP>:8000`。

**验证：**

```powershell
curl http://127.0.0.1:8000/health
```

浏览器打开 `http://127.0.0.1:8000/docs` 查看 API 文档。

### 5.5 生产环境注意事项

| 项目 | 说明 |
|------|------|
| `DEBUG` | 生产建议设为 `false`；桌面客户端不受浏览器 CORS 限制 |
| CORS | 仅在 `DEBUG=true` 时启用；若部署 Web 版 Flutter 需额外配置 |
| 进程守护 | 可用 NSSM、Windows 服务或 `pm2`（通过 `uvicorn` 包装）保持后端常驻 |
| 防火墙 | 开放 TCP 8000（后端）、5432（仅远程数据库时） |

## 6. 学生端部署（stday）

### 6.1 安装依赖

```powershell
cd stday
flutter pub get
```

若缺少平台目录：

```powershell
flutter create . --org com.stday
flutter pub get
```

### 6.2 配置 API 地址

客户端通过编译参数 `API_BASE_URL` 注入，参考 [`config/client.env.example`](../config/client.env.example)。

**本机运行（后端也在本机）：**

```powershell
.\run_windows.bat
```

**指定远程后端：**

```powershell
powershell -File .\run_windows.ps1 -ApiBaseUrl http://39.106.134.222:8000
```

**Release 构建（分发给用户）：**

```powershell
flutter build windows --release --dart-define=API_BASE_URL=http://39.106.134.222:8000
```

产物路径：`stday\build\windows\x64\runner\Release\stday.exe`

### 6.3 Windows 编译问题

若出现 `cpp_client_wrapper` 缺失（C1083），执行：

```powershell
.\repair_windows.bat
```

## 7. 教师端部署（teacher_app）

### 7.1 安装与运行

```powershell
cd teacher_app
flutter pub get
```

**本机：**

```bat
run_windows.bat
```

**指定远程后端：**

```powershell
flutter run -d windows --dart-define=API_BASE_URL=http://39.106.134.222:8000
```

**Release 构建：**

```powershell
flutter build windows --release --dart-define=API_BASE_URL=http://39.106.134.222:8000
```

产物路径：`teacher_app\build\windows\x64\runner\Release\teacher_app.exe`

### 7.2 教师注册

首次使用需在教师端注册账号，注册时：

1. 选择班级
2. 填写注册密钥（与 `backend/.env` 中 `TEACHER_REGISTRATION_SECRET` 一致）

## 8. 环境变量速查

### 后端（`backend/.env`）

| 变量 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `DATABASE_URL` | 是 | — | PostgreSQL 异步连接串 |
| `JWT_SECRET_KEY` | 是 | — | JWT 签名密钥 |
| `JWT_ALGORITHM` | 否 | `HS256` | JWT 算法 |
| `JWT_EXPIRE_MINUTES` | 否 | `1440` | Token 有效期（分钟） |
| `PROJECT_NAME` | 否 | `AI成长观察系统` | 应用名称 |
| `DEBUG` | 否 | `false` | 调试模式 |
| `QWEN_API_KEY` | AI 功能 | — | 千问 API Key |
| `QWEN_BASE_URL` | 否 | DashScope 兼容地址 | 文生文 API |
| `QWEN_DASHSCOPE_BASE_URL` | 否 | DashScope 原生地址 | 文生图/视频 API |
| `QWEN_CHAT_MODEL` | 否 | `qwen-plus` | 长文本对话模型 |
| `QWEN_FAST_MODEL` | 否 | `qwen-flash` | 短交互模型 |
| `QWEN_MOOD_REPORT_MODEL` | 否 | — | `QWEN_FAST_MODEL` 的兼容别名 |
| `QWEN_EMBEDDING_MODEL` | 否 | `text-embedding-v4` | 向量模型 |
| `QWEN_T2I_MODEL` | 否 | `wan2.5-t2i-preview` | 文生图模型 |
| `QWEN_I2V_MODEL` | 否 | `wan2.5-i2v-preview` | 图生视频模型 |
| `QWEN_TASK_POLL_INTERVAL_SEC` | 否 | `3` | 异步任务轮询间隔 |
| `QWEN_TASK_POLL_TIMEOUT_SEC` | 否 | `300` | 异步任务超时 |
| `TEACHER_REGISTRATION_SECRET` | 否 | `root` | 教师注册密钥 |

### 客户端（编译时 `--dart-define`）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `API_BASE_URL` | `http://127.0.0.1:8000` | 后端 API 根地址 |

## 9. 部署检查清单

按顺序逐项确认：

- [ ] Python、PostgreSQL、Flutter、`flutter doctor` 全部通过
- [ ] `backend/.env` 已从 `.env.example` 创建并填写
- [ ] PostgreSQL 数据库 `stday` 已创建
- [ ] `alembic upgrade head` 执行成功
- [ ] `GET /health` 返回 `{"code":200,...}`
- [ ] 千问 API Key 有效（可选：`python scripts/check_qwen.py`）
- [ ] 学生端能登录（`POST /api/v1/auth/entry`）
- [ ] 教师端能注册并登录
- [ ] Release 构建的 exe 中 `API_BASE_URL` 指向正确后端地址

## 10. 常见部署场景

### 场景 A：单机全量部署（最常见）

所有组件在同一台 Windows 电脑：

1. 安装 PostgreSQL、Python、Flutter、VS2022
2. 配置 `backend/.env`（`DATABASE_URL` 用 `127.0.0.1`）
3. 启动后端 `.\run_dev.ps1`
4. 客户端使用默认 `API_BASE_URL=http://127.0.0.1:8000`

### 场景 B：后端集中，客户端多台

- 服务器：PostgreSQL + 后端（`uvicorn --host 0.0.0.0`）
- 各客户端：`API_BASE_URL=http://39.106.134.222:8000` 构建 exe 分发（内网用 `172.25.19.38`）
- 防火墙放行 8000 端口

### 场景 C：仅迁移后端与数据库

1. 在源库执行 `pg_dump -U postgres -d stday -F c -f stday.dump`
2. 目标机恢复 `pg_restore -U postgres -d stday stday.dump`
3. 复制 `backend/` 并配置新 `.env`
4. 客户端 API 地址改为新服务器 IP

## 11. 故障排查

| 现象 | 可能原因 | 处理 |
|------|----------|------|
| 客户端连接超时 | 后端只监听 `127.0.0.1` | 改用 `--host 0.0.0.0` |
| 数据库连接失败 | 密码错误或库未创建 | 检查 `DATABASE_URL`，确认 `stday` 库存在 |
| AI 功能报错 | `QWEN_API_KEY` 未配置 | 在 `.env` 填入有效 Key |
| 教师注册失败 | 密钥不匹配 | 确认 `TEACHER_REGISTRATION_SECRET` |
| Flutter C1083 | ephemeral 目录损坏 | 运行 `repair_windows.bat` |
| `flutter` 找不到 | 未加入 PATH | 安装 Flutter 并配置环境变量 |

## 12. 相关文档

- [Linux 后端部署指南](DEPLOYMENT_LINUX_BACKEND.md)
- [项目 README](../README.md)
- [后端 README](../backend/README.md)
- [学生端 README](../stday/README.md)
- [教师端 README](../teacher_app/README.md)
- [后端环境变量模板](../backend/.env.example)
- [客户端环境变量参考](../config/client.env.example)
