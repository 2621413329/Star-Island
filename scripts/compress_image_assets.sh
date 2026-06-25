#!/usr/bin/env bash
# 批量压缩 stday/assets/images 下的 PNG，减小 APK/IPA 体积。
#
# 依赖：optipng、pngquant（Ubuntu: sudo apt install optipng pngquant）
#
# 用法：
#   ./scripts/compress_image_assets.sh              # 无损 + 对大图有损压缩（默认）
#   ./scripts/compress_image_assets.sh --lossless   # 仅 optipng，画质零损失
#   ./scripts/compress_image_assets.sh --dry-run    # 只统计，不写回文件
#   ./scripts/compress_image_assets.sh --min-kb 300 # 仅压缩大于 300KB 的 PNG（有损阶段）

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSET_DIR="$ROOT/stday/assets/images"
MODE="balanced"
DRY_RUN=0
MIN_KB=500
PNGQUANT_QUALITY="65-90"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lossless) MODE="lossless" ;;
    --aggressive) MODE="aggressive"; PNGQUANT_QUALITY="50-85"; MIN_KB=200 ;;
    --dry-run) DRY_RUN=1 ;;
    --min-kb) MIN_KB="${2:?}"; shift ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
  shift
done

for cmd in optipng pngquant; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "缺少依赖: $cmd（例如 apt install optipng pngquant）" >&2
    exit 1
  fi
done

if [[ ! -d "$ASSET_DIR" ]]; then
  echo "资源目录不存在: $ASSET_DIR" >&2
  exit 1
fi

before=0
after=0
count=0
quant_count=0

while IFS= read -r -d '' file; do
  size=$(stat -c%s "$file")
  before=$((before + size))
  count=$((count + 1))

  if [[ "$DRY_RUN" -eq 1 ]]; then
    after=$((after + size))
    continue
  fi

  tmp="$(mktemp "${file}.XXXXXX")"
  cp "$file" "$tmp"

  if [[ "$MODE" != "lossless" && "$size" -ge $((MIN_KB * 1024)) ]]; then
    if pngquant --quality="$PNGQUANT_QUALITY" --skip-if-larger --force \
      --output "$tmp" "$tmp" 2>/dev/null; then
      quant_count=$((quant_count + 1))
    fi
  fi

  optipng -quiet -o2 "$tmp"
  new_size=$(stat -c%s "$tmp")
  if [[ "$new_size" -lt "$size" ]]; then
    mv "$tmp" "$file"
    after=$((after + new_size))
  else
    rm -f "$tmp"
    after=$((after + size))
  fi
done < <(find "$ASSET_DIR" -type f -name '*.png' -print0)

saved=$((before - after))
pct=0
if [[ "$before" -gt 0 ]]; then
  pct=$((saved * 100 / before))
fi

echo "模式: $MODE (dry_run=$DRY_RUN)"
echo "处理 PNG: $count 个"
if [[ "$MODE" != "lossless" ]]; then
  echo "有损压缩 (>=${MIN_KB}KB, quality=$PNGQUANT_QUALITY): $quant_count 个"
fi
echo "压缩前: $(awk -v b="$before" 'BEGIN{printf "%.1f MB", b/1024/1024}')"
echo "压缩后: $(awk -v a="$after" 'BEGIN{printf "%.1f MB", a/1024/1024}')"
echo "节省:   $(python3 -c "print(f'{$saved/1024/1024:.1f} MB ($pct%)')")"
