import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/utils/mood_face_paths.dart';

void main() {
  test('moodFaceAssetCandidates prefers gendered pinyin asset', () {
    final paths = moodFaceAssetCandidates('kai_xin', gender: 'female');
    expect(paths.first, 'assets/images/mood_faces/woman_kai_xin.png');
    expect(paths, contains('assets/images/mood_faces/kai_xin.png'));
  });

  test('moodFaceAssetCandidates maps legacy happy to kai_xin assets', () {
    final paths = moodFaceAssetCandidates('happy', gender: 'male');
    expect(paths, contains('assets/images/mood_faces/man_happy.png'));
    expect(paths, contains('assets/images/mood_faces/kai_xin.png'));
  });
}
