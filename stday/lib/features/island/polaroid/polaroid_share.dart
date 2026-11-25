import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/companion_write_asset.dart';
import '../../../data/models/polaroid_models.dart';
import 'polaroid_card.dart';
import 'polaroid_island_snapshot.dart';
import 'polaroid_skin.dart';

/// 分享弹层要用的锚点。必须落在屏幕内且宽高都大于 0，否则 iPad 打不开。
Rect polaroidShareOrigin({
  required Rect? anchor,
  required Size screen,
}) {
  final screenRect = Offset.zero & screen;
  if (anchor != null && !screenRect.isEmpty) {
    final clipped = anchor.intersect(screenRect);
    if (clipped.width >= 1 && clipped.height >= 1) return clipped;
  }
  if (screen.width < 44 || screen.height < 44) {
    return const Rect.fromLTWH(0, 0, 44, 44);
  }
  return Rect.fromLTWH(screen.width - 52, (screen.height - 44) / 2, 44, 44);
}

/// 只导出正面。安卓和 iOS 都走系统分享，不写入相册，也不申请相册权限。
Future<void> sharePolaroidFront(
  BuildContext context,
  PolaroidCardModel card, {
  PolaroidScene scene = PolaroidScene.fallback,
}) async {
  await _precachePolaroidImages(context, card);
  if (!context.mounted) return;
  final key = GlobalKey();
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: 0,
      top: 0,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.01,
          child: Material(
            color: Colors.transparent,
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 320,
                child: PolaroidFace(
                  card: card,
                  showBack: false,
                  scene: scene,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  try {
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null || !boundary.hasSize) {
      if (context.mounted) _tellShareFailed(context);
      return;
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) {
      if (context.mounted) _tellShareFailed(context);
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/polaroid_${card.id}.png');
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    if (!context.mounted) return;
    final box = context.findRenderObject();
    final anchor = box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await Share.shareXFiles(
      [
        XFile(
          file.path,
          mimeType: 'image/png',
          name: 'polaroid.png',
        ),
      ],
      sharePositionOrigin: polaroidShareOrigin(
        anchor: anchor,
        screen: MediaQuery.sizeOf(context),
      ),
    );
  } catch (_) {
    if (context.mounted) _tellShareFailed(context);
  } finally {
    entry.remove();
  }
}

Future<void> _precachePolaroidImages(
  BuildContext context,
  PolaroidCardModel card,
) async {
  final paths = <String>[
    CompanionWriteAssets.assetPathFor(card.companionRole),
    ...polaroidSnapshotAssetPaths(card),
  ];
  for (final path in paths) {
    if (!context.mounted) return;
    try {
      await precacheImage(AssetImage(path), context);
    } catch (_) {}
  }
}

void _tellShareFailed(BuildContext context) {
  if (!context.mounted) return;
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    const SnackBar(content: Text('这张正面暂时没法分享')),
  );
}
