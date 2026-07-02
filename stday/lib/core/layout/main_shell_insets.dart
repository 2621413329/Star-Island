import 'package:flutter/material.dart';

/// MainShell 内页内容区安全边距（浮动底栏 + 状态栏）。
abstract final class MainShellInsets {
  /// 底栏绘制高度（与 [_FloatingMainNavigationBar] 一致）。
  static const tabBarHeight = 70.0;

  /// 底栏上方留白，避免 FAB 与内容重叠。
  static const tabBarClearance = 12.0;

  static double top(BuildContext context) =>
      MediaQuery.paddingOf(context).top;

  static double bottom(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom +
      tabBarHeight +
      tabBarClearance;

  static EdgeInsets content(BuildContext context) => EdgeInsets.only(
        top: top(context),
        bottom: bottom(context),
      );
}
