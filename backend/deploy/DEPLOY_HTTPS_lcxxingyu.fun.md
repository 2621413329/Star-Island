# lcxxingyu.fun HTTPS 部署指南

API 建议使用子域名 **`api.lcxxingyu.fun`**，根域名 `lcxxingyu.fun` 可留给官网。

## 架构

```
安卓 App  --HTTPS:443-->  Nginx (api.lcxxingyu.fun)  --HTTP-->  uvicorn 127.0.0.1:8090
```

---

## 第一步：DNS 解析（域名控制台）

| 记录类型 | 主机记录 | 记录值 |
|---------|---------|--------|
| A | `api` | `39.106.134.222` |

生效后在本机验证：

```bash
ping api.lcxxingyu.fun
# 应解析到 39.106.134.222
```

---

## 第二步：阿里云安全组

入方向放行：

| 端口 | 协议 | 说明 |
|------|------|------|
| 80 | TCP | certbot 验证 + HTTP 跳转 |
| 443 | TCP | HTTPS API |
| 22 | TCP | SSH（已有可忽略） |

**不必**对公网开放 8090（uvicorn 只绑本机）。

---

## 第三步：安装 Nginx 与 Certbot（服务器）

```bash
# CentOS / Aliyun Linux
sudo yum install -y nginx certbot python3-certbot-nginx

# 或 Ubuntu / Debian
# sudo apt update && sudo apt install -y nginx certbot python3-certbot-nginx

sudo mkdir -p /var/www/certbot
sudo systemctl enable nginx
```

---

## 第四步：合并 Nginx 限流配置

将仓库 `deploy/nginx/nginx.conf` 里 `http { }` 块中的 `limit_req_zone` 两行复制到服务器 `/etc/nginx/nginx.conf` 的 `http` 块内。

---

## 第五步：部署站点配置

```bash
cd /root/star/Star-Island-main
sudo cp deploy/nginx/conf.d/stday-api.ssl.conf /etc/nginx/conf.d/
sudo nginx -t
```

若证书路径尚不存在，可先注释 `ssl_certificate` 两行，仅保留 `listen 80` 的 server 块完成 certbot。

---

## 第六步：后端只监听本机

```bash
cd /root/star/Star-Island-main/backend
# .env 中设置（或 export）:
# UVICORN_HOST=127.0.0.1

export UVICORN_HOST=127.0.0.1
./deploy/start.sh --port 8090
```

验证本机 HTTP：

```bash
curl http://127.0.0.1:8090/health
```

---

## 第七步：申请 Let's Encrypt 免费证书

```bash
sudo certbot --nginx -d api.lcxxingyu.fun
```

按提示填写邮箱并同意条款。成功后 certbot 会自动改 Nginx 配置并配置续期。

手动重载：

```bash
sudo nginx -t && sudo systemctl reload nginx
```

---

## 第八步：验证 HTTPS

```bash
curl https://api.lcxxingyu.fun/health
# 期望: {"code":200,"message":"success","data":{"status":"ok"}}
```

---

## 第九步：安卓打包

```bash
cd stday
flutter pub get
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.lcxxingyu.fun
```

无需写端口（HTTPS 默认 443）。main 分支 `AppConfig` 会保留 `https://`。

---

## 常见问题

### certbot 失败

- 确认 DNS 已生效、`ping api.lcxxingyu.fun` 指向正确 IP
- 确认安全组已放行 80
- 确认没有其他程序占用 80：`sudo ss -lntp | grep ':80'`

### App 仍连不上

- 手机浏览器打开 `https://api.lcxxingyu.fun/health` 应显示 JSON
- 不要用 `http://` 或 `:8090` 打包 Release

### 证书续期

```bash
sudo certbot renew --dry-run
```

certbot 安装时会自动添加定时任务。
