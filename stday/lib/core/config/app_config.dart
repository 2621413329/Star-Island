/// 开发时按平台修改：Android 模拟器用 10.0.2.2，真机用电脑局域网 IP。
class AppConfig {
  static const String _rawApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:9000',
  );

  /// 非本机地址默认走 HTTPS（仅标准 80 端口）；自定义端口保留构建时协议。
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
      final port = uri.hasPort ? uri.port : 80;
      // 非 80 端口多为自建 HTTP 服务（如 8090/9000），勿强行升级为 HTTPS，
      // 否则客户端发 TLS 握手到明文端口，服务端会报 Invalid HTTP request received。
      if (port != 80) return trimmed;
      // 公网 IP 无有效 TLS 证书，80 端口走 Nginx 明文反代，保留 HTTP。
      if (_isPublicIpv4(uri.host)) return trimmed;
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

  static bool _isPublicIpv4(String host) {
    final parts = host.split('.');
    if (parts.length != 4) return false;
    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null || value < 0 || value > 255) return false;
    }
    return true;
  }
}
