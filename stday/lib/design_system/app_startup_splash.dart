import 'package:flutter/material.dart';

import '../core/theme/app_fonts.dart';
import '../core/theme/mood_theme.dart';
import 'island_decorations.dart';

/// 与原生启动页、应用暖色基调一致，覆盖首帧路由/资料未就绪时的空白。
class AppStartupSplash extends StatelessWidget {
  const AppStartupSplash({super.key});

  static const taglinePrimary = '点滴生活皆珍贵，专属记录成长日常';
  static const taglineSecondary = '独为你珍藏守护';

  @override
  Widget build(BuildContext context) {
    const palette = defaultPalette;
    return Material(
      color: palette.gradientStart,
      child: IslandScaffold(
        palette: palette,
        showOrbs: false,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/app_icon.png',
                      width: 112,
                      height: 112,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    taglinePrimary,
                    textAlign: TextAlign.center,
                    style: appTextStyle(
                      fontSize: 15,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5A4E44),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    taglineSecondary,
                    textAlign: TextAlign.center,
                    style: appTextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8C7B6B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
