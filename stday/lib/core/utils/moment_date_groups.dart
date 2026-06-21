import 'package:intl/intl.dart';

import '../../data/models/profile_models.dart';

/// 按 [momentDate] 分组的日常列表（日期新 → 旧，组内保持接口顺序）。
class MomentDateGroup {
  const MomentDateGroup({
    required this.date,
    required this.label,
    required this.moments,
  });

  final DateTime date;
  final String label;
  final List<DailyMomentModel> moments;
}

DateTime momentCalendarDate(DailyMomentModel moment) {
  final d = moment.momentDate;
  return DateTime(d.year, d.month, d.day);
}

bool isMomentToday(DailyMomentModel moment) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return momentCalendarDate(moment) == today;
}

/// 日常卡片上的记录时间（本地时区）。
String formatMomentRecordTime(DailyMomentModel moment) {
  final local = moment.createdAt.toLocal();
  final recordedDay = DateTime(local.year, local.month, local.day);
  final storyDay = momentCalendarDate(moment);
  if (recordedDay == storyDay) {
    return DateFormat('HH:mm', 'zh_CN').format(local);
  }
  return DateFormat('M月d日 HH:mm', 'zh_CN').format(local);
}

String formatMomentDateLabel(DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(day.year, day.month, day.day);
  final diff = today.difference(target).inDays;
  if (diff == 0) return '今天';
  if (diff == 1) return '昨天';
  if (diff < 7) return DateFormat('EEEE', 'zh_CN').format(target);
  if (day.year == now.year) return DateFormat('M月d日', 'zh_CN').format(target);
  return DateFormat('yyyy年M月d日', 'zh_CN').format(target);
}

/// 今日记录心情卡片标题：更多日期选中时为「M-d / 星期X」。
String formatStoryDayMoodCardTitle(DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(day.year, day.month, day.day);
  final diff = today.difference(target).inDays;
  if (diff == 0) return '今天';
  if (diff == 1) return '昨天';
  final datePart = DateFormat('M-d', 'zh_CN').format(target);
  final weekday = DateFormat('EEEE', 'zh_CN').format(target);
  return '$datePart / $weekday';
}

List<MomentDateGroup> groupMomentsByDate(List<DailyMomentModel> moments) {
  if (moments.isEmpty) return const [];

  final ordered = List<DailyMomentModel>.from(moments)
    ..sort((a, b) {
      final d = b.momentDate.compareTo(a.momentDate);
      if (d != 0) return d;
      return b.createdAt.compareTo(a.createdAt);
    });

  final groups = <MomentDateGroup>[];
  DateTime? currentDay;
  List<DailyMomentModel>? bucket;

  for (final m in ordered) {
    final day = momentCalendarDate(m);
    if (currentDay == null || day != currentDay) {
      if (bucket != null && bucket.isNotEmpty) {
        groups.add(
          MomentDateGroup(
            date: currentDay!,
            label: formatMomentDateLabel(currentDay),
            moments: bucket,
          ),
        );
      }
      currentDay = day;
      bucket = [m];
    } else {
      bucket!.add(m);
    }
  }
  if (bucket != null && bucket.isNotEmpty && currentDay != null) {
    groups.add(
      MomentDateGroup(
        date: currentDay,
        label: formatMomentDateLabel(currentDay),
        moments: bucket,
      ),
    );
  }
  return groups;
}
