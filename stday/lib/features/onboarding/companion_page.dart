import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/user_companion.dart';
import '../../core/theme/mood_theme.dart';
import '../../design_system/companion_avatar.dart';
import '../../design_system/companion_loading.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/mood_face_selector.dart';
import '../../providers/app_providers.dart';

class CompanionPage extends ConsumerStatefulWidget {
  const CompanionPage({super.key});

  @override
  ConsumerState<CompanionPage> createState() => _CompanionPageState();
}

class _CompanionPageState extends ConsumerState<CompanionPage> {
  String? _selected;
  bool _loading = false;

  Future<void> _onSelect(String style) async {
    setState(() {
      _selected = style;
      _loading = true;
    });
    await ref.read(profileProvider.notifier).updateCompanion(style);
    if (!mounted) return;
    setState(() => _loading = false);
    await _showMoodPicker();
  }

  Future<void> _showMoodPicker() async {
    final palette = ref.read(moodPaletteProvider);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('今天的天气是？',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('点选即生效，小岛会换上对应颜色',
                  style: TextStyle(color: Color(0xFF8C7B6B))),
              const SizedBox(height: 24),
              MoodFaceSelector(
                selectedId: ref.read(profileProvider).valueOrNull?.todayMood,
                gender: ref.read(profileProvider).valueOrNull?.gender,
                onSelected: (mood) async {
                  await ref.read(profileProvider.notifier).updateMood(mood);
                  await ref.read(profileProvider.notifier).completeOnboarding();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) context.go('/onboarding/arrival?mood=$mood');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: Column(
                    children: [
                      const Text(
                        '选择你的透明小伙伴',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Q版更可爱，正常版更清秀',
                        style: TextStyle(color: Color(0xFF8C7B6B)),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _CompanionOptionCard(
                              title: 'Q版小星',
                              style: 'chibi',
                              selected: _selected == 'chibi',
                              loading: _loading && _selected == 'chibi',
                              palette: palette,
                              onTap: _loading ? null : () => _onSelect('chibi'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _CompanionOptionCard(
                              title: '正常版小星',
                              style: 'normal',
                              selected: _selected == 'normal',
                              loading: _loading && _selected == 'normal',
                              palette: palette,
                              onTap:
                                  _loading ? null : () => _onSelect('normal'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CompanionOptionCard extends StatelessWidget {
  const _CompanionOptionCard({
    required this.title,
    required this.style,
    required this.selected,
    required this.palette,
    required this.onTap,
    this.loading = false,
  });

  final String title;
  final String style;
  final bool selected;
  final bool loading;
  final MoodPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? palette.primaryContainer : palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? palette.accent : Colors.transparent, width: 2),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: palette.accent.withValues(alpha: 0.25),
                      blurRadius: 16)
                ]
              : null,
        ),
        child: Column(
          children: [
            CompanionAvatar(
                style: style, scene: 'stargaze', size: 100, palette: palette),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (loading)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: CompanionLoadingIndicator(
                  palette: palette,
                  companion: UserCompanion(profileStyle: style),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
