import 'package:flutter/material.dart';

import '../../core/models/companion_spec.dart';
import '../../core/theme/mood_theme.dart';
import '../../design_system/companion_avatar.dart';
import '../../design_system/slow_progress_bar.dart';

/// 添加/编辑故事保存时：小人表演 + 等待文案 + 进度条。
class MomentGeneratingPanel extends StatefulWidget {
  const MomentGeneratingPanel({
    super.key,
    required this.palette,
    required this.style,
    required this.scene,
    required this.actionType,
    this.spec,
    this.gender,
    required this.line,
    required this.companionKey,
    required this.progressKey,
  });

  final MoodPalette palette;
  final String style;
  final String scene;
  final String actionType;
  final CompanionSpec? spec;
  final String? gender;
  final String line;
  final GlobalKey<CompanionAvatarState> companionKey;
  final GlobalKey<SlowProgressBarState> progressKey;

  @override
  State<MomentGeneratingPanel> createState() => _MomentGeneratingPanelState();
}

class _MomentGeneratingPanelState extends State<MomentGeneratingPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.companionKey.currentState?.playPerformance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CompanionAvatar(
          key: widget.companionKey,
          style: widget.style,
          scene: widget.scene,
          actionType: widget.actionType,
          spec: widget.spec,
          gender: widget.gender,
          size: 120,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: SlowProgressBar(
            key: widget.progressKey,
            palette: widget.palette,
            duration: const Duration(seconds: 14),
          ),
        ),
      ],
    );
  }
}
