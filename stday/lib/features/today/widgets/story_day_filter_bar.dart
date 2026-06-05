import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/catalog.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../design_system/mood_face_icon.dart';
import '../../../providers/story_day_provider.dart';
import 'story_day_picker_sheet.dart';

/// 今日故事页顶部：切换日期，展示对应日心情表情。
class StoryDayFilterBar extends StatelessWidget {
  const StoryDayFilterBar({
    super.key,
    required this.palette,
    required this.selectedDay,
    required this.recordedDays,
    required this.moodByDayIso,
    required this.onDaySelected,
  });

  final MoodPalette palette;
  final DateTime selectedDay;
  final List<DateTime> recordedDays;
  final Map<String, String> moodByDayIso;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final today = calendarDate(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final historyDays = recordedDays
        .where((d) => d != today && d != yesterday)
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          _StoryDayChip(
            label: '今天',
            day: today,
            moodId: moodByDayIso[storyDayIso(today)],
            selected: calendarDate(selectedDay) == today,
            palette: palette,
            onTap: () => onDaySelected(today),
          ),
          const SizedBox(width: 8),
          if (recordedDays.contains(yesterday)) ...[
            _StoryDayChip(
              label: '昨天',
              day: yesterday,
              moodId: moodByDayIso[storyDayIso(yesterday)],
              selected: calendarDate(selectedDay) == yesterday,
              palette: palette,
              onTap: () => onDaySelected(yesterday),
            ),
            const SizedBox(width: 8),
          ],
          for (final d in historyDays.take(14))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _StoryDayChip(
                label: _historyLabel(d),
                day: d,
                moodId: moodByDayIso[storyDayIso(d)],
                selected: calendarDate(selectedDay) == d,
                palette: palette,
                onTap: () => onDaySelected(d),
              ),
            ),
          _StoryDayChip(
            label: '更多日期',
            day: null,
            moodId: null,
            selected: false,
            palette: palette,
            outlined: true,
            onTap: () => _openMoreDates(context),
          ),
        ],
      ),
    );
  }

  String _historyLabel(DateTime d) {
    if (d.year == DateTime.now().year) {
      return DateFormat('M月d日', 'zh_CN').format(d);
    }
    return DateFormat('yy/M/d', 'zh_CN').format(d);
  }

  Future<void> _openMoreDates(BuildContext context) async {
    final picked = await showStoryDayPickerSheet(
      context: context,
      palette: palette,
      selectedDay: selectedDay,
      recordedDays: recordedDays,
      moodByDayIso: moodByDayIso,
    );
    if (picked != null) onDaySelected(picked);
  }
}

class _StoryDayChip extends StatefulWidget {
  const _StoryDayChip({
    required this.label,
    required this.day,
    required this.moodId,
    required this.selected,
    required this.palette,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final DateTime? day;
  final String? moodId;
  final bool selected;
  final MoodPalette palette;
  final VoidCallback onTap;
  final bool outlined;

  @override
  State<_StoryDayChip> createState() => _StoryDayChipState();
}

class _StoryDayChipState extends State<_StoryDayChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final mood = widget.moodId != null ? moodById(widget.moodId!) : null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : (widget.selected ? 1.03 : 1),
        duration: const Duration(milliseconds: 140),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: widget.selected
                ? widget.palette.primaryContainer
                : (widget.outlined ? Colors.transparent : widget.palette.card),
            border: Border.all(
              color: widget.selected
                  ? widget.palette.accent
                  : widget.palette.accent.withValues(alpha: widget.outlined ? 0.4 : 0.18),
              width: widget.selected ? 1.8 : 1,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: widget.palette.accent.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mood != null) ...[
                MoodFaceIcon(type: mood.faceType, color: mood.color, size: 22),
                const SizedBox(width: 6),
              ] else if (widget.day != null)
                Text(
                  '${widget.day!.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: widget.palette.accent.withValues(alpha: 0.7),
                  ),
                ),
              if (widget.day != null && mood == null) const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.selected ? widget.palette.accent : const Color(0xFF6B5E54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
