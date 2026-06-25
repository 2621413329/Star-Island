import 'package:flutter/material.dart';

import '../../../core/constants/emotion_catalog.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../core/utils/mood_stats.dart';
import '../../../data/models/profile_models.dart';
import '../../../design_system/mood_face_icon.dart';

/// 感受统计 Tab：按 AI 感受展示占比条。
class MoodStatsTab extends StatelessWidget {
  const MoodStatsTab({
    super.key,
    required this.palette,
    required this.periodLabel,
    required this.filterLabel,
    required this.moments,
    required this.categoryFilter,
    required this.showMoodFaces,
    this.emotionFilterId,
    this.gender,
    this.moodCountsOverride,
    this.totalOverride,
  });

  final MoodPalette palette;
  final String periodLabel;
  final String filterLabel;
  final List<DailyMomentModel> moments;
  final String? categoryFilter;
  final String? emotionFilterId;
  final bool showMoodFaces;
  final String? gender;
  final Map<String, int>? moodCountsOverride;
  final int? totalOverride;

  @override
  Widget build(BuildContext context) {
    final counts = moodCountsOverride ??
        moodCountsForMoments(
          moments,
          categoryLabel: categoryFilter,
          emotionFilterId: emotionFilterId,
        );
    final total = totalOverride ??
        moodTotalForFilter(
          moments,
          categoryLabel: categoryFilter,
          emotionFilterId: emotionFilterId,
        );
    final entries = emotionStatsCatalog();

    final itemCount = isPaginated ? total : sorted.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$periodLabel感受 · $filterLabel',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '共 $total 条感受记录',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF8C7B6B),
          ),
        ),
        const SizedBox(height: 16),
        ...entries.map((emotion) {
          final count = counts[emotion.id] ?? 0;
          final pct = (count / total * 100).round();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                if (showMoodFaces)
                  MoodFaceIcon(
                    type: emotion.faceType,
                    color: emotion.color,
                    size: 28,
                    strokeWidth: 2,
                    moodId: emotion.id,
                    gender: gender,
                  )
                else
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: emotion.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: Text(
                    emotion.label,
                    style: TextStyle(
                      color: emotion.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: count / total,
                      minHeight: 10,
                      backgroundColor: palette.primaryContainer,
                      color: emotion.color.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$pct%', style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
