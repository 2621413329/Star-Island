import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/catalog.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../design_system/island_decorations.dart';
import '../../../design_system/mood_face_icon.dart';
import '../../../design_system/pressable_feedback.dart';
import '../../../providers/story_day_provider.dart';

/// 日期选择：按月日历 + 心情表情（适合大量历史记录）。
Future<DateTime?> showStoryDayPickerSheet({
  required BuildContext context,
  required MoodPalette palette,
  required DateTime selectedDay,
  required List<DateTime> recordedDays,
  required Map<String, String> moodByDayIso,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return _StoryDayPickerSheet(
        palette: palette,
        selectedDay: selectedDay,
        recordedDays: recordedDays,
        moodByDayIso: moodByDayIso,
      );
    },
  );
}

class _StoryDayPickerSheet extends StatefulWidget {
  const _StoryDayPickerSheet({
    required this.palette,
    required this.selectedDay,
    required this.recordedDays,
    required this.moodByDayIso,
  });

  final MoodPalette palette;
  final DateTime selectedDay;
  final List<DateTime> recordedDays;
  final Map<String, String> moodByDayIso;

  @override
  State<_StoryDayPickerSheet> createState() => _StoryDayPickerSheetState();
}

class _StoryDayPickerSheetState extends State<_StoryDayPickerSheet> {
  late DateTime _viewMonth;
  late final Set<DateTime> _recordedSet;
  late final Map<String, String> _moodMap;

  @override
  void initState() {
    super.initState();
    final sel = calendarDate(widget.selectedDay);
    _viewMonth = DateTime(sel.year, sel.month);
    _recordedSet = widget.recordedDays.map(calendarDate).toSet();
    _moodMap = widget.moodByDayIso;
  }

  bool _hasRecord(DateTime day) => _recordedSet.contains(calendarDate(day));

  void _shiftMonth(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta);
    });
  }

  void _pick(DateTime day) {
    Navigator.pop(context, calendarDate(day));
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final selected = calendarDate(widget.selectedDay);
    final monthLabel = DateFormat('yyyy年M月', 'zh_CN').format(_viewMonth);
    final daysInMonth = DateUtils.getDaysInMonth(_viewMonth.year, _viewMonth.month);
    final firstWeekday = DateTime(_viewMonth.year, _viewMonth.month).weekday % 7;
    final cellCount = firstWeekday + daysInMonth;
    final rows = (cellCount / 7).ceil();

    final monthRecorded = _recordedSet
        .where((d) => d.year == _viewMonth.year && d.month == _viewMonth.month)
        .length;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: IslandGlassCard(
          palette: palette,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '选择日期',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: palette.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '共 ${widget.recordedDays.length} 天有记录 · 点击带表情的日子',
                style: TextStyle(fontSize: 12, color: palette.primary.withValues(alpha: 0.55)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _shiftMonth(-1),
                    icon: Icon(Icons.chevron_left_rounded, color: palette.accent),
                  ),
                  Expanded(
                    child: Text(
                      monthLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.accent,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _shiftMonth(1),
                    icon: Icon(Icons.chevron_right_rounded, color: palette.accent),
                  ),
                ],
              ),
              if (monthRecorded == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '本月暂无记录，可切换其他月份',
                    style: TextStyle(fontSize: 12, color: palette.primary.withValues(alpha: 0.5)),
                  ),
                ),
              _WeekdayHeader(palette: palette),
              LayoutBuilder(
                builder: (context, constraints) {
                  const crossCount = 7;
                  const crossSpacing = 6.0;
                  const mainSpacing = 6.0;
                  const aspectRatio = 1.05;
                  final cellWidth = (constraints.maxWidth -
                          crossSpacing * (crossCount - 1)) /
                      crossCount;
                  final cellHeight = cellWidth / aspectRatio;
                  final gridHeight =
                      rows * cellHeight + (rows - 1) * mainSpacing;

                  return SizedBox(
                    height: gridHeight,
                    child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    mainAxisSpacing: mainSpacing,
                    crossAxisSpacing: crossSpacing,
                    childAspectRatio: aspectRatio,
                  ),
                  itemCount: rows * 7,
                  itemBuilder: (context, index) {
                    final dayIndex = index - firstWeekday + 1;
                    if (dayIndex < 1 || dayIndex > daysInMonth) {
                      return const SizedBox.shrink();
                    }
                    final day = DateTime(_viewMonth.year, _viewMonth.month, dayIndex);
                    final hasRecord = _hasRecord(day);
                    final isSelected = calendarDate(day) == selected;
                    final moodId = _moodMap[storyDayIso(day)];
                    final mood = moodId != null ? moodById(moodId) : null;

                    return _DayCell(
                      day: dayIndex,
                      mood: mood,
                      hasRecord: hasRecord,
                      isSelected: isSelected,
                      palette: palette,
                      onTap: hasRecord ? () => _pick(day) : null,
                    );
                  },
                ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.palette});

  final MoodPalette palette;

  static const _labels = ['日', '一', '二', '三', '四', '五', '六'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          for (final l in _labels)
            Expanded(
              child: Text(
                l,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: palette.primary.withValues(alpha: 0.45),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.mood,
    required this.hasRecord,
    required this.isSelected,
    required this.palette,
    required this.onTap,
  });

  final int day;
  final MoodOption? mood;
  final bool hasRecord;
  final bool isSelected;
  final MoodPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = hasRecord && onTap != null;
    return PressableFeedback(
      onTap: onTap,
      feedback: PressFeedbackType.selection,
      pressedScale: 0.92,
      inactiveOpacity: 1,
      semanticLabel: '$day',
      selected: isSelected,
      child: Material(
        color: isSelected
            ? palette.primaryContainer.withValues(alpha: 0.95)
            : (hasRecord ? palette.card.withValues(alpha: 0.75) : Colors.transparent),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? palette.accent
                  : (hasRecord
                      ? palette.accent.withValues(alpha: 0.25)
                      : Colors.transparent),
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: enabled
                      ? palette.accent
                      : const Color(0xFFBCAAA4),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 18,
                child: Center(
                  child: mood != null
                      ? MoodFaceIcon(
                          type: mood!.faceType,
                          color: mood!.color,
                          size: 16,
                        )
                      : hasRecord
                          ? Icon(
                              Icons.circle,
                              size: 6,
                              color: palette.accent.withValues(alpha: 0.4),
                            )
                          : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
