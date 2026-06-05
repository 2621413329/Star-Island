import 'package:flutter/material.dart';

/// 与学生端 event_tags[0] 一致；label 与教师端 category_breakdown 键一致。
class GrowthCategory {
  const GrowthCategory(this.id, this.label, this.color);
  final String id;
  final String label;
  final Color color;
}

const growthCategories = <GrowthCategory>[
  GrowthCategory('学习', '学业', Color(0xFF42A5F5)),
  GrowthCategory('朋友', '朋友', Color(0xFFFFB74D)),
  GrowthCategory('运动', '运动', Color(0xFF66BB6A)),
  GrowthCategory('家庭', '家庭', Color(0xFFAB47BC)),
  GrowthCategory('兴趣', '兴趣', Color(0xFFFF7043)),
  GrowthCategory('其它', '其它', Color(0xFF78909C)),
];

GrowthCategory? growthCategoryById(String id) {
  for (final c in growthCategories) {
    if (c.id == id) return c;
  }
  return null;
}

GrowthCategory? growthCategoryByLabel(String label) {
  for (final c in growthCategories) {
    if (c.label == label) return c;
  }
  return null;
}
