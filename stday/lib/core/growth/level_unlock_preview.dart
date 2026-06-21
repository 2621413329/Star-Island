import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../island/config/growth_island_configs.dart';
import '../theme/app_fonts.dart';

/// 等级 / 装饰解锁预览图资源。
class LevelUnlockPreviewAssets {
  LevelUnlockPreviewAssets._();

  /// 「我的等级 → 岛屿装饰解锁」Lv.1–10 预览图（与 [GrowthSystem.unlockLabels] 对应）。
  /// 可直接替换 `stday/assets/images/` 下同名 PNG 文件。
  static const unlockLabelPreviewAssets = <int, String>{
    1: 'assets/images/decor/grass.png',
    2: 'assets/images/decor/footprint_grass.png',
    3: 'assets/images/decor/guardian_tree.png',
    4: 'assets/images/decor/small_stone.png',
    5: 'assets/images/buildings/growth_house.png',
    6: 'assets/images/buildings/emotion_windchime.png',
    7: 'assets/images/buildings/lighthouse.png',
    8: 'assets/images/buildings/habit_flowerbed.png',
    9: 'assets/images/buildings/quiet_tent.png',
    10: 'assets/images/buildings/growth_house_lv2.png',
  };

  static String? buildingAssetForLevel(int level) {
    final exact = GrowthIslandConfigs.buildings
        .where((b) => b.unlockLevel == level)
        .map((b) => b.sprite)
        .firstOrNull;
    if (exact != null) return 'assets/images/$exact';

    final fallback = GrowthIslandConfigs.buildings
        .where((b) => b.unlockLevel <= level)
        .toList()
      ..sort((a, b) => a.unlockLevel.compareTo(b.unlockLevel));
    final picked = fallback.isEmpty ? null : fallback.last;
    return picked == null ? null : 'assets/images/${picked.sprite}';
  }

  static String? decorationAssetForLevel(int level) {
    final mapped = unlockLabelPreviewAssets[level];
    if (mapped != null) return mapped;

    final exact = GrowthIslandConfigs.decorations
        .where((d) => d.unlockLevel == level)
        .map((d) => d.asset)
        .firstOrNull;
    if (exact != null) return 'assets/images/$exact';
    return buildingAssetForLevel(level);
  }
}

Future<void> showLevelUnlockPreviewDialog(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String? assetPath,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    pageBuilder: (ctx, _, __) {
      return Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(ctx).pop(),
            child: const SizedBox.expand(),
          ),
          GestureDetector(
            onTap: () {},
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 36),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF8F3),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: appTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D3229),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: appTextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: const Color(0xFF8C7B6B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (assetPath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          assetPath,
                          height: 168,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            height: 168,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.landscape_outlined,
                              size: 56,
                              color: const Color(0xFF8C7B6B).withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 168,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.landscape_outlined,
                          size: 56,
                          color: const Color(0xFF8C7B6B).withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
