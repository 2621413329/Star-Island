import 'package:flutter/material.dart';
import '../../core/constants/catalog.dart';
import '../../core/utils/moment_tags.dart';
import '../../core/constants/moment_limits.dart';
import '../../core/models/user_companion.dart';
import '../../core/utils/moment_date_groups.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/models/profile_models.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/mood_face_icon.dart';
import '../../design_system/pressable_feedback.dart';
import '../../design_system/user_companion_view.dart';

class TodayStoryCard extends StatefulWidget {
  const TodayStoryCard({
    super.key,
    required this.moment,
    required this.companion,
    required this.palette,
    required this.onViewDetail,
    this.onEdit,
    required this.onPlay,
    this.onDelete,
    this.readOnly = false,
  });

  final DailyMomentModel moment;
  final UserCompanion companion;
  final MoodPalette palette;
  final bool readOnly;
  final VoidCallback onViewDetail;
  final VoidCallback? onEdit;
  final VoidCallback onPlay;
  final VoidCallback? onDelete;

  @override
  State<TodayStoryCard> createState() => _TodayStoryCardState();
}

class _TodayStoryCardState extends State<TodayStoryCard> {
  final GlobalKey<UserCompanionViewState> _key = GlobalKey();
  static const _companionSize = 68.0;
  static const _companionPropOverflow = 14.0;

  @override
  Widget build(BuildContext context) {
    final mood = moodById(widget.moment.emotionTag);
    final title = momentDisplayTitle(widget.moment);
    final aiEmotion = momentAiEmotionLabel(widget.moment);
    final summary = widget.moment.note?.isNotEmpty == true
        ? widget.moment.note!
        : title;
    final showActions =
        widget.onDelete != null || widget.onEdit != null;

    return IslandGlassCard(
      palette: widget.palette,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Opacity(
        opacity: widget.readOnly ? 0.92 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: PressableFeedback(
                onTap: widget.onViewDetail,
                feedback: PressFeedbackType.selection,
                pressedScale: 0.98,
                inactiveOpacity: 1,
                semanticLabel: title,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: MoodFaceIcon(
                        type: mood.faceType,
                        color: mood.color,
                        size: 48,
                        strokeWidth: 2.4,
                        moodId: mood.id,
                        gender: widget.companion.gender,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            aiEmotion ?? mood.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: mood.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            summary,
                            maxLines: momentNotePreviewMaxLines,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Color(0xFF5A4E44),
                            ),
                          ),
                          const SizedBox(height: 6),
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
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (showActions)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onEdit != null)
                        PressableFeedback(
                          onTap: widget.onEdit,
                          pressedScale: 0.9,
                          semanticLabel: 'edit',
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 22,
                              color: widget.palette.accent,
                            ),
                          ),
                        ),
                      if (widget.onDelete != null)
                        PressableFeedback(
                          onTap: widget.onDelete,
                          pressedScale: 0.9,
                          semanticLabel: 'delete',
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 22,
                              color: widget.palette.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                PressableFeedback(
                  onTap: () {
                    _key.currentState?.playPerformance();
                    widget.onPlay();
                  },
                  pressedScale: 0.94,
                  semanticLabel: 'play',
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: _companionSize + _companionPropOverflow,
                    height: _companionSize * 1.15,
                    child: UserCompanionView(
                      key: _key,
                      companion: widget.companion,
                      story: CompanionStoryContext.fromMoment(widget.moment),
                      size: _companionSize,
                      palette: widget.palette,
                      showAura: false,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
