import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../data/models/story_island_models.dart';
import '../../../providers/widget_navigation_provider.dart';
import 'story_island_sea_task_dock.dart';

/// 详情页右侧可收起待办：默认小圆钮贴右，点击后向左展开面板。
class StoryIslandCollapsibleTaskDock extends ConsumerStatefulWidget {
  const StoryIslandCollapsibleTaskDock({
    super.key,
    required this.island,
    required this.palette,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onComplete,
    required this.onUncomplete,
    this.loading = false,
    this.panelWidth = 300,
  });

  final StoryIslandModel? island;
  final MoodPalette palette;
  final VoidCallback onAdd;
  final ValueChanged<StoryIslandTaskModel> onEdit;
  final ValueChanged<StoryIslandTaskModel> onDelete;
  final ValueChanged<StoryIslandTaskModel> onComplete;
  final ValueChanged<StoryIslandTaskModel> onUncomplete;
  final bool loading;
  final double panelWidth;

  @override
  ConsumerState<StoryIslandCollapsibleTaskDock> createState() =>
      _StoryIslandCollapsibleTaskDockState();
}

class _StoryIslandCollapsibleTaskDockState
    extends ConsumerState<StoryIslandCollapsibleTaskDock> {
  static const _duration = Duration(milliseconds: 280);

  bool _open = false;

  @override
  void initState() {
    super.initState();
    _maybeOpenFromProvider();
  }

  @override
  void didUpdateWidget(covariant StoryIslandCollapsibleTaskDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.island?.id != widget.island?.id) {
      _maybeOpenFromProvider();
    }
  }

  void _maybeOpenFromProvider() {
    final pending = ref.read(pendingTaskDockIslandIdProvider);
    final islandId = widget.island?.id;
    if (pending != null && islandId != null && pending == islandId) {
      _open = true;
      ref.read(pendingTaskDockIslandIdProvider.notifier).state = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(pendingTaskDockIslandIdProvider, (previous, next) {
      final islandId = widget.island?.id;
      if (next == null || islandId == null || next != islandId) return;
      setState(() => _open = true);
      ref.read(pendingTaskDockIslandIdProvider.notifier).state = null;
    });

    final accent = widget.palette.accent;
    final tasks = widget.island?.todayTasks ?? const [];
    final pending = tasks.where((t) => !t.completedToday).length;
    final maxPanelHeight = MediaQuery.sizeOf(context).height * 0.52;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRect(
          child: AnimatedAlign(
            duration: _duration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.centerRight,
            widthFactor: _open ? 1 : 0,
            child: AnimatedOpacity(
              duration: _duration,
              opacity: _open ? 1 : 0,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: widget.panelWidth,
                    maxHeight: maxPanelHeight,
                  ),
                  child: widget.loading || widget.island == null
                      ? _LoadingPanel(palette: widget.palette)
                      : SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: StoryIslandSeaTaskDock(
                            island: widget.island!,
                            palette: widget.palette,
                            onAdd: widget.onAdd,
                            onEdit: widget.onEdit,
                            onDelete: widget.onDelete,
                            onComplete: widget.onComplete,
                            onUncomplete: widget.onUncomplete,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        _ToggleFab(
          accent: accent,
          open: _open,
          pendingCount: pending,
          loading: widget.loading,
          onTap: () => setState(() => _open = !_open),
        ),
      ],
    );
  }
}

class _ToggleFab extends StatelessWidget {
  const _ToggleFab({
    required this.accent,
    required this.open,
    required this.pendingCount,
    required this.loading,
    required this.onTap,
  });

  final Color accent;
  final bool open;
  final int pendingCount;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(accent, Colors.white, 0.22)!,
                accent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                )
              else
                Icon(
                  open ? Icons.chevron_right_rounded : Icons.checklist_rounded,
                  color: Colors.white,
                  size: open ? 26 : 22,
                ),
              if (!open && !loading && pendingCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE85D5D),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      pendingCount > 9 ? '9+' : '$pendingCount',
                      style: appTextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({required this.palette});

  final MoodPalette palette;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '加载待办…',
                  style: appTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.primary.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
