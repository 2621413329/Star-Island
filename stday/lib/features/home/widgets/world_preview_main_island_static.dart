import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_companion.dart';
import '../../../design_system/user_companion_view.dart';
import '../../../island/providers/island_world_provider.dart';
import '../../../island/decor/decor_config.dart';
import '../../../island/decor/decor_scale_resolver.dart';
import '../../../providers/app_providers.dart';
import '../../../world/engine/world_state.dart';
import '../../../world/island/island_renderer.dart';
import '../../../world/preview/world_preview_camera.dart';

/// 首页主岛纯 Canvas 静态预览（无 Flame），优先流畅。
class WorldPreviewMainIslandStatic extends ConsumerWidget {
  const WorldPreviewMainIslandStatic({
    super.key,
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ref.watch(islandWorldPreviewProvider);
    final character = base.characters.isNotEmpty ? base.characters.first : null;
    final companion = ref.watch(userCompanionProvider);

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Transform(
          alignment: Alignment.center,
          transform: WorldPreviewCamera.islandTransform(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: _MainIslandPreviewPainter(
                  island: base.island,
                  environment: base.environment,
                ),
              ),
              for (final decor in _previewDecorFor(base))
                _MainIslandPreviewDecor(
                  config: decor,
                  userLevel: _previewLevelFor(base),
                  viewportSize: Size(width, height),
                ),
              if (character != null)
                _MainIslandPreviewCompanion(
                  character: character,
                  viewportSize: Size(width, height),
                  companion: companion,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

int _previewLevelFor(WorldState state) {
  if (state.characters.isEmpty) return 1;
  return state.characters.first.level.clamp(1, 3);
}

List<DecorConfig> _previewDecorFor(WorldState state) {
  final cappedLevel = _previewLevelFor(state);
  return DecorConfigs.unlockedMainIslandAt(cappedLevel)
      .where(DecorConfigs.isMainIslandGroundDecor)
      .toList(growable: false);
}

class _MainIslandPreviewPainter extends CustomPainter {
  _MainIslandPreviewPainter({
    required this.island,
    required this.environment,
  });

  final IslandState island;
  final MoodEnvironmentState environment;

  static final _renderer = IslandRenderer(compact: true);

  @override
  void paint(Canvas canvas, Size size) {
    _renderer.render(canvas, size, island, environment);
  }

  @override
  bool shouldRepaint(covariant _MainIslandPreviewPainter oldDelegate) {
    return oldDelegate.island.radius != island.radius ||
        oldDelegate.island.prosperityTier != island.prosperityTier;
  }
}

class _MainIslandPreviewDecor extends StatelessWidget {
  const _MainIslandPreviewDecor({
    required this.config,
    required this.userLevel,
    required this.viewportSize,
  });

  final DecorConfig config;
  final int userLevel;
  final Size viewportSize;

  @override
  Widget build(BuildContext context) {
    final size = _decorSize(config, userLevel, viewportSize);
    final left = config.x * viewportSize.width - size.width / 2;
    final top = config.y * viewportSize.height - size.height;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = (size.width * dpr).round().clamp(24, 160);

    return Positioned(
      left: left,
      top: top,
      width: size.width,
      height: size.height,
      child: Image.asset(
        'assets/images/${config.assetPath}',
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.low,
        cacheWidth: cacheW,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  Size _decorSize(DecorConfig config, int userLevel, Size viewportSize) {
    final resolver = const DecorScaleResolver();
    final baseHeight = DecorScaleResolver.baseHeightFor(config.category);
    final scale = resolver.finalScale(config, userLevel);
    final depth = 0.82 + (config.y - 0.44).clamp(0.0, 0.28) * 0.9;
    final height = (baseHeight * scale * depth * 0.82)
        .clamp(8.0, viewportSize.height * 0.11)
        .toDouble();
    return Size(height, height);
  }
}

class _MainIslandPreviewCompanion extends StatelessWidget {
  const _MainIslandPreviewCompanion({
    required this.character,
    required this.viewportSize,
    required this.companion,
  });

  final CharacterSnapshot character;
  final Size viewportSize;
  final UserCompanion companion;

  @override
  Widget build(BuildContext context) {
    final size = (viewportSize.width * 0.18).clamp(34.0, 54.0).toDouble();
    final left = character.normalizedPos.dx * viewportSize.width - size / 2;
    final top = character.normalizedPos.dy * viewportSize.height - size * 0.92;

    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size * 1.15,
      child: UserCompanionView(
        companion: companion,
        size: size,
        showAura: false,
      ),
    );
  }
}
