#!/usr/bin/env bash
# 成长小岛 — Linux 后端启动脚本（前台运行，适合测试；生产请用 systemd）
#
# 用法:
#   ./deploy/start.sh                 # 默认 0.0.0.0:8000，单 worker
#   ./deploy/start.sh --reload        # 开发热重载（强制 workers=1）
#   ./deploy/start.sh --migrate       # 启动前执行 alembic upgrade head
#   ./deploy/start.sh --port 9000     # 指定端口
#   UVICORN_PORT=9000 ./deploy/start.sh
#
# 环境变量（可在 .env 或 shell 中设置）:
#   UVICORN_HOST      默认 0.0.0.0（必须监听所有网卡，客户端才能连入）
#   UVICORN_PORT      默认 8000（本机开发常用 9000）
#   UVICORN_WORKERS   默认 1；生产建议 2+
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

HOST=""
PORT=""
WORKERS=""
RELOAD=false
RUN_MIGRATE=false
STOP_EXISTING=true

usage() {
  cat <<'EOF'
用法: ./deploy/start.sh [选项]

选项:
  --host HOST       监听地址（默认 0.0.0.0）
  --port PORT       监听端口（默认读取 UVICORN_PORT，否则 8000）
  --workers N       worker 数量（默认 1；与 --reload 互斥）
  --reload          开启热重载（仅单 worker）
  --migrate         启动前执行 alembic upgrade head
  --no-stop         不释放端口上已有进程
  -h, --help        显示帮助

示例:
  ./deploy/start.sh --migrate
  UVICORN_PORT=9000 ./deploy/start.sh --reload
EOF
}

log() { printf '>> %s\n' "$*"; }
die() { printf '错误: %s\n' "$*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="${2:-}"; shift 2 ;;
    --port) PORT="${2:-}"; shift 2 ;;
    --workers) WORKERS="${2:-}"; shift 2 ;;
    --reload) RELOAD=true; shift ;;
    --migrate) RUN_MIGRATE=true; shift ;;
    --no-stop) STOP_EXISTING=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "未知参数: $1（使用 --help 查看用法）" ;;
  esac
done

load_runtime_env() {
  if [[ ! -f .env ]]; then
    die "未找到 .env，请先 cp .env.example .env 并填写 DATABASE_URL 等配置"
  fi

  # 仅导入启动相关变量，避免污染 shell
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -d '\r')"
    [[ -z "$line" ]] && continue
    case "$line" in
      UVICORN_HOST=*|UVICORN_PORT=*|UVICORN_WORKERS=*|DATABASE_URL=*)
        export "$line"
        ;;
    esac
  done < .env
}

stop_port() {
  local port="$1"
  local pid=""

  if command -v fuser >/dev/null 2>&1; then
    fuser -k "${port}/tcp" >/dev/null 2>&1 || true
    sleep 1
    return
  fi

  if command -v ss >/dev/null 2>&1; then
    pid="$(ss -lptn "sport = :${port}" 2>/dev/null | sed -n 's/.*pid=\([0-9]\+\).*/\1/p' | head -n1 || true)"
  elif command -v lsof >/dev/null 2>&1; then
    pid="$(lsof -tiTCP:"${port}" -sTCP:LISTEN 2>/dev/null | head -n1 || true)"
  fi

  if [[ -n "$pid" ]]; then
    log "释放端口 ${port} 上的进程 PID ${pid} ..."
    kill "$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null || true
    sleep 1
  fi
}

ensure_prerequisites() {
  [[ -f requirements.txt ]] || die "未找到 requirements.txt，请在 backend 目录运行"
  [[ -f .venv/bin/activate ]] || die "未找到 .venv，请先运行 ./deploy/install.sh"

  # shellcheck disable=SC1091
  source .venv/bin/activate

  if [[ -z "${DATABASE_URL:-}" ]]; then
    die ".env 中缺少 DATABASE_URL"
  fi

  mkdir -p logs
}

resolve_listen_config() {
  HOST="${HOST:-${UVICORN_HOST:-0.0.0.0}}"
  PORT="${PORT:-${UVICORN_PORT:-8000}}"
  WORKERS="${WORKERS:-${UVICORN_WORKERS:-1}}"

  if [[ "$RELOAD" == true ]]; then
    WORKERS=1
  fi

  if [[ "$HOST" == "127.0.0.1" || "$HOST" == "localhost" ]]; then
    log "警告: HOST=${HOST} 仅本机可访问；远程客户端需使用 0.0.0.0"
  fi

  if [[ "$RELOAD" == true && "$WORKERS" != "1" ]]; then
    die "--reload 与 workers>1 不能同时使用"
  fi
}

run_migrations() {
  log "执行数据库迁移: alembic upgrade head"
  alembic upgrade head
}

print_banner() {
  log "工作目录: $ROOT"
  log "API 地址:   http://${HOST}:${PORT}"
  log "健康检查:   http://127.0.0.1:${PORT}/health"
  log "workers=${WORKERS} reload=${RELOAD}"
}

main() {
  load_runtime_env
  ensure_prerequisites
  resolve_listen_config

  if [[ "$STOP_EXISTING" == true ]]; then
    log "检查端口 ${PORT} ..."
    stop_port "$PORT"
  fi

  if [[ "$RUN_MIGRATE" == true ]]; then
    run_migrations
  fi

  print_banner

  UVICORN_ARGS=(
    app.main:app
    --host "$HOST"
    --port "$PORT"
  )

  if [[ "$RELOAD" == true ]]; then
    UVICORN_ARGS+=(--reload)
  else
    UVICORN_ARGS+=(--workers "$WORKERS")
  fi

  log "启动 uvicorn ..."
  exec uvicorn "${UVICORN_ARGS[@]}"
}

main
