import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/models/user_companion.dart';
import '../../core/theme/mood_theme.dart';
import '../../design_system/companion_speech_bubble.dart';
import '../../design_system/pressable_feedback.dart';
import '../../design_system/user_companion_view.dart';

/// 日常页右侧小人：默认半透明不挡文字，点击后正常展示；可配置始终高亮或侧边改心情。
class StoryCompanionFloater extends StatefulWidget {
  const StoryCompanionFloater({
    super.key,
    required this.palette,
    required this.companion,
    required this.story,
    required this.companionKey,
    this.size = 72,
    this.expandedSize,
    this.summaryLines = const [],
    this.onFaceTap,
    this.onMoodEdit,
    this.onPlay,
    this.alwaysExpanded = false,
    this.showCollapseControl = true,
  });

  final MoodPalette palette;
  final UserCompanion companion;
  final CompanionStoryContext story;
  final GlobalKey<UserCompanionViewState> companionKey;
  final double size;
  final double? expandedSize;
  final List<String> summaryLines;
  final VoidCallback? onFaceTap;
  final VoidCallback? onMoodEdit;
  final VoidCallback? onPlay;
  final bool alwaysExpanded;
  final bool showCollapseControl;

  static const ghostOpacity = 0.38;
  static const expandedOpacity = 1.0;

  @override
  State<StoryCompanionFloater> createState() => _StoryCompanionFloaterState();
}

class _StoryCompanionFloaterState extends State<StoryCompanionFloater> {
  static final _rnd = Random();
  late bool _expanded;
  String? _speechText;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _expanded = widget.alwaysExpanded;
  }

  @override
  void didUpdateWidget(covariant StoryCompanionFloater oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.alwaysExpanded && !_expanded) {
      _expanded = true;
    } else if (!widget.alwaysExpanded && oldWidget.alwaysExpanded && _expanded) {
      _collapse();
    }
  }

  double get _displaySize =>
      _expanded ? (widget.expandedSize ?? widget.size * 1.35) : widget.size * 0.82;

  double get _opacity => widget.alwaysExpanded || _expanded
      ? StoryCompanionFloater.expandedOpacity
      : StoryCompanionFloater.ghostOpacity;

  bool get _showCollapse =>
      widget.showCollapseControl && !widget.alwaysExpanded && _expanded;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _collapse() {
    if (widget.alwaysExpanded) return;
    _hideTimer?.cancel();
    setState(() {
      _expanded = false;
      _speechText = null;
    });
  }

  void _expand() {
    setState(() => _expanded = true);
  }

  Future<void> _onBodyTap() async {
    if (!_expanded) {
      _expand();
      return;
    }
    widget.onPlay?.call();
    await widget.companionKey.currentState?.playPerformance();
    final lines = widget.summaryLines;
    if (lines.isEmpty) return;
    _hideTimer?.cancel();
    final line = lines[_rnd.nextInt(lines.length)];
    setState(() {
      _speechText = line;
    });
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _speechText = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final faceSize = _displaySize * 0.42;

    final companionColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_showCollapse)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _collapse,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.palette.card.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.palette.accent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(
                      Icons.visibility_off_outlined,
                      size: 18,
                      color: widget.palette.primary.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_speechText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CompanionSpeechBubble(
              text: _speechText!,
              palette: widget.palette,
              maxWidth: 240,
              showTail: false,
            ),
          ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: _opacity,
          child: SizedBox(
            width: _displaySize + 8,
            height: _displaySize * 1.12,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                PressableFeedback(
                  onTap: () => unawaited(_onBodyTap()),
                  pressedScale: 0.94,
                  semanticLabel: _expanded ? '点击小人' : '展开小人',
                  child: UserCompanionView(
                    key: widget.companionKey,
                    companion: widget.companion,
                    story: widget.story,
                    size: _displaySize,
                    palette: widget.palette,
                    showAura: _expanded || widget.alwaysExpanded,
                  ),
                ),
                if (widget.onFaceTap != null)
                  Positioned(
                    top: _displaySize * 0.04,
                    left: (_displaySize + 8 - faceSize) / 2,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onFaceTap,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: faceSize,
                          height: faceSize,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.onMoodEdit != null && _expanded) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6, bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onMoodEdit,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.palette.card.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.palette.accent.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mood_outlined,
                        size: 18,
                        color: widget.palette.accent,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '改心情',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: widget.palette.primary.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          companionColumn,
        ],
      );
    }

    return companionColumn;
  }
}
