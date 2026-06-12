import 'package:flutter/material.dart';

import '../../core/models/user_companion.dart';
import '../../core/theme/mood_theme.dart';
import '../../design_system/slow_progress_bar.dart';
import '../../design_system/user_companion_view.dart';

/// 添加/编辑故事保存时：小人表演 + 等待文案 + 进度条。
class MomentGeneratingPanel extends StatefulWidget {
  const MomentGeneratingPanel({
    super.key,
    required this.palette,
    required this.companion,
    required this.story,
    required this.line,
    required this.companionKey,
    required this.progressKey,
    this.performing = false,
  });

  final MoodPalette palette;
  final UserCompanion companion;
  final CompanionStoryContext story;
  final String line;
  final GlobalKey<UserCompanionViewState> companionKey;
  final GlobalKey<SlowProgressBarState> progressKey;
  final bool performing;

  @override
  State<MomentGeneratingPanel> createState() => _MomentGeneratingPanelState();
}

class _MomentGeneratingPanelState extends State<MomentGeneratingPanel> {
  @override
  void initState() {
    super.initState();
    _playSoon();
  }

  @override
  void didUpdateWidget(covariant MomentGeneratingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.performing && !oldWidget.performing) {
      _playSoon();
    }
  }

  void _playSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.companionKey.currentState?.playPerformance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        UserCompanionView(
          key: widget.companionKey,
          companion: widget.companion,
          story: widget.story,
          size: 300,
          palette: widget.palette,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            widget.line,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: widget.performing
              ? const SizedBox(height: 8)
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SlowProgressBar(
                    key: widget.progressKey,
                    palette: widget.palette,
                    duration: const Duration(seconds: 14),
                  ),
                ),
        ),
      ],
    );
  }
}
