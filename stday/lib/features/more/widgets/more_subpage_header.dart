import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_fonts.dart';

/// 「更多」子页统一页眉，与「我的等级」等页保持一致。
class MoreSubpageHeader extends StatelessWidget {
  const MoreSubpageHeader({
    super.key,
    required this.title,
    this.actions = const [],
  });

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: const Color(0xFF5D4E44),
          ),
          Expanded(
            child: Text(
              title,
              style: appTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3D3229),
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
