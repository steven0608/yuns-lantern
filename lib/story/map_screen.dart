import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app.dart';
import '../core/app_scope.dart';
import '../core/audio/audio_service.dart';
import '../core/content/models.dart';
import '../core/tokens.dart';
import '../core/ui/touch_target.dart';
import '../core/ui/yun.dart';
import 'scene_player.dart';

/// The eight lanterns on the path up Lantern Hill (SPEC §8). Collected lights
/// glow. Chapters the family hasn't bought are misty and unreachable —
/// never padlocked, never a sales pitch. Tapping mist just swirls it.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    return ListenableBuilder(
      listenable: Listenable.merge([s.progress, s.settings]),
      builder: (context, _) {
        final chapters = s.content.story.chapters;
        final lights = s.progress.lightsCollected;
        return Scaffold(
          body: LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth, h = box.maxHeight;
            final node = (h * 0.16).clamp(kMinTouchTarget, 120.0);
            // Winding path from bottom-left up to the great lantern top-right.
            Offset at(int i) {
              final t = i / (chapters.length - 1);
              return Offset(
                w * (0.1 + 0.72 * t) + math.sin(t * math.pi * 3) * w * 0.03,
                h * (0.8 - 0.55 * t) + math.sin(t * math.pi * 4) * h * 0.08,
              );
            }

            return Stack(children: [
              Positioned.fill(child: CustomPaint(painter: _MapPainter(points: [for (var i = 0; i < chapters.length; i++) at(i)], lit: lights.length))),
              // The great lantern: brighter with every light collected.
              Positioned(
                right: w * 0.03,
                top: h * 0.04,
                child: _GreatLantern(size: h * 0.26, glow: lights.length / chapters.length),
              ),
              for (final (i, c) in chapters.indexed)
                Positioned(
                  left: at(i).dx - node / 2 - kHitSlop / 2,
                  top: at(i).dy - node / 2 - kHitSlop / 2,
                  child: _ChapterNode(
                    chapter: c,
                    size: node,
                    lit: lights.contains(c.id),
                    reachable: c.free || s.settings.fullAccess,
                  ),
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: RoundButton(icon: Icons.home_rounded, onTap: () => Navigator.of(context).pop()),
                ),
              ),
            ]);
          }),
        );
      },
    );
  }
}

class _ChapterNode extends StatelessWidget {
  const _ChapterNode({required this.chapter, required this.size, required this.lit, required this.reachable});
  final Chapter chapter;
  final double size;
  final bool lit;
  final bool reachable;

  @override
  Widget build(BuildContext context) {
    final color = Palette.named[chapter.lightColor] ?? Palette.lantern;
    final art = context.services.content.art.scenes[chapter.id];
    return TouchTarget(
      size: Size.square(size),
      sound: reachable ? Sfx.tap : Sfx.whoosh,
      onTap: reachable
          ? () => Navigator.of(context).push(softRoute(ChapterRunner(chapter: chapter)))
          : () {}, // mist swirls (scale bump + whoosh); nothing to buy here
      child: Opacity(
        opacity: reachable ? 1 : 0.45,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reachable ? Palette.card : Palette.mist,
            border: Border.all(color: lit ? color : Palette.paperDeep, width: 6),
            boxShadow: [
              if (lit) BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 30, spreadRadius: 6),
              const BoxShadow(color: Palette.shadow, blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          alignment: Alignment.center,
          child: reachable
              ? Text(art?.emoji.first ?? '🏮', style: TextStyle(fontSize: size * 0.42))
              : Icon(Icons.cloud_rounded, color: Palette.card, size: size * 0.55),
        ),
      ),
    );
  }
}

class _GreatLantern extends StatelessWidget {
  const _GreatLantern({required this.size, required this.glow});
  final double size;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(children: [
        Container(
          width: size * 0.7,
          height: size * 0.8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.3),
            color: Color.lerp(Palette.mist, Palette.lantern, glow),
            boxShadow: [BoxShadow(color: Palette.lantern.withValues(alpha: glow * 0.9), blurRadius: 70 * glow + 1, spreadRadius: 20 * glow)],
          ),
          alignment: Alignment.center,
          child: Yun(size: size * 0.35, mood: glow >= 1 ? YunMood.happy : YunMood.idle),
        ),
      ]),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.points, required this.lit});
  final List<Offset> points;
  final int lit;

  @override
  void paint(Canvas canvas, Size s) {
    final r = Offset.zero & s;
    canvas.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF52588F), Color(0xFFB39AC4), Color(0xFFF5C9A4)]).createShader(r));
    final rng = math.Random(3);
    for (var i = 0; i < 40; i++) {
      canvas.drawCircle(Offset(rng.nextDouble() * s.width, rng.nextDouble() * s.height * 0.4), rng.nextDouble() * 2 + 0.6, Paint()..color = const Color(0xAAFFF3D6));
    }
    final hill = Path()
      ..moveTo(0, s.height)
      ..lineTo(0, s.height * 0.75)
      ..quadraticBezierTo(s.width * 0.45, s.height * 0.62, s.width * 0.7, s.height * 0.3)
      ..quadraticBezierTo(s.width * 0.82, s.height * 0.15, s.width, s.height * 0.2)
      ..lineTo(s.width, s.height)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xFF8DAE7A));
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      path.quadraticBezierTo((a.dx + b.dx) / 2, a.dy, b.dx, b.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF3E1BD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_MapPainter o) => o.lit != lit || o.points.length != points.length || o.points.first != points.first;
}
