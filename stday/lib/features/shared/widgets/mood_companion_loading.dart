import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/companion_loading.dart';
import '../../../design_system/island_decorations.dart';
import '../../../providers/app_providers.dart';

/// 主 Tab 内嵌加载（勿再包 Scaffold，避免与 Shell 双层 Scaffold 导致空白）。
class MoodCompanionLoadingBody extends ConsumerWidget {
  const MoodCompanionLoadingBody({super.key, this.message});

  final String? message;

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
