import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/companion_base_asset.dart';
import 'companion_base_asset_catalog.dart';
import 'companion_prop_asset_catalog.dart';

/// 图片化小人：本体和配饰都来自 assets，方便后续直接替换 PNG。
class CompanionAssetAvatar extends StatelessWidget {
  const CompanionAssetAvatar({
    super.key,
    required this.style,
    required this.expression,
    required this.prop,
    required this.extraProps,
    required this.tint,
    required this.glow,
    required this.performanceLevel,
    required this.showAura,
    required this.gender,
    required this.size,
  });

  final String style;
  final String expression;
  final String prop;
  final List<String> extraProps;
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
    final props = _visibleProps([prop, ...extraProps]);
    final singleProp = props.length == 1;
    final propSlots = singleProp ? _singlePropSlots : _propSlots;
    final propOverflow = singleProp ? size * 0.14 : 0.0;
    final propTopInset = singleProp ? size * 0.06 : 0.0;
    final canvasSize = Size(size, size * 1.15);

    return Padding(
      padding: EdgeInsets.only(right: propOverflow, top: propTopInset),
      child: SizedBox(
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
            for (var i = 0; i < props.length && i < propSlots.length; i++)
              _PropImage(
                prop: props[i],
                slot: propSlots[i],
                avatarSize: size,
              ),
          ],
        ),
      ),
    );
  }

  static List<String> _visibleProps(List<String> props) {
    final seen = <String>{};
    for (final prop in props) {
      if (prop != 'none' && seen.add(prop)) {
        return [prop];
      }
    }
    return const [];
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  String? _resolvedPath;
  var _fallbackIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _resolvePath();
  }

  @override
  void didUpdateWidget(covariant _CompanionBaseImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gender != widget.gender ||
        oldWidget.assetId != widget.assetId) {
      _fallbackIndex = 0;
      _resolvedPath = null;
      _resolvePath();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _resolvePath() async {
    final catalog = await CompanionBaseAssetCatalog.load();
    if (!mounted) return;
    final path = catalog.resolve(
      gender: widget.gender,
      assetId: widget.assetId,
    );
    setState(() {
      _resolvedPath = path ?? _candidateAt(_fallbackIndex);
    });
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
      return SizedBox(
        width: widget.canvasSize.width,
        height: widget.canvasSize.height,
        child: _loadingPlaceholder(),
      );
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth =
        (widget.canvasSize.width * dpr).round().clamp(64, 512);

    return Image.asset(
      path,
      width: widget.canvasSize.width,
      height: widget.canvasSize.height,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
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

class _PropSlot {
  const _PropSlot({
    required this.alignment,
    required this.sizeFactor,
  });

  final Alignment alignment;
  final double sizeFactor;
}

const _propSlots = [
  _PropSlot(alignment: Alignment(-0.74, -0.12), sizeFactor: 0.27),
  _PropSlot(alignment: Alignment(0.74, 0.02), sizeFactor: 0.29),
  _PropSlot(alignment: Alignment(0.52, -0.38), sizeFactor: 0.24),
  _PropSlot(alignment: Alignment(-0.42, 0.40), sizeFactor: 0.22),
];

/// 日常卡片等场景只展示一个配饰时，固定在小人头部右上角。
const _singlePropSlots = [
  _PropSlot(alignment: Alignment(0.54, -0.50), sizeFactor: 0.30),
];

class _PropImage extends StatelessWidget {
  const _PropImage({
    required this.prop,
    required this.slot,
    required this.avatarSize,
  });

  final String prop;
  final _PropSlot slot;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final propSize = avatarSize * slot.sizeFactor;
    return Align(
      alignment: slot.alignment,
      child: FutureBuilder<CompanionPropAssetCatalog>(
        future: CompanionPropAssetCatalog.load(),
        builder: (context, snapshot) {
          final catalog = snapshot.data;
          final assetPath =
              catalog?.resolve(prop) ?? '$companionPropAssetDir/$prop.png';
          if (assetPath.toLowerCase().endsWith('.svg')) {
            return SvgPicture.asset(
              assetPath,
              width: propSize,
              height: propSize,
              fit: BoxFit.contain,
            );
          }
          return Image.asset(
            assetPath,
            width: propSize,
            height: propSize,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
