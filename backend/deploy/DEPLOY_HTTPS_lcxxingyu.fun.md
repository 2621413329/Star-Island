# lcxxingyu.fun HTTPS 部署指南（暂缓，仅供参考）

> **当前使用 HTTP**，请先按 `DEPLOY_API.md` 部署。  
> 本文件与 `deploy/nginx/conf.d/stday-api.ssl.conf` 中的注释模板供日后切换 HTTPS 时参考。

## 架构（日后启用）

```
安卓 App  ──HTTPS:443──►  Nginx (api.lcxxingyu.fun)
                              │
                              └──HTTP──►  uvicorn 127.0.0.1:8000
```

## 切换步骤摘要

1. DNS：`api.lcxxingyu.fun` → 服务器 IP
2. 安全组放行 `80`、`443`
3. 取消注释 `deploy/nginx/conf.d/stday-api.ssl.conf` 中的配置块
4. `sudo certbot certonly --webroot -w /var/www/certbot -d api.lcxxingyu.fun`
5. `sudo bash deploy/nginx/install-https.sh ssl`
6. `curl https://api.lcxxingyu.fun/health`
7. App：`--dart-define=API_BASE_URL=https://api.lcxxingyu.fun`

## 相关文件

- `deploy/nginx/conf.d/stday-api.ssl.conf` — HTTPS 配置模板（已注释）
- `deploy/nginx/conf.d/stday-api.ssl.bootstrap.conf` — certbot 前 bootstrap（已注释）
- `deploy/nginx/install-https.sh` — HTTPS 安装脚本（保留待用）
