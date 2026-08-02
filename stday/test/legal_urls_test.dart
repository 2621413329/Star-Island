import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/legal/legal_urls.dart';

void main() {
  test('公开法律链接指向官网域名', () {
    expect(LegalUrls.termsOfUse, 'https://lcxxingyu.fun/terms');
    expect(LegalUrls.privacyPolicy, 'https://lcxxingyu.fun/privacy');
  });
}
