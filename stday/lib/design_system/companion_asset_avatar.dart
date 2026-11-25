import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/companion_base_asset.dart';
import '../world/rendering/mood_companion_motion.dart';
import 'companion_base_asset_catalog.dart';

/// 图片化小人：本体来自 assets，方便后续直接替换 PNG。
class CompanionAssetAvatar extends StatelessWidget {
  const CompanionAssetAvatar({
    super.key,
    required this.style,
    required this.expression,
    required this.tint,
    required this.glow,
    required this.performanceLevel,
    required this.showAura,
    required this.gender,
    required this.size,
  });

  final String style;
  final String expression;
  final Color tint;
  final Color glow;
  final double performanceLevel;
  final bool showAura;
  final String? gender;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetId = companionBaseAssetId(expression);
    final candidates = companionBaseAssetCandidates(
      gender: gender,
      assetId: assetId,
      includePlaceholder: true,
    );
    final canvasSize = Size(size, size * 1.15);

    return SizedBox(
      width: canvasSize.width,
      height: canvasSize.height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (showAura) _Aura(glow: glow, tint: tint),
          _CompanionBaseImage(
            key: ValueKey('$gender|$assetId'),
            gender: gender,
            assetId: assetId,
            candidates: candidates,
            canvasSize: canvasSize,
            glow: glow,
          ),
        ],
      ),
    );
  }
}

class _CompanionBaseImage extends StatefulWidget {
  const _CompanionBaseImage({
    super.key,
    required this.gender,
    required this.assetId,
    required this.candidates,
    required this.canvasSize,
    required this.glow,
  });

  final String? gender;
  final String assetId;
  final List<String> candidates;
  final Size canvasSize;
  final Color glow;

  @override
  State<_CompanionBaseImage> createState() => _CompanionBaseImageState();
}

class _CompanionBaseImageState extends State<_CompanionBaseImage>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _motion;
  late final DateTime _started;
  String? _resolvedPath;
  ui.Image? _frame;
  var _fallbackIndex = 0;

  @override
  void initState() {
    super.initState();
    _started = DateTime.now();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _resolvePath();
  }

  void _setPulse(bool run) {
    if (run == _pulse.isAnimating) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || run == _pulse.isAnimating) return;
      if (run) {
        _pulse.repeat(reverse: true);
      } else {
        _pulse.stop();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _CompanionBaseImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gender != widget.gender ||
        oldWidget.assetId != widget.assetId) {
      _fallbackIndex = 0;
      _resolvedPath = null;
      _frame?.dispose();
      _frame = null;
      _resolvePath();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _motion.dispose();
    _frame?.dispose();
    super.dispose();
  }

  Future<void> _resolvePath() async {
    final catalog = await CompanionBaseAssetCatalog.load();
    if (!mounted) return;
    final path = catalog.resolve(
      gender: widget.gender,
      assetId: widget.assetId,
    );
    final resolved = path ?? _candidateAt(_fallbackIndex);
    setState(() => _resolvedPath = resolved);
    if (resolved != null) {
      await _loadFrame(resolved);
    }
  }

  Future<void> _loadFrame(String path) async {
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted || _resolvedPath != path) {
        frame.image.dispose();
        return;
      }
      final previous = _frame;
      setState(() => _frame = frame.image);
      previous?.dispose();
    } catch (_) {}
  }

  String? _candidateAt(int index) {
    if (index < 0 || index >= widget.candidates.length) return null;
    return widget.candidates[index];
  }

  Widget _loadingPlaceholder() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final alpha = 0.12 + _pulse.value * 0.14;
        return Center(
          child: Container(
            width: widget.canvasSize.width * 0.62,
            height: widget.canvasSize.height * 0.62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.glow.withValues(alpha: alpha),
              boxShadow: [
                BoxShadow(
                  color: widget.glow.withValues(alpha: alpha * 1.4),
                  blurRadius: widget.canvasSize.width * 0.18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = _resolvedPath ?? _candidateAt(_fallbackIndex);
    if (path == null) {
      _setPulse(true);
      return SizedBox(
        width: widget.canvasSize.width,
        height: widget.canvasSize.height,
        child: _loadingPlaceholder(),
      );
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (widget.canvasSize.width * dpr).round().clamp(64, 512);
    final frame = _frame;
    if (frame != null) {
      return AnimatedBuilder(
        animation: _motion,
        builder: (context, _) {
          final time =
              DateTime.now().difference(_started).inMilliseconds / 1000.0;
          return CustomPaint(
            size: widget.canvasSize,
            painter: _MoodCompanionPainter(
              image: frame,
              moodId: widget.assetId,
              time: time,
            ),
          );
        },
      );
    }

    return Image.asset(
      path,
      width: widget.canvasSize.width,
      height: widget.canvasSize.height,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        final ready = wasSynchronouslyLoaded || frame != null;
        if (ready) {
          _setPulse(false);
          return child;
        }
        _setPulse(true);
        return SizedBox(
          width: widget.canvasSize.width,
          height: widget.canvasSize.height,
          child: _loadingPlaceholder(),
        );
      },
      errorBuilder: (_, __, ___) {
        final next = _fallbackIndex + 1;
        final nextPath = _candidateAt(next);
        if (nextPath != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _fallbackIndex = next;
                _resolvedPath = nextPath;
              });
            }
          });
        }
        return SizedBox(
          width: widget.canvasSize.width,
          height: widget.canvasSize.height,
          child: _loadingPlaceholder(),
        );
      },
    );
  }
}

class _MoodCompanionPainter extends CustomPainter {
  _MoodCompanionPainter({
    required this.image,
    required this.moodId,
    required this.time,
  });

  final ui.Image image;
  final String moodId;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final src =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final fitted = _contain(src.size, size);
    MoodCompanionMotion.paint(
      canvas,
      image: image,
      source: src,
      dest: fitted,
      moodId: moodId,
      time: time,
    );
  }

  Rect _contain(Size source, Size dest) {
    final scale =
        math.min(dest.width / source.width, dest.height / source.height);
    final width = source.width * scale;
    final height = source.height * scale;
    return Rect.fromCenter(
      center: Offset(dest.width / 2, dest.height / 2),
      width: width,
      height: height,
    );
  }

  @override
  bool shouldRepaint(covariant _MoodCompanionPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.moodId != moodId ||
        oldDelegate.image != image;
  }
}

class _Aura extends StatelessWidget {
  const _Aura({required this.glow, required this.tint});

  final Color glow;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            glow.withValues(alpha: 0.22),
            tint.withValues(alpha: 0.07),
            Colors.transparent,
          ],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}


