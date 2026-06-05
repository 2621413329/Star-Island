import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bootstrap/app_bootstrap.dart';
import 'app_providers.dart';
import 'auth_provider.dart';

/// 必须在 [main] 里 override。
final appBootstrapProvider = Provider<AppBootstrap>(
  (ref) => throw StateError('appBootstrapProvider 未在 main 中初始化'),
);

/// 启动遮罩可消失：未登录立即可用；已登录需 profile 至少完成一次加载。
final startupSettledProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) return true;
  final profile = ref.watch(profileProvider);
  return profile.hasValue;
});
