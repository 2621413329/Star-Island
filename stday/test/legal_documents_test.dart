import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/legal/legal_documents.dart';

void main() {
  test('正式版协议已去除公测表述', () {
    final agreementText = userAgreement.sections
        .expand((s) => [s.heading, ...s.paragraphs])
        .join('\n');
    final privacyText = privacyPolicy.sections
        .expand((s) => [s.heading, ...s.paragraphs])
        .join('\n');

    expect(userAgreement.updatedAt, legalDocumentsUpdatedAt);
    expect(privacyPolicy.updatedAt, legalDocumentsUpdatedAt);
    expect(agreementText, contains('星屿会员'));
    expect(agreementText, contains('Terms of Use'));
    expect(agreementText, isNot(contains('公测')));
    expect(agreementText, isNot(contains('测试期')));
    expect(privacyText, isNot(contains('公开测试')));
    expect(privacyText, isNot(contains('测试参与者')));
    expect(privacyText, contains('lcxxingyu.fun/privacy'));
    expect(agreementText, contains('lcxxingyu.fun/terms'));
  });
}
