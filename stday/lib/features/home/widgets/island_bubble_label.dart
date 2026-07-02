import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../design_system/home_theme.dart';

class IslandBubbleLabel extends StatelessWidget {
  const IslandBubbleLabel({
    super.key,
    required this.name,
    required this.level,
    this.highlighted = false,
    this.placeholder = false,
    this.onTap,
  });

  final String name;
  final int level;
  final bool highlighted;
  final bool placeholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final levelText = level > 0 ? 'Lv.$level' : '待开启';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: HomeTheme.card.withValues(
              alpha: placeholder ? 0.72 : 0.92,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlighted
                  ? HomeTheme.primary.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.85),
              width: highlighted ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: appTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: HomeTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                levelText,
                style: appTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: HomeTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
