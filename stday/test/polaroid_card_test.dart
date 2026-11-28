import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stday/data/models/polaroid_models.dart';
import 'package:stday/features/island/polaroid/polaroid_album_page.dart';
import 'package:stday/features/island/polaroid/polaroid_card.dart';
import 'package:stday/features/island/polaroid/polaroid_island_snapshot.dart';
import 'package:stday/features/island/polaroid/polaroid_flip.dart';
import 'package:stday/features/island/polaroid/polaroid_share.dart';
import 'package:stday/features/island/polaroid/polaroid_skin.dart';
import 'package:stday/features/island/polaroid/polaroid_spread.dart';

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
    expect(PolaroidFlip.pageDirection(dx: -80, dy: 10), 1);
    expect(PolaroidFlip.pageDirection(dx: 80, dy: 10), -1);
    expect(PolaroidFlip.pageDirection(dx: 20, dy: 90), 0);
  });

  test('拍立得一行两张并往下排', () {
    final board = PolaroidSpread.boardSize(
      count: 4,
      viewportWidth: 400,
    );
    final slots = PolaroidSpread.slots(4, board);
    final cardHeight = PolaroidSpread.cardHeightFor(400);
    expect(slots, hasLength(4));
    expect(slots[1].left, greaterThan(slots[0].left));
    expect(slots[2].left, closeTo(slots[0].left, 0.1));
    expect(slots.first.top, lessThan(20));
    expect(slots[2].top, greaterThan(slots.first.top + cardHeight * 0.8));
    expect(board.width, 400);
    expect(board.height, greaterThan(cardHeight * 2));
  });

  test('主岛拍立得画出这一级已经在岛上的建筑', () {
    final card = PolaroidCardModel(
      id: 'main-9',
      islandId: 'main',
      islandKind: 'main',
      islandName: '主岛',
      level: 9,
      buildingName: '成长小屋',
      assetKey: 'building:growth_house',
      categoryId: '',
      companionRole: 'xiao_xingzai',
      skinId: 'plain',
      takenAt: DateTime(2026, 3, 12),
      frontCaption: '今天，多了成长小屋',
      backSummary: null,
      backStatus: 'fallback',
      capturedLive: true,
      sourceMoments: const [],
    );
    final assets = polaroidPlacements(card).map((item) => item.asset).toList();
    expect(assets.any((path) => path.endsWith('starter_stone.png')), isTrue);
    expect(assets.any((path) => path.endsWith('record_shed.png')), isTrue);
    expect(assets.any((path) => path.endsWith('memory_mailbox.png')), isTrue);
    expect(assets.any((path) => path.endsWith('buildings/growth_house.png')), isTrue);
    expect(assets.any((path) => path.endsWith('flower_01.png')), isTrue);
    expect(assets.any((path) => path.endsWith('grass_01.png')), isTrue);
    expect(assets.any((path) => path.endsWith('tree_small_02.png')), isTrue);
  });

  test('Lv6 拍立得画出三棵小树，不再叫风车', () {
    final card = PolaroidCardModel(
      id: 'main-6',
      islandId: 'main',
      islandKind: 'main',
      islandName: '主岛',
      level: 6,
      buildingName: '风车',
      assetKey: 'title:6',
      categoryId: '',
      companionRole: 'xiao_xingzai',
      skinId: 'plain',
      takenAt: DateTime(2026, 3, 12),
      frontCaption: '今天，多了风车',
      backSummary: null,
      backStatus: 'fallback',
      capturedLive: true,
      sourceMoments: const [],
    );
    final assets = polaroidPlacements(card).map((item) => item.asset).toList();
    expect(assets.any((path) => path.endsWith('tree_small_02.png')), isTrue);
    expect(assets.any((path) => path.endsWith('tree_small_03.png')), isTrue);
    expect(assets.any((path) => path.endsWith('tree_small_04.png')), isTrue);
    expect(polaroidFrontLine(card), '今天，多了风向矮树、夕照树影等');
    expect(polaroidFrontLine(card).contains('风车'), isFalse);
  });

  test('主岛满级用升级后的小屋和灯塔', () {
    final card = PolaroidCardModel(
      id: 'main-20',
      islandId: 'main',
      islandKind: 'main',
      islandName: '主岛',
      level: 20,
      buildingName: '成长学院',
      assetKey: 'building:growth_academy',
      categoryId: '',
      companionRole: 'xiao_xingzai',
      skinId: 'plain',
      takenAt: DateTime(2026, 3, 12),
      frontCaption: '今天，多了成长学院',
      backSummary: null,
      backStatus: 'fallback',
      capturedLive: true,
      sourceMoments: const [],
    );
    final assets = polaroidPlacements(card).map((item) => item.asset).toList();
    expect(assets.any((path) => path.endsWith('growth_house_lv2.png')), isTrue);
    expect(assets.any((path) => path.endsWith('lighthouse.png')), isTrue);
    expect(assets.any((path) => path.endsWith('growth_academy.png')), isTrue);
    expect(assets.any((path) => path.endsWith('/growth_house.png')), isFalse);
    expect(assets.any((path) => path.endsWith('lighthouse_base.png')), isFalse);
  });

  test('背面没有模型总结时，用这几天的原文', () {
    final card = _card();
    final empty = PolaroidCardModel(
      id: card.id,
      islandId: card.islandId,
      islandKind: card.islandKind,
      islandName: card.islandName,
      level: card.level,
      buildingName: card.buildingName,
      assetKey: card.assetKey,
      categoryId: card.categoryId,
      companionRole: card.companionRole,
      skinId: card.skinId,
      takenAt: card.takenAt,
      frontCaption: card.frontCaption,
      backSummary: null,
      backStatus: 'fallback',
      capturedLive: true,
      sourceMoments: card.sourceMoments,
    );
    final text = polaroidBackBody(empty);
    expect(text.contains('茶屋'), isTrue);
    expect(text.contains('牛肉面'), isTrue);
    expect(text.contains('3月12日'), isTrue);
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
    expect(find.text('今天，进化成了茶屋'), findsOneWidget);
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
    expect(find.text('今天，进化成了茶屋'), findsNothing);

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
    final frontSize = tester.getSize(find.byType(PolaroidFace));
    expect(find.byType(PolaroidIslandSnapshot), findsOneWidget);
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
    expect(tester.getSize(find.byType(PolaroidFace)), frontSize);
    expect(find.byType(PolaroidIslandSnapshot), findsNothing);
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
    expect(find.text('今天，多了野趣小花、晨露花芽等'), findsOneWidget);
    expect(find.byType(PolaroidIslandSnapshot), findsOneWidget);
    expect(find.byKey(const Key('polaroid-main-level-badge')), findsOneWidget);
    expect(find.byKey(const Key('polaroid-theme-wall')), findsOneWidget);
    expect(find.text('这座岛还没有被拍下'), findsNothing);

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('polaroid-spread-p1')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.text('点一下翻到背面'), findsNothing);
    expect(find.text('左右滑动看这些照片，点一张放大'), findsNothing);
  });

  testWidgets('放大后左右滑动换到下一张', (tester) async {
    PolaroidCardModel cardFor(String id, String caption) {
      return PolaroidCardModel(
        id: id,
        islandId: 'island',
        islandKind: 'main',
        islandName: '主岛',
        level: id == 'p1' ? 2 : 5,
        buildingName: caption,
        assetKey: 'title:2',
        categoryId: '',
        companionRole: 'unknown',
        skinId: 'plain',
        takenAt: DateTime(2026, 3, 12),
        frontCaption: caption,
        backSummary: null,
        backStatus: 'fallback',
        capturedLive: true,
        sourceMoments: const [],
      );
    }

    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: PolaroidAlbumPage(
            islandId: 'island',
            initial: [
              cardFor('p1', '今天，多了小树苗'),
              cardFor('p2', '今天，多了记录小屋'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('polaroid-spread-p1')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.drag(find.byKey(const Key('polaroid-viewer')), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
  });
}
