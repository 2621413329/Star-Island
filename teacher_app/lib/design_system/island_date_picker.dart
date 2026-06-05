import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/mood_theme.dart';
import '../providers/date_providers.dart';
import 'island_ui.dart';

/// 单日选择：玻璃卡片 + 底部弹层，风格与学生端一致。
class IslandDateSelector extends StatelessWidget {
  const IslandDateSelector({
    super.key,
    required this.palette,
    required this.selected,
    required this.onChanged,
    this.label = '查看日期',
    this.quickYesterday = true,
    this.quickToday = true,
  });

  final MoodPalette palette;
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;
  final String label;
  final bool quickYesterday;
  final bool quickToday;

  Future<void> _pick(BuildContext context) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SingleDateSheet(
        palette: palette,
        initial: selected,
      ),
    );
    if (picked != null) onChanged(dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (quickYesterday || quickToday)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                if (quickYesterday)
                  IslandChipToggle(
                    label: '昨日',
                    selected: isYesterday(selected),
                    palette: palette,
                    onTap: () {
                      final t = dateOnly(DateTime.now());
                      onChanged(t.subtract(const Duration(days: 1)));
                    },
                  ),
                if (quickYesterday && quickToday) const SizedBox(width: 10),
                if (quickToday)
                  IslandChipToggle(
                    label: '今日',
                    selected: isToday(selected),
                    palette: palette,
                    onTap: () => onChanged(dateOnly(DateTime.now())),
                  ),
              ],
            ),
          ),
        GestureDetector(
          onTap: () => _pick(context),
          child: IslandGlassCard(
            palette: palette,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: palette.accent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8C7B6B))),
                      const SizedBox(height: 2),
                      Text(
                        _formatDay(selected),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.expand_more_rounded, color: palette.accent.withValues(alpha: 0.8)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _formatDay(DateTime d) {
    if (isToday(d)) return '今日 · ${DateFormat('M月d日').format(d)}';
    if (isYesterday(d)) return '昨日 · ${DateFormat('M月d日').format(d)}';
    return DateFormat('yyyy年M月d日').format(d);
  }
}

/// 预警页：日期范围选择。
class IslandDateRangeSelector extends StatelessWidget {
  const IslandDateRangeSelector({
    super.key,
    required this.palette,
    required this.range,
    required this.onChanged,
  });

  final MoodPalette palette;
  final AlertDateRange range;
  final ValueChanged<AlertDateRange> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showModalBottomSheet<AlertDateRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RangeDateSheet(
        palette: palette,
        initial: range.normalized(),
      ),
    );
    if (picked != null) onChanged(picked.normalized());
  }

  @override
  Widget build(BuildContext context) {
    final r = range.normalized();
    return GestureDetector(
      onTap: () => _pick(context),
      child: IslandGlassCard(
        palette: palette,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.date_range_rounded, color: palette.accent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('筛选范围', style: TextStyle(fontSize: 12, color: Color(0xFF8C7B6B))),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('M月d日').format(r.start)} – ${DateFormat('M月d日').format(r.end)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Icon(Icons.expand_more_rounded, color: palette.accent.withValues(alpha: 0.8)),
          ],
        ),
      ),
    );
  }
}

class _SingleDateSheet extends StatefulWidget {
  const _SingleDateSheet({required this.palette, required this.initial});

  final MoodPalette palette;
  final DateTime initial;

  @override
  State<_SingleDateSheet> createState() => _SingleDateSheetState();
}

class _SingleDateSheetState extends State<_SingleDateSheet> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = dateOnly(widget.initial);
  }

  Future<void> _openPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime(2024),
      lastDate: dateOnly(DateTime.now()),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: widget.palette.primary,
            onPrimary: Colors.white,
            surface: widget.palette.card,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selected = dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(
          color: widget.palette.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.palette.accent.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('选择日期', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _openPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: widget.palette.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: widget.palette.accent.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_rounded, color: widget.palette.accent),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('yyyy年M月d日').format(_selected),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              IslandPrimaryAction(
                label: '确定',
                palette: widget.palette,
                onPressed: () => Navigator.pop(context, _selected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeDateSheet extends StatefulWidget {
  const _RangeDateSheet({required this.palette, required this.initial});

  final MoodPalette palette;
  final AlertDateRange initial;

  @override
  State<_RangeDateSheet> createState() => _RangeDateSheetState();
}

class _RangeDateSheetState extends State<_RangeDateSheet> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    final r = widget.initial.normalized();
    _start = r.start;
    _end = r.end;
  }

  void _applyPreset(int days) {
    final today = dateOnly(DateTime.now());
    setState(() {
      _end = today;
      _start = today.subtract(Duration(days: days - 1));
    });
  }

  Future<void> _pickStart() async {
    final picked = await _pickDate(_start);
    if (picked == null) return;
    setState(() {
      _start = picked;
      if (_start.isAfter(_end)) _end = _start;
    });
  }

  Future<void> _pickEnd() async {
    final picked = await _pickDate(_end);
    if (picked == null) return;
    setState(() {
      _end = picked;
      if (_end.isBefore(_start)) _start = _end;
    });
  }

  Future<DateTime?> _pickDate(DateTime initial) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: dateOnly(DateTime.now()),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: widget.palette.primary,
            onPrimary: Colors.white,
            surface: widget.palette.card,
          ),
        ),
        child: child!,
      ),
    ).then((d) => d == null ? null : dateOnly(d));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(
          color: widget.palette.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('日期范围', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  IslandChipToggle(
                    label: '近3天',
                    selected: _isPreset(3),
                    palette: widget.palette,
                    onTap: () => _applyPreset(3),
                  ),
                  IslandChipToggle(
                    label: '近7天',
                    selected: _isPreset(7),
                    palette: widget.palette,
                    onTap: () => _applyPreset(7),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _RangeRow(
                label: '开始',
                value: DateFormat('yyyy/M/d').format(_start),
                palette: widget.palette,
                onTap: _pickStart,
              ),
              const SizedBox(height: 10),
              _RangeRow(
                label: '结束',
                value: DateFormat('yyyy/M/d').format(_end),
                palette: widget.palette,
                onTap: _pickEnd,
              ),
              const SizedBox(height: 20),
              IslandPrimaryAction(
                label: '确定',
                palette: widget.palette,
                onPressed: () => Navigator.pop(
                  context,
                  AlertDateRange(start: _start, end: _end),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isPreset(int days) {
    final today = dateOnly(DateTime.now());
    final start = today.subtract(Duration(days: days - 1));
    return isSameDay(_start, start) && isSameDay(_end, today);
  }
}

class _RangeRow extends StatelessWidget {
  const _RangeRow({
    required this.label,
    required this.value,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final String value;
  final MoodPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: palette.primaryContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(label, style: const TextStyle(color: Color(0xFF8C7B6B), fontSize: 13)),
            ),
            Expanded(
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
            Icon(Icons.edit_calendar_rounded, size: 20, color: palette.accent),
          ],
        ),
      ),
    );
  }
}
