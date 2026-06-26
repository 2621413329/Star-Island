import 'package:flutter/material.dart';

import '../../core/theme/app_fonts.dart';

/// 引导页卡片欢迎介绍（精简：标题 + 价值说明）。
class LandingWelcomeSection extends StatelessWidget {
  const LandingWelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '✨ 欢迎来到星屿',
              textAlign: TextAlign.center,
              style: appTextStyle(
                fontSize: 17,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5D4E44),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '记录今天的一点故事，\n陪伴未来的成长变化。',
              textAlign: TextAlign.center,
              style: appTextStyle(
                fontSize: 14,
                height: 1.65,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B5D52),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '今天，也是值得认真记录的一天。',
              textAlign: TextAlign.center,
              style: appTextStyle(
                fontSize: 13,
                height: 1.55,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8C7B6B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
