import 'package:flutter/material.dart';

import '../core/models/companion_spec.dart';
import '../core/models/user_companion.dart';
import '../core/theme/mood_theme.dart';
import 'island_decorations.dart';
import 'user_companion_view.dart';

/// 按当前心情映射小人的表情与加载时的循环动作。
class CompanionLoadingMotion {
  const CompanionLoadingMotion({
    required this.expression,
    required this.actionType,
    this.pose = 'float',
    this.scene = 'stargaze',
    this.hint,
  });

  final String expression;
  final String actionType;
  final String pose;
  final String scene;
  final String? hint;

  static CompanionLoadingMotion forMood(String? moodId) {
    return switch (moodId) {
      'happy' => const CompanionLoadingMotion(
          expression: 'happy',
          actionType: 'celebrate',
          hint: '今天心情不错，小星在轻轻跳舞',
        ),
      'sad' => const CompanionLoadingMotion(
          expression: 'sad',
          actionType: 'comfort',
          pose: 'breathing',
          hint: '小星在慢慢呼吸，陪你等一会儿',
        ),
      'angry' => const CompanionLoadingMotion(
          expression: 'angry',
          actionType: 'shake',
          pose: 'breathing',
          hint: '小星在平复情绪',
        ),
      'thinking' => const CompanionLoadingMotion(
          expression: 'thinking',
          actionType: 'think',
          hint: '小星在想事情',
        ),
      _ => const CompanionLoadingMotion(
          expression: 'calm',
          actionType: 'wave',
          hint: '小星正在赶来',
        ),
    };
  }

  /// 用户资料里的 companion_style → 绘制样式（默认透明精神体）。
  static String renderStyle(String? profileStyle) {
    return UserCompanion(profileStyle: profileStyle ?? 'chibi').renderStyle;
  }

  CompanionStoryContext storyFor(MoodPalette palette, String? moodId) {
    return CompanionStoryContext(
      spec: CompanionSpec(
        expression: expression,
        prop: 'none',
        animationType: actionType,
        tint: palette.accent,
      ),
      scene: scene,
      pose: pose,
    );
  }
}

/// 全页加载：透明小人 + 心情色光晕 + 循环表演。
class CompanionLoadingView extends StatefulWidget {
  const CompanionLoadingView({
    super.key,
    required this.palette,
    required this.companion,
    this.moodId,
    this.message,
    this.size = 128,
  });

  final MoodPalette palette;
  final UserCompanion companion;
  final String? moodId;
  final String? message;
  final double size;

  @override
  State<CompanionLoadingView> createState() => _CompanionLoadingViewState();
}

class _CompanionLoadingViewState extends State<CompanionLoadingView> {
  final GlobalKey<UserCompanionViewState> _avatarKey = GlobalKey();
  bool _loopActive = true;

  CompanionLoadingMotion get _motion =>
      CompanionLoadingMotion.forMood(widget.moodId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPerformanceLoop());
  }

  @override
  void dispose() {
    _loopActive = false;
    super.dispose();
  }

  Future<void> _runPerformanceLoop() async {
    while (_loopActive && mounted) {
      await _avatarKey.currentState?.playPerformance();
      if (!_loopActive || !mounted) break;
      await Future<void>.delayed(const Duration(milliseconds: 520));
    }
  }

  @override
  Widget build(BuildContext context) {
    final motion = _motion;
    final line = widget.message ?? motion.hint ?? '加载中…';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size * 1.2,
          height: widget.size * 1.35,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size * 0.95,
                height: widget.size * 0.95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.palette.glow.withValues(alpha: 0.55),
                      blurRadius: 36,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
              UserCompanionView(
                key: _avatarKey,
                companion: widget.companion,
                story: motion.storyFor(widget.palette, widget.moodId),
                size: widget.size,
                palette: widget.palette,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            line,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: widget.palette.accent.withValues(alpha: 0.85),
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

/// 带岛屿背景的整页加载容器。
class CompanionLoadingScaffold extends StatelessWidget {
  const CompanionLoadingScaffold({
    super.key,
    required this.palette,
    required this.companion,
    this.moodId,
    this.message,
  });

  final MoodPalette palette;
  final UserCompanion companion;
  final String? moodId;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Center(
            child: CompanionLoadingView(
              palette: palette,
              companion: companion,
              moodId: moodId,
              message: message,
            ),
          ),
        ),
      ),
    );
  }
}

/// 按钮内嵌的小型小人加载（替代 CircularProgressIndicator）。
class CompanionLoadingIndicator extends StatefulWidget {
  const CompanionLoadingIndicator({
    super.key,
    required this.palette,
    this.companion = const UserCompanion(),
    this.moodId,
    this.size = 22,
    this.lightForeground = false,
  });

  final MoodPalette palette;
  final UserCompanion companion;
  final String? moodId;
  final double size;
  final bool lightForeground;

  @override
  State<CompanionLoadingIndicator> createState() =>
      _CompanionLoadingIndicatorState();
}

class _CompanionLoadingIndicatorState extends State<CompanionLoadingIndicator> {
  final GlobalKey<UserCompanionViewState> _key = GlobalKey();
  bool _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loop());
  }

  @override
  void dispose() {
    _active = false;
    super.dispose();
  }

  Future<void> _loop() async {
    while (_active && mounted) {
      await _key.currentState?.playPerformance();
      if (!_active || !mounted) break;
      await Future<void>.delayed(const Duration(milliseconds: 380));
    }
  }

  @override
  Widget build(BuildContext context) {
    final motion = CompanionLoadingMotion.forMood(widget.moodId);
    final tint = widget.lightForeground ? Colors.white : widget.palette.accent;
    return SizedBox(
      width: widget.size * 1.1,
      height: widget.size * 1.2,
      child: UserCompanionView(
        key: _key,
        companion: widget.companion,
        story: CompanionStoryContext(
          spec: CompanionSpec(
            expression: motion.expression,
            prop: 'none',
            animationType: motion.actionType,
            tint: tint,
          ),
          scene: motion.scene,
          pose: motion.pose,
        ),
        size: widget.size,
        palette: widget.palette,
      ),
    );
  }
}

