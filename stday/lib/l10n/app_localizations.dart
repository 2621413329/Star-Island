import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'TW')
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'星屿'**
  String get appTitle;

  /// No description provided for @tabIsland.
  ///
  /// In zh, this message translates to:
  /// **'我的岛屿'**
  String get tabIsland;

  /// No description provided for @tabToday.
  ///
  /// In zh, this message translates to:
  /// **'今日记录'**
  String get tabToday;

  /// No description provided for @tabGrowth.
  ///
  /// In zh, this message translates to:
  /// **'成长轨迹'**
  String get tabGrowth;

  /// No description provided for @tabMore.
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get tabMore;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get back;

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// No description provided for @next.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get next;

  /// No description provided for @saveSuccess.
  ///
  /// In zh, this message translates to:
  /// **'保存成功'**
  String get saveSuccess;

  /// No description provided for @saveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败：{error}'**
  String saveFailed(String error);

  /// No description provided for @networkError.
  ///
  /// In zh, this message translates to:
  /// **'网络异常'**
  String get networkError;

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'加载中'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get noData;

  /// No description provided for @uploadSuccess.
  ///
  /// In zh, this message translates to:
  /// **'上传成功'**
  String get uploadSuccess;

  /// No description provided for @uploadFailed.
  ///
  /// In zh, this message translates to:
  /// **'上传失败'**
  String get uploadFailed;

  /// No description provided for @serverError.
  ///
  /// In zh, this message translates to:
  /// **'服务器异常，请稍后重试'**
  String get serverError;

  /// No description provided for @requestFailed.
  ///
  /// In zh, this message translates to:
  /// **'请求失败'**
  String get requestFailed;

  /// No description provided for @permissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'权限不足'**
  String get permissionDenied;

  /// No description provided for @loginExpired.
  ///
  /// In zh, this message translates to:
  /// **'登录已失效，请重新登录'**
  String get loginExpired;

  /// No description provided for @storyTitle.
  ///
  /// In zh, this message translates to:
  /// **'今天发生了什么？'**
  String get storyTitle;

  /// No description provided for @storySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'记录今天值得记住的一件事'**
  String get storySubtitle;

  /// No description provided for @storyPlaceholder1.
  ///
  /// In zh, this message translates to:
  /// **'今天发生了什么？'**
  String get storyPlaceholder1;

  /// No description provided for @storyPlaceholder2.
  ///
  /// In zh, this message translates to:
  /// **'有什么值得记录的事情？'**
  String get storyPlaceholder2;

  /// No description provided for @storyPlaceholder3.
  ///
  /// In zh, this message translates to:
  /// **'今天最大的收获是什么？'**
  String get storyPlaceholder3;

  /// No description provided for @storyPlaceholder4.
  ///
  /// In zh, this message translates to:
  /// **'今天遇到了什么挑战？'**
  String get storyPlaceholder4;

  /// No description provided for @storyPlaceholder5.
  ///
  /// In zh, this message translates to:
  /// **'有什么想法想留下来？'**
  String get storyPlaceholder5;

  /// No description provided for @storyTextMode.
  ///
  /// In zh, this message translates to:
  /// **'文字记录'**
  String get storyTextMode;

  /// No description provided for @storyVoiceMode.
  ///
  /// In zh, this message translates to:
  /// **'语音记录'**
  String get storyVoiceMode;

  /// No description provided for @storySwitchToVoice.
  ///
  /// In zh, this message translates to:
  /// **'切换到语音'**
  String get storySwitchToVoice;

  /// No description provided for @storySwitchToText.
  ///
  /// In zh, this message translates to:
  /// **'切换到文字'**
  String get storySwitchToText;

  /// No description provided for @storySaveStory.
  ///
  /// In zh, this message translates to:
  /// **'保存故事'**
  String get storySaveStory;

  /// No description provided for @storyRecordAndAnalyze.
  ///
  /// In zh, this message translates to:
  /// **'记录并分析'**
  String get storyRecordAndAnalyze;

  /// No description provided for @storyVoiceUploading.
  ///
  /// In zh, this message translates to:
  /// **'录音上传中...'**
  String get storyVoiceUploading;

  /// No description provided for @storyAnalyzing.
  ///
  /// In zh, this message translates to:
  /// **'小星正在理解你的故事…'**
  String get storyAnalyzing;

  /// No description provided for @storyVoiceSaved.
  ///
  /// In zh, this message translates to:
  /// **'语音记录已保存'**
  String get storyVoiceSaved;

  /// No description provided for @storyPhotoOnlyNote.
  ///
  /// In zh, this message translates to:
  /// **'（照片记录）'**
  String get storyPhotoOnlyNote;

  /// No description provided for @storySavedPhotoUploadFailed.
  ///
  /// In zh, this message translates to:
  /// **'故事已保存，但照片上传失败：{error}'**
  String storySavedPhotoUploadFailed(String error);

  /// No description provided for @storyVoiceHint.
  ///
  /// In zh, this message translates to:
  /// **'按住说话，松开后可试听；确认后发送，上滑取消'**
  String get storyVoiceHint;

  /// No description provided for @storyVoiceSend.
  ///
  /// In zh, this message translates to:
  /// **'发送语音'**
  String get storyVoiceSend;

  /// No description provided for @storyVoiceNoRerecord.
  ///
  /// In zh, this message translates to:
  /// **'语音故事暂不支持重新录制，可删除后新建'**
  String get storyVoiceNoRerecord;

  /// No description provided for @storyContinueWriting.
  ///
  /// In zh, this message translates to:
  /// **'继续记录今天的故事…'**
  String get storyContinueWriting;

  /// No description provided for @voiceHoldToTalk.
  ///
  /// In zh, this message translates to:
  /// **'按住 说话'**
  String get voiceHoldToTalk;

  /// No description provided for @voiceRecording.
  ///
  /// In zh, this message translates to:
  /// **'正在录音'**
  String get voiceRecording;

  /// No description provided for @voiceReleaseToSend.
  ///
  /// In zh, this message translates to:
  /// **'松开完成 · 上滑取消'**
  String get voiceReleaseToSend;

  /// No description provided for @voiceReleaseToCancel.
  ///
  /// In zh, this message translates to:
  /// **'松开 取消'**
  String get voiceReleaseToCancel;

  /// No description provided for @voiceMaxDurationReached.
  ///
  /// In zh, this message translates to:
  /// **'已达最长录音时长'**
  String get voiceMaxDurationReached;

  /// No description provided for @voiceStartFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法开始录音：{error}'**
  String voiceStartFailed(String error);

  /// No description provided for @voiceCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消录音'**
  String get voiceCancelled;

  /// No description provided for @voiceTooShort.
  ///
  /// In zh, this message translates to:
  /// **'说话时间太短'**
  String get voiceTooShort;

  /// No description provided for @voiceUploading.
  ///
  /// In zh, this message translates to:
  /// **'录音上传中'**
  String get voiceUploading;

  /// No description provided for @voiceSaved.
  ///
  /// In zh, this message translates to:
  /// **'语音记录已保存'**
  String get voiceSaved;

  /// No description provided for @voicePlayFailed.
  ///
  /// In zh, this message translates to:
  /// **'语音播放失败'**
  String get voicePlayFailed;

  /// No description provided for @photoAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加照片'**
  String get photoAdd;

  /// No description provided for @photoAlbum.
  ///
  /// In zh, this message translates to:
  /// **'相册'**
  String get photoAlbum;

  /// No description provided for @photoCamera.
  ///
  /// In zh, this message translates to:
  /// **'拍摄'**
  String get photoCamera;

  /// No description provided for @photoDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'照片仅作记录保存，不参与 AI 文字分析'**
  String get photoDisclaimer;

  /// No description provided for @emptyRecordHint.
  ///
  /// In zh, this message translates to:
  /// **'记录一个瞬间吧'**
  String get emptyRecordHint;

  /// No description provided for @emptyStartRecording.
  ///
  /// In zh, this message translates to:
  /// **'开始记录今天的成长吧'**
  String get emptyStartRecording;

  /// No description provided for @storyDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'故事详情'**
  String get storyDetailTitle;

  /// No description provided for @aiGrowthAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'成长分析'**
  String get aiGrowthAnalysis;

  /// No description provided for @aiWeeklySummary.
  ///
  /// In zh, this message translates to:
  /// **'本周总结'**
  String get aiWeeklySummary;

  /// No description provided for @aiMonthlyReport.
  ///
  /// In zh, this message translates to:
  /// **'月度报告'**
  String get aiMonthlyReport;

  /// No description provided for @aiInsight.
  ///
  /// In zh, this message translates to:
  /// **'AI洞察'**
  String get aiInsight;

  /// No description provided for @aiGenerating.
  ///
  /// In zh, this message translates to:
  /// **'正在生成分析'**
  String get aiGenerating;

  /// No description provided for @aiGenerateFailed.
  ///
  /// In zh, this message translates to:
  /// **'分析生成失败'**
  String get aiGenerateFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
