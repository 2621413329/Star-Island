import 'package:flutter/material.dart';

import '../../core/theme/app_fonts.dart';

class LandingWelcomeCopy extends StatelessWidget {
  const LandingWelcomeCopy({
    super.key,
    this.isGuest = true,
    this.subdued = false,
  });

  final bool isGuest;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    final title = isGuest ? '你的成长故事正在继续' : '欢迎回来';
    final subtitle = isGuest ? '记录今天，让未来的自己看见' : '今天的小岛正在等你';

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: appTextStyle(
            fontSize: subdued ? 17 : 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5D4E44),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: appTextStyle(
            fontSize: subdued ? 13 : 15,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8C7B6B),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
