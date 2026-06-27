import 'package:flutter/material.dart';

import '../../../core/constants/emotion_catalog.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../core/utils/mood_stats.dart';
import '../../../data/models/profile_models.dart';
import '../../../design_system/island_decorations.dart';
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
        if (emotionFilterId != null)
          _FilteredEmotionHighlightCard(
            palette: palette,
            emotion: emotionById(emotionFilterId),
            count: counts[emotionFilterId] ?? 0,
            showMoodFaces: showMoodFaces,
            gender: gender,
          )
        else
          ...emotionStatsCatalog().map((emotion) {
            final count = counts[emotion.id] ?? 0;
            final pct = total == 0 ? 0 : (count / total * 100).round();
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
                    width: 40,
                    child: Text(
                      '$count 条',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: emotion.color.withValues(alpha: 0.85),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 56,
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
                        value: total == 0 ? 0 : count / total,
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

/// 感受筛选激活时：仅展示当前感受，放大头像与条数。
class _FilteredEmotionHighlightCard extends StatelessWidget {
  const _FilteredEmotionHighlightCard({
    required this.palette,
    required this.emotion,
    required this.count,
    required this.showMoodFaces,
    this.gender,
  });

  final MoodPalette palette;
  final EmotionDefinition emotion;
  final int count;
  final bool showMoodFaces;
  final String? gender;

  static const _avatarSize = 76.0;

  @override
  Widget build(BuildContext context) {
    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Container(
            width: _avatarSize,
            height: _avatarSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: emotion.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: emotion.color.withValues(alpha: 0.28),
                width: 1.2,
              ),
            ),
            child: showMoodFaces
                ? MoodFaceIcon(
                    type: emotion.faceType,
                    color: emotion.color,
                    size: _avatarSize * 0.72,
                    strokeWidth: 2.2,
                    moodId: emotion.id,
                    gender: gender,
                  )
                : Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: emotion.color,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              emotion.label,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: emotion.color,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: palette.primaryContainer.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: palette.accent.withValues(alpha: 0.22),
              ),
            ),
            child: Text(
              '$count 条',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: palette.accent,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
