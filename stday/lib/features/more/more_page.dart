import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/companion_roles.dart';
import '../../core/utils/api_datetime.dart';
import '../../data/models/mood_check_in_models.dart';
import '../../design_system/app_feedback.dart';
import '../../design_system/island_decorations.dart';
import '../../providers/app_providers.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../providers/mood_report_check_in_provider.dart';
import '../../providers/member_provider.dart';
import '../status/widgets/mood_check_in_week_card.dart';

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
            ? '屿之迹会员已开通'
            : '有效期至 ${formatMembershipExpireDate(member!.expireTime!)}')
        : '订阅开通';

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
                  title: const Text('屿之迹会员'),
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
                  title: const Text('设置'),
                  subtitle: const Text('提醒、声音、说明与账号'),
                  leading: Icon(Icons.settings_outlined, color: palette.primary),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/more/settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
