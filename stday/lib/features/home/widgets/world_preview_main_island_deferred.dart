import 'package:flutter/material.dart';

import '../../../world/preview/world_preview_performance.dart';
import 'world_preview_main_island.dart';

/// 主岛 Flame 视口：首屏延迟 [delay] 再挂载，避免与 UI 同帧争抢。
class WorldPreviewMainIslandDeferred extends StatefulWidget {
  const WorldPreviewMainIslandDeferred({
    super.key,
    required this.width,
    required this.height,
    required this.enginePaused,
    required this.quality,
    this.delay = const Duration(milliseconds: 200),
  });

  final double width;
  final double height;
  final bool enginePaused;
  final WorldPreviewQuality quality;
  final Duration delay;

  @override
  State<WorldPreviewMainIslandDeferred> createState() =>
      _WorldPreviewMainIslandDeferredState();
}

class _WorldPreviewMainIslandDeferredState
    extends State<WorldPreviewMainIslandDeferred> {
  var _mountFlame = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) setState(() => _mountFlame = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_mountFlame) {
      return _MainIslandFlamePlaceholder(
        width: widget.width,
        height: widget.height,
      );
    }
    return WorldPreviewMainIsland(
      width: widget.width,
      height: widget.height,
      enginePaused: widget.enginePaused,
      quality: widget.quality,
    );
  }
}

class _MainIslandFlamePlaceholder extends StatelessWidget {
  const _MainIslandFlamePlaceholder({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: RadialGradient(
            center: const Alignment(0, 0.22),
            radius: 0.72,
            colors: [
              const Color(0xFF8FD4A8).withValues(alpha: 0.55),
              const Color(0xFF5CB88A).withValues(alpha: 0.28),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.landscape_rounded,
            size: width * 0.22,
            color: Colors.white.withValues(alpha: 0.42),
          ),
        ),
      ),
    );
  }
}
