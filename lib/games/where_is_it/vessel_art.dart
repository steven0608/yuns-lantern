import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Placeholder container art for Where Is It?, painted in two layers (back
/// wall + opening, then front wall) so the actor can sit *between* them.
/// That is the only way "inside" reads as inside for a 3-year-old — the front
/// wall hides the actor's legs — instead of looking like "behind".
///
/// Keyed by the round's `container` id purely as art, like ItemArt's emoji
/// map; unknown ids fall back to the box so new content still renders.
enum VesselLayer { back, front }

enum _Style { box, basket, cup, bowl }

class Vessel {
  const Vessel._(this._style, this.width, this.height);

  final _Style _style;

  /// Size as a fraction of the scene's side.
  final double width, height;

  static Vessel of(String id) => switch (id) {
    'basket' => const Vessel._(_Style.basket, 0.42, 0.28),
    'cup' => const Vessel._(_Style.cup, 0.32, 0.32),
    'bowl' => const Vessel._(_Style.bowl, 0.50, 0.24),
    _ => const Vessel._(_Style.box, 0.40, 0.30),
  };

  /// Depth of the opening seen from slightly above, in px for a vessel [w] wide.
  double _rim(double w, double h) => switch (_style) {
    _Style.box => h * 0.26,
    _Style.bowl => w * 0.28,
    _ => w * 0.24,
  };

  /// Y (px from the vessel's top) of the middle of the opening: where an
  /// actor that is *inside* is sunk to.
  double openingY(double w, double h) => _rim(w, h) / 2;

  /// How far below the front rim an actor that is inside reaches, as a
  /// fraction of its size. Shallow bowls hide less, so faces stay visible.
  double get insideSink => _style == _Style.bowl ? 0.16 : 0.3;

  /// Y of the surface an actor sits on when the vessel is closed/upturned.
  double topSurfaceY(double w, double h) => switch (_style) {
    _Style.box || _Style.basket => _rim(w, h) / 2,
    _ => h * 0.04,
  };

  CustomPainter painter(VesselLayer layer, {required bool closed}) =>
      _VesselPainter(_style, layer, closed, _rim);
}

// Warm, medium-saturation placeholder colours (no pure white, SPEC §6).
// Matched to the design canvas (flat fills, soft browns, barely-there lines).
const _cardboard = Color(0xFFAA764B);
const _cardboardLight = Color(0xFFC0915F);
const _cardboardDark = Color(0xFF946340);
const _cardboardInside = Color(0xFF6E4A30);
const _tape = Color(0xFFC89C6C);
const _wicker = Color(0xFFCC9C5F);
const _wickerDark = Color(0xFFB27C44);
const _wickerInside = Color(0xFF7E5530);
// A touch deeper than the wall so the cup never fades into the room.
const _porcelain = Color(0xFFEFE2CB);
const _porcelainShade = Color(0xFFCDB894);
const _cupBand = Color(0xFF6FA6D6);
const _bowlBlue = Color(0xFF7FB7D1);
const _bowlBlueDark = Color(0xFF5E97B5);
const _bowlInside = Color(0xFFEDE4D3);
const _outline = Color(0x264A3426);

class _VesselPainter extends CustomPainter {
  _VesselPainter(this.style, this.layer, this.closed, this.rimOf);
  final _Style style;
  final VesselLayer layer;
  final bool closed;
  final double Function(double w, double h) rimOf;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, r = rimOf(w, h);
    switch (style) {
      case _Style.box:
        _box(canvas, w, h, r);
      case _Style.basket:
        _basket(canvas, w, h, r);
      case _Style.cup:
      case _Style.bowl:
        closed ? _upturned(canvas, w, h) : _openDish(canvas, w, h, r);
    }
  }

  Paint _fill(Color c) => Paint()..color = c;
  Paint _stroke(Color c, double width) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // ── Box ────────────────────────────────────────────────────────────────
  void _box(Canvas canvas, double w, double h, double d) {
    final top = Path()
      ..moveTo(w * 0.12, 0)
      ..lineTo(w * 0.88, 0)
      ..lineTo(w, d)
      ..lineTo(0, d)
      ..close();
    if (layer == VesselLayer.back) {
      if (closed) {
        // Flaps folded shut: a flat lid to sit on.
        canvas.drawPath(top, _fill(_cardboardLight));
        canvas.drawLine(
          Offset(w * 0.5, 0),
          Offset(w * 0.5, d),
          _stroke(_cardboardDark, w * 0.012),
        );
        canvas.drawPath(top, _stroke(_outline, w * 0.012));
        return;
      }
      // Open: back flap up, side flaps splayed out, dark inside.
      final back = Path()
        ..moveTo(w * 0.12, 0)
        ..lineTo(w * 0.88, 0)
        ..lineTo(w * 0.84, -d * 0.7)
        ..lineTo(w * 0.16, -d * 0.7)
        ..close();
      final left = Path()
        ..moveTo(0, d)
        ..lineTo(w * 0.12, 0)
        ..lineTo(-w * 0.04, -d * 0.55)
        ..lineTo(-w * 0.17, d * 0.35)
        ..close();
      final right = Path()
        ..moveTo(w, d)
        ..lineTo(w * 0.88, 0)
        ..lineTo(w * 1.04, -d * 0.55)
        ..lineTo(w * 1.17, d * 0.35)
        ..close();
      for (final f in [back, left, right]) {
        canvas.drawPath(f, _fill(f == back ? _cardboardDark : _cardboardLight));
        canvas.drawPath(f, _stroke(_outline, w * 0.012));
      }
      canvas.drawPath(top, _fill(_cardboardInside));
      return;
    }
    final face = RRect.fromLTRBAndCorners(
      0,
      d,
      w,
      h,
      bottomLeft: Radius.circular(w * 0.04),
      bottomRight: Radius.circular(w * 0.04),
    );
    canvas.drawRRect(
      face,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_cardboard, _cardboardDark],
        ).createShader(face.outerRect),
    );
    canvas.drawRect(
      Rect.fromLTRB(w * 0.43, d, w * 0.57, d + (h - d) * 0.34),
      _fill(_tape.withValues(alpha: 0.8)),
    );
    canvas.drawLine(
      Offset(0, d),
      Offset(w, d),
      _stroke(_cardboardLight, w * 0.025),
    );
    canvas.drawRRect(face, _stroke(_outline, w * 0.012));
  }

  // ── Basket ─────────────────────────────────────────────────────────────
  Path _basketBody(double w, double h, double e) => Path()
    ..moveTo(0, e / 2)
    ..lineTo(w * 0.09, h - w * 0.05)
    ..quadraticBezierTo(w * 0.1, h, w * 0.17, h)
    ..lineTo(w * 0.83, h)
    ..quadraticBezierTo(w * 0.9, h, w * 0.91, h - w * 0.05)
    ..lineTo(w, e / 2)
    ..arcTo(Rect.fromLTWH(0, 0, w, e), 0, math.pi, false)
    ..close();

  void _basket(Canvas canvas, double w, double h, double e) {
    final rim = Rect.fromLTWH(0, 0, w, e);
    if (layer == VesselLayer.back) {
      if (closed) {
        canvas.drawOval(rim, _fill(_wicker));
        canvas.drawOval(rim.deflate(w * 0.06), _stroke(_wickerDark, w * 0.012));
        canvas.drawOval(rim, _stroke(_outline, w * 0.012));
        return;
      }
      // Handle arcs up behind whatever sits in the basket.
      canvas.drawArc(
        Rect.fromLTRB(w * 0.1, -h * 0.75, w * 0.9, e * 0.9),
        math.pi,
        math.pi,
        false,
        _stroke(_wickerDark, w * 0.06),
      );
      canvas.drawOval(rim, _fill(_wickerInside));
      canvas.drawArc(rim, math.pi, math.pi, false, _stroke(_wicker, w * 0.04));
      return;
    }
    final body = _basketBody(w, h, e);
    canvas.drawPath(body, _fill(_wicker));
    canvas.save();
    canvas.clipPath(body);
    // Woven bands.
    final weave = _stroke(_wickerDark.withValues(alpha: 0.55), w * 0.012);
    for (var y = e + (h - e) * 0.2; y < h; y += (h - e) * 0.2) {
      canvas.drawLine(Offset(0, y), Offset(w, y), weave);
    }
    for (var x = w * 0.08; x < w; x += w * 0.1) {
      canvas.drawLine(Offset(x, e / 2), Offset(x + w * 0.02, h), weave);
    }
    canvas.restore();
    canvas.drawArc(rim, 0, math.pi, false, _stroke(_wickerDark, w * 0.045));
    canvas.drawPath(body, _stroke(_outline, w * 0.012));
  }

  // ── Cup and bowl ───────────────────────────────────────────────────────
  Path _dishBody(double w, double h, double e) {
    final p = Path()..moveTo(0, e / 2);
    if (style == _Style.cup) {
      p
        ..lineTo(w * 0.06, h - w * 0.1)
        ..quadraticBezierTo(w * 0.08, h, w * 0.2, h)
        ..lineTo(w * 0.8, h)
        ..quadraticBezierTo(w * 0.92, h, w * 0.94, h - w * 0.1)
        ..lineTo(w, e / 2);
    } else {
      p
        ..cubicTo(0, h * 0.72, w * 0.22, h * 0.9, w * 0.36, h * 0.9)
        ..lineTo(w * 0.36, h)
        ..lineTo(w * 0.64, h)
        ..lineTo(w * 0.64, h * 0.9)
        ..cubicTo(w * 0.78, h * 0.9, w, h * 0.72, w, e / 2);
    }
    return p
      ..arcTo(Rect.fromLTWH(0, 0, w, e), 0, math.pi, false)
      ..close();
  }

  Color get _dish => style == _Style.cup ? _porcelain : _bowlBlue;
  Color get _dishDark => style == _Style.cup ? _porcelainShade : _bowlBlueDark;

  void _dishDecor(
    Canvas canvas,
    double w,
    double h,
    double top,
    double bottom,
  ) {
    if (style == _Style.cup) {
      final y = top + (bottom - top) * 0.45;
      canvas.drawRect(
        Rect.fromLTRB(0, y, w, y + (bottom - top) * 0.16),
        _fill(_cupBand),
      );
    } else {
      final dots = _fill(_bowlInside.withValues(alpha: 0.85));
      final y = top + (bottom - top) * 0.35;
      for (var i = 1; i < 6; i++) {
        canvas.drawCircle(Offset(w * i / 6, y), w * 0.025, dots);
      }
    }
  }

  void _cupHandle(Canvas canvas, double w, double h, {required bool flipped}) {
    if (style != _Style.cup) return;
    final cy = flipped ? h * 0.42 : h * 0.58;
    final ring = Rect.fromCenter(
      center: Offset(w * 0.95, cy),
      width: w * 0.42,
      height: h * 0.44,
    );
    canvas.drawArc(
      ring,
      -math.pi / 2,
      math.pi,
      false,
      _stroke(_porcelainShade, w * 0.09),
    );
    canvas.drawArc(
      ring,
      -math.pi / 2,
      math.pi,
      false,
      _stroke(_porcelain, w * 0.05),
    );
  }

  void _openDish(Canvas canvas, double w, double h, double e) {
    final rim = Rect.fromLTWH(0, 0, w, e);
    if (layer == VesselLayer.back) {
      canvas.drawOval(
        rim,
        _fill(style == _Style.cup ? const Color(0xFFB9A283) : _bowlInside),
      );
      canvas.drawOval(
        Rect.fromLTWH(w * 0.12, e * 0.3, w * 0.76, e * 0.7),
        _fill(
          (style == _Style.cup ? const Color(0xFF9C8568) : _porcelainShade)
              .withValues(alpha: 0.7),
        ),
      );
      canvas.drawArc(
        rim,
        math.pi,
        math.pi,
        false,
        _stroke(_dishDark, w * 0.03),
      );
      return;
    }
    _cupHandle(canvas, w, h, flipped: false);
    final body = _dishBody(w, h, e);
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_dish, _dishDark],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.save();
    canvas.clipPath(body);
    _dishDecor(canvas, w, h, e / 2, h);
    canvas.restore();
    canvas.drawArc(
      rim,
      0,
      math.pi,
      false,
      _stroke(Color.lerp(_dish, const Color(0xFFFFF8EC), 0.4)!, w * 0.035),
    );
    canvas.drawPath(body, _stroke(_outline, w * 0.012));
  }

  /// Cup/bowl turned upside down: a little stand with a flat top to sit on.
  void _upturned(Canvas canvas, double w, double h) {
    if (layer == VesselLayer.back) return;
    canvas.save();
    canvas.translate(0, h);
    canvas.scale(1, -1);
    final e = h * 0.14;
    _cupHandle(canvas, w, h, flipped: true);
    final body = _dishBody(w, h, e);
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [_dish, _dishDark],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.save();
    canvas.clipPath(body);
    _dishDecor(canvas, w, h, e / 2, h);
    canvas.restore();
    canvas.drawPath(body, _stroke(_outline, w * 0.012));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_VesselPainter o) =>
      o.style != style || o.layer != layer || o.closed != closed;
}

