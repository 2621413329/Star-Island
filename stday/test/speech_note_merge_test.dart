import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/constants/moment_limits.dart';
import 'package:stday/core/speech/speech_note_merge.dart';

void main() {
  test('mergeSpeechIntoNote fills empty note from first dictation', () {
    expect(
      mergeSpeechIntoNote(existing: '', spoken: '今天很开心'),
      '今天很开心',
    );
  });

  test('mergeSpeechIntoNote appends second dictation at tail', () {
    expect(
      mergeSpeechIntoNote(existing: '今天很开心', spoken: '还去了公园'),
      '今天很开心 还去了公园',
    );
  });

  test('mergeSpeechIntoNote truncates when exceeding max length', () {
    final existing = 'a' * 495;
    final spoken = 'b' * 20;
    final merged = mergeSpeechIntoNote(existing: existing, spoken: spoken);
    expect(merged.length, momentNoteMaxLength);
    expect(merged, '${'a' * 495}${'b' * 5}');
  });

  test('mergeSpeechIntoNote ignores empty spoken text', () {
    expect(
      mergeSpeechIntoNote(existing: '已有内容', spoken: '   '),
      '已有内容',
    );
  });
}
