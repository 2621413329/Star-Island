# lcxxingyu.fun HTTPS 部署指南

> 完整步骤见 `DEPLOY_API.md`。本文补充域名与运维细节。

## 架构

```
安卓 / Windows / iOS App  ──HTTPS:443──►  Nginx (api.lcxxingyu.fun)
                                              │
                                              └──HTTP──►  uvicorn 127.0.0.1:8000
```

## DNS

| 类型 | 主机记录 | 记录值 |
|------|---------|--------|
| A | `api` | `39.106.134.222`（你的服务器公网 IP） |

验证：`dig +short api.lcxxingyu.fun` 或 `nslookup api.lcxxingyu.fun`

## 安全组 / 防火墙

| 端口 | 策略 |
|------|------|
| 80 | 放行（ACME 验证 + 跳转 HTTPS） |
| 443 | 放行（API 主入口） |
| 8000 | **仅本机**，不对公网开放 |
| 5432 | **仅本机**（PostgreSQL） |
| 6379 | **仅本机**（Redis，若启用限流） |

## 一键命令摘要

```bash
# 1. 后端
cd backend && ./deploy/start.sh --port 8000

# 2. Bootstrap
sudo bash deploy/nginx/install-https.sh bootstrap

# 3. 证书
sudo certbot certonly --webroot -w /var/www/certbot -d api.lcxxingyu.fun

# 4. HTTPS
sudo bash deploy/nginx/install-https.sh ssl

# 5. 验证
curl https://api.lcxxingyu.fun/health
sudo bash deploy/nginx/install-https.sh status
```

## 后端 .env 必改项

```env
DEBUG=false
JWT_SECRET_KEY=<至少32字符随机串>
PUBLIC_API_BASE_URL=https://api.lcxxingyu.fun
DATABASE_URL=postgresql+asyncpg://...
```

## App 打包

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.lcxxingyu.fun
```

## 常见问题

**Q: curl https 报证书错误**  
A: 检查 certbot 是否成功、`stday-api.ssl.conf` 中证书路径是否与 `/etc/letsencrypt/live/api.lcxxingyu.fun/` 一致。

**Q: HTTPS 502**  
A: 后端未启动或 8000 不可达：`curl http://127.0.0.1:8000/health`

**Q: 语音转写失败**  
A: 确认 `PUBLIC_API_BASE_URL=https://api.lcxxingyu.fun`，`USER_MEDIA_ROOT` 指向持久化目录，且 `/media/users/...` 可通过 HTTPS 访问。可先执行 `curl https://api.lcxxingyu.fun/health/media` 检查媒体目录。

**Q: 证书续期**  
A: `sudo certbot renew` 后 `sudo systemctl reload nginx`

## 相关文件

- `deploy/nginx/conf.d/stday-api.ssl.conf` — HTTPS 生产配置
- `deploy/nginx/conf.d/stday-api.ssl.bootstrap.conf` — certbot 前 bootstrap
- `deploy/nginx/install-https.sh` — 安装脚本
- `stday/lib/core/config/app_config.dart` — 客户端默认 HTTPS
