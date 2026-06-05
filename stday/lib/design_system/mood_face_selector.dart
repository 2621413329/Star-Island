import 'package:flutter/material.dart';

import '../core/constants/catalog.dart';
import 'mood_face_icon.dart';
import 'pressable_feedback.dart';

/// Daylio 风格心情；选中样式与 [MomentTagButton] 一致。
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

  static const _buttonDiameter = 62.0;

  static double _circleSizeForSlot(double slotWidth, double preferredSize) {
    final inner = (slotWidth - 8).clamp(40.0, preferredSize);
    return inner.clamp(40.0, _buttonDiameter - 8);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var maxW = constraints.maxWidth;
        if (!maxW.isFinite || maxW <= 0) {
          maxW = MediaQuery.sizeOf(context).width - 72;
        }
        final slotW = maxW / moods.length;
        final faceSize = _circleSizeForSlot(slotW, size);
        final labelSize = slotW < 58 ? 10.0 : 12.0;

        return Row(
          children: moods.map((m) {
            final selected = selectedId == m.id;
            return Expanded(
              child: _MoodFaceButton(
                mood: m,
                selected: selected,
                faceSize: faceSize,
                slotWidth: slotW,
                labelFontSize: labelSize,
                showLabel: showLabels,
                onTap: () => onSelected(m.id),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MoodFaceButton extends StatefulWidget {
  const _MoodFaceButton({
    required this.mood,
    required this.selected,
    required this.faceSize,
    required this.slotWidth,
    required this.labelFontSize,
    required this.showLabel,
    required this.onTap,
  });

  final MoodOption mood;
  final bool selected;
  final double faceSize;
  final double slotWidth;
  final double labelFontSize;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  State<_MoodFaceButton> createState() => _MoodFaceButtonState();
}

class _MoodFaceButtonState extends State<_MoodFaceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() => setState(() {}));
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
    final color = widget.mood.color;
    final scale = 1.0 + (_pulse.value * 0.12);

    return PressableFeedback(
      onTap: widget.onTap,
      feedback: PressFeedbackType.selection,
      pressedScale: 0.94,
      selectedScale: widget.selected ? 1.08 * scale : 1,
      semanticLabel: widget.mood.label,
      selected: widget.selected,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: widget.slotWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: MoodFaceSelector._buttonDiameter,
              height: MoodFaceSelector._buttonDiameter,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.selected
                    ? color.withValues(alpha: 0.12)
                    : Colors.transparent,
                border: Border.all(
                  color: color,
                  width: widget.selected ? 3 : 1.5,
                ),
                boxShadow: widget.selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.32),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: MoodFaceIcon(
                type: widget.mood.faceType,
                color: color,
                size: widget.faceSize,
              ),
            ),
            if (widget.showLabel) ...[
              const SizedBox(height: 6),
              Text(
                widget.mood.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: widget.labelFontSize,
                  fontWeight:
                      widget.selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
