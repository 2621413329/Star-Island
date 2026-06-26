import 'package:flutter/material.dart';

import 'growth_system.dart';

/// 等级称号图片资源（`assets/images/titles/`，文件名为拼音）。
class LevelTitleAssets {
  LevelTitleAssets._();

  static const assetDir = 'assets/images/titles';

  /// Lv1–Lv20 称号 → 拼音文件名（不含扩展名，可替换为 png/webp）。
  static const pinyinByLevel = <int, String>{
    1: 'chuxinzhe',
    2: 'tansuozhe',
    3: 'jiluzhe',
    4: 'chengzhangzhe',
    5: 'jianxingzhe',
    6: 'xuexizhe',
    7: 'kaituozhe',
    8: 'jileizhe',
    9: 'jinjiezhe',
    10: 'linghangzhe',
    11: 'sikaozhe',
    12: 'chuangzaozhe',
    13: 'jianchizhe',
    14: 'yingxiangzhe',
    15: 'zhuiguangzhe',
    16: 'yuanxingzhe',
    17: 'zhumengzhe',
    18: 'xingchenshizhe',
    19: 'qundaoshouhuzhe',
    20: 'daoyuchuanshuo',
  };

  static String pinyinForLevel(int level) =>
      pinyinByLevel[level.clamp(1, GrowthSystem.maxLevel)] ?? pinyinByLevel[1]!;

  static String titleForLevel(int level) =>
      GrowthSystem.levelTitle(level.clamp(1, GrowthSystem.maxLevel));

  /// 优先 png，可替换为同目录下同名 webp。
  static String assetPathForLevel(int level) {
    final slug = pinyinForLevel(level);
    return '$assetDir/lv${level.toString().padLeft(2, '0')}_$slug.png';
  }

  static List<String> candidatePathsForLevel(int level) {
    final slug = pinyinForLevel(level);
    final padded = level.toString().padLeft(2, '0');
    return [
      '$assetDir/lv${padded}_$slug.png',
      '$assetDir/lv${padded}_$slug.webp',
      '$assetDir/$slug.png',
      '$assetDir/$slug.webp',
    ];
  }
}

/// 称号徽章图片：支持多候选路径，缺失时显示占位。
class LevelTitleBadgeImage extends StatelessWidget {
  const LevelTitleBadgeImage({
    super.key,
    required this.level,
    this.size = 56,
    this.borderRadius = 12,
    this.fit = BoxFit.contain,
    this.showLevelLabel = false,
  });

  final int level;
  final double size;
  final double borderRadius;
  final BoxFit fit;
  final bool showLevelLabel;

  @override
  Widget build(BuildContext context) {
    final path = LevelTitleAssets.assetPathForLevel(level);
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          path,
          fit: fit,
          errorBuilder: (_, __, ___) => _PlaceholderBadge(
            level: level,
            borderRadius: borderRadius,
            showLevelLabel: showLevelLabel,
          ),
        ),
      ),
    );
  }
}

class _PlaceholderBadge extends StatelessWidget {
  const _PlaceholderBadge({
    required this.level,
    required this.borderRadius,
    required this.showLevelLabel,
  });

  final int level;
  final double borderRadius;
  final bool showLevelLabel;

  @override
  Widget build(BuildContext context) {
    final title = LevelTitleAssets.titleForLevel(level);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFF5EB),
            const Color(0xFFE8D4C4).withValues(alpha: 0.85),
          ],
        ),
        border: Border.all(color: const Color(0xFFE8A87C).withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      child: showLevelLabel
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Lv.$level',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8C7B6B),
                  ),
                ),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5D4E44),
                  ),
                ),
              ],
            )
          : Icon(
              Icons.military_tech_outlined,
              size: 28,
              color: const Color(0xFFE8A87C).withValues(alpha: 0.9),
            ),
    );
  }
}
