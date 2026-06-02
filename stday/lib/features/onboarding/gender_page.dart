import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../providers/app_providers.dart';

class GenderPage extends ConsumerStatefulWidget {
  const GenderPage({super.key});

  @override
  ConsumerState<GenderPage> createState() => _GenderPageState();
}

class _GenderPageState extends ConsumerState<GenderPage> {
  String? _selected;
  bool _loading = false;

  Future<void> _next() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    await ref.read(profileProvider.notifier).updateGender(_selected!);
    if (mounted) context.go('/onboarding/companion');
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    final options = [('male', '男生'), ('female', '女生'), ('other', '其它')];
    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('选择你的性别', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('仅用于个性化伙伴形象'),
                const SizedBox(height: 32),
                ...options.map((o) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IslandChip(
                      label: o.$2,
                      selected: _selected == o.$1,
                      palette: palette,
                      onTap: () => setState(() => _selected = o.$1),
                    ),
                  );
                }),
                const Spacer(),
                IslandPrimaryAction(
                  label: '下一步',
                  palette: palette,
                  loading: _loading,
                  onPressed: _selected == null || _loading ? null : _next,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
