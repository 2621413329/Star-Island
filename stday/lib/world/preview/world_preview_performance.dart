import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/platform/device_profile.dart';

/// 首页群岛预览渲染档位（影响 Flame 数量、动画帧率、海面细节）。
enum WorldPreviewQuality {
  high,
  balanced,
  low,
}

abstract final class WorldPreviewPerformance {
  static WorldPreviewQuality qualityFor(DeviceProfile device) {
    if (device.terminal == AppTerminal.desktop) {
      return WorldPreviewQuality.balanced;
    }
    final shortest = device.logicalSize.shortestSide;
    if (shortest <= 420 || device.devicePixelRatio <= 2.0) {
      return WorldPreviewQuality.low;
    }
    if (device.preferCompactIsland) {
      return WorldPreviewQuality.low;
    }
    return WorldPreviewQuality.balanced;
  }

  static int maxFlameStoryIslands(WorldPreviewQuality quality) => 0;

  static bool animateIslandFloat(WorldPreviewQuality quality) =>
      quality == WorldPreviewQuality.high;

  static bool enableMapPanZoom(WorldPreviewQuality quality) => false;

  static bool animateShoreline(WorldPreviewQuality quality) =>
      quality != WorldPreviewQuality.low;

  static bool enableMainIslandDecor(WorldPreviewQuality quality) => true;

  static bool enableStoryIslandDecor(WorldPreviewQuality quality) => false;

  static double mainIslandPreviewZoom(WorldPreviewQuality quality) =>
      switch (quality) {
        WorldPreviewQuality.high => 2.82,
        WorldPreviewQuality.balanced => 2.58,
        WorldPreviewQuality.low => 2.32,
      };

  static int environmentTickMs(WorldPreviewQuality quality) =>
      switch (quality) {
        WorldPreviewQuality.high => 16,
        WorldPreviewQuality.balanced => 33,
        WorldPreviewQuality.low => 50,
      };

  static bool useRichOcean(WorldPreviewQuality quality) =>
      quality == WorldPreviewQuality.high;

  /// 首页群岛已用天空底图，关闭生命层以减少持续重绘。
  static bool useLifeLayer(WorldPreviewQuality quality) => false;
}

/// 仅驱动背景/env 动画，避免每帧 rebuild 整个 World（含 Flame）。
class WorldPreviewPhaseTicker extends StatefulWidget {
  const WorldPreviewPhaseTicker({
    super.key,
    required this.quality,
    required this.paused,
    required this.builder,
  });

  final WorldPreviewQuality quality;
  final bool paused;
  final Widget Function(BuildContext context, double phase) builder;

  @override
  State<WorldPreviewPhaseTicker> createState() =>
      _WorldPreviewPhaseTickerState();
}

class _WorldPreviewPhaseTickerState extends State<WorldPreviewPhaseTicker> {
  double _phase = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant WorldPreviewPhaseTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paused != widget.paused ||
        oldWidget.quality != widget.quality) {
      _syncTimer();
    }
  }

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (widget.paused) return;
    final ms = WorldPreviewPerformance.environmentTickMs(widget.quality);
    _timer = Timer.periodic(Duration(milliseconds: ms), (_) {
      if (!mounted) return;
      setState(() {
        _phase = (_phase + ms / 16000.0) % 1.0;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _phase);
  }
}
