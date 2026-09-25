import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/tokens.dart';

// The water tank for Float or Sink. Everything here is a pure function of
// time, so the painters and the item layout agree frame by frame: a floating
// duck rides exactly the wave that is drawn under it.

const double kTankRadius = 36;

/// Where things sit inside the tank, derived from its size so every device
/// gets the same picture.
class TankGeometry {
  TankGeometry(this.size, this.lanes);
  final Size size;

  /// Side-by-side resting places per layer (surface and sand).
  final int lanes;

  double get w => size.width;
  double get h => size.height;
  double get surfaceY => h * 0.22;
  double get floorY => h * 0.86;
  double get itemSize =>
      math.min(w / lanes * 0.56, h * 0.26).clamp(44.0, 150.0);
  double laneX(int lane) => (lane + 0.5) / lanes * w;
}

/// One thing the child has dropped in. It enters at the centre of the lane
/// it was released over (that is where the drag let go of it) and comes to
/// rest in [slot] on the surface or on the sand.
class Drop {
  Drop({
    required this.id,
    required this.floats,
    required this.lane,
    required this.slot,
    required this.t0,
    required this.seed,
  });

  static const double floatIn = 1.1;
  static const double sinkIn = 1.9;

  final String id;
  final bool floats;
  final int lane, slot, seed;
  final double t0;

  /// Last time the child tapped it in the water (it dunks or wiggles).
  double pokedAt = -99;
  bool bubbled = false;

  double get settle => floats ? floatIn : sinkIn;
}

/// Rings on the surface from something landing (strength 1) or a tap (≈0.5).
class Splash {
  Splash({required this.x, required this.t0, this.strength = 1});
  final double x; // fraction of tank width
  final double t0;
  final double strength;
}

/// A little cloud of bubbles released at a point (a tap, a poke).
class Burst {
  Burst({required this.at, required this.t0});
  final Offset at; // fractions of tank size
  final double t0;
}

class WaterFrame {
  WaterFrame({
    required this.geo,
    required this.time,
    required this.drops,
    required this.splashes,
    required this.bursts,
  });

  final TankGeometry geo;
  final double time;
  final List<Drop> drops;
  final List<Splash> splashes;
  final List<Burst> bursts;

  /// Height of the water line at [x]: two slow swells plus rings travelling
  /// out from every recent splash.
  double surfaceAt(double x) {
    final w = geo.w, h = geo.h;
    var y =
        geo.surfaceY +
        h * 0.009 * math.sin(x / w * 9.0 + time * 1.4) +
        h * 0.005 * math.sin(x / w * 21.0 - time * 1.1);
    for (final s in splashes) {
      final a = time - s.t0;
      if (a < 0 || a > 2.6) continue;
      final d = (x - s.x * w).abs() / w;
      final z = (d - a * 0.45) / 0.07;
      final envelope = math.exp(-z * z) + math.exp(-d / 0.04);
      y +=
          h *
          0.028 *
          s.strength *
          math.exp(-a * 1.7) *
          math.sin(a * 12 - d * 55) *
          envelope;
    }
    return y;
  }

  late final List<Offset> _surface = [
    for (var x = 0.0; x < geo.w + 8; x += 8)
      Offset(math.min(x, geo.w), surfaceAt(math.min(x, geo.w))),
  ];

  Path surfaceLine() => Path()..addPolygon(_surface, false);

  Path waterPath() => Path()
    ..addPolygon([Offset(0, geo.h), ..._surface, Offset(geo.w, geo.h)], true);