/// A small wooden table: the "up high" / "down low" reference.
class TablePainter extends CustomPainter {
  const TablePainter();

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final leg = Paint()..color = const Color(0xFFA36A3C);
    canvas.drawRRect(
      RRect.fromLTRBR(
        w * 0.06,
        h * 0.1,
        w * 0.13,
        h,
        Radius.circular(w * 0.02),
      ),
      leg,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
        w * 0.87,
        h * 0.1,
        w * 0.94,
        h,
        Radius.circular(w * 0.02),
      ),
      leg,
    );
    final top = RRect.fromLTRBR(0, 0, w, h * 0.13, Radius.circular(h * 0.05));
    canvas.drawRRect(top, Paint()..color = const Color(0xFFBF824F));
    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, w, h * 0.045, Radius.circular(h * 0.03)),
      Paint()..color = const Color(0xFFD69A64),
    );
  }

  @override
  bool shouldRepaint(TablePainter o) => false;
}

/// Warm little room: wall, skirting, floorboards. Floor depth lets
/// "behind" sit visibly further back than "in front".
class RoomPainter extends CustomPainter {
  const RoomPainter({required this.floorY});

  /// Where the wall meets the floor, as a fraction of height.
  final double floorY;

  @override
  void paint(Canvas canvas, Size s) {
    final y = s.height * floorY;
    final wall = Rect.fromLTWH(0, 0, s.width, y);
    canvas.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFBF1E1), Color(0xFFF3E3CA)],
        ).createShader(wall),
    );
    final floor = Rect.fromLTRB(0, y, s.width, s.height);
    canvas.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE2C49A), Color(0xFFD4B083)],
        ).createShader(floor),
    );
    canvas.drawRect(
      Rect.fromLTRB(0, y - s.height * 0.012, s.width, y + s.height * 0.008),
      Paint()..color = const Color(0xFFE9D3B0),
    );
    final board = Paint()
      ..color = const Color(0x22704C2A)
      ..strokeWidth = 1.5;
    for (var i = 1; i < 4; i++) {
      final fy = y + (s.height - y) * i / 4;
      canvas.drawLine(Offset(0, fy), Offset(s.width, fy), board);
    }
  }

  @override
  bool shouldRepaint(RoomPainter o) => o.floorY != floorY;
}
