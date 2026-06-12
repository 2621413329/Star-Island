import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_fonts.dart';
import '../../core/theme/mood_theme.dart';
import '../../design_system/island_decorations.dart';
import '../../providers/app_providers.dart';

class AppAboutPage extends ConsumerWidget {
  const AppAboutPage({super.key});

  static const _sections = [
    _AboutSection(
      emoji: '🌱',
      title: '请记录真实感受',
      body: '快乐、难过、焦虑、平静都值得被看见。',
      accent: Color(0xFF5A9A6E),
    ),
    _AboutSection(
      emoji: '🔒',
      title: '关于隐私',
      body: '你的日常记录主要由自己保存。老师查看的是成长趋势和需要帮助的提醒，而不是简单查看你的私人日记。',
      accent: Color(0xFFC9A227),
    ),
    _AboutSection(
      emoji: '🤝',
      title: '关于陪伴',
      body: '成长观察不是监督，而是在需要时给予帮助。',
      accent: Color(0xFFC9A227),
    ),
    _AboutSection(
      emoji: '🏝️',
      title: '关于成长',
      body: '每一次记录都会让小岛发生一点变化。欢迎开始你的成长旅程。',
      accent: Color(0xFFC9A227),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(moodPaletteProvider);

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: const Color(0xFF5D4E44),
                    ),
                    Text(
                      '应用说明',
                      style: appTextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D3229),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    Text(
                      '这里记录的不是成绩。',
                      textAlign: TextAlign.center,
                      style: appTextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: palette.primary.withValues(alpha: 0.55),
                      ),
                    ),
                    Text(
                      '而是成长路上的每一天。',
                      textAlign: TextAlign.center,
                      style: appTextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: palette.primary.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 24),
                    IslandGlassCard(
                      palette: palette,
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                      child: Column(
                        children: [
                          for (var i = 0; i < _sections.length; i++) ...[
                            _AboutSectionBlock(section: _sections[i]),
                            if (i < _sections.length - 1)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                child: Divider(
                                  height: 1,
                                  color: palette.primary.withValues(alpha: 0.08),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutSection {
  const _AboutSection({
    required this.emoji,
    required this.title,
    required this.body,
    required this.accent,
  });

  final String emoji;
  final String title;
  final String body;
  final Color accent;
}

class _AboutSectionBlock extends StatelessWidget {
  const _AboutSectionBlock({required this.section});

  final _AboutSection section;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(section.emoji, style: const TextStyle(fontSize: 22, height: 1.2)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: appTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: section.accent,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                section.body,
                style: appTextStyle(
                  fontSize: 14,
                  height: 1.65,
                  color: const Color(0xFF5A4E44),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
