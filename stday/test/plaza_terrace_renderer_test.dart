import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stday/island/building/plaza_terrace_renderer.dart';

void main() {
  test('PlazaTerraceRenderer identifies plaza buildings', () {
    expect(PlazaTerraceRenderer.isPlazaBuilding('story_plaza'), isTrue);
    expect(PlazaTerraceRenderer.isPlazaBuilding('companion_plaza'), isTrue);
    expect(PlazaTerraceRenderer.isPlazaBuilding('growth_academy'), isFalse);
    expect(PlazaTerraceRenderer.isPlazaBuilding(null), isFalse);
  });

  test('PlazaTerraceRenderer draws without throwing', () {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    expect(
      () => PlazaTerraceRenderer.draw(
        canvas,
        base: const Offset(100, 120),
        scale: 1.2,
        accent: Colors.amber,
        sand: const Color(0xFFE8D5B7),
      ),
      returnsNormally,
    );
  });
}
