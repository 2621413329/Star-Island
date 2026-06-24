# lcxxingyu.fun HTTPS 部署指南

对外 **只提供 HTTPS**（`https://api.lcxxingyu.fun`）。  
本机 `8000` 仅供 Nginx 反代，**不要**对公网开放，也 **不要** 写进 App 打包参数。

## 架构

```
安卓 App  ──HTTPS:443──►  Nginx (api.lcxxingyu.fun)
                              │
                              └──HTTP──►  uvicorn 127.0.0.1:8000
```

| 层级 | 地址 | 说明 |
|------|------|------|
| 客户端 | `https://api.lcxxingyu.fun` | 唯一对外 API 入口 |
| Nginx | 公网 `80` / `443` | 80 仅 certbot + 跳转 HTTPS |
| uvicorn | `127.0.0.1:8000` | 仅本机，安全组不开放 |

---

## 快速安装（推荐）

在服务器拉取代码后，于**仓库根目录**执行：

```bash
# 1. 后端本机启动（若尚未运行）
cd backend
export UVICORN_HOST=127.0.0.1
./deploy/start.sh --port 8000
curl http://127.0.0.1:8000/health

# 2. 阶段一：HTTP 反代（申请证书用）
cd ..
sudo bash deploy/nginx/install-https.sh bootstrap
curl http://api.lcxxingyu.fun/health

# 3. 申请证书
sudo certbot certonly --webroot -w /var/www/certbot -d api.lcxxingyu.fun

# 4. 阶段二：启用 HTTPS 443
sudo bash deploy/nginx/install-https.sh ssl
curl https://api.lcxxingyu.fun/health

# 5. 检查状态
sudo bash deploy/nginx/install-https.sh status
```

配置文件位置：

| 文件 | 用途 |
|------|------|
| `deploy/nginx/conf.d/stday-api.ssl.bootstrap.conf` | 证书申请前（仅 80） |
| `deploy/nginx/conf.d/stday-api.ssl.conf` | 证书就绪后（80 + 443） |
| `deploy/nginx/install-https.sh` | 一键安装脚本 |
| `deploy/nginx/snippets/limit_req_zones.conf` | 限流 zone 片段（ssl 阶段需要） |

---

## 第一步：DNS

| 类型 | 主机记录 | 记录值 |
|------|---------|--------|
| A | `api` | `39.106.134.222` |

```bash
ping api.lcxxingyu.fun
```

---

## 第二步：安全组

**放行：** `80`、`443`  
**关闭公网：** `8000`、`8090`、`9000`

---

## 第三步：旧配置说明

若存在 `/etc/nginx/conf.d/stday-api.conf`，安装脚本会自动改名为 `.bak`。  
若不存在（`No such file`），**可忽略**，直接执行 `install-https.sh bootstrap`。

---

## 安卓打包

```bash
cd stday
flutter build apk --release --dart-define=API_BASE_URL=https://api.lcxxingyu.fun
```

---

## 常见问题

### `nginx -t` 报 `limit_req_zone` 不存在

仅在 **ssl 阶段**需要。脚本会自动写入；也可手动将 `deploy/nginx/snippets/limit_req_zones.conf` 内容加入 `/etc/nginx/nginx.conf` 的 `http { }` 块。

### `cannot load certificate`

说明证书尚未申请，请先完成 `bootstrap` + `certbot`，再执行 `install-https.sh ssl`。

### App 仍连不上

手机浏览器访问 `https://api.lcxxingyu.fun/health`，必须先通再排查 App。
