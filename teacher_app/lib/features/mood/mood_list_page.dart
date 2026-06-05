import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/mood_catalog.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../design_system/island_date_picker.dart';
import '../../design_system/island_ui.dart';
import '../../providers/date_providers.dart';
import '../archive/growth_observation_archive_page.dart';

final moodReportsProvider = FutureProvider.autoDispose<List<TeacherMoodReport>>((ref) async {
  final date = ref.watch(moodSelectedDateProvider);
  return ref.read(teacherRepositoryProvider).listMoodReports(formatReportDate(date));
});

class MoodListPage extends ConsumerStatefulWidget {
  const MoodListPage({super.key});

  @override
  ConsumerState<MoodListPage> createState() => _MoodListPageState();
}

class _MoodListPageState extends ConsumerState<MoodListPage> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: ref.read(moodStudentSearchProvider));
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    ref.read(moodStudentSearchProvider.notifier).state = _searchCtrl.text.trim();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TeacherMoodReport> _filter(List<TeacherMoodReport> items, String query) {
    if (query.isEmpty) return items;
    final q = query.toLowerCase();
    return items
        .where((r) => (r.studentName ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    const palette = defaultPalette;
    final selected = ref.watch(moodSelectedDateProvider);
    final search = ref.watch(moodStudentSearchProvider);
    final async = ref.watch(moodReportsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: IslandDateSelector(
            palette: palette,
            selected: selected,
            label: '查看日期',
            onChanged: (d) => ref.read(moodSelectedDateProvider.notifier).state = d,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            _dateTitle(selected),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '输入学生姓名快速筛选',
              prefixIcon: Icon(Icons.search_rounded, color: palette.primary),
              suffixIcon: search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(moodStudentSearchProvider.notifier).state = '';
                      },
                    )
                  : null,
              filled: true,
              fillColor: palette.card.withValues(alpha: 0.92),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: palette.accent.withValues(alpha: 0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: palette.accent.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: palette.primary, width: 1.5),
              ),
            ),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (items) {
              final filtered = _filter(items, search);
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inbox_rounded, size: 48, color: Color(0xFF8C7B6B)),
                        const SizedBox(height: 12),
                        Text(
                          '所选日期暂无学生完成心情上报',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.brown.shade400),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    '没有匹配「$search」的学生',
                    style: TextStyle(color: Colors.brown.shade400),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(moodReportsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: filtered.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          '${DateFormat('M月d日').format(selected)} · '
                          '${search.isEmpty ? '共 ${items.length} 人已上报' : '筛选 ${filtered.length}/${items.length} 人'}',
                          style: const TextStyle(color: Color(0xFF8C7B6B), fontSize: 13),
                        ),
                      );
                    }
                    final report = filtered[index - 1];
                    return _MoodCard(report: report, palette: palette);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _dateTitle(DateTime d) {
    if (isToday(d)) return '今日班级心情';
    if (isYesterday(d)) return '昨日班级心情';
    return '${DateFormat('M月d日').format(d)}班级心情';
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.report, required this.palette});

  final TeacherMoodReport report;
  final MoodPalette palette;

  @override
  Widget build(BuildContext context) {
    final mood = dominantMoodLabel(report.moodCounts);
    final time = report.uploadedAt != null
        ? DateFormat('HH:mm').format(report.uploadedAt!.toLocal())
        : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          final id = report.studentId;
          if (id == null || id.isEmpty) return;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GrowthObservationArchivePage(
                studentId: id,
                studentName: report.studentName ?? '学生',
              ),
            ),
          );
        },
        child: IslandGlassCard(
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.studentName ?? '学生',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: concernColor(report.concernLevel).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      concernBadge(report.concernLevel),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: concernColor(report.concernLevel),
                      ),
                    ),
                  ),
                ],
              ),
              if (report.className != null) ...[
                const SizedBox(height: 4),
                Text(report.className!, style: const TextStyle(fontSize: 13, color: Color(0xFF8C7B6B))),
              ],
              const SizedBox(height: 8),
              Text(
                '$mood · 共 ${report.momentCount} 条${time.isNotEmpty ? ' · $time 上报' : ''}',
                style: const TextStyle(fontSize: 14),
              ),
              if (report.fuzzyAnalysis.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  report.fuzzyAnalysis,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF8C7B6B)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
