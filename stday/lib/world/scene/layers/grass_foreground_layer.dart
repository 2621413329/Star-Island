import '../scene_depth_priority.dart';
import 'world_layer.dart';

/// 前景草层曾用程序草带压住装饰根部。
///
/// 岛体改为手绘岛坯后，草地和岸线都在图里，这一层不再往岛面上加程序草。
class GrassForegroundLayer extends WorldLayer {
  GrassForegroundLayer()
      : super(layerPriority: SceneDepthPriority.foregroundGrass);
}
