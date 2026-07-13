import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/models/mood_check_in_models.dart';
import '../../design_system/app_feedback.dart';
import '../../design_system/island_decorations.dart';
import '../../providers/app_audio_provider.dart';
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
    final vipSubtitle = isVip
        ? (member?.expireTime == null
            ? 'VIP 已激活'
            : '有效期至 ${member!.expireTime!.toLocal().toString().substring(0, 10)}')
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
                  title: const Text('VIP 会员'),
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
              _AudioSettingsCard(palette: palette),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioSettingsCard extends ConsumerWidget {
  const _AudioSettingsCard({required this.palette});

  final MoodPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appAudioSettingsProvider);
    final settings = settingsAsync.valueOrNull;
    final notifier = ref.read(appAudioSettingsProvider.notifier);

    return IslandGlassCard(
      palette: palette,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.graphic_eq_rounded, color: palette.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '声音与沉浸感',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '岛屿、我的世界、今日日常中播放',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (settings == null)
              const LinearProgressIndicator(minHeight: 2)
            else ...[
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: settings.bgmEnabled,
                title: const Text('背景音乐'),
                subtitle: const Text('按本地时间自动切换白天 / 夜晚音乐'),
                activeThumbColor: palette.accent,
                activeTrackColor: palette.accent.withValues(alpha: 0.28),
                onChanged: notifier.setBgmEnabled,
              ),
              _AudioVolumeSlider(
                label: '背景音乐音量',
                value: settings.bgmVolume,
                enabled: settings.bgmEnabled,
                accent: palette.accent,
                onChanged: notifier.setBgmVolume,
              ),
              const Divider(height: 20),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: settings.sfxEnabled,
                title: const Text('操作音效'),
                subtitle: const Text('主要按钮、待办完成、成长奖励和 VIP 成功'),
                activeThumbColor: palette.accent,
                activeTrackColor: palette.accent.withValues(alpha: 0.28),
                onChanged: notifier.setSfxEnabled,
              ),
              _AudioVolumeSlider(
                label: '操作音效音量',
                value: settings.sfxVolume,
                enabled: settings.sfxEnabled,
                accent: palette.accent,
                onChanged: notifier.setSfxVolume,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AudioVolumeSlider extends StatelessWidget {
  const _AudioVolumeSlider({
    required this.label,
    required this.value,
    required this.enabled,
    required this.accent,
    required this.onChanged,
  });

  final String label;
  final double value;
  final bool enabled;
  final Color accent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Opacity(
      opacity: enabled ? 1 : 0.48,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('$percent%'),
            ],
          ),
          Slider(
            value: value,
            activeColor: accent,
            onChanged: enabled ? onChanged : null,
          ),
        ],
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
