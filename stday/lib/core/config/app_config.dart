/// 开发时按平台修改：Android 模拟器用 10.0.2.2，真机用电脑局域网 IP。
class AppConfig {
  static const String _rawApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:9000',
  );

  /// 非本机地址统一走 HTTPS，避免 Release 包误用明文 HTTP。
  static String get apiBaseUrl => normalizeApiBaseUrl(_rawApiBaseUrl);

  static String normalizeApiBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'https://39.106.134.222:8000';

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      return trimmed.startsWith('https://') ? trimmed : 'https://$trimmed';
    }

    if (_isLocalDevHost(uri.host)) return trimmed;

    if (uri.scheme == 'http') {
      return uri.replace(scheme: 'https').toString();
    }
    if (uri.scheme.isEmpty) {
      return 'https://$trimmed';
    }
    return trimmed;
  }

  static bool _isLocalDevHost(String host) {
    return host == '127.0.0.1' ||
        host == 'localhost' ||
        host == '10.0.2.2';
  }
}
