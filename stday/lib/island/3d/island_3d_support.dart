import 'package:flutter/material.dart' show Size;

import '../../core/platform/device_profile.dart';

/// 运行时 3D 能力探测（委托 [IslandRenderPolicy]）。
class Island3DSupport {
  Island3DSupport._();

  static bool get isRuntimeSupported {
    const phone = DeviceProfile(
      terminal: AppTerminal.mobilePhone,
      logicalSize: Size(390, 844),
      devicePixelRatio: 1,
    );
    return phone.supportsFlame3DNative;
  }

  static bool shouldUse3D({
    required bool prefer3D,
    DeviceProfile? profile,
  }) {
    final p = profile ??
        const DeviceProfile(
          terminal: AppTerminal.mobilePhone,
          logicalSize: Size(390, 844),
          devicePixelRatio: 1,
        );
    return IslandRenderPolicy.shouldUse3D(profile: p, prefer3D: prefer3D);
  }

  static void disableAfterFailure() => IslandRenderPolicy.disable3DAfterFailure();
}
