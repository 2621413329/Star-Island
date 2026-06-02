import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/mood_theme.dart';
import '../../design_system/companion_avatar.dart';
import '../../design_system/confetti_paper.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _showConfetti = false;

  @override
  Widget build(BuildContext context) {
    const palette = defaultPalette;
    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    IslandGlassCard(
                      palette: palette,
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                      child: Column(
                        children: [
                          CompanionAvatar(style: 'chibi', scene: 'stargaze', size: 140, palette: palette),
                          const SizedBox(height: 20),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [palette.primary, palette.accent],
                            ).createShader(bounds),
                            child: const Text(
                              '成长小岛',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      '今天你过的好吗？',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, height: 1.4, fontWeight: FontWeight.w600, color: Color(0xFF6B5E54)),
                    ),
                    const Spacer(flex: 3),
                    IslandPrimaryAction(
                      label: '欢迎上岛',
                      palette: palette,
                      onPressed: () => setState(() => _showConfetti = true),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              if (_showConfetti)
                ConfettiPaperFall(
                  onDone: () {
                    if (mounted) context.go('/auth');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
