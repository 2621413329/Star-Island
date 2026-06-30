import 'package:flutter/material.dart';

/// 默认展示 [collapsedMaxChars] 字，可展开至 [expandedMaxChars] 字。
class ExpandablePreviewText extends StatefulWidget {
  const ExpandablePreviewText({
    super.key,
    required this.text,
    required this.style,
    this.collapsedMaxChars = 100,
    this.expandedMaxChars = 150,
    this.expandLabel = '展开',
    this.collapseLabel = '收起',
  });

  final String text;
  final TextStyle style;
  final int collapsedMaxChars;
  final int expandedMaxChars;
  final String expandLabel;
  final String collapseLabel;

  @override
  State<ExpandablePreviewText> createState() => _ExpandablePreviewTextState();
}

class _ExpandablePreviewTextState extends State<ExpandablePreviewText> {
  var _expanded = false;

  String _clip(String value, int maxChars) {
    final chars = value.characters;
    if (chars.length <= maxChars) return value;
    return '${chars.take(maxChars)}…';
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = widget.text.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    final total = trimmed.characters.length;
    final canExpand = total > widget.collapsedMaxChars;
    final display = _expanded
        ? _clip(trimmed, widget.expandedMaxChars)
        : _clip(trimmed, widget.collapsedMaxChars);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(display, style: widget.style),
        if (canExpand)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                _expanded ? widget.collapseLabel : widget.expandLabel,
                style: widget.style.copyWith(
                  fontSize: (widget.style.fontSize ?? 13) - 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