  /// Centre and tilt of a dropped item at [at] (default: now).
  (Offset, double) pose(Drop d, [double? at]) {
    final t = at ?? time;
    final a = math.max(0.0, t - d.t0);
    final s = geo.itemSize;
    final x0 = geo.laneX(d.lane), y0 = geo.h / 2;
    final x1 = geo.laneX(d.slot);
    final poke = t - d.pokedAt;

    if (d.floats) {
      // Pops up from where it went in, overshoots the surface a touch, then bobs.
      final p = (a / Drop.floatIn).clamp(0.0, 1.0);
      final x = x0 + (x1 - x0) * Curves.easeInOut.transform(p);
      final rest =
          surfaceAt(x) + s * 0.1 + math.sin(t * 2.1 + d.seed) * s * 0.03;
      var y = y0 + (rest - y0) * Curves.easeOutBack.transform(p);
      if (poke >= 0 && poke < 1) {
        y += math.sin(poke * math.pi) * (1 - poke) * s * 0.45; // dunk, pop back
      }
      final slope = (surfaceAt(x + 12) - surfaceAt(x - 12)) / 24;
      return (
        Offset(x, y),
        math.atan(slope) * p + math.sin(t * 1.6 + d.seed) * 0.07,
      );
    }

    // Drifts down with a lazy side-to-side sway and settles on the sand.
    final p = (a / Drop.sinkIn).clamp(0.0, 1.0);
    final e = Curves.easeInOutSine.transform(p);
    final sway = math.sin(a * 3.2 + d.seed) * (1 - p);
    final x = x0 + (x1 - x0) * e + sway * s * 0.2;
    var y = y0 + (geo.floorY - s * 0.38 - y0) * e;
    final landed = a - Drop.sinkIn;
    if (landed > 0 && landed < 0.45) {
      y -= math.sin(landed / 0.45 * math.pi) * s * 0.07;
    }
    var tilt = sway * 0.35 + ((d.seed % 5) - 2) * 0.08 * e;
    if (poke >= 0 && poke < 0.9) {
      tilt += math.sin(poke * 22) * 0.16 * (1 - poke / 0.9);
    }
    return (Offset(x, y), tilt);
  }
}

/// Behind the items: air, water body, sun shafts, seaweed, sand, pebbles.
class TankBackPainter extends CustomPainter {
  TankBackPainter(this.f);
  final WaterFrame f;

