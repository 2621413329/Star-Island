import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/app_feedback.dart';
import '../../design_system/island_decorations.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import 'app_about_page.dart';
import 'widgets/more_subpage_header.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final palette = ref.read(moodPaletteProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('确认退出登录？'),
        content: const Text(
          '退出后需要重新登录，才能继续记录你的成长日常。',
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

  /// 账号注销：两次确认弹窗，防止误操作（App Store 5.1.1(v)）。
  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final palette = ref.read(moodPaletteProvider);

    final firstConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('注销账号？'),
        content: const Text(
          '注销后，你的账号、成长记录、会员权益与相关数据将被永久删除，且无法恢复。'
          '此操作不可撤销。',
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
            child: const Text(
              '继续注销',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (firstConfirmed != true || !context.mounted) return;

    final secondConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('再次确认注销'),
        content: const Text(
          '请再次确认：你要永久注销当前账号吗？注销完成后将返回欢迎页。',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              '我再想想',
              style: TextStyle(color: palette.primary.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '确认注销',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (secondConfirmed != true || !context.mounted) return;

    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      if (!context.mounted) return;
      await ref.read(authProvider.notifier).logout();
      ref.invalidate(profileProvider);
      ref.invalidate(todayMomentsProvider);
      ref.invalidate(memberProvider);
      if (!context.mounted) return;
      AppFeedback.showWeak(context, '账号已注销');
      context.go('/welcome');
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(networkErrorMessage)),
        );
      }
    }
  }

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
              const MoreSubpageHeader(title: '设置'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    _SettingsCard(
                      palette: palette,
                      child: ListTile(
                        title: const Text('记录提醒'),
                        subtitle: const Text('自定义时间与文案的本地通知'),
                        leading: Icon(
                          Icons.notifications_none_rounded,
                          color: palette.primary,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/more/reminders'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingsCard(
                      palette: palette,
                      child: ListTile(
                        title: const Text('声音设置'),
                        subtitle: const Text('编辑岛屿音乐与操作音效'),
                        leading: Icon(
                          Icons.graphic_eq_rounded,
                          color: palette.primary,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/more/audio'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _AboutMenuEntry(),
                    const SizedBox(height: 12),
                    _SettingsCard(
                      palette: palette,
                      child: ListTile(
                        title: const Text('退出登录'),
                        leading: const Icon(Icons.logout),
                        onTap: () => _confirmLogout(context, ref),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingsCard(
                      palette: palette,
                      child: ListTile(
                        title: const Text(
                          '注销账号',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                        subtitle: const Text('永久删除账号与相关数据'),
                        leading: const Icon(
                          Icons.person_off_outlined,
                          color: Colors.redAccent,
                        ),
                        onTap: () => _confirmDeleteAccount(context, ref),
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

/// 玻璃卡片自带底色，列表项需要自己的 [Material]，水波纹才会画在卡片之上。
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.palette, required this.child});

  final MoodPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IslandGlassCard(
      palette: palette,
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _AboutMenuEntry extends ConsumerStatefulWidget {
  const _AboutMenuEntry();

  @override
  ConsumerState<_AboutMenuEntry> createState() => _AboutMenuEntryState();
}

class _AboutMenuEntryState extends ConsumerState<_AboutMenuEntry> {
  bool _hidden = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hidden = await isAppAboutMenuHidden();
    if (mounted) {
      setState(() {
        _hidden = hidden;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _hidden) return const SizedBox.shrink();
    final palette = ref.watch(moodPaletteProvider);
    return _SettingsCard(
      palette: palette,
      child: ListTile(
        title: const Text('应用说明'),
        subtitle: const Text('了解屿之迹的功能与隐私说明'),
        leading: Icon(Icons.menu_book_outlined, color: palette.primary),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () async {
          await context.push('/more/about');
          await _load();
        },
      ),
    );
  }
}
