import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/island_decorations.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../landing/landing_growth_provider.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(moodPaletteProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final growthAsync = ref.watch(landingGrowthProvider);
    final summary = growthAsync.valueOrNull;
    final nickname = profile?.nickname;
    final levelSubtitle = summary == null
        ? '查看成长值与岛屿解锁'
        : 'Lv.${summary.level} ${summary.levelTitle} · ${summary.growthValue} 成长值';

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('更多', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              if (nickname != null && nickname.isNotEmpty)
                IslandGlassCard(
                  palette: palette,
                  child: ListTile(
                    title: Text(nickname),
                    subtitle: const Text('我的昵称'),
                    leading: Icon(Icons.person_outline_rounded, color: palette.primary),
                  ),
                ),
              if (nickname != null && nickname.isNotEmpty)
                const SizedBox(height: 12),
              IslandGlassCard(
                palette: palette,
                child: ListTile(
                  title: const Text('我的等级'),
                  subtitle: Text(levelSubtitle),
                  leading: Icon(Icons.military_tech_outlined, color: palette.primary),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/more/my-level'),
                ),
              ),
              const SizedBox(height: 12),
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