  static const _air = [Color(0xFFF6F2E6), Color(0xFFE6F0EA)];
  static const _sand = [Color(0xFFF1D9A8), Color(0xFFDDB77F)];
  static const _weed = Color(0xFF6FA35A);
  static const _pebbles = [
    Color(0xFFCFAE82),
    Color(0xFFB9C6B0),
    Color(0xFFE2C4A8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final g = f.geo;
    final all = Offset.zero & size;
    canvas.drawRect(
      all,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _air,
        ).createShader(all),
    );

    final water = f.waterPath();
    final deep = Rect.fromLTRB(0, g.surfaceY - g.h * 0.04, g.w, g.h);
    canvas.drawPath(
      water,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(Palette.water, Palette.card, 0.35)!,
            Palette.water,
            Palette.waterDeep,
          ],
          stops: const [0, 0.45, 1],
        ).createShader(deep),
    );

    // Slow sun shafts through the water.
    canvas.save();
    canvas.clipPath(water);
    final shaft = Rect.fromLTRB(0, g.surfaceY, g.w, g.floorY);
    for (var i = 0; i < 3; i++) {
      final x =
          g.w * (0.16 + i * 0.3) + math.sin(f.time * 0.35 + i * 2) * g.w * 0.03;
      final alpha = 0.12 + 0.05 * math.sin(f.time * 0.8 + i * 1.7);
      final ray = Path()
        ..moveTo(x, g.surfaceY - 20)
        ..lineTo(x + g.w * 0.05, g.surfaceY - 20)
        ..lineTo(x + g.w * 0.22, g.floorY)
        ..lineTo(x + g.w * 0.08, g.floorY)
        ..close();
      canvas.drawPath(
        ray,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Palette.card.withValues(alpha: alpha),
              Palette.card.withValues(alpha: 0),
            ],
          ).createShader(shaft),
      );
    }
    canvas.restore();

    _seaweed(canvas, g.w * 0.07, 3);
    _seaweed(canvas, g.w * 0.93, 2);

    final sand = Path()..moveTo(0, g.h);
    for (var x = 0.0; x <= g.w + 12; x += 12) {
      sand.lineTo(x, g.floorY + math.sin(x / g.w * math.pi * 3) * g.h * 0.012);
    }
    sand
      ..lineTo(g.w + 12, g.h)
      ..close();
    final sandRect = Rect.fromLTRB(0, g.floorY - 6, g.w, g.h);
    canvas.drawPath(
      sand,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _sand,
        ).createShader(sandRect),
    );

    const spots = [
      (0.22, 1.0),
      (0.27, 0.6),
      (0.58, 1.2),
      (0.74, 0.7),
      (0.46, 0.5),
      (0.86, 1.0),
    ];
    for (final (i, (fx, r)) in spots.indexed) {
      final radius = g.h * 0.018 * r;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            g.w * fx,
            g.floorY + g.h * 0.06 + (i % 2) * g.h * 0.03,
          ),
          width: radius * 2.6,
          height: radius * 1.6,
        ),
        Paint()..color = _pebbles[i % _pebbles.length],
      );
    }
  }

  void _seaweed(Canvas canvas, double x, int strands) {
    final g = f.geo;
    final paint = Paint()
      ..color = _weed.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(5.0, g.w * 0.011);
    for (var j = 0; j < strands; j++) {
      final height = (g.floorY - g.surfaceY) * (0.38 + 0.12 * j);
      final sway = math.sin(f.time * 1.1 + j * 1.3 + x) * g.w * 0.02;
      final spread = (j - (strands - 1) / 2) * g.w * 0.018;
      final base = Offset(x + spread * 0.4, g.floorY + 6);
      canvas.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(
            base.dx + spread - sway * 0.5,
            base.dy - height * 0.5,
            base.dx + spread + sway,
            base.dy - height,
          ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(TankBackPainter old) => true;
}

/// In front of the items: a faint blue veil over everything under water (so
/// floaters read as half in, half out), the shining surface line, ripples,
/// droplets, bubbles, sand puffs, and the glass itself.
class TankFrontPainter extends CustomPainter {
  TankFrontPainter(this.f);
  final WaterFrame f;

  static const _puff = Color(0xFFD0AC78);

  @override
  void paint(Canvas canvas, Size size) {
    final g = f.geo;
    canvas.drawPath(
      f.waterPath(),
      Paint()..color = Palette.waterDeep.withValues(alpha: 0.16),
    );
    canvas.drawPath(
      f.surfaceLine(),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = Palette.card.withValues(alpha: 0.8),
    );

    final unit = (g.h / 400).clamp(0.8, 2.0);
    _ripples(canvas);
    _droplets(canvas, unit);
    _bubbles(canvas, unit);
    _sandPuffs(canvas, unit);

    // Glass: a soft reflection streak and a thick friendly rim.
    canvas.drawRRect(
      RRect.fromLTRBR(
        g.w * 0.025,
        g.h * 0.08,
        g.w * 0.025 + math.max(6.0, g.w * 0.012),
        g.h * 0.62,
        const Radius.circular(8),
      ),
      Paint()..color = Palette.card.withValues(alpha: 0.35),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(3),
        const Radius.circular(kTankRadius - 3),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = Palette.card.withValues(alpha: 0.9),
    );
  }

  void _ripples(Canvas canvas) {
    final g = f.geo;
    for (final s in f.splashes) {
      for (var k = 0; k < 3; k++) {
        final a = f.time - s.t0 - k * 0.22;
        if (a < 0 || a > 1.5) continue;
        final rx = g.w * (0.03 + a * 0.14) * (0.6 + 0.4 * s.strength);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(s.x * g.w, g.surfaceY),
            width: rx * 2,
            height: rx * 0.35,
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = Palette.card.withValues(
              alpha: (1 - a / 1.5) * 0.8 * s.strength.clamp(0.5, 1.0),
            ),
        );
      }
    }
  }

  void _droplets(Canvas canvas, double unit) {
    final g = f.geo;
    final drop = Color.lerp(Palette.water, Palette.card, 0.45)!;
    for (final s in f.splashes) {
      final a = f.time - s.t0;
      if (a < 0 || a > 0.9) continue;
      for (var k = 0; k < 9; k++) {
        final vx = (k - 4) / 4 * g.w * 0.09 * s.strength;
        final vy = -g.h * (0.7 + (k % 3) * 0.15) * s.strength;
        final p = Offset(
          s.x * g.w + vx * a,
          g.surfaceY + vy * a + 1.2 * g.h * a * a,
        );
        if (p.dy > g.surfaceY + 2) continue;
        canvas.drawCircle(
          p,
          (3.5 + (k % 2) * 1.5) * unit,
          Paint()..color = drop.withValues(alpha: 1 - a / 0.9),
        );
      }
    }
  }

  void _bubbles(Canvas canvas, double unit) {
    final g = f.geo;
    final s = g.itemSize;
    final fill = Paint()..color = Palette.card.withValues(alpha: 0.3);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Palette.card.withValues(alpha: 0.85);
    final shine = Paint()..color = Palette.card.withValues(alpha: 0.9);
    final rise =
        (g.floorY - g.surfaceY) / 1.6; // px per second for trail bubbles

    void bubble(
      Offset from,
      double age,
      double r,
      double speed,
      double wobble,
    ) {
      if (age < 0) return;
      final y = from.dy - speed * age;
      final x = from.dx + math.sin(age * 5 + wobble) * r * 1.2;
      if (y < f.surfaceAt(x) + r) return; // reached the top: popped
      final c = Offset(x, y);
      canvas.drawCircle(c, r, fill);
      canvas.drawCircle(c, r, ring);
      canvas.drawCircle(c - Offset(r * 0.35, r * 0.35), r * 0.25, shine);
    }

    // Ambient: two lazy streams from the sand, always there.
    for (var i = 0; i < 8; i++) {
      final period = 3.2 + (i % 3) * 0.9;
      final age = (f.time + i * 1.37) % period;
      final x = g.w * (i.isEven ? 0.14 : 0.83) + (i % 4) * 6;
      bubble(
        Offset(x, g.floorY),
        age,
        (2.5 + (i % 3) * 1.5) * unit,
        (g.floorY - g.surfaceY) / period,
        i.toDouble(),
      );
    }

    for (final d in f.drops) {
      final a = f.time - d.t0;
      if (d.floats) {
        // A quick fizz where it went in.
        if (a < 2) {
          final from = Offset(g.laneX(d.lane), g.h / 2);
          for (var k = 0; k < 8; k++) {
            final off = Offset(
              ((k * 37) % 13 - 6) / 6 * s * 0.3,
              ((k * 17) % 7) / 7 * s * 0.3,
            );
            bubble(
              from + off,
              a - k * 0.03,
              (3 + k % 3 * 1.6) * unit,
              rise * 1.6,
              k.toDouble(),
            );
          }
        }
      } else {
        // A trail rising from it all the way down.
        for (var k = 0; k < 14; k++) {
          final born = k * 0.13;
          if (born > Drop.sinkIn || a < born) continue;
          final (c, _) = f.pose(d, d.t0 + born);
          final off = Offset(((k * 37) % 11 - 5) * s * 0.03, -s * 0.3);
          bubble(
            c + off,
            a - born,
            (2.5 + k % 3 * 1.8) * unit,
            rise,
            k.toDouble(),
          );
        }
      }
      final poke = f.time - d.pokedAt;
      if (poke >= 0 && poke < 3) {
        final (c, _) = f.pose(d, d.pokedAt);
        for (var k = 0; k < 5; k++) {
          bubble(
            c + Offset((k - 2) * s * 0.12, -s * 0.2),
            poke - k * 0.06,
            (3 + k % 2 * 2) * unit,
            rise,
            k.toDouble(),
          );
        }
      }
    }

    for (final b in f.bursts) {
      final age = f.time - b.t0;
      if (age > 3) continue;
      final from = Offset(b.at.dx * g.w, b.at.dy * g.h);
      for (var k = 0; k < 6; k++) {
        bubble(
          from + Offset((k - 2.5) * 7 * unit, 0),
          age - k * 0.05,
          (3 + k % 3 * 1.5) * unit,
          rise,
          k.toDouble(),
        );
      }
    }
  }

  /// Soft puffs of sand when a sinker lands.
  void _sandPuffs(Canvas canvas, double unit) {
    final g = f.geo;
    final s = g.itemSize;
    for (final d in f.drops) {
      if (d.floats) continue;
      final b = f.time - d.t0 - Drop.sinkIn;
      if (b < 0 || b > 0.8) continue;
      final t = b / 0.8;
      final x = g.laneX(d.slot);
      for (var k = 0; k < 6; k++) {
        final dir = k.isEven ? -1 : 1;
        final dist =
            (0.4 + (k % 3) * 0.3) * s * 0.6 * Curves.easeOut.transform(t);
        final lift = math.sin(t * math.pi) * s * 0.12 * ((k % 3) + 1) / 3;
        canvas.drawCircle(
          Offset(x + dir * dist, g.floorY - lift),
          (3 + (k % 3) * 1.5) * unit,
          Paint()..color = _puff.withValues(alpha: (1 - t) * 0.8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(TankFrontPainter old) => true;
}
