import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/profile_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../providers/app_providers.dart';
import '../../providers/story_day_provider.dart';
import '../../island/providers/growth_summary_provider.dart';

/// 语音日常 AI 分析进行中时，按这条日常自己的日期刷新列表。
///
/// 上传已经成功。列表暂时失败、或这条日常不在「今天」里时，返回目前看到的结果
/// （可能为 null），由调用方继续用刚创建的记录收尾，避免把已保存的语音显示成网络错误。
Future<DailyMomentModel?> waitForVoiceMomentAnalysis(
  WidgetRef ref,
  String momentId, {
  DateTime? momentDate,
  Duration interval = const Duration(seconds: 2),
  int maxAttempts = 30,
}) async {
  final repo = ref.read(momentRepositoryProvider);
  DailyMomentModel? latest;
  var consecutiveFailures = 0;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      final moments = momentDate == null
          ? await repo.listTodayMoments()
          : await repo.listMomentsForDate(momentDate);
      consecutiveFailures = 0;
      for (final moment in moments) {
        if (moment.id != momentId) continue;
        latest = moment;
        if (!voiceMomentAnalysisPending(moment)) {
          return moment;
        }
        break;
      }
    } catch (_) {
      consecutiveFailures += 1;
      if (consecutiveFailures >= 3) return latest;
    }
    if (attempt < maxAttempts - 1) {
      await Future.delayed(interval);
    }
  }
  return latest;
}

bool voiceMomentAnalysisPending(DailyMomentModel moment) {
  if (!moment.isVoice) return false;
  if (moment.visualPayload['voice_analysis_pending'] == true) return true;
  final status = moment.speechStatus;
  return status == null || status == 'pending';
}

/// 语音日常 AI 分析进行中时，定时刷新列表直至 `speech_status` 完成。
class VoiceAnalysisPollHost extends ConsumerStatefulWidget {
  const VoiceAnalysisPollHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<VoiceAnalysisPollHost> createState() =>
      _VoiceAnalysisPollHostState();
}

class _VoiceAnalysisPollHostState extends ConsumerState<VoiceAnalysisPollHost> {
  Timer? _timer;
  int _pollCount = 0;

  bool _hasPendingVoiceAnalysis(List<DailyMomentModel> moments) {
    return moments.any(voiceMomentAnalysisPending);
  }

  void _syncPolling(List<DailyMomentModel> moments) {
    if (!_hasPendingVoiceAnalysis(moments)) {
      _timer?.cancel();
      _timer = null;
      _pollCount = 0;
      return;
    }
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      _pollCount += 1;
      await ref.read(todayMomentsProvider.notifier).refresh();
      await ref.read(storyDayViewProvider.notifier).refresh();
      ref.invalidate(growthSummaryProvider);
      if (_pollCount >= 30) {
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<DailyMomentModel>>>(todayMomentsProvider,
        (previous, next) {
      final moments = next.valueOrNull;
      if (moments != null) _syncPolling(moments);
    });
    final moments = ref.watch(todayMomentsProvider).valueOrNull;
    if (moments != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncPolling(moments);
      });
    }
    return widget.child;
  }
}
