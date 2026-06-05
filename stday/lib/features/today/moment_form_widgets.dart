import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MomentTagChoice {
  const MomentTagChoice({
    required this.id,
    required this.label,
    required this.color,
    this.emoji,
    this.icon,
  });

  final String id;
  final String label;
  final Color color;
  final String? emoji;
  final IconData? icon;
}

class MomentTagSelector extends StatelessWidget {
  const MomentTagSelector({
    super.key,
    required this.selected,
    required this.options,
    required this.onPick,
    this.alignment = WrapAlignment.center,
  });

  final String? selected;
  final List<MomentTagChoice> options;
  final ValueChanged<String> onPick;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 18,
      alignment: alignment,
      runAlignment: alignment,
      children: options
          .map(
            (option) => MomentTagButton(
              option: option,
              selected: selected == option.id,
              onTap: () => onPick(option.id),
            ),
          )
          .toList(),
    );
  }
}

class MomentTagButton extends StatefulWidget {
  const MomentTagButton({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final MomentTagChoice option;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<MomentTagButton> createState() => _MomentTagButtonState();
}

class _MomentTagButtonState extends State<MomentTagButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant MomentTagButton oldWidget) {
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
    final color = widget.option.color;
    final scale = 1.0 + (_pulse.value * 0.12);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: widget.selected ? 1.08 * scale : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 62,
                height: 62,
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
                child: widget.option.icon != null
                    ? Icon(widget.option.icon, color: color, size: 30)
                    : Text(
                        widget.option.emoji ?? '•',
                        style: const TextStyle(fontSize: 26),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.option.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
