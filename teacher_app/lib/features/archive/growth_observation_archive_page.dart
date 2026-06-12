import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/growth_categories.dart';
import '../../core/constants/mood_catalog.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../design_system/growth_observation_report_card.dart';
import '../../design_system/growth_widgets.dart';
import '../../design_system/growth_trend_chart.dart';
import '../../design_system/island_ui.dart';
import '../../design_system/mood_face_icon.dart';
import '../../design_system/risk_dismiss_link.dart';
import '../../data/models/critical_risk.dart';
import '../../data/models/growth_observation.dart';
import '../../providers/growth_providers.dart';

class GrowthObservationArchivePage extends ConsumerStatefulWidget {
  const GrowthObservationArchivePage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  final String studentId;
  final String studentName;

  @override
  ConsumerState<GrowthObservationArchivePage> createState() =>
      _GrowthObservationArchivePageState();
}

class _GrowthObservationArchivePageState extends ConsumerState<GrowthObservationArchivePage>
    with SingleTickerProviderStateMixin {
  String? _dismissingMomentId;
  static const _dangerTabIds = ['all', '学习', '朋友', '运动', '家庭', '兴趣', '其它'];
  late TabController _dangerTabCtrl;

  @override
  void initState() {
    super.initState();
    _dangerTabCtrl = TabController(length: _dangerTabIds.length, vsync: this);
  }

  @override
  void dispose() {
    _dangerTabCtrl.dispose();
    super.dispose();
  }

  List<String> _growthFocusTags(GrowthArchive archive) {
    if (archive.insight.focusDirections.isNotEmpty) {
      return archive.insight.focusDirections;
    }
    return archive.attentionTags
        .map((t) => t.count > 1 ? '${t.label} ×${t.count}' : t.label)
        .toList();
  }

  List<({String date, DangerSignalRecord record})> _flattenDangerRecords(
    GrowthArchive archive,
    String categoryFilter,
  ) {
    final out = <({String date, DangerSignalRecord record})>[];
    for (final day in archive.dailyRecords) {
      for (final r in _filterDangerRecords(day.dangerRecords, categoryFilter)) {
        out.add((date: day.date, record: r));
      }
    }
    return out;
  }

  Future<void> _dismissRisk(String momentId) async {
    setState(() => _dismissingMomentId = momentId);
    try {
      await ref.read(teacherRepositoryProvider).dismissRiskExposure(
            studentId: widget.studentId,
            momentId: momentId,
          );
      ref.invalidate(growthArchiveProvider(widget.studentId));
      ref.invalidate(criticalRiskListProvider);
      ref.invalidate(pendingGrowthFocusCountProvider);
      await ref.read(criticalRiskListProvider.future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已撤销危险标记，该日危险记录已移除')),
        );
      }
    } finally {
      if (mounted) setState(() => _dismissingMomentId = null);
    }
  }

  Widget _buildDangerRecord(MoodPalette palette, DangerSignalRecord r, {String? dateLabel}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1).withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dateLabel != null)
                        Text(
                          dateLabel,
                          style: TextStyle(fontSize: 11, color: palette.primary, fontWeight: FontWeight.w600),
                        ),
                      Text(
                        r.storyDetail,
                        style: const TextStyle(fontWeight: FontWeight.w600, height: 1.45, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${r.categoryLabel} · ${moodLabel(r.emotionTag)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF8C7B6B)),
            ),
            if (r.canDismiss) ...[
              const SizedBox(height: 4),
              RiskDismissLink(
                alignment: Alignment.centerRight,
                loading: _dismissingMomentId == r.momentId,
                label: '非危险信号，撤销标记',
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('确认撤销危险标记？'),
                      content: const Text('撤销后该条将不再展示。'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认撤销')),
                      ],
                    ),
                  );
                  if (ok == true) await _dismissRisk(r.momentId);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDangerSignalsSection(
    GrowthArchive archive,
    String categoryFilter,
    MoodPalette palette,
  ) {
    final tabIndex = _dangerTabIds.indexOf(categoryFilter).clamp(0, _dangerTabIds.length - 1);
    if (_dangerTabCtrl.index != tabIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _dangerTabCtrl.index != tabIndex) {
          _dangerTabCtrl.animateTo(tabIndex);
        }
      });
    }

    final tabLabels = [
      '全部',
      ...growthCategories.map((c) => c.label),
    ];
    final items = _flattenDangerRecords(archive, categoryFilter);

    return IslandGlassCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 20),
              SizedBox(width: 8),
              Text('危险信号', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          TabBar(
            controller: _dangerTabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 10),
            dividerHeight: 0,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            labelColor: palette.primary,
            unselectedLabelColor: const Color(0xFF8C7B6B),
            indicatorColor: palette.primary,
            onTap: (i) => ref
                .read(archiveCategoryFilterProvider(widget.studentId).notifier)
                .state = _dangerTabIds[i],
            tabs: [for (final l in tabLabels) Tab(text: l)],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '该分类下暂无危险信号记录',
                style: TextStyle(fontSize: 13, color: Color(0xFF8C7B6B)),
              ),
            )
          else
            ...items.map(
              (e) => _buildDangerRecord(
                palette,
                e.record,
                dateLabel: _formatDayLabel(e.date),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDayLabel(String iso) {
    final p = DateTime.tryParse(iso);
    if (p == null) return iso;
    return DateFormat('yyyy年M月d日').format(p);
  }

  List<DangerSignalRecord> _filterDangerRecords(
    List<DangerSignalRecord> records,
    String categoryFilter,
  ) {
    if (categoryFilter == 'all') return records;
    return records.where((e) => e.categoryTag == categoryFilter).toList();
  }

  Map<String, int> _moodStatsForFilter(GrowthArchive archive, String categoryFilter) {
    final byCat = archive.moodCountsByCategory;
    if (byCat.isNotEmpty) {
      return byCat[categoryFilter] ?? byCat['all'] ?? archive.moodCounts;
    }
    return archive.moodCounts;
  }

  Widget _buildArchiveDaysFilter(MoodPalette palette, int days) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final d in const [3, 5, 7, 14, 30])
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: IslandChipToggle(
                  label: '近$d天',
                  selected: days == d,
                  palette: palette,
                  compact: true,
                  onTap: () => ref
                      .read(archiveTrendDaysProvider(widget.studentId).notifier)
                      .state = d,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const palette = defaultPalette;
    final days = ref.watch(archiveTrendDaysProvider(widget.studentId));
    final categoryFilter = ref.watch(archiveCategoryFilterProvider(widget.studentId));
    final async = ref.watch(growthArchiveProvider(widget.studentId));

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.studentName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const Text(
                            '成长观察档案',
                            style: TextStyle(fontSize: 11, color: Color(0xFF8C7B6B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildArchiveDaysFilter(palette, days),
              Expanded(
                child: async.when(
                  skipLoadingOnReload: true,
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (archive) => RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(growthArchiveProvider(widget.studentId)),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        IslandGlassCard(
                          palette: palette,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI成长总结',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                archive.aiSummary,
                                style: const TextStyle(fontSize: 13, height: 1.45),
                              ),
                            ],
                          ),
                        ),
                        if (archive.observation != null) ...[
                          const SizedBox(height: 12),
                          GrowthObservationReportCard(
                            observation: archive.observation!,
                            palette: palette,
                          ),
                        ],
                        const SizedBox(height: 12),
                        IslandGlassCard(
                          palette: palette,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '成长趋势',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '近$days天 · 情绪正向指数',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: palette.accent.withValues(alpha: 0.55),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TrendIndicator(trend: trendFromTrendPoints(archive.trendPoints)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              GrowthTrendChart(
                                points: archive.trendPoints,
                                palette: palette,
                                metricLabel: archive.trendMetricLabel.isNotEmpty
                                    ? archive.trendMetricLabel
                                    : '情绪正向指数（越高表示积极情绪占比越高，范围 0–1）',
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
                                '成长分类',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  IslandChipToggle(
                                    label: '全部',
                                    selected: categoryFilter == 'all',
                                    palette: palette,
                                    onTap: () => ref
                                        .read(archiveCategoryFilterProvider(widget.studentId).notifier)
                                        .state = 'all',
                                  ),
                                  for (final c in growthCategories)
                                    IslandChipToggle(
                                      label: c.label,
                                      selected: categoryFilter == c.id,
                                      palette: palette,
                                      onTap: () => ref
                                          .read(archiveCategoryFilterProvider(widget.studentId).notifier)
                                          .state = c.id,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Builder(
                                builder: (context) {
                                  final moodStats = _moodStatsForFilter(archive, categoryFilter);
                                  final total = moodStats.values.fold<int>(0, (a, b) => a + b);
                                  final maxForBar = total > 0 ? total : 1;
                                  return Column(
                                    children: moods.map((m) {
                                      final n = moodStats[m.id] ?? 0;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          children: [
                                            MoodFaceIcon(moodId: m.id, size: 32),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 40,
                                              child: Text(
                                                m.label,
                                                style: TextStyle(
                                                  color: m.color,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: LinearProgressIndicator(
                                                value: n / maxForBar,
                                                minHeight: 8,
                                                backgroundColor: m.color.withValues(alpha: 0.12),
                                                color: m.color,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 28,
                                              child: Text(
                                                '$n',
                                                textAlign: TextAlign.end,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: n > 0 ? m.color : const Color(0xFF8C7B6B),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        if (_growthFocusTags(archive).isNotEmpty) ...[
                          const SizedBox(height: 12),
                          IslandGlassCard(
                            palette: palette,
                            child: FocusTagChips(
                              tags: _growthFocusTags(archive),
                              palette: palette,
                              label: '成长关注点',
                            ),
                          ),
                        ],
                        if (archive.insight.riskLevel == 'critical' &&
                            archive.insight.riskReminder != null) ...[
                          const SizedBox(height: 12),
                          IslandGlassCard(
                            palette: palette,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '风险提醒',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFE65100)),
                                ),
                                const SizedBox(height: 8),
                                RiskReminderStrip(
                                  message: archive.insight.riskReminder!,
                                  palette: palette,
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildDangerSignalsSection(archive, categoryFilter, palette),
                      ],
                    ),
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
