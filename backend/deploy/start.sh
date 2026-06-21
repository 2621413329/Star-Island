#!/usr/bin/env bash
# 成长小岛 — Linux 后端启动脚本（常驻运行+自动重启；生产建议用 systemd，此脚本适合测试/轻量场景）
#
# 用法:
#   ./deploy/start.sh                 # 默认 0.0.0.0:8000，单 worker，常驻重启
#   ./deploy/start.sh --reload        # 开发热重载（强制 workers=1，仍常驻）
#   ./deploy/start.sh --migrate       # 启动前执行 alembic upgrade head
#   ./deploy/start.sh --port 9000     # 指定端口
#   UVICORN_PORT=9000 ./deploy/start.sh
#
# 环境变量（可在 .env 或 shell 中设置）:
#   UVICORN_HOST      默认 0.0.0.0（必须监听所有网卡，客户端才能连入）
#   UVICORN_PORT      默认 8000（本机开发常用 9000）
#   UVICORN_WORKERS   默认 1；生产建议 2+
#   RESTART_DELAY     重启延迟（秒），默认 3
#   MAX_RESTARTS      最大重启次数（0=无限），默认 0
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# 新增：重启相关配置
RESTART_DELAY="${RESTART_DELAY:-3}"
MAX_RESTARTS="${MAX_RESTARTS:-0}"
restart_count=0
uvicorn_pid=0

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

环境变量扩展:
  RESTART_DELAY     服务崩溃后重启延迟（秒），默认 3
  MAX_RESTARTS      最大重启次数（0=无限重启），默认 0

示例:
  ./deploy/start.sh --migrate
  RESTART_DELAY=5 MAX_RESTARTS=10 ./deploy/start.sh --reload
  UVICORN_PORT=9000 ./deploy/start.sh
EOF
}

log() { printf '>> [%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"; }
die() { printf '错误: [%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*" >&2; exit 1; }

# 新增：捕获退出信号，优雅停止子进程
cleanup() {
  if [[ $uvicorn_pid -ne 0 ]]; then
    log "捕获停止信号，正在终止 uvicorn 进程（PID: $uvicorn_pid）..."
    kill "$uvicorn_pid" 2>/dev/null || kill -9 "$uvicorn_pid" 2>/dev/null
    uvicorn_pid=0
  fi
  log "服务已停止"
  exit 0
}

# 注册信号捕获（SIGINT=Ctrl+C、SIGTERM=kill 命令）
trap cleanup SIGINT SIGTERM

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
  log "重启策略: 延迟 ${RESTART_DELAY} 秒，最大重启次数 ${MAX_RESTARTS}（0=无限）"
}

# 新增：启动并监控 uvicorn 进程
start_and_monitor() {
  local uvicorn_args=(
    app.main:app
    --host "$HOST"
    --port "$PORT"
  )

  if [[ "$RELOAD" == true ]]; then
    uvicorn_args+=(--reload)
  else
    uvicorn_args+=(--workers "$WORKERS")
  fi

  # 后台启动 uvicorn，记录 PID
  log "启动 uvicorn ... (PID 将记录为子进程)"
  uvicorn "${uvicorn_args[@]}" > logs/uvicorn.log 2>&1 &
  uvicorn_pid=$!

  # 等待子进程退出，并获取退出码
  wait "$uvicorn_pid"
  local exit_code=$?
  uvicorn_pid=0

  log "uvicorn 进程退出，退出码: $exit_code"
  return $exit_code
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

  # 核心：重启循环
  while true; do
    # 检查最大重启次数（0=无限）
    if [[ $MAX_RESTARTS -gt 0 && $restart_count -ge $MAX_RESTARTS ]]; then
      log "已达到最大重启次数（$MAX_RESTARTS），停止重启"
      exit 1
    fi

    # 启动并监控进程
    start_and_monitor
    local exit_code=$?

    # 若捕获到停止信号（cleanup），直接退出循环
    if [[ $exit_code -eq 0 ]]; then
      break
    fi

    # 累加重启次数，延迟后重启
    restart_count=$((restart_count + 1))
    log "准备重启服务（第 ${restart_count} 次），延迟 ${RESTART_DELAY} 秒..."
    sleep "$RESTART_DELAY"
  done
}

main
