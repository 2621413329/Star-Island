import '../features/today/widgets/growth_world_viewport.dart';

export '../features/today/widgets/growth_world_viewport.dart'
    show GrowthWorldViewport, GrowthWorldViewportState;

/// 已迁移至 [GrowthWorldViewport]；保留类型别名以兼容旧引用。
@Deprecated('Use GrowthWorldViewport')
typedef GrowthIslandScene = GrowthWorldViewport;

@Deprecated('Use GrowthWorldViewportState')
typedef GrowthIslandSceneState = GrowthWorldViewportState;
