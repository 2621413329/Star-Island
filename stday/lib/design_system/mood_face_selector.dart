import 'package:flutter/material.dart';

import '../core/constants/emotion_catalog.dart';
import '../core/utils/mood_face_paths.dart';
import 'mood_face_icon.dart';
import 'pressable_feedback.dart';

/// AI 感受心情选择器（10 种感受，双行网格）。
class MoodFaceSelector extends StatelessWidget {
  const MoodFaceSelector({
    super.key,
    this.selectedId,
    required this.onSelected,
    this.size = 56,
    this.showLabels = true,
    this.gender,
  });

  final String? selectedId;
  final ValueChanged<String> onSelected;
  final double size;
  final bool showLabels;
  final String? gender;

  static const _buttonDiameter = 62.0;
  static const _columns = 5;

  static double _circleSizeForSlot(double slotWidth, double preferredSize) {
    final inner = (slotWidth - 8).clamp(40.0, preferredSize);
    return inner.clamp(40.0, _buttonDiameter - 8);
  }

  @override
  Widget build(BuildContext context) {
    final emotions = emotionPickerCatalog();
    final normalizedSelected =
        selectedId == null ? null : normalizeEmotionId(selectedId);

    return LayoutBuilder(
      builder: (context, constraints) {
        var maxW = constraints.maxWidth;
        if (!maxW.isFinite || maxW <= 0) {
          maxW = MediaQuery.sizeOf(context).width - 72;
        }
        final slotW = maxW / _columns;
        final faceSize = _circleSizeForSlot(slotW, size);
        final labelSize = slotW < 58 ? 10.0 : 12.0;

        return Wrap(
          spacing: 0,
          runSpacing: showLabels ? 10 : 6,
          children: [
            for (final emotion in emotions)
              SizedBox(
                width: slotW,
                child: _EmotionFaceButton(
                  emotion: emotion,
                  assetPath:
                      moodFaceAssetPath(emotion.id, gender: gender),
                  gender: gender,
                  selected: normalizedSelected == emotion.id,
                  faceSize: faceSize,
                  slotWidth: slotW,
                  labelFontSize: labelSize,
                  showLabel: showLabels,
                  onTap: () => onSelected(emotion.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmotionFaceButton extends StatefulWidget {
  const _EmotionFaceButton({
    required this.emotion,
    required this.assetPath,
    required this.gender,
    required this.selected,
    required this.faceSize,
    required this.slotWidth,
    required this.labelFontSize,
    required this.showLabel,
    required this.onTap,
  });

  final EmotionDefinition emotion;
  final String? assetPath;
  final String? gender;
  final bool selected;
  final double faceSize;
  final double slotWidth;
  final double labelFontSize;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  State<_EmotionFaceButton> createState() => _EmotionFaceButtonState();
}

class _EmotionFaceButtonState extends State<_EmotionFaceButton>
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
  void didUpdateWidget(covariant _EmotionFaceButton oldWidget) {
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
    final color = widget.emotion.color;
    final scale = 1.0 + (_pulse.value * 0.12);
    const frameSize = MoodFaceSelector._buttonDiameter;
    final innerSize = frameSize * 0.88;

    return PressableFeedback(
      onTap: widget.onTap,
      feedback: PressFeedbackType.selection,
      pressedScale: 0.94,
      selectedScale: widget.selected ? 1.08 * scale : 1,
      semanticLabel: widget.emotion.label,
      selected: widget.selected,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: widget.slotWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: frameSize,
              height: frameSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.selected
                    ? color.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.selected
                      ? color
                      : color.withValues(alpha: 0.35),
                  width: widget.selected ? 2 : 1,
                ),
              ),
              child: ClipOval(
                child: Padding(
                  padding: EdgeInsets.all(frameSize * 0.06),
                  child: widget.assetPath != null
                      ? Image.asset(
                          widget.assetPath!,
                          width: innerSize,
                          height: innerSize,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => MoodFaceIcon(
                            type: widget.emotion.faceType,
                            color: color,
                            size: innerSize,
                            moodId: widget.emotion.id,
                            gender: widget.gender,
                          ),
                        )
                      : MoodFaceIcon(
                          type: widget.emotion.faceType,
                          color: color,
                          size: innerSize,
                          moodId: widget.emotion.id,
                          gender: widget.gender,
                        ),
                ),
              ),
            ),
            if (widget.showLabel) ...[
              const SizedBox(height: 6),
              Text(
                widget.emotion.label,
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
