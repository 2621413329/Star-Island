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

const _sheetHeightFactor = 2 / 3;
const _closeDragThreshold = 120.0;

/// 查询当前副岛全部日常（星屿会员），按日期倒序展示。
/// 交互与书写日常一致：半透明遮罩 + 底部面板 + 下拉/点遮罩关闭。
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

  await Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => _StoryIslandMomentsPage(
        island: island,
        palette: palette,
      ),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity:
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        );
      },
    ),
  );
}

class _StoryIslandMomentsPage extends ConsumerStatefulWidget {
  const _StoryIslandMomentsPage({
    required this.island,
    required this.palette,
  });

  final StoryIslandModel island;
  final MoodPalette palette;

  @override
  ConsumerState<_StoryIslandMomentsPage> createState() =>
      _StoryIslandMomentsPageState();
}

class _StoryIslandMomentsPageState
    extends ConsumerState<_StoryIslandMomentsPage> {
  double _handleDragOffset = 0;

  void _close() {
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  void _onHandleDragUpdate(DragUpdateDetails details) {
    _handleDragOffset += details.delta.dy;
    if (_handleDragOffset < 0) _handleDragOffset = 0;
  }

  void _onHandleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_handleDragOffset > _closeDragThreshold || velocity > 850) {
      _close();
    }
    _handleDragOffset = 0;
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final island = widget.island;
    final momentsAsync = ref.watch(recentStoryMomentsProvider);
    final companion = ref.watch(userCompanionProvider);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final sheetHeight = screenHeight * _sheetHeightFactor;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.35),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                behavior: HitTestBehavior.opaque,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: sheetHeight,
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  elevation: 0,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  clipBehavior: Clip.antiAlias,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          palette.gradientStart,
                          palette.gradientEnd,
                          Colors.white,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragUpdate: _onHandleDragUpdate,
                          onVerticalDragEnd: _onHandleDragEnd,
                          child: _SheetHeader(
                            island: island,
                            palette: palette,
                            onClose: _close,
                          ),
                        ),
                        Expanded(
                          child: momentsAsync.when(
                            loading: () => Center(
                              child: CircularProgressIndicator(
                                color: palette.accent,
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
                                    (m) =>
                                        momentBelongsToStoryIsland(m, island.id),
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
                                physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  4,
                                  16,
                                  20 + bottomInset,
                                ),
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
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.island,
    required this.palette,
    required this.onClose,
  });

  final StoryIslandModel island;
  final MoodPalette palette;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final levelLabel = storyIslandLevelBadge(island);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 28,
              alignment: Alignment.center,
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
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
                onPressed: onClose,
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
        mainAxisAlignment: MainAxisAlignment.center,
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
