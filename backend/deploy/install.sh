#!/usr/bin/env bash
# 在 Linux 服务器上安装后端 Python 依赖（首次部署或更新依赖后执行）
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo ">> 工作目录: $ROOT"

if [[ ! -f requirements.txt ]]; then
  echo "错误: 未找到 requirements.txt，请在 backend 目录下运行" >&2
  exit 1
fi

if [[ ! -f .env ]]; then
  if [[ -f .env.example ]]; then
    echo ">> 未找到 .env，从 .env.example 复制..."
    cp .env.example .env
    echo ">> 请编辑 .env 后重新运行本脚本，或继续安装依赖后手动配置"
  else
    echo "警告: 未找到 .env，部署前必须创建并填写环境变量" >&2
  fi
fi

if ! command -v python3 &>/dev/null; then
  echo "错误: 未安装 python3" >&2
  exit 1
fi

PY_VER="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
echo ">> Python 版本: $PY_VER"

if ! python3 -c 'import sys; exit(0 if sys.version_info >= (3, 10) else 1)'; then
  echo "错误: 需要 Python 3.10 及以上" >&2
  exit 1
fi

if [[ ! -d .venv ]]; then
  echo ">> 创建虚拟环境 .venv ..."
  python3 -m venv .venv
fi

# shellcheck disable=SC1091
source .venv/bin/activate

echo ">> 安装依赖..."
pip install --upgrade pip
pip install -r requirements.txt

mkdir -p logs

echo ">> 依赖安装完成"
echo ""
echo "下一步:"
echo "  1. 编辑 $ROOT/.env（DATABASE_URL、JWT_SECRET_KEY、QWEN_API_KEY 等）"
echo "  2. source .venv/bin/activate && alembic upgrade head"
echo "  3. ./deploy/start.sh  或配置 systemd（deploy/stday-api.service）"
