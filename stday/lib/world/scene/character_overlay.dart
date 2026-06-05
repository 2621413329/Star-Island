import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/models/companion_spec.dart';
import '../../core/theme/mood_theme.dart';
import '../../design_system/companion_avatar.dart';
import '../../world/behaviors/character_motion_behavior.dart';
import '../../world/engine/world_state.dart';

/// CharacterLayer 的 Flutter 渲染宿主：角色与道具由 WorldState 驱动，不再在地图上重复摆道具。
class CharacterOverlay extends StatefulWidget {
  const CharacterOverlay({
    super.key,
    required this.characters,
    required this.companionStyle,
    required this.palette,
    required this.compact,
    this.onCharacterTap,
  });

  final List<CharacterSnapshot> characters;
  final String companionStyle;
  final MoodPalette palette;
  final bool compact;
  final void Function(CharacterSnapshot character, CompanionAvatarState state)? onCharacterTap;

  @override
  State<CharacterOverlay> createState() => CharacterOverlayState();
}

class CharacterOverlayState extends State<CharacterOverlay> with TickerProviderStateMixin {
  final Map<String, GlobalKey<CompanionAvatarState>> _keys = {};
  late final AnimationController _idle;
  final Map<String, double> _phaseSeeds = {};
  final CharacterMotionBehavior _motionBehavior = const CharacterMotionBehavior();

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _syncKeys();
  }

  @override
  void didUpdateWidget(covariant CharacterOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncKeys();
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  void _syncKeys() {
    final ids = widget.characters.map((c) => c.id).toSet();
    _keys.removeWhere((id, _) => !ids.contains(id));
    for (final c in widget.characters) {
      _keys.putIfAbsent(c.id, GlobalKey.new);
      _phaseSeeds.putIfAbsent(c.id, () {
        // 将 id 映射到 0–2π 的稳定相位，用于“随机”游走。
        final hash = c.id.hashCode;
        final normalized = (hash & 0x7fffffff) / 0x7fffffff;
        return normalized * math.pi * 2;
      });
    }
  }

  void playPerformance(String? linkedEventId) {
    if (linkedEventId == null) return;
    for (final c in widget.characters) {
      if (c.linkedEventId == linkedEventId) {
        _keys[c.id]?.currentState?.playPerformance();
      }
    }
  }

  void playAllPerformances() {
    for (final c in widget.characters) {
      _keys[c.id]?.currentState?.playPerformance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final size = widget.compact ? 62.0 : 80.0;

        return AnimatedBuilder(
          animation: _idle,
          builder: (context, _) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < widget.characters.length; i++)
                  _buildCharacter(widget.characters[i], w, h, size, i),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCharacter(CharacterSnapshot c, double w, double h, double size, int index) {
    final base = Offset(c.normalizedPos.dx * w, c.normalizedPos.dy * h);
    final t = _idle.value * math.pi * 2;
    final seed = _phaseSeeds[c.id] ?? (index.toDouble());
    final motion = _motionBehavior.sample(
      motion: c.motion,
      time: t,
      seed: seed,
    );
    final pos = base + motion.wander;
    final key = _keys[c.id]!;
    final spec = CompanionSpec(
      expression: c.expression,
      prop: c.prop,
      animationType: c.animationKey,
      tint: _parseTint(c.tintHex) ?? widget.palette.accent,
    );

    return Positioned(
      left: pos.dx - size * 0.5,
      top: pos.dy + motion.bob - size * 0.62,
      child: GestureDetector(
        onTap: () {
          key.currentState?.playPerformance();
          final st = key.currentState;
          if (st != null) widget.onCharacterTap?.call(c, st);
        },
        child: CompanionAvatar(
          key: key,
          style: widget.companionStyle,
          scene: c.companionScene,
          pose: c.companionPose,
          spec: spec,
          size: size,
          palette: widget.palette,
        ),
      ),
    );
  }

  Color? _parseTint(String? hex) {
    if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;
    final v = int.tryParse(hex.substring(1), radix: 16);
    if (v == null) return null;
    return Color(0xFF000000 | v);
  }
}
