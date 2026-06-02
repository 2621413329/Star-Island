import 'package:flutter/material.dart';

import '../../core/constants/catalog.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/models/profile_models.dart';
import '../../design_system/companion_avatar.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/mood_face_painter.dart';

class MomentStoryCard extends StatefulWidget {
  const MomentStoryCard({
    super.key,
    required this.moment,
    required this.companionStyle,
    required this.palette,
    required this.height,
  });

  final DailyMomentModel moment;
  final String companionStyle;
  final MoodPalette palette;
  final double height;

  @override
  State<MomentStoryCard> createState() => _MomentStoryCardState();
}

class _MomentStoryCardState extends State<MomentStoryCard> {
  final GlobalKey<CompanionAvatarState> _companionKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final title = primaryStoryLabel(widget.moment.eventTags);
    final tagsText = widget.moment.eventTags.join(' · ');
    final summary = widget.moment.note?.isNotEmpty == true
        ? widget.moment.note!
        : '记录了关于$tagsText的瞬间';
    final mood = moodById(widget.moment.emotionTag);

    return SizedBox(
      height: widget.height,
      child: IslandGlassCard(
        palette: widget.palette,
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF5C5048)),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 8),
                        child: CustomPaint(
                          painter: MoodFacePainter(
                            type: mood.faceType,
                            color: mood.color,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      Text(
                        mood.label,
                        style: TextStyle(color: mood.color, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      ...widget.moment.eventTags.take(2).map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                t,
                                style: TextStyle(fontSize: 11, color: widget.palette.primary.withValues(alpha: 0.8)),
                              ),
                            ),
                          ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _companionKey.currentState?.playPerformance(),
              child: Column(
                children: [
                  CompanionAvatar(
                    key: _companionKey,
                    style: widget.companionStyle,
                    scene: widget.moment.companionScene,
                    pose: widget.moment.companionPose,
                    spec: widget.moment.companionSpec,
                    size: 76,
                    palette: widget.palette,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '点我演出',
                    style: TextStyle(fontSize: 10, color: widget.palette.accent),
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

class EmptyStoryCard extends StatelessWidget {
  const EmptyStoryCard({super.key, required this.palette, required this.height, required this.onAdd});

  final MoodPalette palette;
  final double height;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: IslandGlassCard(
        palette: palette,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '今天还是空白的一页',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text('记录一个瞬间吧', style: TextStyle(color: Color(0xFF8C7B6B))),
            const SizedBox(height: 24),
            IslandPrimaryAction(label: '+ 添加故事', palette: palette, onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}
