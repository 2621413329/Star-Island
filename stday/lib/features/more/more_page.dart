import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../design_system/island_decorations.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../island/providers/growth_summary_provider.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  Future<void> _editNickname(
    BuildContext context,
    WidgetRef ref, {
    String? current,
  }) async {
    final palette = ref.read(moodPaletteProvider);
    final controller = TextEditingController(text: current ?? '');
    final nickname = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 32,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: '我的昵称',
            hintText: '请输入昵称',
          ),
          onSubmitted: (_) {
            final value = controller.text.trim();
            if (value.isNotEmpty) Navigator.pop(ctx, value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '取消',
              style: TextStyle(color: palette.primary.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(ctx, value);
            },
            child: Text(
              '保存',
              style: TextStyle(
                color: palette.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (nickname == null || nickname.isEmpty || !context.mounted) return;

    try {
      await ref.read(profileProvider.notifier).updateNickname(nickname);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('昵称已更新')),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final palette = ref.read(moodPaletteProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('确认退出登录？'),
        content: const Text(
          '退出后需要重新登录，才能继续记录你的成长故事。',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              '取消',
              style: TextStyle(color: palette.primary.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '退出登录',
              style: TextStyle(
                color: palette.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(authProvider.notifier).logout();
    ref.invalidate(profileProvider);
    ref.invalidate(todayMomentsProvider);
    if (context.mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(moodPaletteProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final growthAsync = ref.watch(growthSummaryProvider);
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
              IslandGlassCard(
                palette: palette,
                child: ListTile(
                  title: Text(
                    (nickname != null && nickname.isNotEmpty)
                        ? nickname
                        : '未设置昵称',
                    style: TextStyle(
                      color: (nickname != null && nickname.isNotEmpty)
                          ? null
                          : palette.primary.withValues(alpha: 0.55),
                    ),
                  ),
                  subtitle: const Text('我的昵称'),
                  leading: Icon(Icons.person_outline_rounded, color: palette.primary),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _editNickname(context, ref, current: nickname),
                ),
              ),
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
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/more/companion'),
                ),
              ),
              const SizedBox(height: 12),
              IslandGlassCard(
                palette: palette,
                child: ListTile(
                  title: const Text('记录提醒'),
                  subtitle: const Text('自定义时间与文案的本地通知'),
                  leading: Icon(Icons.notifications_active_outlined,
                      color: palette.primary),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/more/reminders'),
                ),
              ),
              const SizedBox(height: 12),
              IslandGlassCard(
                palette: palette,
                child: ListTile(
                  title: const Text('应用说明'),
                  subtitle: const Text('记录、隐私与成长陪伴'),
                  leading: Icon(Icons.menu_book_outlined, color: palette.primary),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/more/about'),
                ),
              ),
              const SizedBox(height: 12),
              IslandGlassCard(
                palette: palette,
                child: ListTile(
                  title: const Text('退出登录'),
                  leading: const Icon(Icons.logout),
                  onTap: () => _confirmLogout(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
