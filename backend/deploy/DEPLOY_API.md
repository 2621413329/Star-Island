# API 部署指南（当前：HTTP）

对外使用 **HTTP**（`http://api.lcxxingyu.fun` 或 `http://39.106.134.222`）。  
本机 `8000` 由 Nginx 反代，建议不对公网直接暴露。

## 架构

```
安卓 App  ──HTTP:80──►  Nginx (api.lcxxingyu.fun / IP)
                            │
                            └──HTTP──►  uvicorn 127.0.0.1:8000
```

---

## 快速安装

```bash
# 1. 后端本机启动
cd backend
export UVICORN_HOST=127.0.0.1
./deploy/start.sh --port 8000
curl http://127.0.0.1:8000/health

# 2. 安装 HTTP 反代
cd ..
sudo bash deploy/nginx/install-http.sh

# 3. 验证
curl http://api.lcxxingyu.fun/health
curl http://39.106.134.222/health
sudo bash deploy/nginx/install-http.sh status
```

若服务器上已有**未注释的** `stday-api.ssl.conf`，`install-http.sh` 会自动备份，避免 443/301 冲突。

---

## DNS（可选，有域名时）

| 类型 | 主机记录 | 记录值 |
|------|---------|--------|
| A | `api` | `39.106.134.222` |

无域名时可直接用 IP：`http://39.106.134.222`

---

## 安全组

**放行：** `80`（HTTP）  
**建议关闭公网：** `8000`、`8090`、`9000`（仅本机反代）

---

## 安卓打包

```bash
cd stday
flutter build apk --release --dart-define=API_BASE_URL=http://api.lcxxingyu.fun
```

无域名时：

```bash
flutter build apk --release --dart-define=API_BASE_URL=http://39.106.134.222
```

---

## 配置文件说明

| 文件 | 状态 |
|------|------|
| `deploy/nginx/conf.d/stday-api.conf` | **当前使用**（HTTP 80） |
| `deploy/nginx/conf.d/stday-api.ssl.conf` | 已注释，HTTPS 模板 |
| `deploy/nginx/conf.d/stday-api.ssl.bootstrap.conf` | 已注释，certbot 用 |
| `deploy/nginx/install-http.sh` | **当前使用** |
| `deploy/nginx/install-https.sh` | 保留，日后启用 HTTPS 时用 |

---

<!-- 以下 HTTPS 方案暂缓，配置模板见 stday-api.ssl.conf -->

## （暂缓）HTTPS 切换步骤

日后需要 HTTPS 时：

1. 阅读并取消注释 `deploy/nginx/conf.d/stday-api.ssl.conf`
2. 申请证书：`sudo certbot certonly --webroot -w /var/www/certbot -d api.lcxxingyu.fun`
3. 执行：`sudo bash deploy/nginx/install-https.sh ssl`
4. App 打包改为：`--dart-define=API_BASE_URL=https://api.lcxxingyu.fun`
5. 安全组额外放行 `443`

详细说明见同目录 `DEPLOY_HTTPS_lcxxingyu.fun.md`（参考文档）。
