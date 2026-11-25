import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stday/data/models/polaroid_models.dart';
import 'package:stday/features/island/polaroid/polaroid_album_page.dart';
import 'package:stday/features/island/polaroid/polaroid_card.dart';
import 'package:stday/features/island/polaroid/polaroid_flip.dart';
import 'package:stday/features/island/polaroid/polaroid_share.dart';

PolaroidCardModel _card() {
  return PolaroidCardModel(
    id: 'p1',
    islandId: 'island',
    islandKind: 'story',
    islandName: '生活岛',
    level: 6,
    buildingName: '茶屋',
    assetKey: 'story:life:6',
    categoryId: 'life',
    companionRole: 'xiao_xingzai',
    skinId: 'plain',
    takenAt: DateTime(2026, 3, 12),
    frontCaption: '今天，多了茶屋',
    backSummary: '这段日子里，你把午饭写了下来。',
    backStatus: 'ready',
    capturedLive: true,
    sourceMoments: [
      PolaroidSourceMoment(
        id: 'm1',
        momentDate: DateTime(2026, 3, 12),
        excerpt: '今天和妈妈吃了牛肉面',
      ),
    ],
  );
}

void main() {
  test('翻面角度吸到正面或背面', () {
    expect(PolaroidFlip.snapAngle(0.4), 0);
    expect(PolaroidFlip.snapAngle(math.pi / 2), math.pi);
    expect(PolaroidFlip.snapAngle(2), math.pi);
    expect(PolaroidFlip.snapAngle(-1), 0);
    expect(PolaroidFlip.pageDirection(dx: 10, dy: 80), 1);
    expect(PolaroidFlip.pageDirection(dx: 90, dy: 80), 0);
  });

  testWidgets('正面不含日常正文，背面才有', (tester) async {
    final card = PolaroidCardModel(
      id: 'p1',
      islandId: 'island',
      islandKind: 'story',
      islandName: '生活岛',
      level: 6,
      buildingName: '茶屋',
      assetKey: 'story:missing:6',
      categoryId: 'life',
      companionRole: 'unknown',
      skinId: 'plain',
      takenAt: DateTime(2026, 3, 12),
      frontCaption: '今天，多了茶屋',
      backSummary: '这段日子里，你把午饭写了下来。',
      backStatus: 'ready',
      capturedLive: true,
      sourceMoments: [
        PolaroidSourceMoment(
          id: 'm1',
          momentDate: DateTime(2026, 3, 12),
          excerpt: '今天和妈妈吃了牛肉面',
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 280,
              child: PolaroidFace(card: card, showBack: false),
            ),
          ),
        ),
      ),
    );
    expect(find.text('今天，多了茶屋'), findsOneWidget);
    expect(find.textContaining('牛肉面'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 280,
              child: PolaroidFace(card: card, showBack: true),
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('牛肉面'), findsOneWidget);
    expect(find.text('今天，多了茶屋'), findsNothing);
  });

  test('拍立得列表按模型保留等级', () {
    final card = _card();
    expect(card.level, 6);
    expect(card.frontCaption.contains('牛肉面'), isFalse);
  });

  test('分享锚点留在屏幕里', () {
    const screen = Size(390, 844);
    final clipped = polaroidShareOrigin(
      anchor: const Rect.fromLTWH(-20, 10, 80, 40),
      screen: screen,
    );
    expect(clipped.left, greaterThanOrEqualTo(0));
    expect(clipped.top, greaterThanOrEqualTo(0));
    expect(clipped.right, lessThanOrEqualTo(screen.width));
    expect(clipped.bottom, lessThanOrEqualTo(screen.height));
    expect(clipped.width, greaterThanOrEqualTo(1));
    expect(clipped.height, greaterThanOrEqualTo(1));

    final fallback = polaroidShareOrigin(
      anchor: const Rect.fromLTWH(-100, -100, 10, 10),
      screen: screen,
    );
    expect(fallback, const Rect.fromLTWH(338, 400, 44, 44));
  });

  testWidgets('相册打开时显示已经拍下的卡片', (tester) async {
    final card = PolaroidCardModel(
      id: 'p1',
      islandId: 'island',
      islandKind: 'main',
      islandName: '主岛',
      level: 2,
      buildingName: '小树苗',
      assetKey: 'title:missing',
      categoryId: '',
      companionRole: 'unknown',
      skinId: 'plain',
      takenAt: DateTime(2026, 3, 12),
      frontCaption: '今天，多了小树苗',
      backSummary: null,
      backStatus: 'fallback',
      capturedLive: true,
      sourceMoments: const [],
    );
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: PolaroidAlbumPage(
            islandId: 'island',
            initial: [card],
          ),
        ),
      ),
    );
    expect(find.text('今天，多了小树苗'), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.text('这座岛还没有被拍下'), findsNothing);
  });
}
