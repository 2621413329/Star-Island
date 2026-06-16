import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 提醒图标预览：支持 PNG / WebP / SVG。
class ReminderIconPreview extends StatelessWidget {
  const ReminderIconPreview({
    super.key,
    required this.assetPath,
    this.size = 40,
    this.color,
    this.fallbackIcon = Icons.notifications_outlined,
  });

  final String assetPath;
  final double size;
  final Color? color;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final lower = assetPath.toLowerCase();
    if (lower.endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: color != null
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
        placeholderBuilder: (_) => _fallback(),
      );
    }
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Icon(
      fallbackIcon,
      size: size * 0.72,
      color: color ?? Colors.grey,
    );
  }
}
