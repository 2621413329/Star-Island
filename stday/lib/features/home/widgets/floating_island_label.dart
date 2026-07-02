import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';

/// 岛屿上方纯文字标签（小字号，无木牌装饰）。
class FloatingIslandLabel extends StatelessWidget {
  const FloatingIslandLabel({
    super.key,
    required this.name,
    required this.level,
    this.highlighted = false,
    this.depth = 0,
  });

  final String name;
  final int level;
  final bool highlighted;
  final double depth;

  @override
  Widget build(BuildContext context) {
    final alpha = (0.94 - depth * 0.22).clamp(0.62, 0.94);
    final levelText = level > 0 ? 'Lv.$level' : '待开启';
    final label = '$name · $levelText';

    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: appTextStyle(
        fontSize: 9,
        fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
        color: Colors.white.withValues(alpha: alpha),
      ).copyWith(
        shadows: const [
          Shadow(
            color: Color(0xAA000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
