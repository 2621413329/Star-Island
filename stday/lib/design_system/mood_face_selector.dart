import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/catalog.dart';
import 'mood_face_painter.dart';

/// Daylio 风格心情：点击即选中，无二次确认。
class MoodFaceSelector extends StatelessWidget {
  const MoodFaceSelector({
    super.key,
    this.selectedId,
    required this.onSelected,
    this.size = 56,
    this.showLabels = true,
  });

  final String? selectedId;
  final ValueChanged<String> onSelected;
  final double size;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: moods.map((m) {
        final selected = selectedId == m.id;
        return _MoodFaceButton(
          mood: m,
          selected: selected,
          size: size,
          showLabel: showLabels,
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(m.id);
          },
        );
      }).toList(),
    );
  }
}

class _MoodFaceButton extends StatefulWidget {
  const _MoodFaceButton({
    required this.mood,
    required this.selected,
    required this.size,
    required this.showLabel,
    required this.onTap,
  });

  final MoodOption mood;
  final bool selected;
  final double size;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  State<_MoodFaceButton> createState() => _MoodFaceButtonState();
}

class _MoodFaceButtonState extends State<_MoodFaceButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant _MoodFaceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _pulse.forward(from: 0).then((_) => _pulse.reverse());
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + (_pulse.value * 0.12);
  final ring = widget.selected ? 3.0 : 1.5;
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: widget.selected ? 1.08 * scale : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Container(
              width: widget.size + 12,
              height: widget.size + 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.mood.color, width: ring),
                boxShadow: widget.selected
                    ? [
                        BoxShadow(
                          color: widget.mood.color.withValues(alpha: 0.35),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: CustomPaint(
                  painter: MoodFacePainter(type: widget.mood.faceType, color: widget.mood.color),
                ),
              ),
            ),
          ),
          if (widget.showLabel) ...[
            const SizedBox(height: 6),
            Text(
              widget.mood.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: widget.mood.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
