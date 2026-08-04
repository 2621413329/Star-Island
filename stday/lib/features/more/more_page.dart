import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/companion_roles.dart';
import '../../core/legal/legal_documents.dart';
import '../../core/utils/api_datetime.dart';
import '../../data/models/mood_check_in_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/app_feedback.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/legal_agreement.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../providers/mood_report_check_in_provider.dart';
import '../../providers/member_provider.dart';
import '../status/widgets/mood_check_in_week_card.dart';
import 'app_about_page.dart';

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
        AppFeedback.showWeak(context, '昵称已更新');
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
    final profile = ref.watch(profileProvider).valueOrNull;
    final growthAsync = ref.watch(growthSummaryProvider);
    final checkIn = ref.watch(moodReportCheckInProvider).valueOrNull ??
        MoodReportCheckIn.empty;
    final summary = growthAsync.valueOrNull;
    final nickname = profile?.nickname;
    final levelSubtitle = summary == null
        ? '查看经验值与岛屿解锁'
        : '成长等级：Lv.${summary.level} ${summary.levelTitle}';

    final isVip = ref.watch(isVipProvider);
    final member = ref.watch(memberProvider).valueOrNull;
    final companionRoleId = CompanionRoles.resolveRoleId(
      companionRoleId: profile?.companionRoleId,
      legacyGender: profile?.gender,
    );
    final companionName = CompanionRoles.nameFor(companionRoleId);
    final vipSubtitle = isVip
        ? (member?.expireTime == null
            ? '星屿会员已开通'
            : '有效期至 ${formatMembershipExpireDate(member!.expireTime!)}')
        : '解锁完整成长功能';

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('更多', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              MoodCheckInWeekCard(
                palette: palette,
                checkIn: checkIn,
              ),
              const SizedBox(height: 16),
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
                  leading: Icon(Icons.person_outline_rounded,
                      color: palette.primary),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _editNickname(context, ref, current: nickname),
                ),
              ),
              const SizedBox(height: 12),
              IslandGlassCard(
                palette: palette,
                child: ListTile(
                  title: const Text('星屿会员'),
                  subtitle: Text(vipSubtitle),
                  leading: Icon(
                    isVip
                        ? Icons.workspace_premium_rounded
                        : Icons.workspace_premium_outlined,
                    color: palette.accent,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/more/membership'),
                ),
              ),
              const SizedBox(height: 12),
              IslandGlassCard(
                palette: palette,
                child: ListTile(
                  title: const Text('我的等级'),
                  subtitle: Text(levelSubtitle),
                  leading: Icon(Icons.military_tech_outlined,
                      color: palette.primary),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/more/my-level'),
                ),
              ),
              const SizedBox(height: 12),
              IslandGlassCard(
                palette: palette,
                child: ListTile(
                  title: Text('成长伙伴$companionName'),
                  subtitle: const Text('你的成长小伙伴'),
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
                  title: const Text('声音设置'),
                  subtitle: const Text('编辑岛屿音乐与操作音效'),
                  leading:
                      Icon(Icons.graphic_eq_rounded, color: palette.primary),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/more/audio'),
                ),
              ),
              const SizedBox(height: 12),
              const _AboutMenuEntry(),
              const SizedBox(height: 12),
              IslandGlassCard(
                palette: palette,
                child: ListTile(
                  title: const Text('退出登录'),
                  leading: const Icon(Icons.logout),
                  onTap: () => _confirmLogout(context, ref),
                ),
              ),
              const SizedBox(height: 12),
              IslandGlassCard(
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
    return IslandGlassCard(
      palette: palette,
      child: ListTile(
        title: const Text('应用说明'),
        subtitle: const Text('了解星屿的功能与隐私说明'),
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
