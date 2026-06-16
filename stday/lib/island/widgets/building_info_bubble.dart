import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_fonts.dart';
import '../../core/theme/mood_theme.dart';
import '../../design_system/companion_speech_bubble.dart';

/// 建筑点击后的获得时间气泡。
class BuildingInfoBubble extends StatelessWidget {
  const BuildingInfoBubble({
    super.key,
    required this.buildingName,
    required this.unlockedAt,
    required this.palette,
    this.unlockLevel,
  });

  final String buildingName;
  final DateTime? unlockedAt;
  final int? unlockLevel;
  final MoodPalette palette;

  static final _dateFormat = DateFormat('yyyy年M月d日');

  String get _subtitle {
    if (unlockedAt != null) {
      return '${_dateFormat.format(unlockedAt!)} 获得';
    }
    if (unlockLevel != null) {
      return '成长 Lv.$unlockLevel 解锁';
    }
    return '继续记录，让小岛长出新建筑';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          buildingName,
          style: appTextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: palette.accent.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 4),
        CompanionSpeechBubble(
          text: _subtitle,
          palette: palette,
          maxWidth: 200,
        ),
      ],
    );
  }
}
