import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/catalog.dart';
import '../../core/constants/companion_prop_labels.dart';
import '../../core/models/companion_spec.dart';
import '../../core/utils/companion_prop_infer.dart';
import '../../core/models/user_companion.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/mood_theme.dart';
import '../../core/utils/companion_base_expression.dart';
import '../../data/models/profile_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/companion_prop_asset_catalog.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/user_companion_view.dart';
import '../../providers/app_providers.dart';
import 'companion_prop_badge_detail.dart';

final _collectedPropsProvider =
    FutureProvider<List<CollectedCompanionProp>>((ref) async {
  // 与今日故事列表联动，新增/删除故事后立即重算配饰。
  final todayFromState =
      ref.watch(todayMomentsProvider).valueOrNull ?? const <DailyMomentModel>[];

  final repo = ref.read(appRepositoryProvider);
  final byId = <String, DailyMomentModel>{};

  try {
    for (final m in await repo.listRecentMoments(days: 365)) {
      byId[m.id] = m;
    }
  } catch (_) {
    for (final m in todayFromState) {
      byId[m.id] = m;
    }
    if (byId.isEmpty) {
      try {
        for (final m in await repo.listTodayMoments()) {
          byId[m.id] = m;
        }
      } catch (_) {
        return const [];
      }
    }
  }

  // 内存中的今日列表优先，避免 API 尚未同步时漏掉刚提交的故事。
  for (final m in todayFromState) {
    byId[m.id] = m;
  }

  return collectCompanionProps(byId.values.toList());
});

class CollectedCompanionProp {
  const CollectedCompanionProp({
    required this.id,
    required this.assetPath,
    required this.firstEarnedAt,
    required this.displayTitle,
  });

  final String id;
  final String assetPath;
  final DateTime firstEarnedAt;
  final String displayTitle;
}

/// 每条故事只统计与卡片展示一致的 companionSpec.prop。
Future<List<CollectedCompanionProp>> collectCompanionProps(
  List<DailyMomentModel> moments,
) async {
  final catalog = await CompanionPropAssetCatalog.load();
  final seenAssets = <String>{};
  final seenMomentIds = <String>{};
  final items = <CollectedCompanionProp>[];

  final sorted = List<DailyMomentModel>.from(moments)
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  for (final moment in sorted) {
    if (!seenMomentIds.add(moment.id)) continue;

    final prop = displayPropFromMoment(moment);
    if (prop == null || !_isCollectibleProp(prop)) continue;

    final assetPath = catalog.resolve(prop);
    if (!seenAssets.add(assetPath)) continue;

    items.add(
      CollectedCompanionProp(
        id: prop,
        assetPath: assetPath,
        firstEarnedAt: moment.createdAt,
        displayTitle: CompanionPropLabels.resolve(
          prop: prop,
          assetPath: assetPath,
          storedLabel: moment.visualPayload['prop_label'] as String?,
        ),
      ),
    );
  }

  items.sort((a, b) => b.firstEarnedAt.compareTo(a.firstEarnedAt));
  return items;
}

/// 与故事卡片 [DailyMomentModel.companionSpec] 使用同一 prop，保证图标一致。
String? displayPropFromMoment(DailyMomentModel moment) {
  final prop = moment.companionSpec.prop;
  if (prop == 'none' || prop == 'stars') return null;
  return prop;
}

bool _isCollectibleProp(String prop) {
  if (prop == 'none' || prop == 'stars') return false;
  return CompanionPropInfer.isAllowedProp(prop);
}

class CompanionShowcasePage extends ConsumerStatefulWidget {
  const CompanionShowcasePage({super.key});

  @override
  ConsumerState<CompanionShowcasePage> createState() =>
      _CompanionShowcasePageState();
}

class _CompanionShowcasePageState extends ConsumerState<CompanionShowcasePage> {
  late final PageController _moodPageController;
  int _moodIndex = 0;

