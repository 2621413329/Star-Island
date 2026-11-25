class PolaroidSourceMoment {
  const PolaroidSourceMoment({
    required this.id,
    required this.momentDate,
    required this.excerpt,
  });

  final String id;
  final DateTime momentDate;
  final String excerpt;

  factory PolaroidSourceMoment.fromJson(Map<String, dynamic> json) {
    return PolaroidSourceMoment(
      id: '${json['id']}',
      momentDate: DateTime.tryParse('${json['moment_date']}') ?? DateTime.now(),
      excerpt: '${json['excerpt'] ?? ''}',
    );
  }
}

class PolaroidCardModel {
  const PolaroidCardModel({
    required this.id,
    required this.islandId,
    required this.islandKind,
    required this.islandName,
    required this.level,
    required this.buildingName,
    required this.assetKey,
    required this.categoryId,
    required this.companionRole,
    required this.skinId,
    required this.takenAt,
    required this.frontCaption,
    required this.backSummary,
    required this.backStatus,
    required this.capturedLive,
    required this.sourceMoments,
  });

  final String id;
  final String islandId;
  final String islandKind;
  final String islandName;
  final int level;
  final String buildingName;
  final String assetKey;
  final String categoryId;
  final String companionRole;
  final String skinId;
  final DateTime takenAt;
  final String frontCaption;
  final String? backSummary;
  final String backStatus;
  final bool capturedLive;
  final List<PolaroidSourceMoment> sourceMoments;

  bool get isMain => islandKind == 'main';

  bool get isDeveloping => backStatus == 'developing';

  factory PolaroidCardModel.fromJson(Map<String, dynamic> json) {
    final rawSources = json['source_moments'];
    return PolaroidCardModel(
      id: '${json['id']}',
      islandId: '${json['island_id']}',
      islandKind: '${json['island_kind'] ?? 'story'}',
      islandName: '${json['island_name'] ?? ''}',
      level: json['level'] as int? ?? 0,
      buildingName: '${json['building_name'] ?? ''}',
      assetKey: '${json['asset_key'] ?? ''}',
      categoryId: '${json['category_id'] ?? ''}',
      companionRole: '${json['companion_role'] ?? ''}',
      skinId: '${json['skin_id'] ?? 'plain'}',
      takenAt: DateTime.tryParse('${json['taken_at']}')?.toLocal() ??
          DateTime.now(),
      frontCaption: '${json['front_caption'] ?? ''}',
      backSummary: json['back_summary'] as String?,
      backStatus: '${json['back_status'] ?? 'fallback'}',
      capturedLive: json['captured_live'] as bool? ?? false,
      sourceMoments: rawSources is List
          ? rawSources
              .whereType<Map>()
              .map((item) => PolaroidSourceMoment.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }
}
