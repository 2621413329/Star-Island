import 'dart:ui';

import 'protagonist_behavior.dart';

/// 与 [CharacterLayer] 主角命中区域一致，供 Flutter 叠层手势复用。
class CompanionHitTest {
  CompanionHitTest._();

  static const _cozyRatio = 0.132;
  static const _cozyMaxSize = 100.0;
  static const _hitScale = 1.45;

  static Rect hitRect(Size viewport, {bool cozyHero = true}) {
    const base = ProtagonistBehavior.defaultBase;
    final w = viewport.width;
    final h = viewport.height;
    final ratio = cozyHero ? _cozyRatio : 0.112;
    final maxSize = cozyHero ? _cozyMaxSize : 76.0;
    final charSize = (w * ratio).clamp(34.0, maxSize).toDouble();
    final charHeight = charSize * 1.15;
    final groundX = base.dx * w;
    final groundY = base.dy * h;
    return Rect.fromCenter(
      center: Offset(groundX, groundY - charHeight * 0.38),
      width: charSize * _hitScale,
      height: charHeight * _hitScale,
    );
  }

  static bool contains(Offset local, Size viewport, {bool cozyHero = true}) {
    return hitRect(viewport, cozyHero: cozyHero).contains(local);
  }

  /// 将全屏叠层坐标映射到 Flame 视口（[GrowthWorldViewport.scale] > 1 时）。
  static bool containsScreenTap(
    Offset screenLocal,
    Size screenSize, {
    double viewportScale = 1.0,
    bool cozyHero = true,
  }) {
    if (viewportScale <= 0.999) {
      return contains(screenLocal, screenSize, cozyHero: cozyHero);
    }
    final gameSize = Size(
      screenSize.width / viewportScale,
      screenSize.height / viewportScale,
    );
    final gamePos = Offset(
      screenLocal.dx / viewportScale,
      screenLocal.dy / viewportScale,
    );
    return contains(gamePos, gameSize, cozyHero: cozyHero);
  }

  /// 副岛详情页岛区（与 [StoryIslandStaticDetailViewport] 布局一致）。
  static Rect storyIslandDetailFrame(Size screenSize) {
    final islandW = screenSize.width * 0.94;
    final islandH = (screenSize.height * 0.58).clamp(300.0, 460.0);
    final islandLeft = (screenSize.width - islandW) / 2;
    final islandTop = (screenSize.height - islandH) / 2;
    return Rect.fromLTWH(islandLeft, islandTop, islandW, islandH);
  }

  static Rect storyIslandCompanionHitRect(
    Size screenSize, {
    bool cozyHero = true,
  }) {
    final frame = storyIslandDetailFrame(screenSize);
    final local = hitRect(Size(frame.width, frame.height), cozyHero: cozyHero);
    return local.shift(frame.topLeft);
  }

  static bool containsStoryIslandDetailTap(
    Offset screenLocal,
    Size screenSize, {
    bool cozyHero = true,
  }) {
    return storyIslandCompanionHitRect(screenSize, cozyHero: cozyHero)
        .contains(screenLocal);
  }
}
