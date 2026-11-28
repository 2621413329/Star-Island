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

/// 相册墙：一行两张，从顶部排开，多的往下排，上下滑动。
class PolaroidSpread {
  const PolaroidSpread._();

  static const columns = 2;
  static const edge = 12.0;
  static const gap = 16.0;

  static double cardWidthFor(double viewportWidth) {
    final width = viewportWidth.isFinite && viewportWidth > 0
        ? viewportWidth
        : 360.0;
    return (width - edge * 2 - gap) / columns;
  }

  static double cardHeightFor(double viewportWidth) =>
      cardWidthFor(viewportWidth) / polaroidCardAspect;

  static int columnsFor(int count, double viewportWidth) {
    if (count <= 1) return 1;
    return columns;
  }

  static Size boardSize({
    required int count,
    required double viewportWidth,
  }) {
    final width = viewportWidth.isFinite && viewportWidth > 0
        ? viewportWidth
        : 360.0;
    final cols = columnsFor(count, width);
    final rows = count <= 0 ? 1 : (count / cols).ceil();
    final cardHeight = cardHeightFor(width);
    return Size(width, edge + rows * (cardHeight + gap));
  }

  static List<PolaroidSpreadSlot> slots(int count, Size board) {
    if (count <= 0) return const [];
    final cols = columnsFor(count, board.width);
    final cardWidth = cardWidthFor(board.width);
    final cardHeight = cardHeightFor(board.width);
    final rowWidth = cols * cardWidth + (cols - 1) * gap;
    final start = (board.width - rowWidth) / 2;
    const angles = [-0.08, 0.06, -0.04, 0.07, -0.05, 0.03];
    return [
      for (var i = 0; i < count; i++)
        PolaroidSpreadSlot(
          left: start + (i % cols) * (cardWidth + gap),
          top: edge + (i ~/ cols) * (cardHeight + gap),
          angle: angles[i % angles.length],
        ),
    ];
  }
}
