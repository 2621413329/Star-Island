import 'package:flutter/material.dart';

import '../../core/theme/app_fonts.dart';
import 'landing_warm_quotes.dart';

/// 引导页下方带边框的温馨成长语句展示框。
class LandingWarmQuoteBox extends StatefulWidget {
  const LandingWarmQuoteBox({super.key});

  @override
  State<LandingWarmQuoteBox> createState() => _LandingWarmQuoteBoxState();
}

class _LandingWarmQuoteBoxState extends State<LandingWarmQuoteBox> {
  late final String _quote;

  @override
  void initState() {
    super.initState();
    _quote = LandingWarmQuotes.pickRandom();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3D342C), width: 1.6),
        color: const Color(0xFFFFF8F0).withValues(alpha: 0.55),
      ),
      child: Text(
        _quote,
        textAlign: TextAlign.center,
        style: appTextStyle(
          fontSize: 13,
          height: 1.55,
          color: const Color(0xFF5D4E44),
        ),
      ),
    );
  }
}
