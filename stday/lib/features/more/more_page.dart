import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/island_decorations.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(moodPaletteProvider);
    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('更多', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              IslandGlassCard(
                palette: palette,
                child: ListTile(
                  title: const Text('成长伙伴小星'),
                  subtitle: const Text('你的透明小伙伴'),
                  leading: Icon(Icons.auto_awesome, color: palette.primary),
                ),
              ),
              const SizedBox(height: 12),
              IslandGlassCard(
                palette: palette,
                child: ListTile(
                  title: const Text('退出登录'),
                  leading: const Icon(Icons.logout),
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    ref.invalidate(profileProvider);
                    ref.invalidate(todayMomentsProvider);
                    if (context.mounted) context.go('/welcome');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
