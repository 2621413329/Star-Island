import 'package:flutter/material.dart';

import '../../../design_system/home_theme.dart';

/// 世界地图中的分岛建筑精灵（最高等级建筑或分类默认岛体）。
class IslandSlotIcon extends StatelessWidget {
  const IslandSlotIcon({
    super.key,
    required this.assetPath,
    required this.hasBuilding,
    this.size = 72,
    this.onTap,
  });

  final String assetPath;
  final bool hasBuilding;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size * 0.92,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // 岛体柔光边缘
            Positioned(
              bottom: size * 0.08,
              child: Container(
                width: size * 0.88,
                height: size * 0.72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size * 0.35),
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: size * 0.04),
              child: Image.asset(
                assetPath,
                width: size * 0.88,
                height: size * 0.88,
                fit: BoxFit.contain,
              ),
            ),
            if (hasBuilding)
              Positioned(
                top: 0,
                right: size * 0.04,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: HomeTheme.primary.withValues(alpha: 0.55),
                    boxShadow: [
                      BoxShadow(
                        color: HomeTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
