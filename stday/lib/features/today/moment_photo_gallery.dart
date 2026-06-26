import 'package:flutter/material.dart';

import '../../core/theme/mood_theme.dart';
import '../../data/models/profile_models.dart';
import 'moment_photo_section.dart';

/// 全屏查看日常照片，带关闭按钮。
Future<void> showMomentPhotoViewer(
  BuildContext context, {
  required List<MomentPhotoModel> photos,
  int initialIndex = 0,
}) {
  if (photos.isEmpty) return Future.value();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '关闭照片',
    barrierColor: Colors.black.withValues(alpha: 0.88),
    pageBuilder: (ctx, _, __) {
      return _MomentPhotoViewer(
        photos: photos,
        initialIndex: initialIndex.clamp(0, photos.length - 1),
      );
    },
  );
}

/// 横向缩略图，点击放大。
class MomentPhotoThumbnailStrip extends StatelessWidget {
  const MomentPhotoThumbnailStrip({
    super.key,
    required this.photos,
    this.thumbnailSize = 72,
    this.spacing = 8,
  });

  final List<MomentPhotoModel> photos;
  final double thumbnailSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: thumbnailSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => SizedBox(width: spacing),
        itemBuilder: (context, index) {
          final photo = photos[index];
          return GestureDetector(
            onTap: () => showMomentPhotoViewer(
              context,
              photos: photos,
              initialIndex: index,
            ),
            child: MomentNetworkImage(
              url: momentPhotoFullUrl(photo.urlPath),
              width: thumbnailSize,
              height: thumbnailSize,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }
}

/// 列表卡片底部：默认收起，点击箭头展开缩略图。
class MomentPhotoCollapsibleStrip extends StatefulWidget {
  const MomentPhotoCollapsibleStrip({
    super.key,
    required this.photos,
    required this.palette,
  });

  final List<MomentPhotoModel> photos;
  final MoodPalette palette;

  @override
  State<MomentPhotoCollapsibleStrip> createState() =>
      _MomentPhotoCollapsibleStripState();
}

class _MomentPhotoCollapsibleStripState extends State<MomentPhotoCollapsibleStrip> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: widget.palette.accent,
                ),
                const SizedBox(width: 4),
                Text(
                  _expanded
                      ? '收起照片 (${widget.photos.length})'
                      : '查看照片 (${widget.photos.length})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.palette.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          MomentPhotoThumbnailStrip(photos: widget.photos),
        ],
      ],
    );
  }
}

class _MomentPhotoViewer extends StatefulWidget {
  const _MomentPhotoViewer({
    required this.photos,
    required this.initialIndex,
  });

  final List<MomentPhotoModel> photos;
  final int initialIndex;

  @override
  State<_MomentPhotoViewer> createState() => _MomentPhotoViewerState();
}

class _MomentPhotoViewerState extends State<_MomentPhotoViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, index) {
                final url = momentPhotoFullUrl(widget.photos[index].urlPath);
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(
                    child: MomentNetworkImage(
                      url: url,
                      fit: BoxFit.contain,
                      placeholderColor: Colors.black.withValues(alpha: 0.25),
                      progressColor: Colors.white54,
                      errorIconColor: Colors.white54,
                      progressSize: 28,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              right: 12,
              child: Material(
                color: Colors.black.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  tooltip: '关闭',
                ),
              ),
            ),
            if (widget.photos.length > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_index + 1} / ${widget.photos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
