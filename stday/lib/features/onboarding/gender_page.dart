import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/layout/app_layout.dart';
import '../../core/theme/mood_theme.dart';
import '../../design_system/companion_avatar.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';

class GenderPage extends ConsumerStatefulWidget {
  const GenderPage({super.key});

  @override
  ConsumerState<GenderPage> createState() => _GenderPageState();
}

class _GenderPageState extends ConsumerState<GenderPage> {
  String? _selected;
  bool _loading = false;

  static const _previewStyle = 'mindscape';

  Future<void> _enterApp() async {
    if (_selected == null || _loading) return;
    if (!ref.read(authProvider).isLoggedIn) {
      context.go('/auth');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(profileProvider.notifier).updateGender(_selected!);
      if (!mounted) return;
      context.go('/onboarding/companion');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.pageHorizontal,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    Text(
                      '选择你的性别',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '小星会根据你的选择换上对应发型',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8C7B6B)),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _GenderOptionCard(
                            gender: 'male',
                            label: '男生',
                            subtitle: '光头小星',
                            selected: _selected == 'male',
                            palette: palette,
                            onTap: _loading
                                ? null
                                : () => setState(() => _selected = 'male'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _GenderOptionCard(
                            gender: 'female',
                            label: '女生',
                            subtitle: '长发小星',
                            selected: _selected == 'female',
                            palette: palette,
                            onTap: _loading
                                ? null
                                : () => setState(() => _selected = 'female'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    IslandPrimaryAction(
                      label: '进入成长小岛',
                      palette: palette,
                      loading: _loading,
                      onPressed: _selected == null || _loading ? null : _enterApp,
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

class _GenderOptionCard extends StatelessWidget {
  const _GenderOptionCard({
    required this.gender,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String gender;
  final String label;
  final String subtitle;
  final bool selected;
  final MoodPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? palette.primaryContainer : palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? palette.accent : palette.accent.withValues(alpha: 0.25),
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.22),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CompanionAvatar(
              style: _GenderPageState._previewStyle,
              gender: gender,
              scene: 'stargaze',
              expression: 'happy',
              size: 76,
              palette: palette,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: selected ? palette.accent : const Color(0xFF5D4E42),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: selected ? palette.primary : const Color(0xFF8C7B6B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
