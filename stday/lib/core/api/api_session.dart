typedef ForceReloginCallback = Future<void> Function();

ForceReloginCallback? _forceRelogin;

/// 由 [dioProvider] 注册；仅在鉴权失败时清除 token。
void registerForceRelogin(ForceReloginCallback callback) {
  _forceRelogin = callback;
}

bool shouldForceRelogin(int? statusCode) => statusCode == 401;

Future<void> forceReloginIfNeeded({int? statusCode}) async {
  if (!shouldForceRelogin(statusCode)) return;
  await _forceRelogin?.call();
}
