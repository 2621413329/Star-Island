import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/companion_write_asset.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../data/models/polaroid_models.dart';
import 'polaroid_flip.dart';
import 'polaroid_skin.dart';

class PolaroidFace extends StatelessWidget {
  const PolaroidFace({
    super.key,
    required this.card,
    required this.showBack,
    this.onOpenMoment,
  });

  final PolaroidCardModel card;
  final bool showBack;
  final ValueChanged<PolaroidSourceMoment>? onOpenMoment;

  @override
  Widget build(BuildContext context) {
    final skin = PolaroidSkin.resolve(card.skinId);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: skin.paper,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
        child: showBack ? _back(skin) : _front(skin),
      ),
    );
  }

  Widget _front(PolaroidSkin skin) {
    final asset = polaroidImageAsset(card.assetKey);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: skin.edge,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (asset != null)
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Image.asset(
                      asset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      CompanionWriteAssets.assetPathFor(card.companionRole),
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          polaroidDateLine(card.islandName, card.takenAt),
          textAlign: TextAlign.center,
          style: appTextStyle(fontSize: 13, color: skin.ink.withValues(alpha: 0.72)),
        ),
        const SizedBox(height: 4),
        Text(
          card.frontCaption,
          key: const Key('polaroid-front-caption'),
          textAlign: TextAlign.center,
          style: appTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: skin.ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '屿之迹',
          style: appTextStyle(fontSize: 12, color: skin.ink.withValues(alpha: 0.55)),
        ),
      ],
    );
  }

  Widget _back(PolaroidSkin skin) {
    final summary = card.isDeveloping
        ? '正在显影'
        : (card.backSummary?.trim().isNotEmpty == true
            ? card.backSummary!.trim()
            : '');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          polaroidDateLine(card.islandName, card.takenAt),
          style: appTextStyle(fontSize: 13, color: skin.ink.withValues(alpha: 0.72)),
        ),
        const SizedBox(height: 8),
        Text(
          card.buildingName,
          style: appTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: skin.ink,
          ),
        ),
        if (summary.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            summary,
            key: const Key('polaroid-back-summary'),
            style: appTextStyle(fontSize: 15, height: 1.45, color: skin.ink),
          ),
        ],
        if (card.sourceMoments.isNotEmpty) ...[
          const SizedBox(height: 14),
          for (final moment in card.sourceMoments)
            InkWell(
              onTap: onOpenMoment == null ? null : () => onOpenMoment!(moment),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${moment.momentDate.month}月${moment.momentDate.day}日  ${moment.excerpt}',
                  key: Key('polaroid-source-${moment.id}'),
                  style: appTextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: skin.ink.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class PolaroidCard extends StatefulWidget {
  const PolaroidCard({
    super.key,
    required this.card,
    this.onNext,
    this.onPrevious,
    this.onOpenMoment,
  });

  final PolaroidCardModel card;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final ValueChanged<PolaroidSourceMoment>? onOpenMoment;

  @override
  State<PolaroidCard> createState() => _PolaroidCardState();
}

class _PolaroidCardState extends State<PolaroidCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _snap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  double _angle = 0;
  double _panDx = 0;
  double _panDy = 0;
  bool _showBack = false;
  Animation<double>? _snapAnimation;

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _snapAnimation?.removeListener(_onSnapTick);
    final animation = Tween<double>(begin: _angle, end: target).animate(
      CurvedAnimation(parent: _snap, curve: Curves.easeOutCubic),
    );
    _snapAnimation = animation;
    animation.addListener(_onSnapTick);
    _snap.forward(from: 0);
  }

  void _onSnapTick() {
    final value = _snapAnimation?.value ?? _angle;
    if (!mounted) return;
    setState(() => _angle = value);
  }

  void _toggle() {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      setState(() => _showBack = !_showBack);
      return;
    }
    _animateTo(_angle < math.pi / 2 ? math.pi : 0);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final showingBack = reduce ? _showBack : _angle >= math.pi / 2;
    final face = PolaroidFace(
      card: widget.card,
      showBack: showingBack,
      onOpenMoment: widget.onOpenMoment,
    );
    return GestureDetector(
      onTap: _toggle,
      onPanUpdate: (details) {
        _panDx += details.delta.dx;
        _panDy += details.delta.dy;
        _snap.stop();
        if (reduce || _panDx.abs() <= _panDy.abs()) return;
        final width = context.size?.width ?? 280;
        setState(() {
          _angle = PolaroidFlip.clampAngle(
            _angle + details.delta.dx / width * math.pi,
          );
        });
      },
      onPanEnd: (details) {
        final page = PolaroidFlip.pageDirection(dx: _panDx, dy: _panDy);
        _panDx = 0;
        _panDy = 0;
        if (page > 0) {
          widget.onNext?.call();
          return;
        }
        if (page < 0) {
          widget.onPrevious?.call();
          return;
        }
        if (!reduce) _animateTo(PolaroidFlip.snapAngle(_angle));
      },
      child: reduce
          ? face
          : Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(_angle),
              child: showingBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: face,
                    )
                  : face,
            ),
    );
  }
}
