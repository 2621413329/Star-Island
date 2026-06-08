import 'package:flutter/material.dart';

import '../core/models/user_companion.dart';
import '../core/theme/mood_theme.dart';
import 'companion_loading.dart';
import 'island_decorations.dart';

/// 与原生启动页、应用暖色基调一致，覆盖首帧路由/资料未就绪时的空白。
class AppStartupSplash extends StatelessWidget {
  const AppStartupSplash({super.key, this.message = '成长小岛启动中…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    const palette = defaultPalette;
    return Material(
      color: palette.gradientStart,
      child: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Center(
            child: CompanionLoadingView(
              palette: palette,
              companion: const UserCompanion(),
              moodId: 'calm',
              message: message,
              size: 110,
            ),
          ),
        ),
      ),
    );
  }
}
