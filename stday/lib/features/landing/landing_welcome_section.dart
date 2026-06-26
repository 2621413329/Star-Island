import 'package:flutter/material.dart';

import '../../core/theme/app_fonts.dart';

/// 引导页卡片上方的欢迎介绍区。
class LandingWelcomeSection extends StatelessWidget {
  const LandingWelcomeSection({super.key});

  static const _features = [
    '记录每日心情',
    '保存成长故事',
    '见证小岛变化',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const SizedBox(height: 10),
          Text(
            '记录今天的一点故事，\n陪伴未来的成长变化。',
            textAlign: TextAlign.center,
            style: appTextStyle(
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B5D52),
            ),
          ),
          const SizedBox(height: 16),
          const _SoftDivider(),
          const SizedBox(height: 14),
          for (var i = 0; i < _features.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _FeatureRow(label: _features[i]),
          ],
          const SizedBox(height: 14),
          const _SoftDivider(),
          const SizedBox(height: 14),
          Text(
            '今天，\n也是值得认真记录的一天。',
            textAlign: TextAlign.center,
            style: appTextStyle(
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5D4E44),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE8DDD4).withValues(alpha: 0.2),
                  const Color(0xFFE8DDD4),
                  const Color(0xFFE8DDD4).withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE8A87C).withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 14,
            color: Color(0xFFC4845C),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: appTextStyle(
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B5D52),
          ),
        ),
      ],
    );
  }
}
