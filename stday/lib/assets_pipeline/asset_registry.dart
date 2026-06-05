/// V1 资源注册表占位；后续接入 world_assets.yaml。
class AssetRegistry {
  AssetRegistry._();
  static final instance = AssetRegistry._();

  bool _loaded = false;

  Future<void> preload() async {
    if (_loaded) return;
    _loaded = true;
  }
}
