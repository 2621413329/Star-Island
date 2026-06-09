import 'dart:async';
import 'dart:ui';

import '../../../island/decoration/decoration_asset_resolver.dart';
import '../../../island/decoration/decoration_renderer.dart';
import '../../engine/world_state.dart';
import 'world_layer.dart';

class DecorationLayer extends WorldLayer {
  DecorationLayer() : super(layerPriority: -25);

  final DecorationAssetResolver _assetResolver = DecorationAssetResolver();
  final DecorationRenderer _renderer = const DecorationRenderer();
  double _time = 0;

  @override
  void onWorldStateChanged(WorldState worldState) {
    unawaited(_assetResolver.preload(game, worldState.decorations));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!isMounted) return;
    final size = sceneSize;
    final decorations = [...state.decorations]
      ..sort((a, b) => a.position.dy.compareTo(b.position.dy));
    for (final decoration in decorations) {
      final p = Offset(
        decoration.position.dx * size.x,
        decoration.position.dy * size.y,
      );
      final asset = _assetResolver.cachedOrFallback(decoration);
      if (asset.hasImage) {
        _drawAsset(canvas, decoration, asset, p);
        continue;
      }
      _renderer.render(
        canvas,
        decoration: decoration,
        base: p,
        wind: state.environment.windStrength,
        time: _time,
        flowerColor: state.island.style.flower,
      );
    }
  }

  void _drawAsset(
    Canvas canvas,
    DecorationSnapshot decoration,
    DecorationAsset asset,
    Offset base,
  ) {
    final image = asset.image;
    final src = asset.region;
    if (image == null || src == null) return;
    final size = _assetSize(decoration.type) * decoration.scale;
    final dst = Rect.fromCenter(
      center: base + Offset(0, -size.height * 0.32),
      width: size.width,
      height: size.height,
    );
    canvas.save();
    canvas.translate(dst.center.dx, dst.center.dy);
    canvas.rotate(decoration.rotation);
    canvas.drawImageRect(
      image,
      src,
      Rect.fromCenter(
        center: Offset.zero,
        width: dst.width,
        height: dst.height,
      ),
      Paint(),
    );
    canvas.restore();
  }

  Size _assetSize(String type) {
    return switch (type) {
      'tree' => const Size(46, 62),
      'flower' => const Size(20, 18),
      'grass' => const Size(22, 16),
      _ => const Size(24, 18),
    };
  }
}
