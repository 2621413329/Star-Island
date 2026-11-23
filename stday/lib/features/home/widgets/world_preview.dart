import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/utils/story_island_names.dart';
import '../../../design_system/home_theme.dart';
import '../../../providers/app_providers.dart';
import '../../../world/island/island_body_ready_scope.dart';
import '../../../world/preview/world_island_layout.dart';
import '../../../world/preview/world_island_visual.dart';
import '../../../world/preview/world_preview_performance.dart';
import '../providers/home_island_slots_provider.dart';
import 'floating_island_label.dart';
import 'world_preview_backdrop.dart';
import 'world_preview_float.dart';
import 'world_preview_island_pedestal.dart';
import 'world_preview_main_island_static.dart';
import 'world_preview_story_island_static.dart';

/// 沉浸式世界预览：海面 + 中心主岛 Flame + 四周副岛静态图（无底部卡片）。
class WorldPreview extends StatelessWidget {
  const WorldPreview({
    super.key,
    required this.enginePaused,
    this.onIslandSlotTap,
    this.onMainIslandTap,
  });

  final bool enginePaused;
  final void Function(HomeIslandSlot slot)? onIslandSlotTap;
  final VoidCallback? onMainIslandTap;

  /// 名称牌略溢出视口时的余量（贴视觉岛缘，不再空出整段底边）。
  static const _labelBlockHeight = 8.0;

  /// 首屏以世界为主。高度按屏高约六成，保证下方还能露出一句邀请。
  static double previewHeightFor(double screenHeight) =>
      (screenHeight * 0.60).clamp(400.0, 540.0);

  /// 与首页群岛实际布局同一块画布，供切页前预生成岛体。
  static Size canvasForScreen(Size screen) {
    final width = screen.width - AppLayout.pageHorizontal * 2;
    return Size(
      width < 1 ? 1 : width,
      previewHeightFor(screen.height),
    );
  }

  /// 岛体按画布短边取尺寸，避免在竖长卡片里被拉得过大、互相叠住。
  static const _mainShortSideFactor = 0.50;
  static const _subShortSideFactor = 0.30;

  /// 视口内岛体视觉下缘。手绘岛坯几乎铺满卡片，名称牌贴在岸线下沿。
  static double islandVisualBottomFactor({bool isMain = false}) =>
      isMain ? 0.92 : 0.90;

  /// 标签紧贴视觉岛缘下方，消除岛底与名称牌之间的大块空白。
  static double islandLabelTop(double islandHeight, {bool isMain = false}) =>
      islandHeight * islandVisualBottomFactor(isMain: isMain) + 2;

  static double islandRimTopFactor({double islandRadius = 1.0}) {
    const cy = 0.54;
    const ryBase = 0.118 * 1.48 * 1.22;
    return (cy - ryBase * islandRadius).clamp(0.20, 0.38);
  }

  static Size mainIslandViewportSize(Size canvas, {int level = 1}) {
    final side = canvas.shortestSide * _mainShortSideFactor;
    return Size(side, side * 0.86);
  }

