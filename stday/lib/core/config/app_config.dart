/// 开发时按平台修改：Android 模拟器用 10.0.2.2，真机用电脑局域网 IP。
class AppConfig {
  /// 生产环境统一入口（HTTPS 443，由 Nginx 反代本机 uvicorn）。
  static const productionApiBaseUrl = 'https://api.lcxxingyu.fun';

  static const String _rawApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:9000',
  );

  /// 非本机地址一律走 HTTPS；8000/8090/9000 等端口仅作本机反代，不对外暴露。
  static String get apiBaseUrl => normalizeApiBaseUrl(_rawApiBaseUrl);

  static String normalizeApiBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return productionApiBaseUrl;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      return trimmed.startsWith('https://') ? trimmed : 'https://$trimmed';
    }

    if (_isLocalDevHost(uri.host)) return trimmed;

    if (uri.scheme == 'http' || uri.scheme.isEmpty) {
      return _toHttps(uri);
    }
    return _stripLegacyPort(uri);
  }

  static String _toHttps(Uri uri) {
    return _stripLegacyPort(uri.replace(scheme: 'https'));
  }

  /// 历史直连端口（8000/8090/9000/80）经 Nginx 443 对外，URL 中不写端口。
  static String _stripLegacyPort(Uri uri) {
    if (!uri.hasPort) return uri.toString();
    const legacyPorts = {80, 443, 8000, 8090, 9000};
    if (legacyPorts.contains(uri.port)) {
      return uri.replace(port: null).toString();
    }
    return uri.toString();
  }

  static bool _isLocalDevHost(String host) {
    return host == '127.0.0.1' ||
        host == 'localhost' ||
        host == '10.0.2.2';
  }
}
