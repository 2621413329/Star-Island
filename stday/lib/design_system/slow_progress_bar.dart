import 'package:flutter/material.dart';

import '../core/theme/mood_theme.dart';

/// 生成等待用慢速进度条（约 12 秒走完，可随 API 提前完成）。
class SlowProgressBar extends StatefulWidget {
  const SlowProgressBar({
    super.key,
    required this.palette,
    this.duration = const Duration(seconds: 12),
    this.onFinished,
  });

  final MoodPalette palette;
  final Duration duration;
  final VoidCallback? onFinished;

  @override
  State<SlowProgressBar> createState() => SlowProgressBarState();
}

class SlowProgressBarState extends State<SlowProgressBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onFinished?.call();
      })
      ..forward();
  }

  void complete() {
    _c.animateTo(1.0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _c.value.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: widget.palette.primaryContainer,
            color: widget.palette.accent,
          ),
        );
      },
    );
  }
}
