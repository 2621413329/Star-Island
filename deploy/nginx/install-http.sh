#!/usr/bin/env bash
# 成长小岛 API — HTTP 反代一键安装（当前使用）
#
# 用法（仓库根目录）:
#   sudo bash deploy/nginx/install-http.sh
#   sudo bash deploy/nginx/install-http.sh status
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONF_SRC="$REPO_ROOT/deploy/nginx/conf.d"
CONF_DST="/etc/nginx/conf.d"

log() { echo "[install-http] $*"; }
die() { echo "[install-http] 错误: $*" >&2; exit 1; }

require_root() {
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || die "请使用 sudo 运行"
}

ensure_limit_req_zones() {
  local nginx_conf="/etc/nginx/nginx.conf"
  if grep -q 'zone=auth_login' "$nginx_conf" 2>/dev/null; then
    return 0
  fi
  log "写入 limit_req_zone 到 $nginx_conf ..."
  cp -a "$nginx_conf" "${nginx_conf}.bak.$(date +%Y%m%d%H%M%S)"
  sed -i '/http\s*{/a\
    limit_req_zone $binary_remote_addr zone=auth_login:10m rate=10r/m;\
    limit_req_zone $binary_remote_addr zone=auth_register:10m rate=3r/h;\
    limit_req_status 429;' "$nginx_conf"
}

disable_active_ssl_conf() {
  local ssl_conf="$CONF_DST/stday-api.ssl.conf"
  if [[ -f "$ssl_conf" ]] && grep -qE '^[^#[:space:]]' "$ssl_conf"; then
    log "备份含生效指令的 ssl 配置 → stday-api.ssl.conf.bak"
    mv -f "$ssl_conf" "${ssl_conf}.bak.$(date +%Y%m%d%H%M%S)"
  fi
}

install_http() {
  require_root
  disable_active_ssl_conf
  ensure_limit_req_zones
  cp -f "$CONF_SRC/stday-api.conf" "$CONF_DST/stday-api.conf"
  nginx -t
  systemctl reload nginx
  log "HTTP 反代已安装"
  log "验证: curl http://api.lcxxingyu.fun/health"
  log "验证: curl http://39.106.134.222/health"
}

show_status() {
  echo "=== 监听端口 ==="
  ss -lntp | grep -E ':80|:443|:8000' || true
  echo
  echo "=== 本机后端 ==="
  curl -fsS "http://127.0.0.1:8000/health" && echo || echo "127.0.0.1:8000 不可达"
  echo
  echo "=== HTTP 域名 ==="
  curl -fsS "http://api.lcxxingyu.fun/health" && echo || echo "http://api.lcxxingyu.fun 不可达"
  echo
  echo "=== HTTP IP ==="
  curl -fsS "http://39.106.134.222/health" && echo || echo "http://39.106.134.222 不可达"
}

main() {
  case "${1:-install}" in
    install|"") install_http ;;
    status) show_status ;;
    *) die "用法: sudo bash deploy/nginx/install-http.sh [install|status]" ;;
  esac
}

main "$@"
