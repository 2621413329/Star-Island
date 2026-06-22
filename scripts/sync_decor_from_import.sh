#!/usr/bin/env bash
# 从 decor_import 暂存目录同步到 decor（Cloud Agent / Linux 用）
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/stday/assets/images/decor_import"
DST="$ROOT/stday/assets/images/decor"

REQUIRED=(
  grass_01.png grass_02.png grass_03.png
  flower_01.png flower_02.png flower_03.png
  stone_01.png stone_02.png
  bush_01.png bush_02.png
  tree_small_01.png tree_small_02.png tree_small_03.png
  mushroom_01.png wood_01.png
  butterfly_01.png
  tree_large_01.png
  cloud_01.png cloud_02.png cloud_03.png
  flower_field_01.png
  bird_01.png
  tree_large_02.png
  pond_01.png
  bird_02.png bird_03.png cloud_04.png
  firefly_01.png
  rare_flower_01.png
  rainbow_cloud_01.png
  seagull_group_01.png
  life_tree_01.png
)

if [ ! -d "$SRC" ]; then
  echo "源目录不存在: $SRC"
  echo "请先将 PNG 放入 stday/assets/images/decor_import/"
  exit 1
fi

mkdir -p "$DST"
copied=0
missing=0

for f in "${REQUIRED[@]}"; do
  if [ -f "$SRC/$f" ]; then
    cp -f "$SRC/$f" "$DST/$f"
    echo "[复制] $f"
    copied=$((copied + 1))
  else
    echo "[缺失] $f"
    missing=$((missing + 1))
  fi
done

# 复制其他 png
for f in "$SRC"/*.png; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  cp -f "$f" "$DST/$base"
done

echo ""
echo "完成: $copied / ${#REQUIRED[@]} 项必需装饰"
[ "$missing" -eq 0 ] || exit 1
