#!/usr/bin/env bash
# 成长小岛 API — Nginx HTTPS 一键安装
#
# 用法（在仓库根目录执行）:
#   sudo bash deploy/nginx/install-https.sh bootstrap   # 阶段1：HTTP 反代 + 申请证书
#   sudo bash deploy/nginx/install-https.sh ssl         # 阶段2：启用 HTTPS 443
#   sudo bash deploy/nginx/install-https.sh status      # 查看监听与 health
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONF_SRC="$REPO_ROOT/deploy/nginx/conf.d"
CONF_DST="/etc/nginx/conf.d"
DOMAIN="api.lcxxingyu.fun"
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"

log() { echo "[install-https] $*"; }
die() { echo "[install-https] 错误: $*" >&2; exit 1; }

require_root() {
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || die "请使用 sudo 运行"
}

disable_legacy_conf() {
  if [[ -f "$CONF_DST/stday-api.conf" ]]; then
    log "禁用旧配置 stday-api.conf → stday-api.conf.bak"
    mv -f "$CONF_DST/stday-api.conf" "$CONF_DST/stday-api.conf.bak"
  fi
}

ensure_limit_req_zones() {
  local nginx_conf="/etc/nginx/nginx.conf"
  if grep -q 'zone=auth_login' "$nginx_conf" 2>/dev/null; then
    return 0
  fi
  log "未检测到 limit_req_zone，正在写入 $nginx_conf ..."
  cp -a "$nginx_conf" "${nginx_conf}.bak.$(date +%Y%m%d%H%M%S)"
  sed -i '/http\s*{/a\
    limit_req_zone $binary_remote_addr zone=auth_login:10m rate=10r/m;\
    limit_req_zone $binary_remote_addr zone=auth_register:10m rate=3r/h;\
    limit_req_status 429;' "$nginx_conf"
}

install_bootstrap() {
  require_root
  disable_legacy_conf
  mkdir -p /var/www/certbot
  cp -f "$CONF_SRC/stday-api.ssl.bootstrap.conf" "$CONF_DST/stday-api.ssl.conf"
  nginx -t
  systemctl reload nginx
  log "bootstrap 已安装。请验证: curl http://$DOMAIN/health"
  log "然后执行: sudo certbot certonly --webroot -w /var/www/certbot -d $DOMAIN"
}

install_ssl() {
  require_root
  disable_legacy_conf
  [[ -f "$CERT_DIR/fullchain.pem" ]] || die "证书不存在: $CERT_DIR/fullchain.pem，请先运行 certbot"
  [[ -f "$CERT_DIR/privkey.pem" ]] || die "证书不存在: $CERT_DIR/privkey.pem，请先运行 certbot"
  ensure_limit_req_zones
  mkdir -p /var/www/certbot
  cp -f "$CONF_SRC/stday-api.ssl.conf" "$CONF_DST/stday-api.ssl.conf"
  nginx -t
  systemctl reload nginx
  log "HTTPS 已启用。请验证: curl https://$DOMAIN/health"
}

show_status() {
  echo "=== 监听端口 ==="
  ss -lntp | grep -E ':80|:443|:8000' || true
  echo
  echo "=== 本机后端 ==="
  curl -fsS "http://127.0.0.1:8000/health" && echo || echo "127.0.0.1:8000 不可达"
  echo
  echo "=== HTTP 域名 ==="
  curl -fsS "http://$DOMAIN/health" && echo || echo "http://$DOMAIN 不可达"
  echo
  echo "=== HTTPS 域名 ==="
  curl -fsS "https://$DOMAIN/health" && echo || echo "https://$DOMAIN 不可达"
}

usage() {
  cat <<EOF
用法: sudo bash deploy/nginx/install-https.sh <bootstrap|ssl|status>

  bootstrap  安装证书申请前的 HTTP 反代（80 → 127.0.0.1:8000）
  ssl        安装完整 HTTPS 配置（需先 certbot 申请证书）
  status     检查端口与 health 接口
EOF
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    bootstrap) install_bootstrap ;;
    ssl) install_ssl ;;
    status) show_status ;;
    *) usage; exit 1 ;;
  esac
}

main "$@"
