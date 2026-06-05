import 'package:flutter/material.dart';
import '../../core/constants/catalog.dart';
import '../../core/utils/moment_date_groups.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/models/profile_models.dart';
import '../../design_system/companion_avatar.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/mood_face_painter.dart';
import '../../design_system/pressable_feedback.dart';

class TodayStoryCard extends StatefulWidget {
  const TodayStoryCard({
    super.key,
    required this.moment,
    required this.companionStyle,
    this.companionGender,
    required this.palette,
    this.onEdit,
    required this.onPlay,
    this.onDelete,
    this.readOnly = false,
  });

  final DailyMomentModel moment;
  final String companionStyle;
  final String? companionGender;
  final MoodPalette palette;
  final bool readOnly;
  final VoidCallback? onEdit;
  final VoidCallback onPlay;
  final VoidCallback? onDelete;

  @override
  State<TodayStoryCard> createState() => _TodayStoryCardState();
}

class _TodayStoryCardState extends State<TodayStoryCard> {
  final GlobalKey<CompanionAvatarState> _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final mood = moodById(widget.moment.emotionTag);
    final title = primaryStoryLabel(widget.moment.eventTags);
    final summary = widget.moment.note?.isNotEmpty == true
        ? widget.moment.note!
        : widget.moment.eventTags.join(' · ');

    return IslandGlassCard(
      palette: widget.palette,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Opacity(
        opacity: widget.readOnly ? 0.92 : 1,
        child: Row(
          children: [
            Expanded(
              child: PressableFeedback(
                onTap: widget.onEdit,
                feedback: PressFeedbackType.selection,
                pressedScale: 0.98,
                inactiveOpacity: 1,
                semanticLabel: title,
                behavior: widget.onEdit != null
                    ? HitTestBehavior.opaque
                    : HitTestBehavior.deferToChild,
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CustomPaint(
                        painter: MoodFacePainter(
                          type: mood.faceType,
                          color: mood.color,
                          strokeWidth: 2.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: Color(0xFF6B5E54),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatMomentRecordTime(widget.moment),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8C7B6B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.onDelete != null)
              PressableFeedback(
                onTap: widget.onDelete,
                pressedScale: 0.9,
                semanticLabel: 'delete',
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: widget.palette.primary,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            PressableFeedback(
              onTap: () {
                _key.currentState?.playPerformance();
                widget.onPlay();
              },
              pressedScale: 0.94,
              semanticLabel: 'play',
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  CompanionAvatar(
                    key: _key,
                    style: widget.companionStyle,
                    gender: widget.companionGender,
                    scene: widget.moment.companionScene,
                    pose: widget.moment.companionPose,
                    spec: widget.moment.companionSpec,
                    size: 64,
                    palette: widget.palette,
                  ),
                  Text(
                    '点我',
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.palette.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
