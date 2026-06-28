/// 开发时按平台修改：Android 模拟器用 10.0.2.2，真机用电脑局域网 IP。
class AppConfig {
  /// 生产环境 API 域名。协议由 [productionApiScheme] 控制，便于 HTTP/HTTPS 快速切换。
  static const productionApiHost = 'api.lcxxingyu.fun';

  /// 日后切 HTTPS 可通过 `--dart-define=API_SCHEME=https` 覆盖。
  static const productionApiScheme = String.fromEnvironment(
    'API_SCHEME',
    defaultValue: 'http',
  );

  static String get productionApiBaseUrl => buildApiBaseUrl(
        scheme: productionApiScheme,
        host: productionApiHost,
      );

  static const apiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '127.0.0.1',
  );

  static const apiPort = String.fromEnvironment(
    'API_PORT',
    defaultValue: '9000',
  );

  /// 仍支持完整 URL 覆盖；为空时由 scheme/host/port 组装。
  static const _rawApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    final trimmed = _rawApiBaseUrl.trim();
    if (trimmed.isNotEmpty) return normalizeApiBaseUrl(trimmed);
    return buildApiBaseUrl(
      scheme: productionApiScheme,
      host: apiHost,
      port: apiPort,
    );
  }

  static String normalizeApiBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return productionApiBaseUrl;
    return trimmed;
  }

  static String buildApiBaseUrl({
    required String scheme,
    required String host,
    String port = '',
  }) {
    final normalizedScheme = scheme.trim().replaceAll(RegExp(r':/*$'), '');
    final normalizedHost = host.trim();
    final normalizedPort = port.trim();
    final shouldUsePort =
        normalizedPort.isNotEmpty && !normalizedHost.contains(':');
    return '$normalizedScheme://$normalizedHost'
        '${shouldUsePort ? ':$normalizedPort' : ''}';
  }
}
