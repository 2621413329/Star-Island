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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          _quote,
          textAlign: TextAlign.center,
          style: appTextStyle(
            fontSize: 12,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF8C7B6B),
          ),
        ),
      ),
    );
  }
}
