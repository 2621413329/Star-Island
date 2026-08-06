import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/version/app_version.dart';
import '../data/models/app_version_policy.dart';
import '../data/repositories/app_repository.dart';

class ForceUpdateState {
  const ForceUpdateState({
    required this.required,
    this.policy,
    this.localVersion,
  });

  final bool required;
  final AppVersionPolicy? policy;
  final String? localVersion;

  static const none = ForceUpdateState(required: false);
}

/// iOS 启动时检查是否需要强制更新。非 iOS / 请求失败时不拦截（fail-open）。
final forceUpdateProvider =
    FutureProvider<ForceUpdateState>((ref) async {
  if (kIsWeb || (!kIsWeb && !Platform.isIOS)) {
    return ForceUpdateState.none;
  }

  try {
    final info = await PackageInfo.fromPlatform();
    final policy =
        await ref.read(appVersionRepositoryProvider).getIosPolicy();
    final needUpdate = requiresForceUpdate(
      localVersion: info.version,
      minSupportedVersion: policy.minSupportedVersion,
    );
    return ForceUpdateState(
      required: needUpdate,
      policy: policy,
      localVersion: info.version,
    );
  } catch (error, stack) {
    debugPrint('force update check failed: $error\n$stack');
    return ForceUpdateState.none;
  }
});

final forceUpdateRequiredProvider = Provider<bool>((ref) {
  return ref.watch(forceUpdateProvider).valueOrNull?.required ?? false;
});