  @override
  void initState() {
    super.initState();
    _moodPageController = PageController();
  }

  @override
  void dispose() {
    _moodPageController.dispose();
    super.dispose();
  }

  CompanionStoryContext _storyForMood(MoodOption mood) {
    return CompanionStoryContext(
      spec: CompanionSpec(
        expression: companionBaseExpressionFromMoodId(mood.id),
        prop: 'none',
        animationType: 'wave',
        tint: mood.color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    final companion = ref.watch(userCompanionProvider);
    final propsAsync = ref.watch(_collectedPropsProvider);
    final currentMood = moods[_moodIndex];

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: const Color(0xFF5D4E44),
                    ),
                    Text(
                      '成长伙伴小星',
                      style: appTextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D3229),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: palette.primary,
                  onRefresh: () async {
                    await ref.read(todayMomentsProvider.notifier).refresh();
                    ref.invalidate(_collectedPropsProvider);
                    await ref.read(_collectedPropsProvider.future);
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 280,
                              child: PageView.builder(
                                controller: _moodPageController,
                                itemCount: moods.length,
                                onPageChanged: (index) =>
                                    setState(() => _moodIndex = index),
                                itemBuilder: (context, index) {
                                  final mood = moods[index];
                                  return Center(
                                    child: UserCompanionView(
                                      companion: companion,
                                      story: _storyForMood(mood),
                                      size: 220,
                                      palette: palette,
                                      showAura: true,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currentMood.label,
                              style: appTextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: currentMood.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < moods.length; i++)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    margin:
                                        const EdgeInsets.symmetric(horizontal: 3),
                                    width: i == _moodIndex ? 18 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: i == _moodIndex
                                          ? currentMood.color
                                          : currentMood.color
                                              .withValues(alpha: 0.28),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '左右滑动，看看不同心情下的小星',
                              style: appTextStyle(
                                fontSize: 12,
                                color: palette.primary.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      sliver: propsAsync.when(
                        loading: () => const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        error: (_, __) => SliverToBoxAdapter(
                          child: IslandGlassCard(
                            palette: palette,
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              '配饰加载失败，请稍后再试',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: palette.primary.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                        ),
                        data: (props) {
                          if (props.isEmpty) {
                            return SliverToBoxAdapter(
                              child: IslandGlassCard(
                                palette: palette,
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  '还没有收集到配饰图标\n去记录一个故事，小星会带上新的陪伴物回来',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.55,
                                    color:
                                        palette.primary.withValues(alpha: 0.62),
                                  ),
                                ),
                              ),
                            );
                          }
                          return SliverMainAxisGroup(
                            slivers: [
                              SliverToBoxAdapter(
                                child: Row(
                                  children: [
                                    Text(
                                      '获得的配饰',
                                      style: appTextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF3D3229),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '共 ${props.length} 种',
                                      style: appTextStyle(
                                        fontSize: 12,
                                        color: const Color(0xFF8C7B6B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SliverToBoxAdapter(child: SizedBox(height: 12)),
                              SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 1,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final item = props[index];
                                    final heroTag =
                                        'companion_prop_${item.assetPath}_$index';
                                    return _PropCollectTile(
                                      item: item,
                                      palette: palette,
                                      heroTag: heroTag,
                                      onTap: () => showCompanionPropBadgeDetail(
                                        context,
                                        prop: item,
                                        palette: palette,
                                        heroTag: heroTag,
                                      ),
                                    );
                                  },
                                  childCount: props.length,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
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

class _PropCollectTile extends StatelessWidget {
  const _PropCollectTile({
    required this.item,
    required this.palette,
    required this.heroTag,
    required this.onTap,
  });

  final CollectedCompanionProp item;
  final MoodPalette palette;
  final String heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Hero(
          tag: heroTag,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              shape: BoxShape.circle,
              border: Border.all(
                color: palette.primary.withValues(alpha: 0.22),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              item.assetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.image_not_supported_outlined,
                color: palette.primary.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
