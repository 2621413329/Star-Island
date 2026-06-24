import 'profile_models.dart';

class PaginatedMomentsModel {
  const PaginatedMomentsModel({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.items,
  });

  final int total;
  final int page;
  final int pageSize;
  final List<DailyMomentModel> items;

  int get totalPages {
    if (pageSize <= 0) return 1;
    final pages = (total / pageSize).ceil();
    return pages < 1 ? 1 : pages;
  }

  factory PaginatedMomentsModel.fromJson(Map<String, dynamic> json) {
    return PaginatedMomentsModel(
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 10,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => DailyMomentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
