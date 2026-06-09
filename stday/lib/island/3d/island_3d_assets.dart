import 'package:flame_3d/model.dart';
import 'package:flame_3d/parser.dart';

/// GLB 资源路径与加载缓存。
///
/// 替换模型：将自定义 GLB 放入 `assets/3d/models/` 并保持下列文件名即可。
class Island3DAssets {
  Island3DAssets._();

  static const heroGlb = 'assets/3d/models/hero.glb';
  static const treePineGlb = 'assets/3d/models/tree_pine.glb';
  static const treePuffyGlb = 'assets/3d/models/tree_puffy.glb';
  static const islandGroundGlb = 'assets/3d/models/island_ground.glb';
  static const rockGlb = 'assets/3d/models/rock.glb';

  static final _cache = <String, Model>{};

  static Future<Model?> loadGlb(String path) async {
    final cached = _cache[path];
    if (cached != null) return cached;
    try {
      final model = await ModelParser.parse(path);
      _cache[path] = model;
      return model;
    } on Object {
      return null;
    }
  }

  static void clearCache() => _cache.clear();
}
