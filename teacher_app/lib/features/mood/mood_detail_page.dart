import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/mood_catalog.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../design_system/island_ui.dart';
import '../../providers/growth_providers.dart';

class MoodDetailPage extends ConsumerWidget {
  const MoodDetailPage({super.key, required this.report});

  final TeacherMoodReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const palette = defaultPalette;
    final uploaded = report.uploadedAt != null
        ? DateFormat('HH:mm').format(report.uploadedAt!.toLocal())
        : '—';
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
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        report.studentName ?? '学生',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    IslandGlassCard(
                      palette: palette,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (report.className != null)
                            Text(report.className!, style: const TextStyle(color: Color(0xFF8C7B6B))),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: concernColor(report.concernLevel).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  concernBadge(report.concernLevel),
                                  style: TextStyle(
                                    color: concernColor(report.concernLevel),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('共 ${report.momentCount} 条 · $uploaded 上报'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '主情绪：${dominantMoodLabel(report.moodCounts)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(report.fuzzyAnalysis, style: const TextStyle(height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('情绪分布', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    IslandGlassCard(
                      palette: palette,
                      child: Column(
                        children: moods.map((m) {
                          final n = report.moodCounts[m.id] ?? 0;
                          final total = report.momentCount.clamp(1, 9999);
                          final ratio = n / total;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 56,
                                  child: Text(m.label, style: TextStyle(color: m.color, fontWeight: FontWeight.w600)),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: ratio.clamp(0.0, 1.0),
                                      minHeight: 8,
                                      backgroundColor: m.color.withValues(alpha: 0.12),
                                      color: m.color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('$n'),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (report.categoryBreakdown.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('成长分类', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 8),
                      IslandGlassCard(
                        palette: palette,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: report.categoryBreakdown.entries
                              .map(
                                (e) => Chip(
                                  label: Text('${e.key} ${e.value}'),
                                  backgroundColor: palette.primaryContainer,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                    if (report.attentionHighlights.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('观察要点', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 8),
                      IslandGlassCard(
                        palette: palette,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: report.attentionHighlights
                              .map((h) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('· '),
                                        Expanded(child: Text(h)),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                    if (report.riskFlags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      IslandGlassCard(
                        palette: palette,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '风险摘要（脱敏）',
                              style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFE53935)),
                            ),
                            const SizedBox(height: 8),
                            ...report.riskFlags.map((f) => Text('• $f')),
                          ],
                        ),
                      ),
                    ],
                    if (report.riskExposures.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        '危险信号复核',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFFE65100)),
                      ),
                      const SizedBox(height: 8),
                      ...report.riskExposures.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: IslandGlassCard(
                            palette: palette,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '以下为检测到危险信号时的学生原文，仅供二次确认：',
                                  style: TextStyle(fontSize: 12, color: Colors.brown.shade400),
                                ),
                                const SizedBox(height: 8),
                                Text(r.note, style: const TextStyle(height: 1.4)),
                                if (r.canDismiss && report.studentId != null) ...[
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('确认撤销危险标记？'),
                                          content: const Text('确认后备注不再展示，并同步更新成长观察。'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('取消'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('确认撤销'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (ok != true) return;
                                      await ref.read(teacherRepositoryProvider).dismissRiskExposure(
                                            studentId: report.studentId!,
                                            momentId: r.momentId,
                                          );
                                      ref.invalidate(criticalRiskListProvider);
                                      ref.invalidate(pendingGrowthFocusCountProvider);
                                      await ref.read(criticalRiskListProvider.future);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('已撤销危险标记')),
                                        );
                                        Navigator.pop(context);
                                      }
                                    },
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                    label: const Text('非危险信号，撤销标记'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      '说明：平时不可见学生原文备注；仅危险信号时展示上文供复核。风险标签为脱敏摘要。',
                      style: TextStyle(fontSize: 12, color: Colors.brown.shade300),
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
