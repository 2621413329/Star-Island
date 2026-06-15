import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 终端形态：用于布局与渲染管线分流。
enum AppTerminal {
  web,
  mobilePhone,
  mobileTablet,
  desktop,
}

/// 当前设备的布局与渲染能力快照。
class DeviceProfile {
  const DeviceProfile({
    required this.terminal,
    required this.logicalSize,
    required this.devicePixelRatio,
  });

  final AppTerminal terminal;
  final Size logicalSize;
  final double devicePixelRatio;

  factory DeviceProfile.fromContext(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return DeviceProfile(
      terminal: _detectTerminal(mq),
      logicalSize: mq,
      devicePixelRatio: dpr,
    );
  }

  factory DeviceProfile.fromSize(Size size, {double devicePixelRatio = 1}) {
    return DeviceProfile(
      terminal: _detectTerminal(size),
      logicalSize: size,
      devicePixelRatio: devicePixelRatio,
    );
  }

  static AppTerminal _detectTerminal(Size size) {
    if (kIsWeb) return AppTerminal.web;
    if (_isDesktopPlatform) return AppTerminal.desktop;
    if (size.shortestSide >= 600) return AppTerminal.mobileTablet;
    return AppTerminal.mobilePhone;
  }

  static bool get _isDesktopPlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    } on Object {
      return defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS;
    }
  }

  bool get preferCompactIsland =>
      terminal == AppTerminal.mobilePhone || logicalSize.width <= 520;

  double get desktopFrameWidth => 390;
  double get tabletMaxWidth => 720;

  bool get isWideLayout => logicalSize.width > 520;
}
