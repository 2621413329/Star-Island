import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/config/app_config.dart';

void main() {
  group('normalizeApiBaseUrl', () {
    test('自定义端口保留 HTTP', () {
      expect(
        AppConfig.normalizeApiBaseUrl('http://39.106.134.222:9000'),
        'http://39.106.134.222:9000',
      );
    });

    test('公网 IP 的 80 端口保留 HTTP', () {
      expect(
        AppConfig.normalizeApiBaseUrl('http://39.106.134.222'),
        'http://39.106.134.222',
      );
    });

    test('域名 80 端口升级为 HTTPS', () {
      expect(
        AppConfig.normalizeApiBaseUrl('http://api.example.com'),
        'https://api.example.com',
      );
    });

    test('本机开发地址不改动', () {
      expect(
        AppConfig.normalizeApiBaseUrl('http://127.0.0.1:9000'),
        'http://127.0.0.1:9000',
      );
    });
  });
}
