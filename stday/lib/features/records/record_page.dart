import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/layout/app_layout.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/models/profile_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/growth_reward_dialog.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../providers/app_providers.dart';
import '../../providers/growth_observation_provider.dart';
import '../../providers/story_day_provider.dart';
import '../today/add_moment_flow.dart';
import '../today/voice_analysis_poll.dart';
import '../today/edit_moment_sheet.dart';
import '../today/moment_detail_page.dart';
import '../today/mood_today_card.dart';
import '../today/today_story_card.dart';
import '../today/widgets/story_day_filter_bar.dart';
import '../today/widgets/story_day_picker_sheet.dart';
import 'widgets/weekly_observation_card.dart';

/// 今日日常列表页（从原 TodayStoriesPage 拆分，不含岛屿）。
class RecordPage extends ConsumerStatefulWidget {
  const RecordPage({super.key});

  @override
  ConsumerState<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends ConsumerState<RecordPage> {
  static const double _bottomActionBarHeight = 68;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(storyDayViewProvider.notifier).refresh();
    });
  }

  Future<void> _refreshStories() async {
    await ref.read(storyDayViewProvider.notifier).refresh();
    await ref.read(todayMomentsProvider.notifier).refresh();
    ref.invalidate(growthSummaryProvider);
    ref.invalidate(weeklySummaryProvider);
  }

  Future<void> _openAddPastRoutine({
    required StoryDayViewState view,
    required bool viewingToday,
    required MoodPalette palette,
  }) async {
    final companion = ref.read(userCompanionProvider);
    DateTime? targetDay;
    if (viewingToday) {
      final yesterday = calendarDate(DateTime.now()).subtract(const Duration(days: 1));
      targetDay = await showStoryDayPickerSheet(
        context: context,
        palette: palette,
        selectedDay: yesterday,
        recordedDays: view.recordedDays,
        moodByDayIso: view.moodByDayIso,
        gender: companion.gender,
        allowAnyPastDay: true,
      );
      if (targetDay == null || !mounted) return;
    } else {
      targetDay = calendarDate(view.selectedDay);
    }

    final growthBefore = await fetchCurrentGrowthSummary(ref);
    if (!mounted) return;
    final saved = await showAddMomentFlow(
      context,
      ref,
      targetDay: targetDay,
    );
    if (!mounted) return;
    if (saved == true) {
      ref.read(selectedStoryDayProvider.notifier).state = calendarDate(targetDay);
      await _refreshStories();
      if (!mounted) return;
      await showGrowthRewardsAfterAction(context, ref, before: growthBefore);
    }
  }

  Future<void> _openAdd() async {
    if (!isCalendarToday(ref.read(selectedStoryDayProvider))) return;
    final growthBefore = await fetchCurrentGrowthSummary(ref);
    if (!mounted) return;
    await showAddMomentFlow(context, ref);
    if (!mounted) return;
    await _refreshStories();
    if (!mounted) return;
    await showGrowthRewardsAfterAction(context, ref, before: growthBefore);
  }

  Future<void> _openEdit(DailyMomentModel moment) async {
    final saved = await showEditMomentSheet(context, ref, moment: moment);
    if (saved == true && mounted) {
      await _refreshStories();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日常已更新')),
      );
    }
  }

  Future<void> _confirmDelete(DailyMomentModel moment) async {
    final id = moment.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这条日常？'),
        content: const Text('删除后，这条日常将从你的记录中移除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final viewingToday =
        isCalendarToday(ref.read(selectedStoryDayProvider));
    try {
      await ref.read(appRepositoryProvider).deleteMoment(id);
      await _refreshStories();
      if (viewingToday) {
        await ref.read(todayMomentsProvider.notifier).refresh();
      } else {
        ref.invalidate(todayMomentsProvider);
      }
      ref.invalidate(growthSummaryProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除日常')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final storyAsync = ref.watch(storyDayViewProvider);
    final selectedDay = ref.watch(selectedStoryDayProvider);
    final viewingToday = isCalendarToday(selectedDay);
    final palette = ref.watch(moodPaletteProvider);

    return VoiceAnalysisPollHost(
      child: storyAsync.when(
        loading: () => _buildBody(
          view: StoryDayViewState.initial(day: selectedDay),
          profile: profile,
          viewingToday: viewingToday,
          palette: palette,
          showTopLoader: true,
        ),
        error: (e, _) => IslandScaffold(
          palette: palette,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppLayout.pageHorizontal),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('加载失败：$e', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  IslandPrimaryAction(
                    label: '重试',
                    palette: palette,
                    onPressed: () => ref.invalidate(storyDayViewProvider),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (view) => _buildBody(
          view: view,
          profile: profile,
          viewingToday: viewingToday,
          palette: palette,
        ),
      ),
    );
  }

  Widget _buildBody({
    required StoryDayViewState view,
    required UserProfileModel? profile,
    required bool viewingToday,
    required MoodPalette palette,
    bool showTopLoader = false,
  }) {
    final moments = view.moments;
    final dayMoodId = view.moodForDay(view.selectedDay) ??
        resolveStoryDayMoodId(
          viewingToday: viewingToday,
          moments: moments,
          profileTodayMood: profile?.todayMood,
        );
    final pagePalette = paletteForMood(dayMoodId);
    final companion = ref.watch(userCompanionProvider);

    return IslandScaffold(
      palette: pagePalette,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    color: pagePalette.accent,
                    onRefresh: _refreshStories,
                    child: CustomScrollView(
                      primary: false,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppLayout.pageHorizontal,
                              12,
                              AppLayout.pageHorizontal,
                              8,
                            ),
                            child: Text(
                              context.l10n.tabToday,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppLayout.pageHorizontal,
                            ),
                            child: StoryDayFilterBar(
                              palette: pagePalette,
                              selectedDay: view.selectedDay,
                              recordedDays: view.recordedDays,
                              moodByDayIso: view.moodByDayIso,
                              gender: companion.gender,
                              onDaySelected: (day) {
                                ref
                                    .read(selectedStoryDayProvider.notifier)
                                    .state = calendarDate(day);
                              },
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppLayout.pageHorizontal,
                              10,
                              AppLayout.pageHorizontal,
                              10,
                            ),
                            child: MoodTodayCard(
                              palette: pagePalette,
                              selectedDay: view.selectedDay,
                              displayMoodId: dayMoodId,
                              canEdit: viewingToday && moments.isEmpty,
                              hasStoryStats: moments.isNotEmpty,
                            ),
                          ),
                        ),
                        if (viewingToday)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppLayout.pageHorizontal,
                                0,
                                AppLayout.pageHorizontal,
                                10,
                              ),
                              child: WeeklyObservationCard(palette: pagePalette),
                            ),
                          ),
                        if (moments.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppLayout.pageHorizontal,
                                24,
                                AppLayout.pageHorizontal,
                                viewingToday ? _bottomActionBarHeight + 16 : 12,
                              ),
                              child: Text(
                                viewingToday
                                    ? '记下第一个日常，让你的成长岛更充实'
                                    : '这一天还没有日常记录',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: pagePalette.primary
                                      .withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              AppLayout.pageHorizontal,
                              4,
                              AppLayout.pageHorizontal,
                              viewingToday ? _bottomActionBarHeight + 8 : 12,
                            ),
                            sliver: SliverList.separated(
                              itemCount: moments.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final m = moments[i];
                                return TodayStoryCard(
                                  moment: m,
                                  companion: companion,
                                  palette: pagePalette,
                                  companionAlwaysVisible: false,
                                  onViewDetail: () =>
                                      openMomentDetailPage(context, moment: m),
                                  onEdit: () => _openEdit(m),
                                  onPlay: () {},
                                  onDelete: () => _confirmDelete(m),
                                  onMoodChanged: () =>
                                      ref.invalidate(storyDayViewProvider),
                                );
                              },
                            ),
                          ),
                        if (!viewingToday)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppLayout.pageHorizontal,
                                4,
                                AppLayout.pageHorizontal,
                                8,
                              ),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => _openAddPastRoutine(
                                  view: view,
                                  viewingToday: viewingToday,
                                  palette: pagePalette,
                                ),
                                child: Text(
                                  '添加之前的日常',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: pagePalette.accent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (showTopLoader)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        color: pagePalette.accent,
                        backgroundColor: pagePalette.primaryContainer,
                      ),
                    ),
                ],
              ),
            ),
            if (viewingToday)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppLayout.pageHorizontal,
                  6,
                  AppLayout.pageHorizontal,
                  8,
                ),
                child: IslandPrimaryAction(
                  label: moments.isEmpty ? '+ 添加今日日常' : '+ 再记录一个日常',
                  palette: pagePalette,
                  loadingMoodId: dayMoodId,
                  onPressed: _openAdd,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
