// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '星屿';

  @override
  String get tabIsland => '我的岛屿';

  @override
  String get tabToday => '今日记录';

  @override
  String get tabGrowth => '成长轨迹';

  @override
  String get tabMore => '更多';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get confirm => '确认';

  @override
  String get back => '返回';

  @override
  String get done => '完成';

  @override
  String get next => '下一步';

  @override
  String get saveSuccess => '保存成功';

  @override
  String saveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String get networkError => '网络异常';

  @override
  String get loading => '加载中';

  @override
  String get noData => '暂无数据';

  @override
  String get uploadSuccess => '上传成功';

  @override
  String get uploadFailed => '上传失败';

  @override
  String get serverError => '服务器异常，请稍后重试';

  @override
  String get requestFailed => '请求失败';

  @override
  String get permissionDenied => '权限不足';

  @override
  String get loginExpired => '登录已失效，请重新登录';

  @override
  String get storyTitle => '今天发生了什么？';

  @override
  String get storySubtitle => '记录今天值得记住的一件事';

  @override
  String get storyPlaceholder1 => '今天发生了什么？';

  @override
  String get storyPlaceholder2 => '有什么值得记录的事情？';

  @override
  String get storyPlaceholder3 => '今天最大的收获是什么？';

  @override
  String get storyPlaceholder4 => '今天遇到了什么挑战？';

  @override
  String get storyPlaceholder5 => '有什么想法想留下来？';

  @override
  String get storyTextMode => '文字记录';

  @override
  String get storyVoiceMode => '语音记录';

  @override
  String get storySwitchToVoice => '切换到语音';

  @override
  String get storySwitchToText => '切换到文字';

  @override
  String get storySaveStory => '保存日常';

  @override
  String get storyRecordAndAnalyze => '记录并分析';

  @override
  String get storyVoiceUploading => '录音上传中...';

  @override
  String get storyAnalyzing => '小星正在理解你的日常…';

  @override
  String get storyVoiceSaved => '语音记录已保存';

  @override
  String get storyPhotoOnlyNote => '（照片记录）';

  @override
  String storySavedPhotoUploadFailed(String error) {
    return '日常已保存，但照片上传失败：$error';
  }

  @override
  String get storyVoiceHint => '按住说话，松开后可试听；确认后发送，上滑取消';

  @override
  String get storyVoiceSend => '发送语音';

  @override
  String get storyVoiceNoRerecord => '长按可重新录制，确认后保存';

  @override
  String get storyContinueWriting => '继续记录今天的日常…';

  @override
  String get voiceHoldToTalk => '按住 说话';

  @override
  String get voiceRecording => '正在录音';

  @override
  String get voiceReleaseToSend => '松开完成 · 上滑取消';

  @override
  String get voiceReleaseToCancel => '松开 取消';

  @override
  String get voiceMaxDurationReached => '已达最长录音时长';

  @override
  String voiceStartFailed(String error) {
    return '无法开始录音：$error';
  }

  @override
  String get voiceCancelled => '已取消录音';

  @override
  String get voiceTooShort => '说话时间太短';

  @override
  String get voiceUploading => '录音上传中';

  @override
  String get voiceSaved => '语音记录已保存';

  @override
  String get voicePlayFailed => '语音播放失败';

  @override
  String get photoAdd => '添加照片';

  @override
  String get photoAlbum => '相册';

  @override
  String get photoCamera => '拍摄';

  @override
  String get photoDisclaimer => '照片仅作记录保存，不参与 AI 文字分析';

  @override
  String get emptyRecordHint => '记录一个瞬间吧';

  @override
  String get emptyStartRecording => '开始记录今天的成长吧';

  @override
  String get storyDetailTitle => '日常详情';

  @override
  String get aiGrowthAnalysis => '成长分析';

  @override
  String get aiWeeklySummary => '本周总结';

  @override
  String get aiMonthlyReport => '月度报告';

  @override
  String get aiInsight => 'AI洞察';

  @override
  String get aiGenerating => '正在生成分析';

  @override
  String get aiGenerateFailed => '分析生成失败';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => '星嶼';

  @override
  String get tabIsland => '我的島嶼';

  @override
  String get tabToday => '今日記錄';

  @override
  String get tabGrowth => '成長軌跡';

  @override
  String get tabMore => '更多';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get confirm => '確認';

  @override
  String get back => '返回';

  @override
  String get done => '完成';

  @override
  String get next => '下一步';

  @override
  String get saveSuccess => '保存成功';

  @override
  String saveFailed(String error) {
    return '保存失敗：$error';
  }

  @override
  String get networkError => '網絡異常';

  @override
  String get loading => '加載中';

  @override
  String get noData => '暫無數據';

  @override
  String get uploadSuccess => '上傳成功';

  @override
  String get uploadFailed => '上傳失敗';

  @override
  String get serverError => '服務器異常，請稍後重試';

  @override
  String get requestFailed => '請求失敗';

  @override
  String get permissionDenied => '權限不足';

  @override
  String get loginExpired => '登錄已失效，請重新登錄';

  @override
  String get storyTitle => '今天發生了什麼？';

  @override
  String get storySubtitle => '記錄今天值得記住的一件事';

  @override
  String get storyPlaceholder1 => '今天發生了什麼？';

  @override
  String get storyPlaceholder2 => '有什麼值得記錄的事情？';

  @override
  String get storyPlaceholder3 => '今天最大的收穫是什麼？';

  @override
  String get storyPlaceholder4 => '今天遇到了什麼挑戰？';

  @override
  String get storyPlaceholder5 => '有什麼想法想留下來？';

  @override
  String get storyTextMode => '文字記錄';

  @override
  String get storyVoiceMode => '語音記錄';

  @override
  String get storySwitchToVoice => '切換到語音';

  @override
  String get storySwitchToText => '切換到文字';

  @override
  String get storySaveStory => '保存日常';

  @override
  String get storyRecordAndAnalyze => '記錄並分析';

  @override
  String get storyVoiceUploading => '錄音上傳中...';

  @override
  String get storyAnalyzing => '小星正在理解你的日常…';

  @override
  String get storyVoiceSaved => '語音記錄已保存';

  @override
  String get storyPhotoOnlyNote => '（照片記錄）';

  @override
  String storySavedPhotoUploadFailed(String error) {
    return '日常已保存，但照片上傳失敗：$error';
  }

  @override
  String get storyVoiceHint => '按住說話，鬆開後可試聽；確認後發送，上滑取消';

  @override
  String get storyVoiceSend => '發送語音';

  @override
  String get storyVoiceNoRerecord => '長按可重新錄製，確認後保存';

  @override
  String get storyContinueWriting => '繼續記錄今天的日常…';

  @override
  String get voiceHoldToTalk => '按住 說話';

  @override
  String get voiceRecording => '正在錄音';

  @override
  String get voiceReleaseToSend => '鬆開完成 · 上滑取消';

  @override
  String get voiceReleaseToCancel => '鬆開 取消';

  @override
  String get voiceMaxDurationReached => '已達最長錄音時長';

  @override
  String voiceStartFailed(String error) {
    return '無法開始錄音：$error';
  }

  @override
  String get voiceCancelled => '已取消錄音';

  @override
  String get voiceTooShort => '說話時間太短';

  @override
  String get voiceUploading => '錄音上傳中';

  @override
  String get voiceSaved => '語音記錄已保存';

  @override
  String get voicePlayFailed => '語音播放失敗';

  @override
  String get photoAdd => '添加照片';

  @override
  String get photoAlbum => '相冊';

  @override
  String get photoCamera => '拍攝';

  @override
  String get photoDisclaimer => '照片僅作記錄保存，不參與 AI 文字分析';

  @override
  String get emptyRecordHint => '記錄一個瞬間吧';

  @override
  String get emptyStartRecording => '開始記錄今天的成長吧';

  @override
  String get storyDetailTitle => '日常詳情';

  @override
  String get aiGrowthAnalysis => '成長分析';

  @override
  String get aiWeeklySummary => '本週總結';

  @override
  String get aiMonthlyReport => '月度報告';

  @override
  String get aiInsight => 'AI洞察';

  @override
  String get aiGenerating => '正在生成分析';

  @override
  String get aiGenerateFailed => '分析生成失敗';
}
