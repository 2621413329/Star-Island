import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/catalog.dart';
import '../../core/layout/app_layout.dart';
import '../../core/models/mood_island_config.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/models/profile_models.dart';
import '../../design_system/growth_island_rules_sheet.dart';
import '../../design_system/growth_reward_dialog.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../providers/app_providers.dart';
import '../../core/utils/moment_date_groups.dart';
import '../../providers/story_day_provider.dart';
import 'add_moment_flow.dart';
import 'edit_moment_sheet.dart';
import 'mood_today_card.dart';
import 'today_story_card.dart';
import 'widgets/growth_world_viewport.dart';
import 'daily_mood_prompt.dart';
import 'daily_mood_report_action.dart';
import 'widgets/story_day_filter_bar.dart';
import 'widgets/today_mood_recap_bar.dart';
import '../../data/models/mood_check_in_models.dart';
import '../../providers/mood_report_check_in_provider.dart';

class TodayStoriesPage extends ConsumerStatefulWidget {
  const TodayStoriesPage({super.key});

  @override
  ConsumerState<TodayStoriesPage> createState() => _TodayStoriesPageState();
}

class _TodayStoriesPageState extends ConsumerState<TodayStoriesPage> {
  static const double _islandHeight = 200;
  /// 底部固定按钮区高度（按钮 52 + 上下内边距），列表需留出相应空白。
  static const double _bottomActionBarHeight = 68;
  final GlobalKey<GrowthWorldViewportState> _islandKey =
      GlobalKey<GrowthWorldViewportState>();
  bool _uploadingMood = false;

  void _handleCharacterInteraction(
    DailyMomentModel moment,
    String? nearbyBuildingId,
    String characterId,
  ) {
    _islandKey.currentState?.playMoment(moment.id);
    if (!mounted) return;
    final palette = ref.read(moodPaletteProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CharacterInteractionSheet(
        palette: palette,
        moment: moment,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(storyDayViewProvider.notifier).refresh();
      ref.invalidate(moodReportCheckInProvider);
      ref.read(moodIslandRegistryProvider.notifier).refresh();
      if (!mounted) return;
      await showGrowthIslandRulesIfNeeded(context);
      if (!mounted) return;
      await showDailyMoodPromptIfNeeded(context, ref);
    });
  }

  Future<void> _refreshStories() async {
    await ref.read(storyDayViewProvider.notifier).refresh();
    await ref.read(todayMomentsProvider.notifier).refresh();
    ref.invalidate(moodReportCheckInProvider);
  }

  Future<void> _uploadTodayMood() async {
    if (_uploadingMood) return;
    setState(() => _uploadingMood = true);
    try {
      await uploadAndShowDailyMoodReport(context: context, ref: ref);
    } finally {
      if (mounted) setState(() => _uploadingMood = false);
    }
  }

  Future<void> _openAdd() async {
    if (!isCalendarToday(ref.read(selectedStoryDayProvider))) return;
    final growthBefore = await fetchCurrentGrowthSummary(ref);
    await showAddMomentFlow(context, ref);
    if (!mounted) return;
    await _refreshStories();
    if (!mounted) return;
    await showGrowthRewardsAfterAction(
      context,
      ref,
      before: growthBefore,
    );
  }

