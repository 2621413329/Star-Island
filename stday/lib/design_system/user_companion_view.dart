import 'package:flutter/material.dart';

import '../core/models/user_companion.dart';
import '../core/theme/mood_theme.dart';
import 'companion_avatar.dart';

/// 全应用统一的小人展示入口：基础样貌来自 [UserCompanion]，故事配饰来自 [CompanionStoryContext]。
class UserCompanionView extends StatefulWidget {
  const UserCompanionView({
    super.key,
    required this.companion,
    this.story,
    this.size = 140,
    this.palette,
    this.autoPlayOnMount = false,
    this.showAura = true,
  });

  final UserCompanion companion;
  final CompanionStoryContext? story;
  final double size;
  final MoodPalette? palette;
  final bool autoPlayOnMount;
  final bool showAura;

  @override
  UserCompanionViewState createState() => UserCompanionViewState();
}

class UserCompanionViewState extends State<UserCompanionView> {
  final GlobalKey<CompanionAvatarState> _avatarKey = GlobalKey();

  Future<void> playPerformance() async {
    await _avatarKey.currentState?.playPerformance();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final spec = story?.spec;
    return CompanionAvatar(
      key: _avatarKey,
      style: widget.companion.renderStyle,
      gender: widget.companion.gender,
      scene: story?.scene ?? 'stargaze',
      pose: story?.pose ?? 'breathing',
      actionType: spec?.animationType ?? 'wave',
      expression: spec?.expression ?? 'calm',
      prop: spec?.prop ?? 'none',
      companionTint: spec?.tint,
      spec: spec,
      size: widget.size,
      palette: widget.palette,
      autoPlayOnMount: widget.autoPlayOnMount,
      showAura: widget.showAura,
    );
  }
}
