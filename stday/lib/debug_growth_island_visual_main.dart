import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/island/growth_island_visual_debug_page.dart';

void main() {
  runApp(
    const ProviderScope(
      child: _GrowthIslandVisualCheckApp(),
    ),
  );
}

class _GrowthIslandVisualCheckApp extends StatelessWidget {
  const _GrowthIslandVisualCheckApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GrowthIslandVisualDebugPage(),
    );
  }
}
