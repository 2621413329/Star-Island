import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/emotion_catalog.dart';
import '../../../core/models/user_companion.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../core/utils/moment_highlight.dart';
import '../../../core/utils/moment_tags.dart';
import '../../../core/utils/story_island_visual.dart';
import '../../../data/models/profile_models.dart';
import '../../../data/models/story_island_models.dart';
import '../../../design_system/healing_jelly_button.dart';
import '../../../design_system/home_theme.dart';
import '../../../design_system/user_companion_view.dart';
import '../../../providers/app_providers.dart';

/// 首页故事流：今日小确幸 / 昨日回响 / 旧日拾光。
class TodayStoryList extends ConsumerWidget {
  const TodayStoryList({
    super.key,
    required this.moments,
    required this.storyGroups,
    required this.palette,
    required this.onAllRecordsTap,
    required this.onStoryTap,
  });

  final List<DailyMomentModel> moments;
  final List<StoryIslandCategoryModel> storyGroups;
  final MoodPalette palette;
  final VoidCallback onAllRecordsTap;
  final void Function(DailyMomentModel moment) onStoryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(profileProvider).valueOrNull?.userId;
    final today = pickHighlightMoment(moments);
    final yesterday = pickYesterdayMoment(moments);
    final oldMemory = pickRandomOldMoment(moments, seed: userId);
    final tone = HealingJellyTone.fromPalette(palette);
    final companion = ref.watch(userCompanionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '故事拾光',
                style: appTextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: HomeTheme.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: onAllRecordsTap,
              child: Text(
                '全部记录 >',
                style: appTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.accent,
                ),
              ),
            ),
          ],
        ),
        _StoryFeedSection(
          title: '今日小确幸',
          emptyHint: '今天还没有故事。一个瞬间，就足够让世界开始生长。',
          moment: today,
          storyGroups: storyGroups,
          palette: palette,
          tone: tone,
          companion: companion,
          onTap: today == null ? null : () => onStoryTap(today),
        ),
        const SizedBox(height: 12),
        _StoryFeedSection(
          title: '昨日回响',
          emptyHint: '昨天还没有留下故事。',
          moment: yesterday,
          storyGroups: storyGroups,
          palette: palette,
          tone: tone,
          companion: companion,
          onTap: yesterday == null ? null : () => onStoryTap(yesterday),
        ),
        const SizedBox(height: 12),
        _StoryFeedSection(
          title: '旧日拾光',
          emptyHint: '更早的故事还在等你翻开。',
          moment: oldMemory,
          storyGroups: storyGroups,
          palette: palette,
          tone: tone,
          companion: companion,
          onTap: oldMemory == null ? null : () => onStoryTap(oldMemory),
        ),
      ],
    );
  }
}

class _StoryFeedSection extends StatelessWidget {
  const _StoryFeedSection({
    required this.title,
    required this.emptyHint,
    required this.moment,
    required this.storyGroups,
    required this.palette,
    required this.tone,
    required this.companion,
    this.onTap,
  });

  final String title;
  final String emptyHint;
  final DailyMomentModel? moment;
  final List<StoryIslandCategoryModel> storyGroups;
  final MoodPalette palette;
  final HealingJellyTone tone;
  final UserCompanion companion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: appTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: HomeTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        if (moment == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: HomeTheme.card,
              borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
              boxShadow: const [HomeTheme.cardShadow],
            ),
            child: Text(
              emptyHint,
              style: appTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: HomeTheme.textSecondary,
                height: 1.45,
              ),
            ),
          )
        else
          _HighlightMomentCard(
            moment: moment!,
            storyGroups: storyGroups,
            palette: palette,
            tone: tone,
            companion: companion,
            onTap: onTap!,
          ),
      ],
    );
  }
}

class _HighlightMomentCard extends StatelessWidget {
  const _HighlightMomentCard({
    required this.moment,
    required this.storyGroups,
    required this.palette,
    required this.tone,
    required this.companion,
    required this.onTap,
  });

  final DailyMomentModel moment;
  final List<StoryIslandCategoryModel> storyGroups;
  final MoodPalette palette;
  final HealingJellyTone tone;
  final UserCompanion companion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final emotion = effectiveEmotionForMoment(moment);
    final category = storyIslandCategoryForMoment(moment, groups: storyGroups);
    final iconColor = storyIslandCategoryColor(
      category,
      fallback: palette.accent,
    );
    final title = _storyTitle(moment);
    final islandLabel = storyIslandDisplayLabel(moment, groups: storyGroups);
    final timeLabel =
        DateFormat('MM-dd HH:mm').format(moment.createdAt.toLocal());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
            boxShadow: const [HomeTheme.cardShadow],
          ),
          child: HealingSparkleBackground(
            tone: tone,
            borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        iconColor.withValues(alpha: 0.30),
                        iconColor.withValues(alpha: 0.12),
                      ],
                    ),
                  ),
                  child: Icon(
                    storyIslandCategoryIcon(
                      category?.id ?? '',
                      fallbackIcon: category?.icon,
                    ),
                    color: iconColor.withValues(alpha: 0.92),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: appTextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: HomeTheme.textPrimary,
                                height: 1.32,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            timeLabel,
                            style: appTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: HomeTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: emotion.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              emotion.label,
                              style: appTextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: emotion.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            storyIslandCategoryIcon(
                              category?.id ?? '',
                              fallbackIcon: category?.icon,
                            ),
                            size: 13,
                            color: iconColor.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              islandLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: appTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: HomeTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: UserCompanionView(
                    companion: companion,
                    size: 44,
                    showAura: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _storyTitle(DailyMomentModel moment) {
    final note = momentStoryNote(moment);
    if (note.isNotEmpty) return note;
    return momentDisplayTitle(moment);
  }
}
