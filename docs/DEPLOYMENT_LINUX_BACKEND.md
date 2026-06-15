# Linux 服务器 — 后端部署指南

本文档说明如何在 **Linux 新服务器** 上部署 `backend/`（FastAPI + PostgreSQL），供 Windows 本地打包的 Flutter 客户端连接。

## 当前服务器信息

| 项目 | 值 |
|------|-----|
| 公网 IP | `39.106.134.222` |
| 私有 IP | `172.25.19.38` |
| API 公网地址 | `http://39.106.134.222:8000` |
| API 内网地址 | `http://172.25.19.38:8000` |

配置文件：[config/server.env](../config/server.env)

```text
┌──────────── Linux 服务器 39.106.134.222 ────────────┐
│  PostgreSQL :5432（仅本机 127.0.0.1，不对外开放）      │
│  FastAPI    :8000（0.0.0.0，需放行公网）              │
└────────────────────────────────────────────────────┘
            ▲
            │  API_BASE_URL=http://39.106.134.222:8000
┌───────────┴───────────┐
│  Windows 本地打包客户端 │
│  Windows 本地打包 stday  │
└───────────────────────┘
```

## 需要开放的端口

| 端口 | 协议 | 是否对外开放 | 说明 |
|------|------|--------------|------|
| **8000** | TCP | **是（必开）** | FastAPI 后端，Flutter 客户端连接此端口 |
| **22** | TCP | 是（建议限制来源 IP） | SSH 远程登录维护服务器 |
| **5432** | TCP | **否** | PostgreSQL 仅本机 `127.0.0.1` 访问，切勿对公网开放 |
| 80 / 443 | TCP | 可选 | 仅在使用 Nginx 反代 / HTTPS 时需要 |

### 阿里云安全组（必做）

在 ECS 控制台 → 安全组 → **入方向** 添加：

| 端口 | 授权对象 | 说明 |
|------|----------|------|
| 8000/8000 | `0.0.0.0/0` 或指定办公网 IP | 客户端访问 API |
| 22/22 | 你的办公网 IP | SSH 管理 |

### 服务器防火墙（若启用了 ufw）

```bash
sudo ufw allow 22/tcp
sudo ufw allow 8000/tcp
sudo ufw reload
# 不要执行 ufw allow 5432
```

## 1. 服务器要求

| 项目 | 建议 |
|------|------|
| 系统 | Ubuntu 22.04/24.04、Debian 12、CentOS Stream 9 等主流 64 位 Linux |
| CPU / 内存 | 2 核 / 2 GB 起（推荐 4 核 / 4 GB） |
| 磁盘 | ≥ 5 GB |
| 网络 | 能访问 DashScope（千问 API）；客户端能访问 8000 端口 |

| 软件 | 版本 |
|------|------|
| Python | 3.10+（推荐 3.12） |
| PostgreSQL | 14+ |
| Git | 任意较新版本 |

## 2. 安装系统依赖

### Ubuntu / Debian

```bash
sudo apt update
sudo apt install -y python3 python3-venv python3-pip git \
  postgresql postgresql-contrib curl

python3 --version    # 应 ≥ 3.10
psql --version
```

### CentOS / 阿里云 Linux

```bash
sudo yum install -y python3 python3-pip python3-venv git \
  postgresql-server postgresql-contrib

python3 --version    # 应 ≥ 3.10
```

> **常见报错** ` .venv/bin/activate: No such file or directory`：先安装 `python3-venv`，删除旧目录后重装：
> ```bash
> sudo yum install -y python3-venv   # 或 python3.10-venv
> rm -rf /root/stday/backend/.venv
> ./deploy/install.sh
> ```

若系统 Python 低于 3.10，可安装 `deadsnakes` PPA 或使用 pyenv，此处不展开。

### 创建运行用户（推荐）

```bash
sudo useradd -r -m -s /bin/bash stday
sudo su - stday
```

后续步骤默认在 `stday` 用户下执行；也可使用你自己的部署账号。

## 3. 获取代码

```bash
# 示例：部署到 /opt/stday
sudo mkdir -p /opt/stday
sudo chown stday:stday /opt/stday
cd /opt/stday

git clone <你的仓库地址> .
# 或仅上传 backend/ 目录：
# scp -r backend/ user@server:/opt/stday/backend/
```

> **安全**：`backend/.env` 含密钥，请用 `scp` 或密钥管理单独传输，不要放进公开压缩包。

## 4. PostgreSQL 配置

### 4.1 创建数据库与用户

```bash
sudo -u postgres psql
```

```sql
CREATE USER stday_app WITH PASSWORD '强密码请替换';
CREATE DATABASE stday OWNER stday_app ENCODING 'UTF8';
GRANT ALL PRIVILEGES ON DATABASE stday TO stday_app;
\q
```

### 4.2 连接串

`backend/.env` 中填写（密码含特殊字符需 URL 编码，如 `@` → `%40`）：

```env
DATABASE_URL=postgresql+asyncpg://stday_app:强密码请替换@127.0.0.1:5432/stday
```

数据库与后端同机时用 `127.0.0.1` 即可。

## 5. 后端环境变量

```bash
cd /opt/stday/backend
cp .env.example .env
nano .env   # 或 vim
```

### 生产环境推荐值

```env
PROJECT_NAME=AI成长观察系统
DEBUG=false

DATABASE_URL=postgresql+asyncpg://stday_app:你的密码@127.0.0.1:5432/stday

JWT_SECRET_KEY=<随机长字符串，至少32字符>
JWT_EXPIRE_MINUTES=5256000

TEACHER_REGISTRATION_SECRET=<生产环境自定义密钥，勿用 root>

QWEN_API_KEY=sk-xxxxxxxx
QWEN_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
QWEN_DASHSCOPE_BASE_URL=https://dashscope.aliyuncs.com/api/v1
QWEN_CHAT_MODEL=qwen-plus
QWEN_FAST_MODEL=qwen-flash
```

