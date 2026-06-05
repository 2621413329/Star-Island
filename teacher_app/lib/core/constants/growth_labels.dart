import 'package:flutter/material.dart';

Color growthStatusColor(String status) {
  switch (status) {
    case 'priority':
      return const Color(0xFFE65100);
    case 'ongoing':
      return const Color(0xFFFF9800);
    default:
      return const Color(0xFF7CB342);
  }
}