  Future<void> _openEdit(DailyMomentModel moment) async {
    if (!isMomentToday(moment)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('仅今日故事可以修改')),
        );
      }
      return;
    }
    final saved = await showEditMomentSheet(context, ref, moment: moment);
    if (saved == true && mounted) {
      await _refreshStories();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('故事已更新')),
      );
    }
  }

  Future<void> _confirmDelete(DailyMomentModel moment) async {
    if (!isMomentToday(moment)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('仅今日故事可以删除')),
        );
      }
      return;
    }
    final id = moment.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这条今日事件？'),
        content: const Text('删除后，这只小星会从今日小岛上离开。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(todayMomentsProvider.notifier).remove(id);
      await _refreshStories();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('已删除故事')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('删除失败：$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final storyAsync = ref.watch(storyDayViewProvider);
    final selectedDay = ref.watch(selectedStoryDayProvider);
    final viewingToday = isCalendarToday(selectedDay);
    final checkInAsync = ref.watch(moodReportCheckInProvider);
    final checkIn = checkInAsync.valueOrNull ?? MoodReportCheckIn.empty;

    final palette = ref.watch(moodPaletteProvider);

    return storyAsync.when(
      loading: () => _buildStoriesBody(
        view: StoryDayViewState.initial(
          day: ref.watch(selectedStoryDayProvider),
        ),
        profile: profile,
        viewingToday: viewingToday,
        checkIn: checkIn,
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
                Text(
                  '加载失败：$e',
                  textAlign: TextAlign.center,
                ),
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
      data: (view) => _buildStoriesBody(
        view: view,
        profile: profile,
        viewingToday: viewingToday,
        checkIn: checkIn,
        palette: palette,
        showTopLoader: false,
      ),
    );
  }

  Widget _buildStoriesBody({
    required StoryDayViewState view,
    required UserProfileModel? profile,
    required bool viewingToday,
    required MoodReportCheckIn checkIn,
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
    final islandRegistry = ref.watch(moodIslandRegistryProvider).valueOrNull ??
        MoodIslandRegistry.defaults();
    final companionStyle = profile?.companionStyle ?? 'chibi';
    final islandConfig = islandRegistry.resolve(dayMoodId);

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
                    '今日故事',
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
                    onDaySelected: (day) {
                      ref.read(selectedStoryDayProvider.notifier).state =
                          calendarDate(day);
                    },
                  ),
                ),
              ),
              if (viewingToday)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppLayout.pageHorizontal,
                      8,
                      AppLayout.pageHorizontal,
                      0,
                    ),
                    child: TodayMoodRecapBar(
                      palette: pagePalette,
                      checkIn: checkIn,
                      loading: _uploadingMood,
                      loadingMoodId: dayMoodId,
                      onPressed: _uploadTodayMood,
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
                    canEdit: viewingToday,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppLayout.pageHorizontal,
                    0,
                    AppLayout.pageHorizontal,
                    8,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: _islandHeight,
                      width: double.infinity,
                      child: GrowthWorldViewport(
                        key: _islandKey,
                        moodId: dayMoodId,
                        palette: pagePalette,
                        islandConfig: islandConfig,
                        companionStyle: companionStyle,
                        moments: moments,
                        enginePaused: false,
                        scale: 1,
                        compact: false,
                        onCharacterInteraction: _handleCharacterInteraction,
                      ),
                    ),
                  ),
                ),
              ),
              if (moments.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppLayout.pageHorizontal,
                      4,
                      AppLayout.pageHorizontal,
                      viewingToday ? _bottomActionBarHeight + 16 : 16,
                    ),
                    child: Text(
                      viewingToday
                          ? '记下第一个故事，小星会出现在你的岛上'
                          : '这一天还没有故事记录',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: pagePalette.primary.withValues(alpha: 0.75),
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
                    viewingToday ? _bottomActionBarHeight + 8 : 24,
                  ),
                  sliver: SliverList.separated(
                    itemCount: moments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final m = moments[i];
                      final editable = isMomentToday(m);
                      return TodayStoryCard(
                        moment: m,
                        companionStyle: companionStyle,
                        companionGender: profile?.gender,
                        palette: pagePalette,
                        readOnly: !editable,
                        onEdit: editable ? () => _openEdit(m) : null,
                        onPlay: () =>
                            _islandKey.currentState?.playMoment(m.id),
                        onDelete:
                            editable ? () => _confirmDelete(m) : null,
                      );
                    },
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
                  label: moments.isEmpty
                      ? '+ 添加今日故事'
                      : '+ 再记录一个故事',
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

class _CharacterInteractionSheet extends StatelessWidget {
  const _CharacterInteractionSheet({
    required this.palette,
    required this.moment,
  });

  final MoodPalette palette;
  final DailyMomentModel moment;

  @override
  Widget build(BuildContext context) {
    final story = moment.note?.trim();
    final subtitle = (story == null || story.isEmpty) ? '它看起来有话想跟你说。' : story;
    final tagLabels = momentSelectionLabels(
      tags: moment.eventTags,
      emotionTag: moment.emotionTag,
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: palette.card.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
            boxShadow: [
              BoxShadow(
                color: palette.accent.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tagLabels
                    .map(
                      (label) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: palette.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: palette.accent.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: palette.accent,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6E5A4A),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              IslandPrimaryAction(
                label: '确定',
                palette: palette,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
