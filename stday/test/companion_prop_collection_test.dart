import 'package:flutter_test/flutter_test.dart';
import 'package:stday/data/models/profile_models.dart';
import 'package:stday/features/more/companion_showcase_page.dart';

DailyMomentModel _moment({
  required String id,
  required String storedProp,
  List<String> eventTags = const ['朋友', '友谊'],
  String emotionTag = 'calm',
  String? note = '今天比较忙',
  DateTime? createdAt,
  List<String> extraProps = const [],
}) {
  final earnedAt = createdAt ?? DateTime(2026, 6, 11, 16, 44);
  return DailyMomentModel(
    id: id,
    eventTags: eventTags,
    emotionTag: emotionTag,
    note: note,
    companionScene: 'stargaze',
    companionPose: 'breathing',
    momentDate: DateTime(earnedAt.year, earnedAt.month, earnedAt.day),
    createdAt: earnedAt,
    visualPayload: {
      'prop': storedProp,
      'extra_props': extraProps,
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('displayPropFromMoment matches story card companionSpec', () {
    final moment = _moment(
      id: '1',
      storedProp: 'music',
      extraProps: const ['chat_bubbles', 'heart'],
    );
    expect(displayPropFromMoment(moment), moment.companionSpec.prop);
    expect(displayPropFromMoment(moment), isNot('music'));
  });

  test('collectCompanionProps counts one icon per story', () async {
    final moment = _moment(
      id: '1',
      storedProp: 'music',
      extraProps: const ['chat_bubbles', 'heart'],
    );
    final items = await collectCompanionProps([moment]);
    expect(items, hasLength(1));
    expect(items.first.id, moment.companionSpec.prop);
  });

  test('collectCompanionProps dedupes duplicate moment rows', () async {
    final moment = _moment(id: '1', storedProp: 'friends');
    final items = await collectCompanionProps([moment, moment, moment]);
    expect(items, hasLength(1));
  });

  test('collectCompanionProps keeps distinct icons from multiple stories', () async {
    final guitar = _moment(
      id: '1',
      eventTags: const ['朋友', '友谊'],
      storedProp: 'music',
    );
    final study = _moment(
      id: '2',
      eventTags: const ['学业', '学业故事'],
      emotionTag: 'happy',
      note: '学习还是很有趣的',
      storedProp: 'workbook',
    );
    final items = await collectCompanionProps([guitar, study]);
    expect(items, hasLength(2));
    expect(items.map((e) => e.id).toSet(), hasLength(2));
  });

  test('collectCompanionProps records earliest earn time per asset', () async {
    final early = _moment(
      id: '1',
      storedProp: 'music',
      createdAt: DateTime(2026, 6, 1, 10, 0),
    );
    final later = _moment(
      id: '2',
      storedProp: 'music',
      eventTags: const ['朋友', '友谊'],
      createdAt: DateTime(2026, 6, 10, 10, 0),
    );
    final items = await collectCompanionProps([later, early]);
    expect(items, hasLength(1));
    expect(items.first.firstEarnedAt, early.createdAt);
  });
}
