import '../../data/models/profile_models.dart';

/// 与添加/编辑故事表单共用：event_tags 编解码。
class MomentFormState {
  MomentFormState({
    this.event,
    this.eventKeyword,
    this.studySubject,
    this.studyState,
    this.mood,
    this.note,
  });

  String? event;
  String? eventKeyword;
  String? studySubject;
  String? studyState;
  String? mood;
  String? note;

  bool get isStudyEvent => event == '学习';

  List<String> get eventTags => [
        if (event != null) event!,
        if (!isStudyEvent && eventKeyword != null) eventKeyword!,
        if (isStudyEvent && studySubject != null) studySubject!,
        if (isStudyEvent && studySubject != '自定义' && studyState != null)
          studyState!,
      ];

  bool get isValid => eventTags.isNotEmpty && mood != null;

  factory MomentFormState.fromMoment(DailyMomentModel moment) {
    final tags = moment.eventTags;
    if (tags.isEmpty) {
      return MomentFormState(mood: moment.emotionTag, note: moment.note);
    }
    final main = tags.first;
    if (main == '学习') {
      return MomentFormState(
        event: main,
        studySubject: tags.length > 1 ? tags[1] : null,
        studyState: tags.length > 2 ? tags[2] : null,
        mood: moment.emotionTag,
        note: moment.note,
      );
    }
    return MomentFormState(
      event: main,
      eventKeyword: tags.length > 1 ? tags[1] : null,
      mood: moment.emotionTag,
      note: moment.note,
    );
  }
}
