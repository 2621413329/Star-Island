import 'package:flutter/material.dart';

import 'island_unlock_catalog.dart';
import '../theme/app_fonts.dart';

/// 等级 / 装饰解锁预览。
class LevelUnlockPreviewAssets {
  LevelUnlockPreviewAssets._();

  static List<IslandUnlockItem> previewItemsForLevel(int level) =>
      IslandUnlockCatalog.itemsAtLevel(level);
}

Future<void> showLevelUnlockPreviewDialog(
  BuildContext context, {
  required int level,
  required bool unlocked,
  List<IslandUnlockItem>? items,
}) {
  final previewItems = items ?? IslandUnlockCatalog.itemsAtLevel(level);
  if (previewItems.isEmpty) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Lv.$level',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      pageBuilder: (ctx, _, __) => _UnlockPreviewShell(
        onDismiss: () => Navigator.of(ctx).pop(),
        child: _UnlockPreviewCard(
          title: 'Lv.$level',
          subtitle: unlocked ? '已解锁' : '升级后解锁',
          body: Container(
            height: 168,
            alignment: Alignment.center,
            child: Icon(
              Icons.landscape_outlined,
              size: 56,
              color: const Color(0xFF8C7B6B).withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  if (previewItems.length == 1) {
    final item = previewItems.first;
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: item.name,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      pageBuilder: (ctx, _, __) => _UnlockPreviewShell(
        onDismiss: () => Navigator.of(ctx).pop(),
        child: _UnlockPreviewCard(
          title: 'Lv.$level ${item.name}',
          subtitle: unlocked ? '已解锁' : '升级后解锁',
          body: _UnlockPreviewImage(assetPath: item.assetPath),
        ),
      ),
    );
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Lv.$level',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    pageBuilder: (ctx, _, __) {
      return _UnlockPreviewShell(
        onDismiss: () => Navigator.of(ctx).pop(),
        child: _SwipeUnlockPreview(
          level: level,
          unlocked: unlocked,
          items: previewItems,
        ),
      );
    },
  );
}

class _UnlockPreviewShell extends StatelessWidget {
  const _UnlockPreviewShell({
    required this.onDismiss,
    required this.child,
  });

  final VoidCallback onDismiss;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onDismiss,
          child: const SizedBox.expand(),
        ),
        GestureDetector(
          onTap: () {},
          child: child,
        ),
      ],
    );
  }
}

class _SwipeUnlockPreview extends StatefulWidget {
  const _SwipeUnlockPreview({
    required this.level,
    required this.unlocked,
    required this.items,
  });

  final int level;
  final bool unlocked;
  final List<IslandUnlockItem> items;

  @override
  State<_SwipeUnlockPreview> createState() => _SwipeUnlockPreviewState();
}

class _SwipeUnlockPreviewState extends State<_SwipeUnlockPreview> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_index];
    return _UnlockPreviewCard(
      title: 'Lv.${widget.level} ${item.name}',
      subtitle: widget.unlocked ? '已解锁 · 左右滑动预览' : '升级后解锁 · 左右滑动预览',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 168,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.items.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) {
                return _UnlockPreviewImage(
                  assetPath: widget.items[index].assetPath,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.items.length; i++)
                Container(
                  width: i == _index ? 8 : 6,
                  height: i == _index ? 8 : 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index
                        ? const Color(0xFFE8A87C)
                        : const Color(0xFFE8DDD4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_index + 1}/${widget.items.length}',
            style: appTextStyle(
              fontSize: 11,
              color: const Color(0xFF8C7B6B),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockPreviewCard extends StatelessWidget {
  const _UnlockPreviewCard({
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final String title;
  final String subtitle;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 36),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF8F3),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: appTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3D3229),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: appTextStyle(
                fontSize: 12,
                height: 1.45,
                color: const Color(0xFF8C7B6B),
              ),
            ),
            const SizedBox(height: 16),
            body,
          ],
        ),
      ),
    );
  }
}

class _UnlockPreviewImage extends StatelessWidget {
  const _UnlockPreviewImage({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        assetPath,
        height: 168,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          height: 168,
          alignment: Alignment.center,
          child: Icon(
            Icons.landscape_outlined,
            size: 56,
            color: const Color(0xFF8C7B6B).withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

Future<void> showTitlePreviewDialog(
  BuildContext context, {
  required int level,
  required String title,
  required int threshold,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    pageBuilder: (ctx, _, __) => _UnlockPreviewShell(
      onDismiss: () => Navigator.of(ctx).pop(),
      child: _UnlockPreviewCard(
        title: 'Lv.$level $title',
        subtitle: threshold == 0 ? '起点称号' : '累计成长值 $threshold',
        body: Container(
          height: 120,
          alignment: Alignment.center,
          child: Icon(
            Icons.military_tech_outlined,
            size: 56,
            color: const Color(0xFFE8A87C).withValues(alpha: 0.85),
          ),
        ),
      ),
    ),
  );
}