  static Size subIslandViewportSize(
    Size canvas,
    WorldIslandSlotLayout layout, {
    String? categoryId,
  }) {
    final side = canvas.shortestSide *
        _subShortSideFactor *
        layout.depthScale *
        WorldIslandVisualProfile.categoryScale(categoryId);
    return Size(side, side * 0.86);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return _WorldPreviewStage(
          child: RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
                  child: _WorldPreviewBackdropHost(size: size),
                ),
                for (final layout in WorldIslandLayout.sortedByDepth())
                  if (layout.slotId != WorldIslandLayout.mainSlotId)
                    _SubIslandNode(
                      size: size,
                      layout: layout,
                      onTap: onIslandSlotTap,
                    ),
                _MainIslandNode(
                  size: size,
                  enginePaused: enginePaused,
                  onTap: onMainIslandTap,
                ),
                const _EmptyWorldHintHost(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WorldPreviewBackdropHost extends StatelessWidget {
  const _WorldPreviewBackdropHost({required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return WorldPreviewBackdrop(
      phase: 0,
      size: size,
      quality: WorldPreviewQuality.low,
    );
  }
}

class _MainIslandNode extends ConsumerWidget {
  const _MainIslandNode({
    required this.size,
    required this.enginePaused,
    this.onTap,
  });

  final Size size;
  final bool enginePaused;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slot = ref.watch(
      homeIslandSlotByIdProvider(WorldIslandLayout.mainSlotId),
    );
    if (slot == null) return const SizedBox.shrink();
    final layout = WorldIslandLayout.forSlot(WorldIslandLayout.mainSlotId);
    final center = worldSlotPixel(layout, size);
    final viewport = WorldPreview.mainIslandViewportSize(
      size,
      level: slot.level,
    );
    final w = viewport.width;
    final h = viewport.height;
    final rotation = WorldIslandVisualProfile.combinedRotation(
      layoutRotation: layout.rotationRadians,
      categoryId: null,
    );
    final floatEnabled = false;

    return Positioned(
      left: center.dx - w / 2,
      top: center.dy - h / 2,
      width: w,
      height: h + WorldPreview._labelBlockHeight,
      child: _MainIslandHitRegion(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: WorldPreviewFloat(
            amplitude: layout.floatAmplitude(isMain: true),
            enabled: floatEnabled,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: w,
                  height: h,
                  child: WorldPreviewIslandPedestal(
                    width: w,
                    rotationRadians: rotation,
                    isMain: true,
                    animateRipple: false,
                    child: WorldPreviewMainIslandStatic(
                      width: w,
                      height: h,
                      growthLevel: slot.level,
                      enginePaused: enginePaused,
                    ),
                  ),
                ),
                Positioned(
                  left: -48,
                  right: -48,
                  top: WorldPreview.islandLabelTop(h, isMain: true),
                  child: Center(
                    child: FloatingIslandLabel(
                      name: slot.displayName,
                      level: slot.level,
                      highlighted: slot.hasStories,
                      isMain: true,
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

class _MainIslandHitRegion extends SingleChildRenderObjectWidget {
  const _MainIslandHitRegion({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMainIslandHitRegion();
  }
}

class _RenderMainIslandHitRegion extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_containsMainIsland(position)) return false;
    return super.hitTest(result, position: position);
  }

  bool _containsMainIsland(Offset position) {
    if (size.isEmpty) return false;
    final dx = (position.dx / size.width - 0.5) / 0.48;
    final dy = (position.dy / size.height - 0.52) / 0.44;
    return dx * dx + dy * dy <= 1;
  }
}

class _SubIslandNode extends ConsumerWidget {
  const _SubIslandNode({
    required this.size,
    required this.layout,
    this.onTap,
  });

  final Size size;
  final WorldIslandSlotLayout layout;
  final void Function(HomeIslandSlot slot)? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slot = ref.watch(homeIslandSlotByIdProvider(layout.slotId));
    final island = slot?.island;
    if (slot == null || island == null) return const SizedBox.shrink();

    final center = worldSlotPixel(layout, size);
    final viewport = WorldPreview.subIslandViewportSize(
      size,
      layout,
      categoryId: slot.categoryId,
    );
    final w = viewport.width;
    final h = viewport.height;
    final rotation = WorldIslandVisualProfile.combinedRotation(
      layoutRotation: layout.rotationRadians,
      categoryId: slot.categoryId,
    );
    final categoryLabel = storyIslandNameStem(
      defaultStoryIslandName(
        slot.categoryId ?? '',
        slot.displayName,
      ),
    );

    return Positioned(
      left: center.dx - w / 2,
      top: center.dy - h / 2,
      width: w,
      height: h + WorldPreview._labelBlockHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap?.call(slot),
        child: maybeBlurDepth(
          blurSigma: layout.blurSigma,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: w,
                height: h,
                child: WorldPreviewIslandPedestal(
                  width: w,
                  rotationRadians: rotation,
                  animateRipple: false,
                  child: WorldPreviewStoryIslandStatic(
                    island: island,
                    width: w,
                    height: h,
                  ),
                ),
              ),
              Positioned(
                left: -56,
                right: -56,
                top: WorldPreview.islandLabelTop(h, isMain: false),
                child: Center(
                  child: FloatingIslandLabel(
                    name: categoryLabel,
                    level: slot.level,
                    opened: slot.isOpened,
                    highlighted: slot.hasStories,
                    categoryId: slot.categoryId,
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

class _EmptyWorldHintHost extends ConsumerWidget {
  const _EmptyWorldHintHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(homeWorldHasStoryIslandProvider)) {
      return const SizedBox.shrink();
    }
    return const _EmptyWorldHint();
  }
}

class _EmptyWorldHint extends StatelessWidget {
  const _EmptyWorldHint();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            '你的世界还在等第一个瞬间。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF3C5870),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}

/// 岛体位图要等出图。提前在首帧同步栅格化会卡住页面，所以先盖住，画完再揭开。
class _WorldPreviewStage extends ConsumerStatefulWidget {
  const _WorldPreviewStage({required this.child});

  final Widget child;

  @override
  ConsumerState<_WorldPreviewStage> createState() => _WorldPreviewStageState();
}

class _WorldPreviewStageState extends ConsumerState<_WorldPreviewStage>
    with TickerProviderStateMixin {
  final IslandBodyReadyBoard _board = IslandBodyReadyBoard();
  late final AnimationController _reveal;
  late final AnimationController _pulse;
  Timer? _timeout;
  var _maskVisible = true;
  var _revealed = false;
  var _maskPainted = false;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _board.addListener(_tryReveal);
    _timeout = Timer(const Duration(seconds: 8), () {
      if (!mounted || _revealed) return;
      _maskPainted = true;
      _beginReveal();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _revealed) return;
      _maskPainted = true;
      _tryReveal();
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _board.removeListener(_tryReveal);
    _reveal.dispose();
    _pulse.dispose();
    _board.dispose();
    super.dispose();
  }

  void _tryReveal() {
    if (_revealed || !mounted) return;
    final groups = ref.read(storyIslandGroupsProvider);
    final storiesPending = groups.isLoading && !groups.hasValue;
    if (storiesPending || !_board.settled) return;
    _beginReveal();
  }

  void _beginReveal() {
    if (_revealed || !mounted) return;
    _revealed = true;
    _timeout?.cancel();
    if (!_maskPainted) {
      _reveal.value = 1;
      setState(() => _maskVisible = false);
      return;
    }
    _reveal.forward().whenComplete(() {
      if (mounted) setState(() => _maskVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      storyIslandGroupsProvider,
      (_, __) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _tryReveal();
        });
      },
    );
    return IslandBodyReadyScope(
      board: _board,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _reveal,
            builder: (context, child) {
              final t = Curves.easeOutCubic.transform(_reveal.value);
              return Opacity(
                opacity: t,
                child: Transform.scale(
                  scale: 0.94 + 0.06 * t,
                  alignment: Alignment.center,
                  child: child,
                ),
              );
            },
            child: widget.child,
          ),
          if (_maskVisible)
            AnimatedBuilder(
              animation: Listenable.merge([_reveal, _pulse]),
              builder: (context, _) {
                final t = Curves.easeOutCubic.transform(_reveal.value);
                return IgnorePointer(
                  ignoring: t > 0.92,
                  child: Opacity(
                    opacity: (1 - t).clamp(0.0, 1.0),
                    child: _WorldConstructingMask(pulse: _pulse.value),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _WorldConstructingMask extends StatelessWidget {
  const _WorldConstructingMask({required this.pulse});

  final double pulse;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD7F1FF),
              Color(0xFFB7E2F8),
              Color(0xFF8FCBEA),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: 0.92 + pulse * 0.12,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.38 + pulse * 0.22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3E8EBE)
                            .withValues(alpha: 0.16 + pulse * 0.14),
                        blurRadius: 16 + pulse * 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.public_rounded,
                    color: Color(0xFF2F6F9A),
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '今日世界构建中',
                style: appTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2F5F8A),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2F6F9A).withValues(
                          alpha: 0.28 + (((pulse + i / 3) % 1) * 0.72),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
