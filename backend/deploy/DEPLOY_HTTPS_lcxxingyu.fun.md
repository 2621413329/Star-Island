# lcxxingyu.fun HTTPS 部署指南

对外 **只提供 HTTPS**（`https://api.lcxxingyu.fun`）。  
本机 `8000` / `8090` / `9000` 仅供 Nginx 反代，**不要**对公网开放，也 **不要** 写进 App 打包参数。

## 架构

```
安卓 App  ──HTTPS:443──►  Nginx (api.lcxxingyu.fun)
                              │
                              └──HTTP──►  uvicorn 127.0.0.1:8090
```

| 层级 | 地址 | 说明 |
|------|------|------|
| 客户端 | `https://api.lcxxingyu.fun` | 唯一对外 API 入口 |
| Nginx | 公网 `80` / `443` | 80 仅 certbot + 跳转 HTTPS |
| uvicorn | `127.0.0.1:8090` | 仅本机，安全组不开放 |

---

## 第一步：DNS

在域名控制台添加：

| 类型 | 主机记录 | 记录值 |
|------|---------|--------|
| A | `api` | `39.106.134.222` |

验证：

```bash
ping api.lcxxingyu.fun
# 应解析到 39.106.134.222
```

**DNS 未生效前无法申请证书，App 也无法用该域名连通。**

---

## 第二步：安全组（阿里云）

**入方向放行：**

| 端口 | 协议 | 说明 |
|------|------|------|
| 80 | TCP | certbot 验证、HTTP→HTTPS 跳转 |
| 443 | TCP | HTTPS API |
| 22 | TCP | SSH |

**建议关闭公网入站：** `8000`、`8090`、`9000`（历史直连端口，改由 Nginx 443 统一对外）。

---

## 第三步：停用旧 HTTP 配置

若服务器上已有 `stday-api.conf`（监听 80 反代 8000），必须先禁用，否则会出现 `duplicate upstream "stday_api"` 或错误跳转：

```bash
sudo mv /etc/nginx/conf.d/stday-api.conf /etc/nginx/conf.d/stday-api.conf.bak
```

停止对外直听的 uvicorn（若仍在 `0.0.0.0:8000` / `:9000`）：

```bash
sudo ss -lntp | grep -E ':8000|:9000|:8090'
# 对外进程应全部停掉，仅保留 127.0.0.1:8090
```

---

## 第四步：安装 Nginx 与 Certbot

```bash
# CentOS / Aliyun Linux
sudo yum install -y nginx certbot python3-certbot-nginx

# Ubuntu / Debian
# sudo apt update && sudo apt install -y nginx certbot python3-certbot-nginx

sudo mkdir -p /var/www/certbot
sudo systemctl enable nginx
```

将仓库 `deploy/nginx/nginx.conf` 中 `http { }` 里的 `limit_req_zone` 两行合并进服务器 `/etc/nginx/nginx.conf`。

---

## 第五步：后端只监听本机 8090

```bash
cd /path/to/Star-Island/backend
export UVICORN_HOST=127.0.0.1
./deploy/start.sh --port 8090
```

验证（仅本机）：

```bash
curl http://127.0.0.1:8090/health
# {"code":200,"message":"success","data":{"status":"ok"}}
```

---

## 第六步：Nginx — 两阶段部署证书

### 6.1 申请证书前（bootstrap，仅 HTTP:80）

```bash
cd /path/to/Star-Island
sudo cp deploy/nginx/conf.d/stday-api.ssl.bootstrap.conf /etc/nginx/conf.d/stday-api.ssl.conf
sudo nginx -t && sudo systemctl reload nginx
```

验证 HTTP 已通（外网）：

```bash
curl http://api.lcxxingyu.fun/health
```

### 6.2 申请 Let's Encrypt 证书

```bash
sudo certbot certonly --webroot -w /var/www/certbot -d api.lcxxingyu.fun
```

或使用 Nginx 插件（bootstrap 已就绪时）：

```bash
sudo certbot --nginx -d api.lcxxingyu.fun
```

### 6.3 启用完整 HTTPS 配置

```bash
sudo cp deploy/nginx/conf.d/stday-api.ssl.conf /etc/nginx/conf.d/stday-api.ssl.conf
sudo nginx -t && sudo systemctl reload nginx
```

---

## 第七步：验证 HTTPS

```bash
curl https://api.lcxxingyu.fun/health
# 期望: {"code":200,"message":"success","data":{"status":"ok"}}
```

手机浏览器打开同一地址，也应看到 JSON。

---

## 第八步：安卓打包

**唯一推荐写法（不要带端口、不要写 IP、不要写 http）：**

```bash
cd stday
flutter clean
flutter pub get
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.lcxxingyu.fun
```

Windows 可直接运行 `build_release_android.bat`（已指向该地址）。

安装新 APK 前请先卸载旧版。

---

## 常见问题

### certbot 失败

- `ping api.lcxxingyu.fun` 是否指向 `39.106.134.222`
- 安全组是否放行 **80**
- 是否已禁用旧 `stday-api.conf`
- `sudo ss -lntp | grep ':80'` 确认 80 由 nginx 监听

### App 显示「网络错误」

1. 手机浏览器访问 `https://api.lcxxingyu.fun/health` — 若失败，先修服务器，不是 App 问题
2. 确认打包参数为 `https://api.lcxxingyu.fun`，**不要**使用：
   - `http://39.106.134.222:9000`
   - `https://39.106.134.222:8000`
   - 任何带 `:8090` / `:9000` 的地址
3. `flutter clean` 后重新 `build apk`，避免旧编译缓存

### 证书续期

```bash
sudo certbot renew --dry-run
```

---

## 端口对照（迁移说明）

| 旧用法（废弃） | 新用法 |
|---------------|--------|
| `http://39.106.134.222:8000` | `https://api.lcxxingyu.fun` |
| `http://39.106.134.222:9000` | `https://api.lcxxingyu.fun` |
| uvicorn `0.0.0.0:8090` 公网直连 | `127.0.0.1:8090` + Nginx 443 |

客户端与 Nginx 之间全程 HTTPS；Nginx 到 uvicorn 为本机 HTTP，不暴露到公网。
