import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_fonts.dart';
import '../../design_system/island_decorations.dart';
import '../../providers/app_providers.dart';

const _hideAboutMenuKey = 'hide_app_about_menu_entry';

/// 是否在「更多」页隐藏「应用说明」入口。
Future<bool> isAppAboutMenuHidden() async {
  final sp = await SharedPreferences.getInstance();
  return sp.getBool(_hideAboutMenuKey) ?? false;
}

Future<void> setAppAboutMenuHidden(bool hidden) async {
  final sp = await SharedPreferences.getInstance();
  await sp.setBool(_hideAboutMenuKey, hidden);
}

class AppAboutPage extends ConsumerStatefulWidget {
  const AppAboutPage({super.key});

  @override
  ConsumerState<AppAboutPage> createState() => _AppAboutPageState();
}

class _AppAboutPageState extends ConsumerState<AppAboutPage> {
  bool _detailsVisible = true;

  static const _sections = [
    _AboutSection(
      emoji: '🏝️',
      title: '星屿是什么',
      body:
          '星屿是一款温暖陪伴型的成长记录 App。你可以用简短的故事记录每天的生活与感受，'
          'AI 伙伴会帮你理解情绪、整理成长标签，并把这些记录变成一座会随你变化的小岛。',
      accent: Color(0xFF5A9A6E),
    ),
    _AboutSection(
      emoji: '📝',
      title: '你可以做什么',
      body: '· 记录今日故事与心情\n'
          '· 为故事添加成长标签与照片\n'
          '· 在成长轨迹中查看心情与标签统计\n'
          '· 设置本地提醒，到点温柔推送\n'
          '· 观察小岛随记录逐渐繁荣、天气变化',
      accent: Color(0xFF4A8FB8),
    ),
    _AboutSection(
      emoji: '🤖',
      title: 'AI 如何参与',
      body: 'AI 会基于你的文字推断情绪与标签，帮助你更快完成记录；'
          '照片仅作个人保存，不参与 AI 分析。所有 AI 结果都可以手动修改。',
      accent: Color(0xFF7E6DB7),
    ),
    _AboutSection(
      emoji: '🔒',
      title: '隐私与数据',
      body: '你的日常故事主要由自己保存与查看。'
          '若启用教师端能力，老师看到的是成长趋势与需要关注的提醒，而非逐条私人日记。',
      accent: Color(0xFFC9A227),
    ),
  ];

  Future<void> _hideFromMoreMenu() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('隐藏应用说明？'),
        content: const Text(
          '隐藏后，「更多」页将不再显示「应用说明」入口。\n'
          '你仍可通过直接访问路由进入（如需恢复可 reinstall 或清除应用数据）。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('隐藏'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await setAppAboutMenuHidden(true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已从「更多」隐藏应用说明')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: const Color(0xFF5D4E44),
                    ),
                    Expanded(
                      child: Text(
                        '应用说明',
                        style: appTextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3D3229),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _detailsVisible ? '收起说明' : '展开说明',
                      onPressed: () =>
                          setState(() => _detailsVisible = !_detailsVisible),
                      icon: Icon(
                        _detailsVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF5D4E44),
                      ),
                    ),
                    IconButton(
                      tooltip: '从更多页隐藏',
                      onPressed: _hideFromMoreMenu,
                      icon: const Icon(
                        Icons.hide_source_outlined,
                        color: Color(0xFF8C7B6B),
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
                      '星屿 · 温暖陪伴型成长记录',
                      textAlign: TextAlign.center,
                      style: appTextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF3D3229),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '记录真实感受，见证小岛与自身一起成长。',
                      textAlign: TextAlign.center,
                      style: appTextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: palette.primary.withValues(alpha: 0.62),
                      ),
                    ),
                    if (_detailsVisible) ...[
                      const SizedBox(height: 20),
                      IslandGlassCard(
                        palette: palette,
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                        child: Column(
                          children: [
                            for (var i = 0; i < _sections.length; i++) ...[
                              _AboutSectionBlock(section: _sections[i]),
                              if (i < _sections.length - 1)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  child: Divider(
                                    height: 1,
                                    color: palette.primary
                                        .withValues(alpha: 0.08),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Text(
                          '说明已收起，点击右上角眼睛图标可重新展开。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.primary.withValues(alpha: 0.5),
                          ),
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
