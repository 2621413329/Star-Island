import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bootstrap/app_bootstrap.dart';
import 'app_providers.dart';
import 'auth_provider.dart';

/// 必须在 [main] 里 override。
final appBootstrapProvider = Provider<AppBootstrap>(
  (ref) => throw StateError('appBootstrapProvider 未在 main 中初始化'),
);

/// 启动遮罩最短展示时间，避免原生图标页一闪而过、看不到品牌文案。
final appSplashHoldProvider =
    NotifierProvider<AppSplashHoldNotifier, bool>(AppSplashHoldNotifier.new);

class AppSplashHoldNotifier extends Notifier<bool> {
  static const holdDuration = Duration(milliseconds: 1400);

  @override
  bool build() {
    final timer = Timer(holdDuration, () {
      state = true;
    });
    ref.onDispose(timer.cancel);
    return false;
  }
}

/// 启动遮罩可消失：最短展示时间 + 未登录立即可用；已登录需 profile 完成加载或明确失败。
/// 若资料请求过久，最多等待 [startupProfileWaitCap] 后仍进入主界面，避免一直卡在启动页。
const startupProfileWaitCap = Duration(seconds: 8);

final startupProfileTimeoutProvider =
    NotifierProvider<StartupProfileTimeoutNotifier, bool>(
  StartupProfileTimeoutNotifier.new,
);

class StartupProfileTimeoutNotifier extends Notifier<bool> {
  @override
  bool build() {
    final timer = Timer(startupProfileWaitCap, () {
      state = true;
    });
    ref.onDispose(timer.cancel);
    return false;
  }
}

final startupSettledProvider = Provider<bool>((ref) {
  if (!ref.watch(appSplashHoldProvider)) return false;
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return true;
  final profile = ref.watch(profileProvider);
  final timedOut = ref.watch(startupProfileTimeoutProvider);
  return profile.hasValue || profile.hasError || timedOut;
});
