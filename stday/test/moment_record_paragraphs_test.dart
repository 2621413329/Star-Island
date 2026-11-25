import 'package:flutter_test/flutter_test.dart';
import 'package:stday/features/today/moment_detail_page.dart';

void main() {
  test('记录按换行拆成段落', () {
    expect(
      momentRecordParagraphs('早上出门\n\n中午吃面\n晚上回家'),
      ['早上出门', '中午吃面', '晚上回家'],
    );
    expect(momentRecordParagraphs('  只有一段  '), ['只有一段']);
    expect(momentRecordParagraphs('\n\n'), isEmpty);
  });
}
