// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Star Isle';

  @override
  String get tabIsland => 'My Island';

  @override
  String get tabToday => 'Today';

  @override
  String get tabGrowth => 'Growth';

  @override
  String get tabMore => 'More';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get next => 'Next';

  @override
  String get saveSuccess => 'Saved successfully';

  @override
  String saveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get networkError => 'Network error';

  @override
  String get loading => 'Loading';

  @override
  String get noData => 'No data yet';

  @override
  String get uploadSuccess => 'Upload successful';

  @override
  String get uploadFailed => 'Upload failed';

  @override
  String get serverError => 'Server error, please try again later';

  @override
  String get requestFailed => 'Request failed';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get loginExpired => 'Session expired, please sign in again';

  @override
  String get storyTitle => 'What happened today?';

  @override
  String get storySubtitle => 'Record one thing worth remembering today';

  @override
  String get storyPlaceholder1 => 'What happened today?';

  @override
  String get storyPlaceholder2 => 'Anything worth recording?';

  @override
  String get storyPlaceholder3 => 'What was your biggest takeaway today?';

  @override
  String get storyPlaceholder4 => 'What challenge did you face today?';

  @override
  String get storyPlaceholder5 => 'Any thoughts you want to keep?';

  @override
  String get storyTextMode => 'Text';

  @override
  String get storyVoiceMode => 'Voice';

  @override
  String get storySwitchToVoice => 'Switch to voice';

  @override
  String get storySwitchToText => 'Switch to text';

  @override
  String get storySaveStory => 'Save story';

  @override
  String get storyRecordAndAnalyze => 'Record & analyze';

  @override
  String get storyVoiceUploading => 'Uploading voice...';

  @override
  String get storyAnalyzing => 'Star is understanding your story…';

  @override
  String get storyVoiceSaved => 'Voice note saved';

  @override
  String get storyPhotoOnlyNote => '(Photo record)';

  @override
  String storySavedPhotoUploadFailed(String error) {
    return 'Story saved, but photo upload failed: $error';
  }

  @override
  String get storyVoiceHint =>
      'Hold to talk, release to send; slide up to cancel';

  @override
  String get storyVoiceNoRerecord =>
      'Voice stories cannot be re-recorded. Delete and create a new one.';

  @override
  String get storyContinueWriting => 'Continue today\'s story…';

  @override
  String get voiceHoldToTalk => 'Hold to Talk';

  @override
  String get voiceRecording => 'Recording...';

  @override
  String get voiceReleaseToSend => 'Release to send · Slide up to cancel';

  @override
  String get voiceReleaseToCancel => 'Release to cancel';

  @override
  String get voiceMaxDurationReached => 'Maximum recording length reached';

  @override
  String voiceStartFailed(String error) {
    return 'Cannot start recording: $error';
  }

  @override
  String get voiceCancelled => 'Recording cancelled';

  @override
  String get voiceTooShort => 'Recording too short';

  @override
  String get voiceUploading => 'Uploading voice';

  @override
  String get voiceSaved => 'Voice note saved';

  @override
  String get voicePlayFailed => 'Voice playback failed';

  @override
  String get photoAdd => 'Add photos';

  @override
  String get photoAlbum => 'Album';

  @override
  String get photoCamera => 'Camera';

  @override
  String get photoDisclaimer =>
      'Photos are saved for your records only and are not used in AI text analysis';

  @override
  String get emptyRecordHint => 'Capture a moment';

  @override
  String get emptyStartRecording => 'Start recording today\'s growth';

  @override
  String get storyDetailTitle => 'Story detail';

  @override
  String get aiGrowthAnalysis => 'Growth analysis';

  @override
  String get aiWeeklySummary => 'Weekly summary';

  @override
  String get aiMonthlyReport => 'Monthly report';

  @override
  String get aiInsight => 'AI insights';

  @override
  String get aiGenerating => 'Generating analysis';

  @override
  String get aiGenerateFailed => 'Failed to generate analysis';
}
