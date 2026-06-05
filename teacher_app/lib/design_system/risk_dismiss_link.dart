import 'package:flutter/material.dart';

/// 与档案危险记录一致的「非危险信号，撤销标记」文字链。
class RiskDismissLink extends StatelessWidget {
  const RiskDismissLink({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.label = '非危险信号，撤销标记',
    this.alignment = Alignment.center,
  });

  final VoidCallback? onPressed;
  final bool loading;
  final String label;
  final Alignment alignment;

  static const Color linkColor = Color(0xFFD4A574);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: TextButton.icon(
        onPressed: loading ? null : onPressed,
        icon: Icon(
          Icons.delete_outline_rounded,
          size: 17,
          color: loading ? linkColor.withValues(alpha: 0.45) : linkColor,
        ),
        label: Text(
          loading ? '处理中…' : label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: loading ? linkColor.withValues(alpha: 0.45) : linkColor,
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: linkColor,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
