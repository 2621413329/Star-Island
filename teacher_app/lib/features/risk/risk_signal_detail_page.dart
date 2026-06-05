import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/mood_catalog.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/models/critical_risk.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../design_system/island_ui.dart';
import '../../design_system/risk_dismiss_link.dart';
import '../../providers/growth_providers.dart';
import 'risk_follow_actions.dart';

class RiskSignalDetailPage extends ConsumerStatefulWidget {
  const RiskSignalDetailPage({
    super.key,
    required this.momentId,
    required this.studentName,
  });

  final String momentId;
  final String studentName;

  @override
  ConsumerState<RiskSignalDetailPage> createState() => _RiskSignalDetailPageState();
}

class _RiskSignalDetailPageState extends ConsumerState<RiskSignalDetailPage> {
  bool _dismissing = false;

  Future<void> _dismiss(CriticalRiskDetail detail) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认撤销危险标记？'),
        content: const Text('确认后该条将不再展示，并同步更新成长关注列表。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认撤销')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _dismissing = true);
    try {
      await ref.read(teacherRepositoryProvider).dismissRiskExposure(
            studentId: detail.studentId,
            momentId: detail.momentId,
          );
      invalidateRiskFollowState(ref, detail.momentId);
      ref.invalidate(growthArchiveProvider(detail.studentId));
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已撤销危险标记')),
        );
      }
    } finally {
      if (mounted) setState(() => _dismissing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const palette = defaultPalette;
    final async = ref.watch(criticalRiskDetailProvider(widget.momentId));

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: const Text(
                        '危险信号详情',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: async.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (d) => ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      IslandGlassCard(
                        palette: palette,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.studentName,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            if (d.className.isNotEmpty)
                              Text(d.className, style: const TextStyle(color: Color(0xFF8C7B6B))),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('yyyy年M月d日').format(DateTime.parse(d.reportDate)),
                              style: const TextStyle(fontSize: 13, color: Color(0xFF8C7B6B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      IslandGlassCard(
                        palette: palette,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '危险信号提醒',
                              style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFE65100)),
                            ),
                            const SizedBox(height: 8),
                            Text(d.riskReminder, style: const TextStyle(height: 1.4)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      IslandGlassCard(
                        palette: palette,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '故事内容',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              d.storyDetail,
                              style: const TextStyle(fontSize: 13, height: 1.45),
                            ),
                            const SizedBox(height: 12),
                            Text('情绪：${moodLabel(d.emotionTag)}'),
                            Text('分类：${d.categoryLabel}'),
                            if (d.detailTags.isNotEmpty)
                              Text('标签：${d.detailTags.join('、')}'),
                            if (d.companionDisplay.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Text(
                                '陪伴场景',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                d.companionDisplay,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: palette.primary.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            const Text(
                              '学生填写原文',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              d.note.isEmpty ? '（无文字备注）' : d.note,
                              style: const TextStyle(height: 1.55, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      IslandGlassCard(
                        palette: palette,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '关注记录',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: d.isFollowed
                                        ? const Color(0xFFE8F5E9)
                                        : const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    d.isFollowed ? '已关注' : '待关注',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: d.isFollowed
                                          ? const Color(0xFF2E7D32)
                                          : const Color(0xFFE65100),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (d.isFollowed && d.followNote != null && d.followNote!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(d.followNote!, style: const TextStyle(height: 1.45)),
                            ],
                            if (d.isFollowed && d.followedAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                '关注时间：${DateFormat('yyyy/M/d HH:mm').format(d.followedAt!.toLocal())}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF8C7B6B)),
                              ),
                            ],
                            if (!d.isFollowed)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                  '尚未记录教师关注内容',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF8C7B6B)),
                                ),
                              ),
                            const SizedBox(height: 10),
                            if (d.isFollowed)
                              TextButton(
                                onPressed: () => reactivateRiskFollow(
                                  ref,
                                  context: context,
                                  momentId: d.momentId,
                                ),
                                child: const Text('重新激活待关注'),
                              )
                            else
                              IslandPrimaryAction(
                                label: '标记已关注',
                                palette: palette,
                                onPressed: () => markRiskFollowed(
                                  ref,
                                  context: context,
                                  momentId: d.momentId,
                                  studentName: d.studentName,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (d.canDismiss) ...[
                        const SizedBox(height: 16),
                        RiskDismissLink(
                          loading: _dismissing,
                          onPressed: () => _dismiss(d),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

