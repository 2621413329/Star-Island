import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/models/companion_spec.dart';
import '../core/theme/mood_theme.dart';
import 'companion_asset_avatar.dart';

class CompanionAvatar extends StatefulWidget {
  const CompanionAvatar({
    super.key,
    required this.style,
    this.scene = 'stargaze',
    this.pose = 'breathing',
    this.actionType = 'wave',
    this.expression = 'calm',
    this.prop = 'none',
    this.companionTint,
    this.spec,
    this.size = 140,
    this.palette,
    this.autoPlayOnMount = false,
    this.showAura = true,
    this.gender,
  });

  final String style;
  final String scene;
  final String pose;
  final String actionType;
  final String expression;
  final String prop;
  final Color? companionTint;
  final CompanionSpec? spec;
  final double size;
  final MoodPalette? palette;
  final bool autoPlayOnMount;
  final bool showAura;
  final String? gender;

  @override
  CompanionAvatarState createState() => CompanionAvatarState();
}

class CompanionAvatarState extends State<CompanionAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _idle;
  AnimationController? _performance;
  bool _performing = false;
  double _perfLevel = 0;

  String get _action => widget.spec?.animationType ?? widget.actionType;
  String get _expression => widget.spec?.expression ?? widget.expression;
  String get _prop => widget.spec?.prop ?? widget.prop;
  List<String> get _extraProps => widget.spec?.extraProps ?? const [];

  String get _paintStyle {
    if (widget.style == 'chibi' ||
        widget.style == 'normal' ||
        widget.style == 'mindscape') {
      return 'cozy';
    }
    return widget.style;
  }

  Color get _tint {
    if (widget.spec != null) return widget.spec!.tint;
    if (widget.companionTint != null) return widget.companionTint!;
    return widget.palette?.accent ?? defaultPalette.accent;
  }

  Color get _glow => Color.lerp(_tint, Colors.white, 0.35) ?? _tint;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.pose == 'float' ? 2400 : 3000),
    )..repeat(reverse: true);
    if (widget.autoPlayOnMount) {
      WidgetsBinding.instance.addPostFrameCallback((_) => playPerformance());
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _performance?.dispose();
    super.dispose();
  }

  Future<void> playPerformance() async {
    if (_performing) return;
    _performing = true;
    _performance?.dispose();
    _performance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..addListener(() {
        if (mounted) setState(() => _perfLevel = _performance!.value);
      });
    if (mounted) setState(() => _perfLevel = 0.01);
    await _performance!.forward(from: 0);
    _performance?.dispose();
    _performance = null;
    _performing = false;
    if (mounted) setState(() => _perfLevel = 0);
  }

  @override
  Widget build(BuildContext context) {
    final perf = _performance;
    return AnimatedBuilder(
      animation: Listenable.merge([_idle, if (perf != null) perf]),
      builder: (context, child) {
        final t = _idle.value;
        var breath = math.sin(t * math.pi) * 4.0;
        var scale = 1 + 0.02 * math.sin(t * math.pi);
        var dx = 0.0;
        var dy = 0.0;
        var rot = 0.0;

        if (perf != null) {
          final p = Curves.easeInOutCubic.transform(perf.value.clamp(0.0, 1.0));
          final action = _action;
          switch (action) {
            case 'celebrate':
            case 'cheer':
              scale = 1 + 0.28 * math.sin(p * math.pi * 2);
              breath = -14 * math.sin(p * math.pi);
            case 'wave':
              dx = 14 * math.sin(p * math.pi * 3);
              rot = 0.12 * math.sin(p * math.pi * 2);
            case 'shake':
              dx = 16 * math.sin(p * math.pi * 8);
            case 'swing':
              dx = 10 * math.sin(p * math.pi * 2);
              rot = -0.34 * math.sin(p * math.pi * 1.4);
              scale = 1 + 0.08 * math.sin(p * math.pi);
            case 'lose_slump':
              dy = 14 * math.sin(p * math.pi);
              rot = 0.14;
              scale = 0.9 + 0.04 * math.cos(p * math.pi);
            case 'hug':
              scale = 1 + 0.1 * math.sin(p * math.pi);
            case 'comfort':
              scale = 1 + 0.08 * math.sin(p * math.pi);
              dx = 6 * math.sin(p * math.pi);
              dy = -3 * math.sin(p * math.pi * 2);
            case 'reach_out':
              dx = 12 * math.sin(p * math.pi);
              rot = -0.08 * math.sin(p * math.pi);
            case 'think':
              rot = -0.12 * math.sin(p * math.pi);
              dy = 4 * math.sin(p * math.pi);
            case 'sit':
              dy = 6 * math.sin(p * math.pi);
              breath = 2 * math.sin(p * math.pi);
            case 'slump_read':
              rot = 0.08 * math.sin(p * math.pi);
              dy = 8 + 6 * math.sin(p * math.pi);
              scale = 0.96 + 0.02 * math.sin(p * math.pi);
            case 'look_down':
              dy = 10 * math.sin(p * math.pi);
              rot = 0.06;
              scale = 0.94 + 0.03 * (1 - p);
            default:
              dx = 10 * math.sin(p * math.pi * 2);
              scale = 1 + 0.12 * math.sin(p * math.pi);
          }
        }

        return Transform.translate(
          offset: Offset(dx, -breath + dy),
          child: Transform.rotate(
            angle: rot,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: CompanionAssetAvatar(
        size: widget.size,
        style: _paintStyle,
        expression: _expression,
        prop: _prop,
        extraProps: _extraProps,
        tint: _tint,
        glow: _glow,
        performanceLevel: _perfLevel,
        showAura: _paintStyle == 'cozy' ? false : widget.showAura,
        gender: widget.gender,
      ),
    );
  }
}
