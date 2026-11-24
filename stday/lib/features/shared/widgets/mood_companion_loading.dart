import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/companion_loading.dart';

/// 分析日常时，主文案下方轮播的小字。
const storyUnderstandingHints = <String>[
  '收集碎片，读懂独一无二的你🍀',
  '沉淀细节，拒绝仓促的回应',
  '拾取日常信号，靠近真实的你',
  '梳理点滴，酝酿贴合你的答案',
  '收纳细碎情绪，读懂你的节奏',
  '拼凑时光，看见日常里的温柔',
  '品读生活，让回应足够走心',
  '捕捉烟火线索，走进你的世界',
  '慢慢沉淀，读懂你的生活肌理',
  '收集微光，准备有温度的感知',
  '收纳日常，打磨专属你的理解',
  '梳理痕迹，不错过你的偏好',
  '静待融合，送上懂你的陪伴',
  '捡拾时光片段，读懂你的心绪',
  '不急于完成，好好读懂你的每一面',
  '串联平凡碎片，读懂心底期许',
  '沉淀线索，让内容更加契合你',
  '珍藏日常印记，酝酿温柔回应',
  '拆解点滴，跟上属于你的步调',
  '汇聚细碎日常，给你恰到好处的懂得',
];
import '../../../design_system/island_decorations.dart';
import '../../../providers/app_providers.dart';

/// 主 Tab 内嵌加载（勿再包 Scaffold，避免与 Shell 双层 Scaffold 导致空白）。
class MoodCompanionLoadingBody extends ConsumerWidget {
  const MoodCompanionLoadingBody({super.key, this.message, this.hints = const []});

  final String? message;
  final List<String> hints;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(moodPaletteProvider);
    final companion = ref.watch(userCompanionProvider);
    return IslandScaffold(
      palette: palette,
      child: SafeArea(
        child: Center(
          child: CompanionLoadingView(
            palette: palette,
            companion: companion,
            moodId: ref.watch(profileProvider).valueOrNull?.todayMood,
            message: message,
            hints: hints,
          ),
        ),
      ),
    );
  }
}

/// 独立路由全屏加载（含 Scaffold）。
class MoodCompanionLoadingScaffold extends ConsumerWidget {
  const MoodCompanionLoadingScaffold({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: MoodCompanionLoadingBody(message: message),
    );
  }
}

/// Riverpod 上下文下的按钮加载指示器。
class MoodCompanionLoadingIndicator extends ConsumerWidget {
  const MoodCompanionLoadingIndicator({
    super.key,
    this.size = 22,
    this.lightForeground = false,
  });

  final double size;
  final bool lightForeground;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(moodPaletteProvider);
    final companion = ref.watch(userCompanionProvider);
    return CompanionLoadingIndicator(
      palette: palette,
      companion: companion,
      moodId: ref.watch(profileProvider).valueOrNull?.todayMood,
      size: size,
      lightForeground: lightForeground,
    );
  }
}
