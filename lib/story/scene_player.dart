import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/art/item_art.dart';
import '../core/audio/audio_service.dart';
import '../core/content/content_loader.dart';
import '../core/content/models.dart';
import '../core/tokens.dart';
import '../core/ui/touch_target.dart';
import '../core/ui/yun.dart';
import '../games/registry.dart';
import '../games/shared/activity_scaffold.dart';

/// Runs one chapter (SPEC §8): open → activity → activity → beat → activity
/// → close → a light lands. Activities the child can't see (age, parent
/// setting, not yet built) are skipped so a chapter can always be finished.
class ChapterRunner extends StatefulWidget {
  const ChapterRunner({super.key, required this.chapter});
  final Chapter chapter;

  @override
  State<ChapterRunner> createState() => _ChapterRunnerState();
}

sealed class _Step {}

class _Narrate extends _Step {
  _Narrate(this.part);
  final String part;
}

class _Play extends _Step {
  _Play(this.game);
  final GameDef game;
}

class _ChapterRunnerState extends State<ChapterRunner> {
  late final List<_Step> _steps;
  int _i = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_i == 0 && !_built) _build();
  }

  bool _built = false;
  void _build() {
    _built = true;
    final s = context.services;
    final games = [
      for (final id in widget.chapter.activities)
        if (gameRegistry[id] != null && s.activityVisible(id)) gameRegistry[id]!,
    ];
    _steps = [
      _Narrate('open'),
      for (final (i, g) in games.indexed) ...[
        if (i == games.length - 1 && games.length > 1) _Narrate('beat'),
        _Play(g),
      ],
      if (games.length <= 1) _Narrate('beat'),
      _Narrate('close'),
    ];
  }

  void _advance() {
    if (_i + 1 >= _steps.length) {
      context.services.progress.collectLight(widget.chapter.id);
      Navigator.of(context).pop(widget.chapter.id);
      return;
    }
    setState(() => _i++);
  }

  @override
  Widget build(BuildContext context) {
    final light = Palette.named[widget.chapter.lightColor];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: switch (_steps[_i]) {
        _Narrate(:final part) => ScenePlayer(
            key: ValueKey('n$_i'),
            chapter: widget.chapter,
            part: part,
            onDone: _advance,
            onHome: () => Navigator.of(context).pop(),
          ),
        _Play(:final game) => ActivitySession(key: ValueKey('p$_i'), game: game, onFinished: _advance, lightColor: light),
      },
    );
  }
}

/// Audio-first narration over an illustrated still with a slow parallax pan
/// (no cutscene). Tapping anywhere skips — a child is never trapped (§8).
class ScenePlayer extends StatefulWidget {
  const ScenePlayer({super.key, required this.chapter, required this.part, required this.onDone, required this.onHome});
  final Chapter chapter;
  final String part;
  final VoidCallback onDone;
  final VoidCallback onHome;

  @override
  State<ScenePlayer> createState() => _ScenePlayerState();
}

class _ScenePlayerState extends State<ScenePlayer> with SingleTickerProviderStateMixin {
  late final AnimationController _pan = AnimationController(vsync: this, duration: const Duration(seconds: 14))..forward();
  bool _finishedLine = false;
  bool _left = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      final audio = context.services.audio;
      if (widget.part == 'close') audio.sfx(Sfx.light);
      audio.playVO(widget.chapter.voKey(widget.part)).then((_) {
        if (mounted) setState(() => _finishedLine = true);
      });
    }
  }

  bool _started = false;

  @override
  void dispose() {
    _pan.dispose();
    super.dispose();
  }

  void _continue() {
    if (_left) return;
    _left = true;
    context.services.audio.stopVO();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final art = context.services.content.art.scenes[widget.chapter.id];
    final light = Palette.named[widget.chapter.lightColor] ?? Palette.lantern;
    final isClose = widget.part == 'close';
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _continue,
        child: Stack(fit: StackFit.expand, children: [
          AnimatedBuilder(
            animation: _pan,
            builder: (_, _) => SceneStill(art: art, pan: _pan.value),
          ),
          Align(
            alignment: const Alignment(-0.45, 0.55),
            child: Yun(size: 170, mood: isClose ? YunMood.happy : YunMood.idle, lanternColor: isClose ? light : Palette.mist),
          ),
          if (isClose)
            Align(
              alignment: const Alignment(0.35, -0.2),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutBack,
                builder: (_, t, _) => Transform.scale(
                  scale: t,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: light,
                      boxShadow: [BoxShadow(color: light.withValues(alpha: 0.8), blurRadius: 60 * t, spreadRadius: 20 * t)],
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(padding: const EdgeInsets.all(4), child: RoundButton(icon: Icons.home_rounded, onTap: widget.onHome)),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AnimatedOpacity(
                  opacity: _finishedLine ? 1 : 0.35,
                  duration: kStandardEase,
                  child: RoundButton(
                    icon: Icons.arrow_forward_rounded,
                    onTap: _continue,
                    diameter: 112,
                    color: Palette.lantern,
                    iconColor: Palette.card,
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Placeholder illustration: sky, rolling ground, and the scene's emoji
/// props. [pan] 0→1 drifts layers at different speeds for gentle parallax.
class SceneStill extends StatelessWidget {
  const SceneStill({super.key, required this.art, this.pan = 0});
  final SceneArt? art;
  final double pan;

  @override
  Widget build(BuildContext context) {
    final sky = art?.sky ?? Palette.paper;
    final ground = art?.ground ?? Palette.leaf;
    final emoji = art?.emoji ?? const ['🌳'];
    return LayoutBuilder(builder: (_, box) {
      final w = box.maxWidth, h = box.maxHeight;
      return Stack(fit: StackFit.expand, children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(sky, const Color(0xFFFFFFFF), 0.25)!, sky],
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(-pan * w * 0.03, 0),
          child: CustomPaint(painter: _GroundPainter(ground)),
        ),
        for (final (i, e) in emoji.indexed)
          Positioned(
            left: w * (0.48 + (i % 2) * 0.22 + (i ~/ 2) * 0.08) - pan * w * (0.04 + i * 0.015),
            top: h * (0.18 + (i % 3) * 0.16) + math.sin(pan * math.pi * 2 + i) * 6,
            child: Emoji(e, size: h * (0.13 + (i.isEven ? 0.04 : 0))),
          ),
      ]);
    });
  }
}

class _GroundPainter extends CustomPainter {
  _GroundPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Path()..moveTo(-40, s.height * 0.7);
    for (var x = -40.0; x <= s.width + 80; x += 16) {
      p.lineTo(x, s.height * 0.7 + math.sin(x / s.width * math.pi * 2.3) * s.height * 0.05);
    }
    p
      ..lineTo(s.width + 80, s.height)
      ..lineTo(-40, s.height)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_GroundPainter o) => o.color != color;
}
