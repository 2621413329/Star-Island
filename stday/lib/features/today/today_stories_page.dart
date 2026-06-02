import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/mood_island_config.dart';
import '../../design_system/growth_island_scene.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../providers/app_providers.dart';
import 'add_moment_flow.dart';
import 'mood_today_card.dart';
import 'today_story_card.dart';

class TodayStoriesPage extends ConsumerStatefulWidget {
  const TodayStoriesPage({super.key});

  @override
  ConsumerState<TodayStoriesPage> createState() => _TodayStoriesPageState();
}

class _TodayStoriesPageState extends ConsumerState<TodayStoriesPage> {
  final GlobalKey<GrowthIslandSceneState> _islandKey = GlobalKey();

  static const double _islandMax = 300;
  static const double _islandMin = 72;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(todayMomentsProvider.notifier).refresh();
      ref.read(moodIslandRegistryProvider.notifier).refresh();
    });
  }

  Future<void> _openAdd() async {
    await showAddMomentFlow(context, ref, islandKey: _islandKey);
    await ref.read(todayMomentsProvider.notifier).refresh();
    if (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _islandKey.currentState?.playAllMoments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final momentsAsync = ref.watch(todayMomentsProvider);
    final islandRegistry = ref.watch(moodIslandRegistryProvider).valueOrNull ?? MoodIslandRegistry.defaults();
    final companionStyle = profile?.companionStyle ?? 'chibi';
    final moodId = profile?.todayMood;
    final islandConfig = islandRegistry.resolve(moodId);
    final moments = momentsAsync.valueOrNull ?? [];

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: momentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败：$e')),
            data: (_) => CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('M月d日 EEEE', 'zh_CN').format(DateTime.now()),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF8C7B6B)),
                        ),
                        Text('我的小岛', style: TextStyle(fontWeight: FontWeight.w700, color: palette.accent)),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: MoodTodayCard(palette: palette),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _IslandShrinkHeader(
                    maxExtent: _islandMax,
                    minExtent: _islandMin,
                    builder: (shrink) {
                      final t = ((shrink - _islandMin) / (_islandMax - _islandMin)).clamp(0.0, 1.0);
                      return Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: SizedBox(
                          height: shrink,
                          child: GrowthIslandScene(
                            key: _islandKey,
                            moodId: moodId,
                            palette: palette,
                            islandConfig: islandConfig,
                            companionStyle: companionStyle,
                            moments: t > 0.35 ? moments : [],
                            scale: 0.55 + t * 0.45,
                            compact: t < 0.5,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (moments.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '下滑可专注看故事，上滑放大沙滩小岛',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.primary.withValues(alpha: 0.8)),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  sliver: SliverList.separated(
                    itemCount: moments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final m = moments[i];
                      return TodayStoryCard(
                        moment: m,
                        companionStyle: companionStyle,
                        palette: palette,
                        onPlay: () => _islandKey.currentState?.playMoment(m.id),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: IslandPrimaryAction(
                      label: moments.isEmpty ? '+ 添加今日故事' : '+ 再记录一个故事',
                      palette: palette,
                      onPressed: _openAdd,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IslandShrinkHeader extends SliverPersistentHeaderDelegate {
  _IslandShrinkHeader({
    required double maxExtent,
    required double minExtent,
    required this.builder,
  })  : _maxExtent = maxExtent,
        _minExtent = minExtent;

  final double _maxExtent;
  final double _minExtent;
  final Widget Function(double height) builder;

  @override
  double get maxExtent => _maxExtent;

  @override
  double get minExtent => _minExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final h = (_maxExtent - shrinkOffset).clamp(_minExtent, _maxExtent);
    return Material(
      color: Colors.transparent,
      elevation: overlapsContent ? 2 : 0,
      child: builder(h),
    );
  }

  @override
  bool shouldRebuild(covariant _IslandShrinkHeader old) =>
      old._maxExtent != _maxExtent || old._minExtent != _minExtent;
}
