import 'package:flutter/material.dart';

import '../core/theme/mood_theme.dart';

class WarmBackground extends StatelessWidget {
  const WarmBackground({super.key, required this.palette, required this.child});

  final MoodPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.gradientStart, palette.gradientEnd],
        ),
      ),
      child: child,
    );
  }
}
