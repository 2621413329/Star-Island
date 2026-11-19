import 'package:flutter/material.dart';

import '../../core/theme/app_fonts.dart';
import '../../core/theme/mood_theme.dart';
import '../../design_system/companion_speech_bubble.dart';

/// 建筑点击后只展示中文名称。
class BuildingInfoBubble extends StatelessWidget {
  const BuildingInfoBubble({
    super.key,
    required this.buildingName,
    required this.palette,
  });

  final String buildingName;
  final MoodPalette palette;

  @override
  Widget build(BuildContext context) {
    return CompanionSpeechBubble(
      showTail: false,
      palette: palette,
      maxWidth: 168,
      child: Text(
        buildingName,
        textAlign: TextAlign.center,
        style: appTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: palette.accent,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
