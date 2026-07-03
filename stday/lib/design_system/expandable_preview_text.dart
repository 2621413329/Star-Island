import 'package:flutter/material.dart';

/// 完整展示 [text]，不做字数截断；保留展开/收起参数以兼容旧调用。
class ExpandablePreviewText extends StatelessWidget {
  const ExpandablePreviewText({
    super.key,
    required this.text,
    required this.style,
    this.collapsedMaxChars = 100,
    this.expandedMaxChars,
    this.expandLabel = '展开',
    this.collapseLabel = '收起',
  });

  final String text;
  final TextStyle style;

  /// 已废弃：不再软截断，保留参数兼容旧调用。
  final int collapsedMaxChars;
  final int? expandedMaxChars;
  final String expandLabel;
  final String collapseLabel;

  @override
  Widget build(BuildContext context) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    return Text(trimmed, style: style);
  }
}
