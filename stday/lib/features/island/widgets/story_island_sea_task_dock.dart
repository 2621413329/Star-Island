import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/story_island_size.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../core/utils/story_island_names.dart';
import '../../../data/models/story_island_models.dart';

/// 副岛详情底部「海面待办」浮层：玻璃质感 + 今日任务增删改查。
class StoryIslandSeaTaskDock extends StatefulWidget {
  const StoryIslandSeaTaskDock({
    super.key,
    required this.island,
    required this.palette,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onComplete,
    required this.onUncomplete,
    this.creatingTask = false,
    this.busyTaskIds = const <String>{},
  });

  final StoryIslandModel island;
  final MoodPalette palette;
  final VoidCallback onAdd;
  final ValueChanged<StoryIslandTaskModel> onEdit;
  final ValueChanged<StoryIslandTaskModel> onDelete;
  final ValueChanged<StoryIslandTaskModel> onComplete;
  final ValueChanged<StoryIslandTaskModel> onUncomplete;
  final bool creatingTask;
  final Set<String> busyTaskIds;

  @override
  State<StoryIslandSeaTaskDock> createState() => _StoryIslandSeaTaskDockState();
}

class _StoryIslandSeaTaskDockState extends State<StoryIslandSeaTaskDock> {
  static const _collapsedLimit = 3;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tasks = widget.island.todayTasks;
    final doneCount = tasks.where((t) => t.completedToday).length;
    final tone = _SeaDockTone.fromPalette(widget.palette);
    final visible = _expanded ? tasks : tasks.take(_collapsedLimit).toList();
    final hasHidden = tasks.length > _collapsedLimit;
    final shouldScroll = _expanded && tasks.length > 4;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.78),
                tone.seaLight.withValues(alpha: 0.92),
                tone.seaDeep.withValues(alpha: 0.88),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
            boxShadow: [
              BoxShadow(
                color: tone.shadow.withValues(alpha: 0.16),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SeaWaveRibbon(color: tone.wave),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(tone, doneCount, tasks.length),
                    const SizedBox(height: 8),
                    if (widget.creatingTask) ...[
                      _SeaTaskLoadingHint(tone: tone),
                      const SizedBox(height: 8),
                    ],
                    if (tasks.isEmpty)
                      _EmptySeaTaskHint(
                        tone: tone,
                        onAdd: widget.creatingTask ? () {} : widget.onAdd,
                        isMainIsland: widget.island.isGrowthMainIsland,
                      )
                    else ...[
                      if (shouldScroll)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                for (final task in visible)
                                  _SeaTaskTile(
                                    task: task,
                                    tone: tone,
                                    onComplete: () => widget.onComplete(task),
                                    onUncomplete: () =>
                                        widget.onUncomplete(task),
                                    onEdit: () => widget.onEdit(task),
                                    onDelete: () => widget.onDelete(task),
                                    busy: widget.busyTaskIds.contains(task.id),
                                  ),
                              ],
                            ),
                          ),
                        )
                      else
                        for (final task in visible)
                          _SeaTaskTile(
                            task: task,
                            tone: tone,
                            onComplete: () => widget.onComplete(task),
                            onUncomplete: () => widget.onUncomplete(task),
                            onEdit: () => widget.onEdit(task),
                            onDelete: () => widget.onDelete(task),
                            busy: widget.busyTaskIds.contains(task.id),
                          ),
                      if (hasHidden)
                        TextButton(
                          onPressed: () =>
                              setState(() => _expanded = !_expanded),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: tone.label.withValues(alpha: 0.72),
                            padding: const EdgeInsets.only(top: 2),
                          ),
                          child: Text(
                            _expanded
                                ? '收起'
                                : '还有 ${tasks.length - _collapsedLimit} 项',
                            style: appTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(_SeaDockTone tone, int doneCount, int total) {
    final categoryIcon = _categoryIcon(widget.island.categoryId);
    final stem = storyIslandNameStem(widget.island.name);
    final rewardLabel = widget.island.isGrowthMainIsland
        ? '完成 +$storyIslandTaskGrowthDelta 经验值'
        : '完成 +$storyIslandTaskGrowthDelta 成长值';

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tone.chipTop,
                tone.chipBottom,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: tone.shadow.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(categoryIcon, size: 17, color: tone.label),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '今日待办',
                style: appTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: tone.label,
                ),
              ),
              Text(
                '$stem · $rewardLabel',
                style: appTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tone.label.withValues(alpha: 0.58),
                ),
              ),
            ],
          ),
        ),
        if (total > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tone.wave.withValues(alpha: 0.35)),
            ),
            child: Text(
              '$doneCount/$total',
              style: appTextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: doneCount == total && total > 0
                    ? tone.accent
                    : tone.label.withValues(alpha: 0.72),
              ),
            ),
          ),
        const SizedBox(width: 4),
        Material(
          color: tone.accent.withValues(alpha: 0.16),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.creatingTask ? null : widget.onAdd,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: widget.creatingTask
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: tone.accent,
                      ),
                    )
                  : Icon(Icons.add_rounded, size: 20, color: tone.accent),
            ),
          ),
        ),
      ],
    );
  }

  IconData _categoryIcon(String categoryId) {
    return switch (categoryId) {
      'work' => Icons.work_outline_rounded,
      'study' => Icons.menu_book_outlined,
      'health' => Icons.eco_outlined,
      'social' => Icons.favorite_border_rounded,
      'life' => Icons.home_outlined,
      'finance' || 'wealth' => Icons.shield_outlined,
      'creation' => Icons.brush_outlined,
      _ => Icons.waves_rounded,
    };
  }
}

