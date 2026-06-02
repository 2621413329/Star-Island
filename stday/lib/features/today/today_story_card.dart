import 'package:flutter/material.dart';

import '../../core/constants/catalog.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/models/profile_models.dart';
import '../../design_system/companion_avatar.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/mood_face_painter.dart';

class TodayStoryCard extends StatefulWidget {
  const TodayStoryCard({
    super.key,
    required this.moment,
    required this.companionStyle,
    required this.palette,
    required this.onPlay,
  });

  final DailyMomentModel moment;
  final String companionStyle;
  final MoodPalette palette;
  final VoidCallback onPlay;

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
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CustomPaint(painter: MoodFacePainter(type: mood.faceType, color: mood.color, strokeWidth: 2.2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.35, color: Color(0xFF6B5E54)),
                ),
                const SizedBox(height: 6),
                Text(mood.label, style: TextStyle(fontSize: 12, color: mood.color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              _key.currentState?.playPerformance();
              widget.onPlay();
            },
            child: Column(
              children: [
                CompanionAvatar(
                  key: _key,
                  style: widget.companionStyle,
                  scene: widget.moment.companionScene,
                  pose: widget.moment.companionPose,
                  spec: widget.moment.companionSpec,
                  size: 64,
                  palette: widget.palette,
                ),
                Text('点我', style: TextStyle(fontSize: 10, color: widget.palette.accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
