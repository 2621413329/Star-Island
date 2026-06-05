import 'package:flutter/material.dart';

import '../../../core/theme/mood_theme.dart';
import '../../../data/models/mood_check_in_models.dart';
import '../../../design_system/island_chip.dart';

/// 置顶：整理今日心情（紧凑条，弱化上传感）。
class TodayMoodRecapBar extends StatelessWidget {
  const TodayMoodRecapBar({
    super.key,
    required this.palette,
    required this.checkIn,
    required this.loading,
    required this.onPressed,
    this.loadingMoodId,
  });

  final MoodPalette palette;
  final MoodReportCheckIn checkIn;
  final bool loading;
  final VoidCallback? onPressed;
  final String? loadingMoodId;

  @override
  Widget build(BuildContext context) {
    final action = TodayMoodRecapAction.resolve(checkIn);
    final active = action.enabled && !loading && onPressed != null;

    return IslandCompactAction(
      label: action.label,
      palette: palette,
      loading: loading,
      loadingMoodId: loadingMoodId,
      enabled: active,
      highlight: action.highlight && active,
      onPressed: active ? onPressed : null,
    );
  }
}
