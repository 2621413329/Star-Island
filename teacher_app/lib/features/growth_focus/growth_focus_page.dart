import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/mood_theme.dart';
import '../../data/models/critical_risk.dart';
import '../../design_system/fade_in_card.dart';
import '../../design_system/island_date_picker.dart';
import '../../design_system/island_ui.dart';
import '../../providers/date_providers.dart';
import '../../providers/growth_providers.dart';
import '../archive/growth_observation_archive_page.dart';
import '../risk/risk_follow_actions.dart';
import '../risk/risk_signal_detail_page.dart';

class GrowthFocusPage extends ConsumerWidget {
  const GrowthFocusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const palette = defaultPalette;
    final range = ref.watch(alertsDateRangeProvider).normalized();
    final async = ref.watch(criticalRiskListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('成长关注', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: IslandDateRangeSelector(
            palette: palette,
            range: range,
            onChanged: (r) => ref.read(alertsDateRangeProvider.notifier).state = r,
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 4),
          child: Text(
            '每条卡片对应一名学生的一条危险信号；可标记已关注并填写跟进内容。',
            style: TextStyle(fontSize: 12, color: Color(0xFF8C7B6B)),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Text('所选范围内暂无危险信号', style: TextStyle(color: Color(0xFF8C7B6B))),
                );
              }
              final pending = items.where((e) => !e.isFollowed).length;
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(criticalRiskListProvider);
                  ref.invalidate(pendingGrowthFocusCountProvider);
                  await ref.read(criticalRiskListProvider.future);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  itemCount: items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          '${DateFormat('M/d').format(range.start)}–${DateFormat('M/d').format(range.end)} · '
                          '共 ${items.length} 条 · 待关注 $pending',
                          style: const TextStyle(color: Color(0xFF8C7B6B), fontSize: 13),
                        ),
                      );
                    }
                    final item = items[index - 1];
                    return FadeInCard(
                      index: index - 1,
                      child: _CriticalRiskCard(item: item, palette: palette),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CriticalRiskCard extends ConsumerWidget {
  const _CriticalRiskCard({required this.item, required this.palette});

  final CriticalRiskSignal item;
  final MoodPalette palette;

  Future<void> _openDetail(BuildContext context, WidgetRef ref) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RiskSignalDetailPage(
          momentId: item.momentId,
          studentName: item.studentName,
        ),
      ),
    );
    if (changed == true) {
      invalidateRiskFollowState(ref, item.momentId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateTime.tryParse(item.reportDate);
    final dateLabel = date != null ? DateFormat('M月d日').format(date) : item.reportDate;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IslandGlassCard(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openDetail(context, ref),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.studentName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ),
                      _FollowStatusChip(isFollowed: item.isFollowed),
                      const SizedBox(width: 6),
                      Text(dateLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF8C7B6B))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.storyDetail,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(height: 1.4),
                  ),
                  if (item.isFollowed && item.followNote != null && item.followNote!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '关注内容：${item.followNote}',
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  item.categoryLabel,
                  style: TextStyle(fontSize: 12, color: palette.primary, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => GrowthObservationArchivePage(
                          studentId: item.studentId,
                          studentName: item.studentName,
                        ),
                      ),
                    );
                  },
                  child: const Text('查看档案'),
                ),
                if (item.isFollowed)
                  TextButton(
                    onPressed: () => reactivateRiskFollow(
                      ref,
                      context: context,
                      momentId: item.momentId,
                    ),
                    child: const Text('重新激活'),
                  )
                else
                  FilledButton.tonal(
                    onPressed: () => markRiskFollowed(
                      ref,
                      context: context,
                      momentId: item.momentId,
                      studentName: item.studentName,
                    ),
                    child: const Text('已关注'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowStatusChip extends StatelessWidget {
  const _FollowStatusChip({required this.isFollowed});

  final bool isFollowed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isFollowed ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isFollowed ? '已关注' : '待关注',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isFollowed ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
        ),
      ),
    );
  }
}
