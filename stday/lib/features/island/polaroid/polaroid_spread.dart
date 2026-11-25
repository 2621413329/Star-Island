import 'dart:math' as math;
import 'dart:ui';

import 'polaroid_skin.dart';

class PolaroidSpreadSlot {
  const PolaroidSpreadSlot({
    required this.left,
    required this.top,
    required this.angle,
  });

  final double left;
  final double top;
  final double angle;
}

/// 相册墙：从顶部排开，一行放不下就换行，多了就往右延伸。
class PolaroidSpread {
  const PolaroidSpread._();

  static const cardWidth = 136.0;
  static const edge = 12.0;
  static const gap = 16.0;
  static double get cardHeight => cardWidth / polaroidCardAspect;

  static int columnsFor(int count, double viewportWidth) {
    if (count <= 1) return 1;
    final width = viewportWidth.isFinite ? viewportWidth : cardWidth + gap;
    final fit = math.max(1, ((width - edge) / (cardWidth + gap)).floor());
    if (count <= fit) return count;
    return (count / 2).ceil();
  }

  static Size boardSize({
    required int count,
    required double viewportWidth,
  }) {
    final cols = columnsFor(count, viewportWidth);
    final rows = count <= 0 ? 1 : (count / cols).ceil();
    final width = math.max(
      viewportWidth.isFinite ? viewportWidth : cardWidth + gap,
      edge + cols * (cardWidth + gap),
    );
    final height = edge + rows * (cardHeight + gap);
    return Size(width, height);
  }

  static List<PolaroidSpreadSlot> slots(int count, Size board) {
    if (count <= 0) return const [];
    final cols = columnsFor(count, board.width);
    const angles = [-0.08, 0.06, -0.04, 0.07, -0.05, 0.03];
    return [
      for (var i = 0; i < count; i++)
        PolaroidSpreadSlot(
          left: edge + (i % cols) * (cardWidth + gap),
          top: edge + (i ~/ cols) * (cardHeight + gap),
          angle: angles[i % angles.length],
        ),
    ];
  }
}
