import 'package:flutter/material.dart';

/// 线性铅笔 + 下方短横线（「开始记录」按钮专用，非图片资源）。
class HealingRecordPencilIcon extends StatelessWidget {
  const HealingRecordPencilIcon({
    super.key,
    required this.size,
    this.color = Colors.white,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HealingRecordPencilPainter(color: color),
    );
  }
}

class _HealingRecordPencilPainter extends CustomPainter {
  const _HealingRecordPencilPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.078;
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.38);
    canvas.rotate(-0.72);

    final bodyW = size.width * 0.19;
    final bodyH = size.width * 0.50;
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -bodyH * 0.06),
        width: bodyW,
        height: bodyH,
      ),
      Radius.circular(bodyW * 0.28),
    );
    canvas.drawRRect(body, paint);

    final tipY = bodyH * 0.5 - bodyH * 0.06;
    canvas.drawLine(
      Offset(0, tipY),
      Offset(0, tipY + bodyW * 0.55),
      paint..strokeWidth = stroke * 0.95,
    );

    final eraserY = -bodyH * 0.5 - bodyH * 0.06;
    canvas.drawLine(
      Offset(-bodyW * 0.32, eraserY),
      Offset(bodyW * 0.32, eraserY),
      paint..strokeWidth = stroke * 0.85,
    );
    canvas.restore();

    final lineY = size.height * 0.74;
    canvas.drawLine(
      Offset(size.width * 0.30, lineY),
      Offset(size.width * 0.70, lineY),
      paint..strokeWidth = stroke * 0.92,
    );
  }

  @override
  bool shouldRepaint(covariant _HealingRecordPencilPainter oldDelegate) =>
      oldDelegate.color != color;
}
