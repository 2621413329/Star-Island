import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import 'polaroid_skin.dart';

class PolaroidStackButton extends StatelessWidget {
  const PolaroidStackButton({
    super.key,
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

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
                child: _sheet(skin, Colors.white),
              ),
            ),
            Positioned(
              left: 4,
              top: 2,
              child: Transform.rotate(
                angle: 0.06,
                child: _sheet(skin, skin.paper),
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

  Widget _sheet(PolaroidSkin skin, Color color) {
    return Container(
      width: 52,
      height: 64,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: skin.edge),
      ),
    );
  }
}
