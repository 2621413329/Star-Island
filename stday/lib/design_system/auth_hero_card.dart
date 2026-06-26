import 'package:flutter/material.dart';

import '../core/theme/mood_theme.dart';

/// 登录/注册页顶部英雄区：背景图 + 前景小人 + 标题。
class AuthHeroCard extends StatelessWidget {
  const AuthHeroCard({
    super.key,
    required this.palette,
    required this.title,
    required this.avatar,
  });

  static const backgroundAsset = 'assets/images/auth/auth_hero_background.png';

  final MoodPalette palette;
  final String title;
  final Widget avatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1.45,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              backgroundAsset,
              fit: BoxFit.cover,
            ),
            Align(
              alignment: const Alignment(0, 0.62),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(child: avatar),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Color(0xFF5D4E44),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
