import 'package:flutter/material.dart';

import '../core/storage/growth_island_rules_store.dart';
import '../core/theme/app_fonts.dart';
import '../core/theme/mood_theme.dart';
import 'island_chip.dart';

Future<void> showGrowthIslandRulesIfNeeded(BuildContext context) async {
  final store = GrowthIslandRulesStore();
  if (await store.isAcknowledged()) return;
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => _GrowthIslandRulesSheet(
      onConfirm: () async {
        await store.acknowledge();
        if (ctx.mounted) Navigator.pop(ctx);
      },
    ),
  );
}

class _GrowthIslandRulesSheet extends StatelessWidget {
  const _GrowthIslandRulesSheet({required this.onConfirm});

  final VoidCallback onConfirm;

  static const _sections = [
    (
      '🌱 请记录真实感受',
      '快乐、难过、焦虑、平静都值得被看见。',
    ),
    (
      '🔒 关于隐私',
      '你的日常记录主要由自己保存。\n老师查看的是成长趋势和需要帮助的提醒。\n而不是简单查看你的私人日记。',
    ),
    (
      '🫶 关于陪伴',
      '成长观察不是监督。\n而是在需要时给予帮助。',
    ),
    (
      '🏝 关于成长',
      '每一次记录都会让小岛发生一点变化。\n欢迎开始你的成长旅程。',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const palette = defaultPalette;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom + 12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        decoration: BoxDecoration(
          color: palette.card.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '欢迎来到成长小岛',
                      textAlign: TextAlign.center,
                      style: appTextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF3D3229),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '这里记录的不是成绩。\n而是成长路上的每一天。',
                      textAlign: TextAlign.center,
                      style: appTextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: const Color(0xFF5D4E44),
                      ),
                    ),
                    for (final section in _sections) ...[
                      const SizedBox(height: 14),
                      Divider(
                        height: 1,
                        color: const Color(0xFFE8DDD4).withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        section.$1,
                        style: appTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5D4E44),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        section.$2,
                        style: appTextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: const Color(0xFF8C7B6B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: IslandPrimaryAction(
                label: '我知道了',
                palette: palette,
                height: 44,
                onPressed: onConfirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
