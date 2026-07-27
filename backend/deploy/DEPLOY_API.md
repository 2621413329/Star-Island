# API 部署指南（HTTPS）

对外使用 **HTTPS**（`https://api.lcxxingyu.fun`）。  
本机 `8000` 由 Nginx 反代，**不要**对公网直接暴露 8000 端口。

## 架构

```
客户端 App  ──HTTPS:443──►  Nginx (api.lcxxingyu.fun)
                                │
                                └──HTTP──►  uvicorn 127.0.0.1:8000
```

---

## 一、前置条件

| 项 | 说明 |
|----|------|
| DNS | `api.lcxxingyu.fun` A 记录 → 服务器公网 IP（如 `39.106.134.222`） |
| 安全组 | 放行 **80**（证书申请 + HTTP→HTTPS 跳转）、**443**（HTTPS） |
| 安全组 | **关闭**公网 **8000**、8090、9000（仅本机反代） |
| 后端 | uvicorn 监听 `127.0.0.1:8000` 或 `0.0.0.0:8000`（由 Nginx 反代） |
| 后端 `.env` | `PUBLIC_API_BASE_URL=https://api.lcxxingyu.fun`（语音 ASR 公网拉取） |
| 后端 `.env` | `DEBUG=false`，强随机 `JWT_SECRET_KEY` |

---

## 二、首次启用 HTTPS（服务器操作）

在仓库根目录（如 `/root/Star-Island/Star-Island-v2`）执行：

### 步骤 1：启动后端

```bash
cd backend
export UVICORN_HOST=127.0.0.1
./deploy/start.sh --port 8000
curl http://127.0.0.1:8000/health
```

### 步骤 2：安装 Nginx + certbot（若未装）

```bash
sudo apt update
sudo apt install -y nginx certbot
sudo mkdir -p /var/www/certbot
```

### 步骤 3：Bootstrap（证书申请前，80 反代）

```bash
cd /path/to/Star-Island
sudo bash deploy/nginx/install-https.sh bootstrap
curl http://api.lcxxingyu.fun/health
```

### 步骤 4：申请 Let's Encrypt 证书

```bash
sudo certbot certonly --webroot -w /var/www/certbot -d api.lcxxingyu.fun
```

证书路径：`/etc/letsencrypt/live/api.lcxxingyu.fun/fullchain.pem`

### 步骤 5：启用 HTTPS 443

```bash
sudo bash deploy/nginx/install-https.sh ssl
curl https://api.lcxxingyu.fun/health
sudo bash deploy/nginx/install-https.sh status
```

### 步骤 6：配置后端公网地址

编辑 `backend/.env`：

```env
PUBLIC_API_BASE_URL=https://api.lcxxingyu.fun
USER_MEDIA_ROOT=/data/star-island/user_media
DEBUG=false
```

`USER_MEDIA_ROOT` 必须指向持久化目录，用于保存用户语音和照片；部署后可通过
`curl https://api.lcxxingyu.fun/health/media` 检查目录是否存在且可写。

重启后端：

```bash
cd backend && ./deploy/start.sh --port 8000
```

### 步骤 7：证书自动续期

```bash
sudo certbot renew --dry-run
# certbot 通常已通过 systemd timer 自动续期；续期后需 reload nginx：
# sudo systemctl reload nginx
```

---

## 三、客户端打包

```bash
cd stday
flutter build apk --release --dart-define=API_BASE_URL=https://api.lcxxingyu.fun
flutter build windows --release --dart-define=API_BASE_URL=https://api.lcxxingyu.fun
```

Release 未传 `API_BASE_URL` 时，客户端默认也是 `https://api.lcxxingyu.fun`。

本机开发仍用 HTTP：

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:9000
```

---

## 四、配置文件说明

| 文件 | 用途 |
|------|------|
| `deploy/nginx/conf.d/stday-api.ssl.conf` | **HTTPS 生产配置**（443 + 80 跳转） |
| `deploy/nginx/conf.d/stday-api.ssl.bootstrap.conf` | certbot 申请前 bootstrap |
| `deploy/nginx/conf.d/stday-api.conf` | 旧 HTTP 配置（HTTPS 启用后会被脚本备份） |
| `deploy/nginx/install-https.sh` | **HTTPS 一键安装** |
| `deploy/nginx/install-http.sh` | 仅 HTTP 阶段使用（已切 HTTPS 后勿再用） |

---

## 五、验证清单

```bash
curl -I http://api.lcxxingyu.fun/health          # 应 301 → https
curl https://api.lcxxingyu.fun/health            # 200 JSON
curl http://127.0.0.1:8000/health                # 本机直连（服务器上）
openssl s_client -connect api.lcxxingyu.fun:443 -servername api.lcxxingyu.fun </dev/null 2>/dev/null | openssl x509 -noout -dates
```

---

## 六、从 HTTP 迁移

若当前仍在用 `install-http.sh`：

1. 确认 DNS 与安全组 443 已开
2. 按上文「首次启用 HTTPS」执行 bootstrap → certbot → ssl
3. `install-https.sh ssl` 会自动将 `stday-api.conf` 备份为 `.bak`
4. 重新打包 App（HTTPS URL）

详细域名说明见同目录 `DEPLOY_HTTPS_lcxxingyu.fun.md`。
