import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/story_island_models.dart';

class CurrentIslandSelection {
  const CurrentIslandSelection({
    required this.id,
    required this.name,
    this.isGrowthMain = false,
  });

  final String id;
  final String name;
  final bool isGrowthMain;
}

class CurrentIslandNotifier extends Notifier<CurrentIslandSelection?> {
  static const prefsKey = 'stday_current_island_id';

  @override
  CurrentIslandSelection? build() {
    _restoreFromPrefs();
    return null;
  }

  Future<void> _restoreFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(prefsKey);
    if (id == null || id.isEmpty) return;
    final name = prefs.getString('${prefsKey}_name') ?? '岛屿';
    final isGrowthMain = prefs.getBool('${prefsKey}_growth_main') ?? false;
    state = CurrentIslandSelection(
      id: id,
      name: name,
      isGrowthMain: isGrowthMain,
    );
  }

  Future<void> select({
    required String id,
    required String name,
    bool isGrowthMain = false,
  }) async {
    if (state?.id == id &&
        state?.name == name &&
        state?.isGrowthMain == isGrowthMain) {
      return;
    }
    state = CurrentIslandSelection(
      id: id,
      name: name,
      isGrowthMain: isGrowthMain,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, id);
    await prefs.setString('${prefsKey}_name', name);
    await prefs.setBool('${prefsKey}_growth_main', isGrowthMain);
  }

  Future<void> selectFromIsland(StoryIslandModel island) {
    return select(
      id: island.id,
      name: island.name,
      isGrowthMain: island.isGrowthMainIsland,
    );
  }

  Future<void> cycleIsland({
    required int delta,
    required List<StoryIslandModel> ordered,
    bool wrap = false,
  }) async {
    if (ordered.isEmpty) return;
    final currentId = state?.id;
    var index = 0;
    if (currentId != null) {
      index = ordered.indexWhere((island) => island.id == currentId);
      if (index < 0) index = 0;
    }
    final int nextIndex;
    if (wrap) {
      var next = (index + delta) % ordered.length;
      if (next < 0) next += ordered.length;
      nextIndex = next;
    } else {
      nextIndex = (index + delta).clamp(0, ordered.length - 1);
    }
    await selectFromIsland(ordered[nextIndex]);
  }
}

final currentIslandProvider =
    NotifierProvider<CurrentIslandNotifier, CurrentIslandSelection?>(
  CurrentIslandNotifier.new,
);

StoryIslandModel? findStoryIslandById(
  List<StoryIslandCategoryModel> groups,
  String islandId, {
  StoryIslandModel? growthMainIsland,
}) {
  if (growthMainIsland?.id == islandId) return growthMainIsland;
  for (final group in groups) {
    for (final island in group.islands) {
      if (island.id == islandId) return island;
    }
  }
  return null;
}
