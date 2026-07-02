import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../design_system/home_theme.dart';

class TodayStoryItem extends StatelessWidget {
  const TodayStoryItem({
    super.key,
    required this.title,
    required this.islandLabel,
    required this.growthLabel,
    required this.timeLabel,
    required this.onTap,
    required this.islandIcon,
    required this.islandIconColor,
    this.palette,
  });

  final String title;
  final String islandLabel;
  final String growthLabel;
  final String timeLabel;
  final VoidCallback onTap;
  final IconData islandIcon;
  final Color islandIconColor;
  final MoodPalette? palette;

  @override
  Widget build(BuildContext context) {
    final accent = palette?.accent ?? HomeTheme.primary;

    return Material(
      color: HomeTheme.card,
      borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
            boxShadow: const [HomeTheme.cardShadow],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        islandIconColor.withValues(alpha: 0.28),
                        islandIconColor.withValues(alpha: 0.10),
                      ],
                    ),
                  ),
                  child: Icon(
                    islandIcon,
                    color: islandIconColor.withValues(alpha: 0.92),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: appTextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: HomeTheme.textPrimary,
                          height: 1.32,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            islandIcon,
                            size: 13,
                            color: islandIconColor.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              islandLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: appTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: HomeTheme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            growthLabel,
                            style: appTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  timeLabel,
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
      ),
    );
  }
}
