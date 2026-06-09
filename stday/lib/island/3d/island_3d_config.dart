/// Growth Island 3D 全局配置。
///
/// Visual Prototype 阶段优先呈现 2.5D 微缩景观；3D 能力保留，后续可按
/// 同一视觉方向继续扩展 [Island3DAssets] 与 [Island3DWorldBuilder]。
class Island3DConfig {
  Island3DConfig._();

  /// 当前默认使用 Flame Canvas 2.5D 场景，避免回到模型展示感。
  static const prefer3D = false;

  static const islandRadius = 4.2;
  static const islandHeight = 0.35;
  static const rimHeight = 0.22;
}
