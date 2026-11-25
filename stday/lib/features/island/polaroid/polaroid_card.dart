import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/companion_write_asset.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../data/models/polaroid_models.dart';
import 'polaroid_island_snapshot.dart';
import 'polaroid_skin.dart';

class PolaroidFace extends StatelessWidget {
  const PolaroidFace({
    super.key,
    required this.card,
    required this.showBack,
    this.scene = PolaroidScene.fallback,
    this.onOpenMoment,
  });

  final PolaroidCardModel card;
  final bool showBack;
  final PolaroidScene scene;
  final ValueChanged<PolaroidSourceMoment>? onOpenMoment;

  @override
  Widget build(BuildContext context) {
    final skin = PolaroidSkin.resolve(card.skinId);
    // 大图和小图共用这一版面，缩略图只是整张拍立得的缩小。
    const designWidth = 340.0;
    final designHeight = designWidth / polaroidCardAspect;
    return AspectRatio(
      aspectRatio: polaroidCardAspect,
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: designWidth,
          height: designHeight,
          child: DecoratedBox(
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
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: showBack ? _back(skin) : _front(skin),
            ),
          ),
        ),
      ),
    );
  }

  Widget _front(PolaroidSkin skin) {
    return Column(
      children: [
        Expanded(
          flex: 8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: DecoratedBox(
              decoration: BoxDecoration(color: skin.edge),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PolaroidIslandSnapshot(card: card, scene: scene),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        CompanionWriteAssets.assetPathFor(card.companionRole),
                        width: 54,
                        height: 54,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          polaroidDateLine(card.islandName, card.takenAt),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: appTextStyle(fontSize: 15, color: skin.ink.withValues(alpha: 0.72)),
        ),
        const SizedBox(height: 2),
        Text(
          polaroidFrontLine(card),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: appTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: skin.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '屿之迹',
          maxLines: 1,
          style: appTextStyle(fontSize: 13, color: skin.ink.withValues(alpha: 0.55)),
        ),
      ],
    );
  }

  Widget _back(PolaroidSkin skin) {
    final summary = polaroidBackBody(card);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          polaroidDateLine(card.islandName, card.takenAt),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: appTextStyle(fontSize: 13, color: skin.ink.withValues(alpha: 0.72)),
        ),
        const SizedBox(height: 6),
        Text(
          card.buildingName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: appTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: skin.ink,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (summary.isNotEmpty)
                  Text(
                    summary,
                    style: appTextStyle(fontSize: 15, height: 1.45, color: skin.ink),
                  ),
                if (card.sourceMoments.isNotEmpty) ...[
                  const SizedBox(height: 12),
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
            ),
          ),
        ),
      ],
    );
  }
}

class PolaroidCard extends StatefulWidget {
  const PolaroidCard({
    super.key,
    required this.card,
    this.scene = PolaroidScene.fallback,
    this.onOpenMoment,
  });

  final PolaroidCardModel card;
  final PolaroidScene scene;
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
      scene: widget.scene,
      onOpenMoment: widget.onOpenMoment,
    );
    return GestureDetector(
      onTap: _toggle,
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
