import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../data/models/polaroid_models.dart';
import 'polaroid_island_snapshot.dart';
import 'polaroid_skin.dart';

class PolaroidStackButton extends StatelessWidget {
  const PolaroidStackButton({
    super.key,
    required this.count,
    required this.onTap,
    this.preview,
    this.scene = PolaroidScene.fallback,
  });

  final int count;
  final VoidCallback onTap;
  final PolaroidCardModel? preview;
  final PolaroidScene scene;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final skin = PolaroidSkin.plain;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        height: 84,
        child: Stack(
          children: [
            Positioned(
              left: 8,
              top: 6,
              child: Transform.rotate(
                angle: -0.08,
                child: _sheet(skin, Colors.white, photo: false),
              ),
            ),
            Positioned(
              left: 4,
              top: 2,
              child: Transform.rotate(
                angle: 0.06,
                child: _sheet(skin, skin.paper, photo: true),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF5C4A3A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    '$count',
                    style: appTextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheet(PolaroidSkin skin, Color color, {required bool photo}) {
    final card = preview;
    return Container(
      width: 52,
      height: 64,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: skin.edge),
      ),
      child: photo && card != null
          ? Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
              child: ClipRRect(
                key: const Key('polaroid-stack-preview'),
                borderRadius: BorderRadius.circular(2),
                child: PolaroidIslandSnapshot(card: card, scene: scene),
              ),
            )
          : null,
    );
  }
}