class _SeaDockTone {
  const _SeaDockTone({
    required this.seaLight,
    required this.seaDeep,
    required this.wave,
    required this.label,
    required this.accent,
    required this.shadow,
    required this.chipTop,
    required this.chipBottom,
  });

  final Color seaLight;
  final Color seaDeep;
  final Color wave;
  final Color label;
  final Color accent;
  final Color shadow;
  final Color chipTop;
  final Color chipBottom;

  factory _SeaDockTone.fromPalette(MoodPalette palette) {
    final accent = palette.accent;
    return _SeaDockTone(
      seaLight: Color.lerp(accent, const Color(0xFFEAF6FF), 0.72)!,
      seaDeep: Color.lerp(accent, const Color(0xFF6EB8F7), 0.45)!,
      wave: Color.lerp(accent, const Color(0xFF90CAF9), 0.35)!,
      label: palette.primary,
      accent: accent,
      shadow: const Color(0xFF1A5070),
      chipTop: Colors.white.withValues(alpha: 0.95),
      chipBottom: Color.lerp(accent, Colors.white, 0.55)!,
    );
  }
}

class _SeaWaveRibbon extends StatelessWidget {
  const _SeaWaveRibbon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      width: double.infinity,
      child: CustomPaint(
        painter: _SeaWavePainter(color: color.withValues(alpha: 0.45)),
      ),
    );
  }
}

class _SeaWavePainter extends CustomPainter {
  _SeaWavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.05,
        size.width * 0.5,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.88,
        size.width,
        size.height * 0.35,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SeaWavePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SeaTaskLoadingHint extends StatelessWidget {
  const _SeaTaskLoadingHint({required this.tone});

  final _SeaDockTone tone;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.wave.withValues(alpha: 0.26)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: tone.accent,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '正在创建待办…',
              style: appTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: tone.label.withValues(alpha: 0.68),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySeaTaskHint extends StatelessWidget {
  const _EmptySeaTaskHint({
    required this.tone,
    required this.onAdd,
    this.isMainIsland = false,
  });

  final _SeaDockTone tone;
  final VoidCallback onAdd;
  final bool isMainIsland;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: 22,
                color: tone.accent.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isMainIsland
                      ? '写下主岛今日目标，完成可获经验值 +$storyIslandTaskGrowthDelta'
                      : '在海面写下今天的小目标',
                  style: appTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tone.label.withValues(alpha: 0.68),
                    height: 1.35,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: tone.label.withValues(alpha: 0.42),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeaTaskTile extends StatelessWidget {
  const _SeaTaskTile({
    required this.task,
    required this.tone,
    required this.onComplete,
    required this.onUncomplete,
    required this.onEdit,
    required this.onDelete,
    this.busy = false,
  });

  final StoryIslandTaskModel task;
  final _SeaDockTone tone;
  final VoidCallback onComplete;
  final VoidCallback onUncomplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final done = task.completedToday;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Opacity(
        opacity: busy ? 0.64 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: done
                ? Colors.white.withValues(alpha: 0.42)
                : Colors.white.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: done
                  ? tone.wave.withValues(alpha: 0.22)
                  : tone.wave.withValues(alpha: 0.38),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 2, 4),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: busy ? null : (done ? onUncomplete : onComplete),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: busy
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: tone.accent,
                                    ),
                                  )
                                : Icon(
                                    done
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    size: 20,
                                    color: done
                                        ? tone.accent
                                        : tone.label.withValues(alpha: 0.38),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task.isDaily ? '${task.title} · 每日' : task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: appTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: done
                                    ? tone.label.withValues(alpha: 0.48)
                                    : tone.label.withValues(alpha: 0.86),
                              ).copyWith(
                                decoration:
                                    done ? TextDecoration.lineThrough : null,
                                decorationColor:
                                    tone.label.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (done)
                  TextButton(
                    onPressed: busy ? null : onUncomplete,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: tone.label.withValues(alpha: 0.52),
                    ),
                    child: const Text('撤销', style: TextStyle(fontSize: 11)),
                  ),
                IconButton(
                  onPressed: busy ? null : onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  tooltip: '编辑',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 30, minHeight: 30),
                  color: tone.label.withValues(alpha: 0.52),
                ),
                IconButton(
                  onPressed: busy ? null : onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  tooltip: '删除',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 30, minHeight: 30),
                  color: tone.label.withValues(alpha: 0.42),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
