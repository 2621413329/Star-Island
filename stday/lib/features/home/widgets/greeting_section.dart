import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../design_system/home_theme.dart';
import '../providers/home_greeting_provider.dart';

class GreetingSection extends StatelessWidget {
  const GreetingSection({super.key, required this.greeting});

  final HomeGreeting greeting;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${greeting.period}，${greeting.displayName} ✨',
                style: appTextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: HomeTheme.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                greeting.subtitle,
                style: appTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: HomeTheme.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
          color: HomeTheme.textSecondary,
          tooltip: '通知',
        ),
        IconButton(
          onPressed: () => context.go('/more'),
          icon: const Icon(Icons.person_outline_rounded),
          color: HomeTheme.textSecondary,
          tooltip: '我的',
        ),
      ],
    );
  }
}
