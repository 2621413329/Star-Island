#!/usr/bin/env bash
# 前台启动 API（测试用）；生产环境请使用 systemd
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

HOST="${UVICORN_HOST:-0.0.0.0}"
PORT="${UVICORN_PORT:-8000}"
WORKERS="${UVICORN_WORKERS:-1}"

if [[ ! -f .env ]]; then
  echo "错误: 未找到 .env，请先 cp .env.example .env 并填写" >&2
  exit 1
fi

if [[ ! -d .venv ]]; then
  echo "错误: 未找到 .venv，请先运行 ./deploy/install.sh" >&2
  exit 1
fi

# shellcheck disable=SC1091
source .venv/bin/activate

mkdir -p logs

echo ">> 启动 uvicorn http://${HOST}:${PORT} (workers=${WORKERS})"
exec uvicorn app.main:app \
  --host "$HOST" \
  --port "$PORT" \
  --workers "$WORKERS"
