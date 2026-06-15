import 'package:flutter/material.dart';

import '../core/platform/device_profile.dart';

/// 多端自适应外框：手机全屏、平板宽屏、桌面手机框预览。
class AdaptiveViewport extends StatelessWidget {
  const AdaptiveViewport({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final profile = DeviceProfile.fromSize(size);
        return ColoredBox(
          color: _backdropColor(profile),
          child: _wrapForTerminal(profile, constraints, child),
        );
      },
    );
  }

  Color _backdropColor(DeviceProfile profile) {
    return switch (profile.terminal) {
      AppTerminal.desktop => const Color(0xFFF0EBE3),
      AppTerminal.mobileTablet => const Color(0xFFF5F5F5),
      _ => Colors.white,
    };
  }

  Widget _wrapForTerminal(
    DeviceProfile profile,
    BoxConstraints constraints,
    Widget child,
  ) {
    switch (profile.terminal) {
      case AppTerminal.desktop:
        return _desktopPhoneFrame(profile, constraints, child);
      case AppTerminal.mobileTablet:
        return _tabletFrame(profile, constraints, child);
      case AppTerminal.mobilePhone:
      case AppTerminal.web:
        return child;
    }
  }

  Widget _desktopPhoneFrame(
    DeviceProfile profile,
    BoxConstraints constraints,
    Widget child,
  ) {
    if (profile.logicalSize.width <= 520) return child;

    final height = constraints.maxHeight.clamp(0.0, 844.0);
    return Center(
      child: Container(
        width: profile.desktopFrameWidth,
        height: height > 0 ? height : 844,
        constraints: BoxConstraints(
          maxWidth: profile.desktopFrameWidth,
          maxHeight: 844,
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

  Widget _tabletFrame(
    DeviceProfile profile,
    BoxConstraints constraints,
    Widget child,
  ) {
    final maxW = profile.tabletMaxWidth.clamp(520.0, constraints.maxWidth);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: child,
      ),
    );
  }
}

/// 设计基准尺寸（390×844 手机稿）。
abstract final class PhoneViewportDesign {
  static const Size designSize = Size(390, 844);
}
