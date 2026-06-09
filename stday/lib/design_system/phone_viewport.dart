import 'package:flutter/material.dart';

import 'adaptive_viewport.dart';

/// 兼容旧名；内部使用 [AdaptiveViewport]。
@Deprecated('Use AdaptiveViewport')
class PhoneViewport extends AdaptiveViewport {
  const PhoneViewport({super.key, required super.child});

  static const Size designSize = PhoneViewportDesign.designSize;
}
