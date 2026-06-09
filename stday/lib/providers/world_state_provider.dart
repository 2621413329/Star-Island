import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../world/engine/growth_world_engine.dart';

final growthWorldEngineProvider = Provider<GrowthWorldEngine>(
  (ref) => GrowthWorldEngine(),
);
