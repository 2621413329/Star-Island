import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/legal/legal_urls.dart';

void main() {
  test('公开法律链接指向生产域名 /legal', () {
    expect(LegalUrls.termsOfUse, 'https://api.lcxxingyu.fun/legal/terms');
    expect(LegalUrls.privacyPolicy, 'https://api.lcxxingyu.fun/legal/privacy');
  });
}
