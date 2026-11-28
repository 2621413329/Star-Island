import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout/main_shell_insets.dart';
import '../../data/models/profile_models.dart';
import '../../data/models/story_island_models.dart';
import '../../design_system/healing_jelly_button.dart';
import '../../providers/app_providers.dart';

Future<String?> showStoryIslandPlacementSheet({
  required BuildContext context,
  required DailyMomentModel moment,
  required List<StoryIslandCategoryModel> groups,
  StoryIslandModel? growthMainIsland,
}) {
  final currentId = moment.storyIslandId ??
      moment.visualPayload['story_island_id'] as String?;
  StoryIslandModel? current;
  if (growthMainIsland != null && growthMainIsland.id == currentId) {
    current = growthMainIsland;
  }
  for (final group in groups) {
    for (final island in group.islands) {
      if (island.id == currentId) current = island;
    }
  }

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _StoryIslandPlacementSheet(
        groups: groups,
        growthMainIsland: growthMainIsland,
        selectedId: currentId,
        title:
            current == null ? '选择这篇日常要放入的岛屿' : '这篇日常会化作种子，放入「${current.name}」',
      );
    },
  );
}

class _StoryIslandPlacementSheet extends ConsumerStatefulWidget {
  const _StoryIslandPlacementSheet({
    required this.groups,
    required this.selectedId,
    required this.title,
    this.growthMainIsland,
  });

  final List<StoryIslandCategoryModel> groups;
  final StoryIslandModel? growthMainIsland;
  final String? selectedId;
  final String title;

  @override
  ConsumerState<_StoryIslandPlacementSheet> createState() =>
      _StoryIslandPlacementSheetState();
}

class _StoryIslandPlacementSheetState
    extends ConsumerState<_StoryIslandPlacementSheet> {
  late String? _selectedId = widget.selectedId;
  final Map<String, GlobalKey> _tileKeys = {};
  var _revealAttempts = 0;
  Animation<double>? _routeAnimation;
  AnimationStatusListener? _routeStatusListener;

  GlobalKey _tileKey(String id) => _tileKeys.putIfAbsent(id, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleReveal());
  }

  @override
  void dispose() {
    final animation = _routeAnimation;
    final listener = _routeStatusListener;
    if (animation != null && listener != null) {
      animation.removeStatusListener(listener);
    }
    super.dispose();
  }

  void _scheduleReveal() {
    if (!mounted) return;
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.status == AnimationStatus.completed) {
      _revealSelection();
      return;
    }
    void onStatus(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      animation.removeStatusListener(onStatus);
      _routeStatusListener = null;
      _revealSelection();
    }

    _routeAnimation = animation;
    _routeStatusListener = onStatus;
    animation.addStatusListener(onStatus);
  }

  /// 列表项一次全部建好。弹层动画结束后再滚，避免第一次布局时滚回顶部。
  void _revealSelection() {
    if (!mounted || _revealAttempts > 12) return;
    final id = _selectedId;
    if (id == null) return;
    final target = _tileKeys[id]?.currentContext;
    final scrollable = target == null ? null : Scrollable.maybeOf(target);
    final position = scrollable?.position;
    final targetBox = target?.findRenderObject() as RenderBox?;
    final viewportBox = scrollable?.context.findRenderObject() as RenderBox?;
    final ready = position != null &&
        position.hasContentDimensions &&
        position.hasPixels &&
        targetBox != null &&
        targetBox.hasSize &&
        viewportBox != null &&
        viewportBox.hasSize &&
        viewportBox.size.height > 0;
    if (!ready) {
      _revealAttempts += 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelection());
      return;
    }
    final targetTop =
        targetBox.localToGlobal(Offset.zero, ancestor: viewportBox).dy;
    final desired =
        (position.pixels + targetTop - viewportBox.size.height * 0.12)
            .clamp(0.0, position.maxScrollExtent);
    if ((desired - position.pixels).abs() < 1) return;
    position.animateTo(
      desired,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = ref.watch(moodPaletteProvider);
    final tone = HealingJellyTone.fromPalette(palette);
    final tabBottom = MainShellInsets.tabBarHeight +
        MainShellInsets.tabBarClearance +
        MediaQuery.paddingOf(context).bottom;
    final availableGroups =
        widget.groups.where((group) => group.islands.isNotEmpty).toList();
    final listMaxHeight = MediaQuery.sizeOf(context).height * 0.38;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, tabBottom + 8),
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '你可以手动变更岛屿，确认后小种子会被投放到对应岛屿。',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: listMaxHeight),
              child: ListView(
                shrinkWrap: true,
                scrollCacheExtent: const ScrollCacheExtent.pixels(8000),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                children: [
                  if (widget.growthMainIsland != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        '岛屿',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _IslandChoiceTile(
                      key: _tileKey(widget.growthMainIsland!.id),
                      island: widget.growthMainIsland!,
                      selected: widget.growthMainIsland!.id == _selectedId,
                      onTap: () => setState(
                        () => _selectedId = widget.growthMainIsland!.id,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  for (final group in availableGroups)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              group.label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          for (final island in group.islands)
                            _IslandChoiceTile(
                              key: _tileKey(island.id),
                              island: island,
                              selected: island.id == _selectedId,
                              onTap: () =>
                                  setState(() => _selectedId = island.id),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('稍后再说'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HealingJellyPillButton(
                      onPressed: _selectedId == null
                          ? null
                          : () => Navigator.of(context).pop(_selectedId),
                      label: '提交',
                      tone: tone,
                      expanded: true,
                      height: 48,
                      showGlow: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IslandChoiceTile extends StatelessWidget {
  const _IslandChoiceTile({
    super.key,
    required this.island,
    required this.selected,
    required this.onTap,
  });

  final StoryIslandModel island;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    island.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${island.storyCount} 条',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
