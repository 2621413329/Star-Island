import 'package:flutter/material.dart';

import '../../data/models/growth_tag_models.dart';
import '../../data/models/profile_models.dart';

/// 日常一级分类（优先 AI 字段，兼容旧 event_tags）。
String? momentPrimaryCategory(DailyMomentModel moment) {
  final primary = moment.primaryTag?.trim();
  if (primary != null && primary.isNotEmpty) return primary;
  if (moment.eventTags.isEmpty) return null;
  return moment.eventTags.first;
}

List<String> momentSecondaryTags(DailyMomentModel moment) {
  if (moment.secondaryTags.isNotEmpty) return moment.secondaryTags;
  if (moment.eventTags.length <= 1) return const [];
  return moment.eventTags.sublist(1);
}

/// 日常全部标签文案（一级 + 二级），兼容旧 event_tags。
List<String> momentAllTagLabels(DailyMomentModel moment) {
  final primary = momentPrimaryCategory(moment);
  final secondary = momentSecondaryTags(moment);
  if (primary == null) return secondary;
  return [primary, ...secondary];
}

bool momentHasGrowthTags(DailyMomentModel moment) {
  return momentPrimaryCategory(moment) != null ||
      momentSecondaryTags(moment).isNotEmpty;
}

List<String> momentGrowthPoints(DailyMomentModel moment) {
  if (moment.growthPoints.isNotEmpty) return moment.growthPoints;
  final fromPayload = moment.visualPayload['growth_points'];
  if (fromPayload is List) {
    return fromPayload.map((e) => '$e').where((e) => e.isNotEmpty).toList();
  }
  return const [];
}

String momentDisplayTitle(DailyMomentModel moment) {
  return momentPrimaryCategory(moment) ?? '成长记录';
}

String? momentAiEmotionLabel(DailyMomentModel moment) {
  final ai = moment.aiEmotion?.trim();
  if (ai != null && ai.isNotEmpty) return ai;
  final fromPayload = moment.visualPayload['ai_emotion'];
  if (fromPayload is String && fromPayload.trim().isNotEmpty) {
    return fromPayload.trim();
  }
  return null;
}

bool momentMatchesCategory(DailyMomentModel moment, String? categoryLabel) {
  if (categoryLabel == null) return true;
  return momentPrimaryCategory(moment) == categoryLabel;
}

GrowthTagCategoryModel? findCategoryByLabel(
  List<GrowthTagCategoryModel> categories,
  String? label,
) {
  if (label == null) return null;
  for (final category in categories) {
    if (category.label == label) return category;
  }
  return null;
}

GrowthTagCategoryModel? findCategoryById(
  List<GrowthTagCategoryModel> categories,
  String id,
) {
  for (final category in categories) {
    if (category.id == id) return category;
  }
  return null;
}

/// 标签库「情绪」分类下的二级标签，供 AI 感受编辑使用。
List<String> emotionLabelsFromCatalog(List<GrowthTagCategoryModel> catalog) {
  final emotionCategory = findCategoryById(catalog, 'emotion') ??
      findCategoryByLabel(catalog, '情绪');
  if (emotionCategory == null || !emotionCategory.isActive) {
    return const [];
  }
  return emotionCategory.tags
      .where((tag) => tag.isActive)
      .map((tag) => tag.label)
      .toList();
}

Color parseHexColor(String hex, {Color fallback = const Color(0xFF78909C)}) {
  var value = hex.replaceAll('#', '').trim();
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return fallback;
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return fallback;
  return Color(parsed);
}

IconData growthTagIcon(String iconName) {
  return switch (iconName) {
    'briefcase' => Icons.work_outline_rounded,
    'book' => Icons.menu_book_outlined,
    'fitness_center' => Icons.fitness_center_outlined,
    'groups' => Icons.groups_outlined,
    'home' => Icons.home_outlined,
    'palette' => Icons.palette_outlined,
    'account_balance_wallet' => Icons.account_balance_wallet_outlined,
    'emoji_events' => Icons.emoji_events_outlined,
    'sentiment_satisfied' => Icons.sentiment_satisfied_alt_outlined,
    'lightbulb' => Icons.lightbulb_outline_rounded,
    'celebration' => Icons.celebration_outlined,
    _ => Icons.label_outline_rounded,
  };
}
