import 'package:flutter/material.dart';

/// 桌面调试时约束为常见手机宽高；真机窄屏下占满屏幕。
class PhoneViewport extends StatelessWidget {
  const PhoneViewport({super.key, required this.child});

  /// 设计基准：iPhone 14 / 常见 Android 竖屏
  static const Size designSize = Size(390, 844);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth <= 520;
        Widget content = child;
        if (!isNarrow) {
          final height = constraints.maxHeight.clamp(0.0, designSize.height);
          content = Center(
            child: Container(
              width: designSize.width,
              height: height > 0 ? height : designSize.height,
              constraints: BoxConstraints(
                maxWidth: designSize.width,
                maxHeight: designSize.height,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 36,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          );
        }
        return ColoredBox(
          color: isNarrow ? Colors.white : const Color(0xFFF0EBE3),
          child: content,
        );
      },
    );
  }
}
