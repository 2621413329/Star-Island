#!/usr/bin/env bash
# Static self-check for the 13 UI polish requirements.
set -euo pipefail
ROOT="/workspace/stday/lib"
pass=0
fail=0

check() {
  local name="$1"
  local cond="$2"
  if eval "$cond"; then
    echo "✅ $name"
    pass=$((pass + 1))
  else
    echo "❌ $name"
    fail=$((fail + 1))
  fi
}

echo "=== 13 项 UI 改造静态自测 ==="

check "1. 小岛小人对话框点外关闭" \
  "grep -q '_dismissCompanionSpeech' '$ROOT/features/island/island_home_page.dart' && grep -q 'onTap: _dismissCompanionSpeech' '$ROOT/features/island/island_home_page.dart'"

check "2. 应用说明面向大众" \
  "! grep -q '教师' '$ROOT/features/more/app_about_page.dart' && grep -q '面向所有人' '$ROOT/features/more/app_about_page.dart'"

check "3. 去除应用说明顶部按钮" \
  "! grep -q 'visibility_off_outlined' '$ROOT/features/more/app_about_page.dart' && ! grep -q 'hide_source_outlined' '$ROOT/features/more/app_about_page.dart'"

check "4. 去除测试通知按钮" \
  "! grep -q '测试通知' '$ROOT/features/more/reminder_settings_page.dart' && ! grep -q '_sendTestNotification' '$ROOT/features/more/reminder_settings_page.dart'"

check "5. 记录提醒页眉统一" \
  "grep -q 'MoreSubpageHeader' '$ROOT/features/more/reminder_settings_page.dart' && ! grep -q 'headlineSmall' '$ROOT/features/more/reminder_settings_page.dart'"

check "6. 等级与称号点击弹图" \
  "grep -q 'showLevelUnlockPreviewDialog' '$ROOT/features/more/my_level_page.dart' && grep -q 'onTap:' '$ROOT/features/more/my_level_page.dart'"

check "7. 岛屿装饰解锁同建筑交互" \
  "grep -q 'decorationAssetForLevel' '$ROOT/features/more/my_level_page.dart'"

check "8. 故事详情页眉一致" \
  "grep -q 'MoreSubpageHeader' '$ROOT/features/today/moment_detail_page.dart' && ! grep -q 'SliverAppBar' '$ROOT/features/today/moment_detail_page.dart'"

check "9. 放大小人后侧边改心情" \
  "grep -q 'onMoodEdit' '$ROOT/features/today/moment_detail_page.dart' && ! grep -q 'onFaceTap' '$ROOT/features/today/moment_detail_page.dart'"

check "10. 今日记录小人默认半透明可展开隐藏" \
  "grep -q 'companionAlwaysVisible: false' '$ROOT/features/records/record_page.dart' && grep -q 'showCollapseControl: !widget.companionAlwaysVisible' '$ROOT/features/today/today_story_card.dart' && grep -q 'ghostOpacity' '$ROOT/features/today/story_companion_floater.dart'"

check "11. 编辑故事点遮罩直接关闭" \
  "grep -A3 'void _onScrimTap' '$ROOT/features/today/write_story_page.dart' | grep -q '_closeSheet' && ! grep -A6 'void _onScrimTap' '$ROOT/features/today/write_story_page.dart' | grep -q '_collapsedSheetFactor'"

check "12. 历史记录编辑删除按钮" \
  "grep -q 'onEdit: () => _openEdit' '$ROOT/features/records/record_page.dart' && grep -q 'onDelete: () => _confirmDelete' '$ROOT/features/records/record_page.dart' && ! grep -q '仅今日故事可以修改' '$ROOT/features/records/record_page.dart'"

check "13. 等级区域跳转并滚动" \
  "grep -q 'scrollTo=titles' '$ROOT/features/island/island_home_page.dart' && grep -q 'scrollToSection' '$ROOT/features/more/my_level_page.dart' && grep -q 'onLevelTap' '$ROOT/island/widgets/island_hud_overlay.dart'"

echo ""
echo "通过: $pass / 13，失败: $fail"
test "$fail" -eq 0
