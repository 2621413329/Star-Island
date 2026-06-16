class BuildingUnlockModel {
  const BuildingUnlockModel({
    required this.buildingId,
    required this.unlockLevel,
    required this.unlockedAt,
  });

  final String buildingId;
  final int unlockLevel;
  final DateTime unlockedAt;

  factory BuildingUnlockModel.fromJson(Map<String, dynamic> json) {
    return BuildingUnlockModel(
      buildingId: json['building_id'] as String,
      unlockLevel: json['unlock_level'] as int? ?? 1,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String).toLocal(),
    );
  }
}
