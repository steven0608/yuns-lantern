import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/item_art.dart';
import '../content/content_loader.dart';
import '../tokens.dart';

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
