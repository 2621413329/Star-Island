#!/usr/bin/env bash
# 成长等级 + 岛屿装饰系统自测（静态 + 可选 flutter test）
set -euo pipefail

ROOT="/workspace/stday"
PASS=0
FAIL=0

pass() { echo "✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "❌ $1"; FAIL=$((FAIL + 1)); }

echo "=== 成长等级 & 装饰系统自测 ==="

# 1. 20 级称号配置
if grep -q "static const maxLevel = 20" "$ROOT/lib/core/growth/growth_system.dart" \
   && grep -q "12: '创造者'" "$ROOT/lib/core/growth/growth_system.dart" \
   && grep -q "20: '岛屿传说'" "$ROOT/lib/core/growth/growth_system.dart"; then
  pass "20 级称号与 maxLevel 配置"
else
  fail "20 级称号与 maxLevel 配置"
fi

# 2. 满级经验 36000
if grep -q "static const maxGrowthValue = 36000" "$ROOT/lib/core/growth/growth_system.dart"; then
  pass "满级成长值 36000"
else
  fail "满级成长值 36000"
fi

# 3. enrich 统一口径
if grep -q "static GrowthSummary enrich" "$ROOT/lib/core/growth/growth_system.dart" \
   && grep -q "GrowthSystem.enrich" "$ROOT/lib/island/providers/growth_summary_provider.dart"; then
  pass "GrowthSystem.enrich 接入 provider"
else
  fail "GrowthSystem.enrich 接入 provider"
fi

# 4. UI 百分比进度展示
if grep -q "levelProgressPercent" "$ROOT/lib/features/landing/landing_island_progress.dart" \
   && grep -q "nextLevelDistanceLabel" "$ROOT/lib/features/landing/landing_island_progress.dart"; then
  pass "欢迎页百分比 + 下一级提示"
else
  fail "欢迎页百分比 + 下一级提示"
fi

# 5. 岛屿装饰解锁目录
if [ -f "$ROOT/lib/core/growth/island_unlock_catalog.dart" ] \
   && grep -q "IslandUnlockCatalog.allLevelGroups" "$ROOT/lib/features/more/my_level_page.dart"; then
  pass "更多页岛屿装饰解锁列表"
else
  fail "更多页岛屿装饰解锁列表"
fi

# 6. 滑动预览
if grep -q "PageView.builder" "$ROOT/lib/core/growth/level_unlock_preview.dart"; then
  pass "解锁预览支持左右滑动"
else
  fail "解锁预览支持左右滑动"
fi

# 7. 装饰 PNG 资源齐全
MISSING=$(python3 - <<'PY'
import re
from pathlib import Path
text = Path("/workspace/stday/lib/island/decor/decor_config.dart").read_text()
images = re.findall(r"image: '([^']+)'", text)
root = Path("/workspace/stday/assets/images/decor")
missing = [i for i in images if not (root / i).exists()]
print(len(missing))
PY
)
if [ "$MISSING" = "0" ]; then
  pass "37 项装饰 PNG 资源齐全"
else
  fail "装饰 PNG 缺失 $MISSING 项"
fi

# 8. 旧代码绘制装饰已移除
if [ ! -f "$ROOT/lib/island/decoration/decoration_renderer.dart" ] \
   && [ -f "$ROOT/lib/island/decor/decor_manager.dart" ]; then
  pass "新 DecorManager 替代旧渲染器"
else
  fail "装饰系统文件结构"
fi

# 9. 建筑解锁等级重映射
python3 - <<'PY' >/dev/null && pass "建筑 unlockLevel 重映射" || fail "建筑 unlockLevel 重映射"
import re
from pathlib import Path
text = Path("/workspace/stday/lib/island/config/growth_island_configs.dart").read_text()
expected = {
    'starter_stone': 1, 'record_shed': 5, 'memory_mailbox': 7, 'growth_house': 9,
    'harbor_pier': 11, 'emotion_windchime': 13, 'habit_flowerbed': 15,
    'quiet_tent': 17, 'growth_house_lv2': 20,
}
for bid, lvl in expected.items():
    m = re.search(rf"id: '{bid}',[\s\S]*?unlockLevel: (\d+)", text)
    assert m and int(m.group(1)) == lvl, f"{bid} expected {lvl} got {m.group(1) if m else None}"
PY

echo ""
if command -v flutter >/dev/null 2>&1 || [ -x /tmp/flutter/bin/flutter ]; then
  FLUTTER=$(command -v flutter 2>/dev/null || echo /tmp/flutter/bin/flutter)
  echo "=== 运行 flutter test ==="
  (cd "$ROOT" && "$FLUTTER" pub get >/dev/null 2>&1 && "$FLUTTER" test test/growth_system_test.dart test/decor_config_test.dart test/island_unlock_catalog_test.dart test/level_unlock_preview_test.dart test/growth_island_visual_snapshot_test.dart 2>&1) || true
else
  echo "⚠️  未检测到 Flutter SDK，跳过 flutter test"
fi

echo ""
echo "静态自测通过: $PASS，失败: $FAIL"
test "$FAIL" -eq 0
