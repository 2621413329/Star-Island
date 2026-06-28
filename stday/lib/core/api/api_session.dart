typedef AccessTokenReader = String? Function();
typedef ForceReloginCallback = Future<void> Function();

class ApiSessionCallbacks {
  const ApiSessionCallbacks({
    required this.readAccessToken,
    required this.forceRelogin,
  });

  final AccessTokenReader readAccessToken;
  final ForceReloginCallback forceRelogin;
}

ApiSessionCallbacks? _callbacks;

/// 由应用鉴权层注册；网络层只依赖此抽象，不直接依赖 auth provider。
void registerApiSession(ApiSessionCallbacks callbacks) {
  _callbacks = callbacks;
}

String? readAccessToken() => _callbacks?.readAccessToken();

bool shouldForceRelogin(int? statusCode) => statusCode == 401;

Future<void> forceReloginIfNeeded({int? statusCode}) async {
  if (!shouldForceRelogin(statusCode)) return;
  await _callbacks?.forceRelogin();
}