完整变量说明见 [`backend/.env.example`](../backend/.env.example)。

生成随机 JWT 密钥：

```bash
python3 -c "import secrets; print(secrets.token_urlsafe(48))"
```

## 6. 安装 Python 依赖

### 方式 A：一键脚本

```bash
cd /opt/stday/backend
chmod +x deploy/install.sh
./deploy/install.sh
```

### 方式 B：手动

```bash
cd /opt/stday/backend
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

## 7. 数据库迁移

```bash
cd /opt/stday/backend
source .venv/bin/activate
alembic upgrade head
```

迁移使用 `.env` 中的 `DATABASE_URL`（`alembic/env.py` 已自动读取）。

## 8. 启动与验证

### 8.1 临时启动（测试用）

```bash
cd /opt/stday/backend
chmod +x deploy/start.sh
./deploy/start.sh
```

或：

```bash
source .venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

> **必须** 使用 `--host 0.0.0.0`，否则外部客户端无法连接。

### 8.2 验证

在服务器上：

```bash
curl http://127.0.0.1:8000/health
```

在 Windows 开发机上（公网验证）：

```powershell
curl http://39.106.134.222:8000/health
```

同一 VPC 内网验证：

```bash
curl http://172.25.19.38:8000/health
```

期望返回：`{"code":200,"message":"success","data":{"status":"ok"}}`

可选：检查千问配置

```bash
source .venv/bin/activate
python scripts/check_qwen.py
```

### 8.3 防火墙

**Ubuntu（ufw）：**

```bash
sudo ufw allow 8000/tcp
sudo ufw reload
```

**云服务器**：在安全组中放行入站 TCP 8000。

## 9. systemd 常驻服务（生产推荐）

```bash
# 1. 编辑服务文件中的路径与用户
sudo nano /opt/stday/backend/deploy/stday-api.service

# 2. 安装服务
sudo cp /opt/stday/backend/deploy/stday-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable stday-api
sudo systemctl start stday-api
```

常用命令：

```bash
sudo systemctl status stday-api
sudo systemctl restart stday-api
sudo journalctl -u stday-api -f          # 查看日志
```

应用日志同时写入 `backend/logs/app.log`、`backend/logs/error.log`。

## 10. Nginx 反向代理（可选）

若希望通过 80/443 访问，或后续加 HTTPS：

```nginx
# /etc/nginx/sites-available/stday-api
server {
    listen 80;
    server_name api.example.com;   # 改为你的域名或 IP

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/stday-api /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

客户端 `API_BASE_URL` 改为 `http://api.example.com` 或 `https://api.example.com`。

## 11. 从 Windows 环境迁移数据

在 **原 Windows 机器** 导出：

```powershell
pg_dump -U postgres -d stday -F c -f stday.dump
```

上传到 Linux 服务器后恢复：

```bash
pg_restore -U stday_app -d stday --no-owner stday.dump
# 若提示已存在对象，可加 --clean（谨慎，会清表）
```

然后在新服务器执行 `alembic upgrade head` 确保版本最新。

## 12. 客户端对接

后端部署完成后，在 **Windows 本地** 打包客户端：

```bat
stday\build_release_server.bat
```

或手动：

```powershell
flutter build windows --release --dart-define=API_BASE_URL=http://39.106.134.222:8000
```

VPC 内网机器打包时用私有 IP：

```powershell
flutter build windows --release --dart-define=API_BASE_URL=http://172.25.19.38:8000
```

## 13. 部署检查清单

- [ ] Python 3.10+、PostgreSQL 已安装
- [ ] 数据库 `stday` 与用户 `stday_app` 已创建
- [ ] `backend/.env` 已配置（`DEBUG=false`、JWT、千问 Key）
- [ ] `pip install -r requirements.txt` 成功
- [ ] `alembic upgrade head` 成功
- [ ] `curl http://39.106.134.222:8000/health` 正常
- [ ] 防火墙 / 安全组已放行 8000
- [ ] systemd 服务 `active (running)`
- [ ] Windows 客户端 `API_BASE_URL` 指向该服务器

## 14. 故障排查

| 现象 | 原因 | 处理 |
|------|------|------|
| `Connection refused`（外网） | 监听 `127.0.0.1` 或防火墙 | `--host 0.0.0.0`，放行 8000 |
| 数据库连接失败 | 密码错误或用户权限 | 检查 `DATABASE_URL`，`psql` 手动登录测试 |
| `ModuleNotFoundError` | 未激活 venv | `source .venv/bin/activate` |
| Alembic 失败 | `.env` 未创建 | 先 `cp .env.example .env` |
| AI 接口 500 | `QWEN_API_KEY` 空 | 填写有效 Key，服务器需能访问外网 |
| systemd 启动失败 | 路径或用户不对 | `journalctl -u stday-api -n 50` 查看详情 |

## 15. 相关文件

| 文件 | 说明 |
|------|------|
| [`backend/.env.example`](../backend/.env.example) | 环境变量模板 |
| [`backend/deploy/install.sh`](../backend/deploy/install.sh) | 依赖安装脚本 |
| [`backend/deploy/start.sh`](../backend/deploy/start.sh) | 前台启动脚本 |
| [`backend/deploy/stday-api.service`](../backend/deploy/stday-api.service) | systemd 单元 |
| [`docs/DEPLOYMENT.md`](DEPLOYMENT.md) | 全量部署（含 Windows 客户端） |
