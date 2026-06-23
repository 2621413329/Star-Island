import 'package:flutter/material.dart';

import '../../core/constants/catalog.dart';
import '../../core/utils/moment_tags.dart';
import '../../design_system/moment_tag_chips.dart';
import '../../core/constants/moment_limits.dart';
import '../../core/models/user_companion.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/models/profile_models.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/mood_face_icon.dart';
import '../../design_system/user_companion_view.dart';

class MomentStoryCard extends StatefulWidget {
  const MomentStoryCard({
    super.key,
    required this.moment,
    required this.companion,
    required this.palette,
    required this.height,
  });

  final DailyMomentModel moment;
  final UserCompanion companion;
  final MoodPalette palette;
  final double height;

  @override
  State<MomentStoryCard> createState() => _MomentStoryCardState();
}

class _MomentStoryCardState extends State<MomentStoryCard> {
  final GlobalKey<UserCompanionViewState> _companionKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final title = momentDisplayTitle(widget.moment);
    final summary = widget.moment.note?.isNotEmpty == true
        ? widget.moment.note!
        : title;
    final mood = moodById(widget.moment.emotionTag);
    final aiEmotion = momentAiEmotionLabel(widget.moment);

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
                      maxLines: momentNoteCardMaxLines,
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
                        child: MoodFaceIcon(
                          type: mood.faceType,
                          color: mood.color,
                          size: 28,
                          strokeWidth: 2,
                          moodId: mood.id,
                          gender: widget.companion.gender,
                        ),
                      ),
                      Text(
                        mood.label,
                        style: TextStyle(
                          color: mood.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  MomentTagChipRow(
                    moment: widget.moment,
                    palette: widget.palette,
                    compact: true,
                    aiEmotionLabel: aiEmotion == null
                        ? null
                        : 'AI感受 · $aiEmotion',
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _companionKey.currentState?.playPerformance(),
              child: UserCompanionView(
                key: _companionKey,
                companion: widget.companion,
                story: CompanionStoryContext.fromMoment(widget.moment),
                size: 76,
                palette: widget.palette,
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
            IslandPrimaryAction(label: '+ 添加日常', palette: palette, onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}
