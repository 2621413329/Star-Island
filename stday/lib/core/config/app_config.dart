import 'package:flutter/foundation.dart';

/// 开发时按平台修改：Android 模拟器用 10.0.2.2，真机用电脑局域网 IP。
class AppConfig {
  /// 生产环境 API 域名（经 Nginx 443 反代，无需端口）。
  static const productionApiHost = 'api.lcxxingyu.fun';

  static const productionApiScheme = String.fromEnvironment(
    'API_SCHEME',
    defaultValue: 'https',
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

  /// 仍支持完整 URL 覆盖；为空时 Release 用 [productionApiBaseUrl]，Debug 用本机 HTTP。
  static const _rawApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    final trimmed = _rawApiBaseUrl.trim();
    if (trimmed.isNotEmpty) return normalizeApiBaseUrl(trimmed);
    if (kReleaseMode) return productionApiBaseUrl;
    return buildApiBaseUrl(
      scheme: _schemeForHost(apiHost),
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

  /// 本机 / 模拟器开发仍走 HTTP；生产域名走 HTTPS。
  static String _schemeForHost(String host) {
    if (_isLocalHost(host)) return 'http';
    return productionApiScheme;
  }

  static bool _isLocalHost(String host) {
    final h = host.trim().toLowerCase();
    return h == '127.0.0.1' || h == 'localhost' || h == '10.0.2.2';
  }
}
