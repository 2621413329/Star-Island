/// 开发时按平台修改：Android 模拟器用 10.0.2.2，真机用电脑局域网 IP。
class AppConfig {
  /// 生产环境 HTTP 入口（Nginx 80 反代本机 uvicorn）。
  /// 日后切 HTTPS 时改为: https://api.lcxxingyu.fun
  static const productionApiBaseUrl = 'http://api.lcxxingyu.fun';

  static const String _rawApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:9000',
  );

  static String get apiBaseUrl => normalizeApiBaseUrl(_rawApiBaseUrl);

  static String normalizeApiBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return productionApiBaseUrl;
    return trimmed;
  }
}
