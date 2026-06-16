import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/reminder_record.dart';
import '../../core/notifications/story_reminder_service.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/reminder_icon_asset_catalog.dart';
import '../../providers/app_providers.dart';
import 'widgets/reminder_editor_sheet.dart';
import 'widgets/reminder_icon_preview.dart';

final _reminderIconCatalogProvider =
    FutureProvider<ReminderIconAssetCatalog>((ref) {
  return ReminderIconAssetCatalog.load();
});

class ReminderSettingsPage extends ConsumerStatefulWidget {
  const ReminderSettingsPage({super.key});

  @override
  ConsumerState<ReminderSettingsPage> createState() =>
      _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends ConsumerState<ReminderSettingsPage> {
  bool _masterEnabled = true;
  List<ReminderRecord> _records = const [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadFromProfile();
  }

  void _loadFromProfile() {
    final prefs =
        ref.read(profileProvider).valueOrNull?.appPreferences ?? const {};
    _masterEnabled = prefs['reminders_enabled'] != false;
    _records = ReminderRecord.fromPreferences(prefs);
  }

  Future<void> _persist({String? snackMessage}) async {
    setState(() => _saving = true);
    try {
      final payload = {
        'reminders_enabled': _masterEnabled,
        'custom_reminders': ReminderRecord.toJsonList(_records),
      };
      final profile =
          await ref.read(appRepositoryProvider).patchAppPreferences(payload);
      ref.read(profileProvider.notifier).refresh();
      final status = await ref
          .read(storyReminderServiceProvider)
          .ensureSchedulePermissions();
      await ref
          .read(storyReminderServiceProvider)
          .scheduleFromPreferences(profile.appPreferences);
      final pending =
          await ref.read(storyReminderServiceProvider).pendingReminderCount();
      if (mounted && snackMessage != null) {
        final extra = _scheduleHint(status, pending);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status.notificationsGranted
                  ? '$snackMessage$extra'
                  : '$snackMessage（请在系统设置中允许通知权限）',
            ),
          ),
        );
      } else if (mounted && !status.notificationsGranted && _masterEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('提醒已保存，但通知权限未开启，请在系统设置中允许')),
        );
      } else if (mounted && _masterEnabled && pending == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '提醒已保存，但系统未成功注册定时推送${_scheduleHint(status, pending)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleMaster(bool value) async {
    setState(() => _masterEnabled = value);
    await _persist(snackMessage: value ? '提醒已开启' : '提醒已关闭');
  }

  Future<void> _toggleRecord(ReminderRecord record, bool enabled) async {
    setState(() {
      _records = _records
          .map((r) => r.id == record.id ? r.copyWith(enabled: enabled) : r)
          .toList();
    });
    await _persist();
  }

  String _scheduleHint(ReminderScheduleStatus status, int pending) {
    final parts = <String>[];
    if (pending > 0) {
      parts.add('，已注册 $pending 条定时提醒');
    }
    if (!status.exactAlarmsGranted) {
      parts.add('；若到点未推送，请在系统设置中允许「闹钟与提醒」并关闭省电限制');
    }
    return parts.join();
  }

  Future<void> _addOrEdit({ReminderRecord? initial}) async {
    final palette = ref.read(moodPaletteProvider);
    final catalog = await ref.read(_reminderIconCatalogProvider.future);
    if (!mounted) return;

    final result = await showReminderEditorSheet(
      context: context,
      palette: palette,
      iconAssets: catalog.allAssetPaths,
      defaultIcon: catalog.defaultIcon,
      initial: initial,
    );
    if (result == null) return;

    setState(() {
      if (initial != null) {
        _records = _records
            .map((r) => r.id == initial.id ? result : r)
            .toList();
      } else {
        _records = [..._records, result];
      }
    });
    await _persist(
      snackMessage: initial != null ? '提醒已更新' : '提醒已添加',
    );
  }

  Future<void> _sendTestNotification() async {
    setState(() => _saving = true);
    try {
      final service = ref.read(storyReminderServiceProvider);
      final granted = await service.requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先允许通知权限')),
        );
        return;
      }
      String? testIconAsset;
      for (final record in _records) {
        if (record.enabled) {
          testIconAsset = record.iconAsset;
          break;
        }
      }
      await service.showTestNotification(iconAsset: testIconAsset);
      if (!mounted) return;
      final enabled = await service.areNotificationsEnabled();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? '已发送测试通知，请下拉通知栏查看'
                : '系统通知权限未开启，请在设置中允许「星屿」发送通知',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('测试失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete(ReminderRecord record) async {
    final palette = ref.read(moodPaletteProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('删除这条提醒？'),
        content: Text(
          '「${record.text}」将不再发送本地通知。',
          style: const TextStyle(height: 1.5),
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
              '删除',
              style: TextStyle(
                color: palette.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _records = _records.where((r) => r.id != record.id).toList();
    });
    await _persist(snackMessage: '提醒已删除');
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    final iconCatalogAsync = ref.watch(_reminderIconCatalogProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : () => _addOrEdit(),
        backgroundColor: palette.accent,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('添加提醒'),
      ),
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Column(
            children: [
              Material(
                color: palette.card.withValues(alpha: 0.9),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: palette.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '记录提醒',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: Text(
                          '自定义提醒时间与文案，在 App 外收到温柔推送',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: palette.primary.withValues(alpha: 0.78),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
                      children: [
                  IslandGlassCard(
                    palette: palette,
                    child: SwitchListTile(
                      title: const Text('开启记录提醒'),
                      subtitle: const Text('关闭后将不再发送本地通知'),
                      value: _masterEnabled,
                      activeThumbColor: palette.accent,
                      onChanged: _saving ? null : _toggleMaster,
                    ),
                  ),
                  if (_masterEnabled) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _saving ? null : _sendTestNotification,
                        icon: const Icon(Icons.notifications_active_outlined, size: 18),
                        label: const Text('发送测试通知'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '我的提醒',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: palette.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '共 ${_records.length} 条',
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.primary.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_records.isEmpty)
                    IslandGlassCard(
                      palette: palette,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          '还没有提醒记录\n点击右下角「添加提醒」创建第一条',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.55,
                            color: palette.primary.withValues(alpha: 0.62),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._records.map(
                      (record) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ReminderRecordCard(
                          palette: palette,
                          record: record,
                          masterEnabled: _masterEnabled,
                          onToggle: (v) => _toggleRecord(record, v),
                          onEdit: () => _addOrEdit(initial: record),
                          onDelete: () => _confirmDelete(record),
                        ),
                      ),
                    ),
                  iconCatalogAsync.when(
                    data: (catalog) {
                      if (catalog.allAssetPaths.isNotEmpty) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '提示：可将图标放入 assets/images/companion/times/ 后在图标库中选择',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            color: palette.primary.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
              if (_saving)
                Positioned(
                  top: 12,
                  right: 24,
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.accent,
                    ),
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

class _ReminderRecordCard extends StatelessWidget {
  const _ReminderRecordCard({
    required this.palette,
    required this.record,
    required this.masterEnabled,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final MoodPalette palette;
  final ReminderRecord record;
  final bool masterEnabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dimmed = !masterEnabled || !record.enabled;

    return Opacity(
      opacity: dimmed && masterEnabled ? 0.65 : (masterEnabled ? 1 : 0.55),
      child: IslandGlassCard(
        palette: palette,
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: ReminderIconPreview(
                    assetPath: record.iconAsset,
                    size: 32,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.time,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: palette.primary,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        record.text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: palette.primary.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: record.enabled,
                  activeThumbColor: palette.accent,
                  onChanged: masterEnabled ? onToggle : null,
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('编辑'),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: palette.primary.withValues(alpha: 0.65),
                    ),
                    label: Text(
                      '删除',
                      style: TextStyle(
                        color: palette.primary.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

