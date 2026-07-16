import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/user_companion.dart';
import '../../../core/membership/vip_guard.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../core/utils/moment_date_groups.dart';
import '../../../core/utils/story_island_visual.dart';
import '../../../data/models/profile_models.dart';
import '../../../data/models/story_island_models.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/member_provider.dart';
import '../../today/moment_detail_page.dart';
import '../../today/today_story_card.dart';
import '../story_island_progress.dart';

/// 查询当前副岛全部日常（星屿会员），按日期倒序展示。
Future<void> showStoryIslandMomentsDialog({
  required BuildContext context,
  required WidgetRef ref,
  required StoryIslandModel island,
  required MoodPalette palette,
}) async {
  if (!ref.read(isVipProvider)) {
    await showVipRequiredDialog(
      context,
      title: '星屿会员 · 成长足迹',
      message: '开通星屿会员后，可回顾本岛全部成长日常，'
          '见证岛屿随你的记录一点点长大。',
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _StoryIslandMomentsSheet(
      island: island,
      palette: palette,
    ),
  );
}

class _StoryIslandMomentsSheet extends ConsumerWidget {
  const _StoryIslandMomentsSheet({
    required this.island,
    required this.palette,
  });

  final StoryIslandModel island;
  final MoodPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentsAsync = ref.watch(recentStoryMomentsProvider);
    final companion = ref.watch(userCompanionProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom > 0 ? 0 : 8),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      palette.gradientStart,
                      palette.gradientEnd,
                      Colors.white,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SheetHeader(island: island, palette: palette),
                    Flexible(
                      child: momentsAsync.when(
                        loading: () => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: palette.accent,
                            ),
                          ),
                        ),
                        error: (_, __) => _EmptyHint(
                          palette: palette,
                          title: '暂时无法加载成长记录',
                          subtitle: '请稍后再试，你的岛屿故事不会丢失',
                        ),
                        data: (all) {
                          final filtered = all
                              .where(
                                (m) => momentBelongsToStoryIsland(m, island.id),
                              )
                              .toList();
                          if (filtered.isEmpty) {
                            return _EmptyHint(
                              palette: palette,
                              title: '这里还等待着你的第一段成长故事',
                              subtitle: '为「${island.name}」记下日常，'
                                  '岛屿会随你的坚持慢慢长大',
                            );
                          }
                          final groups = groupMomentsByDate(filtered);
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                            itemCount: groups.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, gi) {
                              final group = groups[gi];
                              return _DateGroupSection(
                                group: group,
                                palette: palette,
                                companion: companion,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.island,
    required this.palette,
  });

  final StoryIslandModel island;
  final MoodPalette palette;

  @override
  Widget build(BuildContext context) {
    final levelLabel = island.currentLevel <= 0
        ? 'Lv.0'
        : storyIslandLevelLabel(island);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      palette.accent.withValues(alpha: 0.35),
                      palette.accent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: palette.accent.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${island.name} · 成长足迹',
                      style: appTextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: palette.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$levelLabel · 已记录 ${island.storyCount} 段日常 · '
                      '成长值 ${island.growthValue}',
                      style: appTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: palette.primary.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: palette.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateGroupSection extends StatelessWidget {
  const _DateGroupSection({
    required this.group,
    required this.palette,
    required this.companion,
  });

  final MomentDateGroup group;
  final MoodPalette palette;
  final UserCompanion companion;

  @override
  Widget build(BuildContext context) {
    final dateDetail = DateFormat('yyyy年M月d日', 'zh_CN').format(group.date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: palette.accent,
            ),
            const SizedBox(width: 6),
            Text(
              group.label,
              style: appTextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: palette.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dateDetail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: appTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.primary.withValues(alpha: 0.45),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${group.moments.length} 条',
                style: appTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: palette.primary.withValues(alpha: 0.72),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < group.moments.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          TodayStoryCard(
            moment: group.moments[i],
            companion: companion,
            palette: palette,
            readOnly: true,
            companionAlwaysVisible: false,
            headerMetaLabel: _momentDateMeta(group.moments[i], group),
            onViewDetail: () {
              Navigator.pop(context);
              openMomentDetailPage(context, moment: group.moments[i]);
            },
            onPlay: () {},
          ),
        ],
      ],
    );
  }

  String _momentDateMeta(DailyMomentModel moment, MomentDateGroup group) {
    if (group.moments.length <= 1) {
      return group.label;
    }
    return '${group.label} · ${formatMomentRecordTime(moment)}';
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.palette,
    required this.title,
    required this.subtitle,
  });

  final MoodPalette palette;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.spa_outlined,
            size: 48,
            color: palette.accent.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: appTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: palette.primary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: appTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: palette.primary.withValues(alpha: 0.58),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
