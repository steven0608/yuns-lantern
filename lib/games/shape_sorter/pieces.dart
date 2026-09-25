import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/tokens.dart';

/// [shape] fitted into [r], centred, in its natural proportions and already
/// the right way up — a 3-year-old should never have to rotate a piece.
Path shapePath(String shape, Rect r) {
  final c = r.center;
  final s = r.shortestSide;
  switch (shape) {
    case 'square':
      final d = s * 0.84;
      return Path()
        ..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: d, height: d), Radius.circular(d * 0.12)));
    case 'rectangle':
      final rw = s, rh = s * 0.56;
      return Path()
        ..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: rw, height: rh), Radius.circular(rh * 0.18)));
    case 'triangle':
      final tw = s, th = s * 0.88;
      return _roundedPolygon([
        Offset(c.dx, c.dy - th / 2),
        Offset(c.dx + tw / 2, c.dy + th / 2),
        Offset(c.dx - tw / 2, c.dy + th / 2),
      ], s * 0.08);
    case 'semicircle':
      final radius = s / 2;
      final baseY = c.dy + radius / 2;
      return Path()
        ..moveTo(c.dx - radius, baseY)
        ..arcTo(Rect.fromCircle(center: Offset(c.dx, baseY), radius: radius), math.pi, math.pi, false)
        ..close();
    default: // circle (and anything unexpected)
      return Path()..addOval(Rect.fromCircle(center: c, radius: s * 0.48));
  }
}

Path _roundedPolygon(List<Offset> pts, double radius) {
  final path = Path();
  final n = pts.length;
  for (var i = 0; i < n; i++) {
    final prev = pts[(i - 1 + n) % n], cur = pts[i], next = pts[(i + 1) % n];
    final toPrev = prev - cur, toNext = next - cur;
    final rr = math.min(radius, math.min(toPrev.distance, toNext.distance) / 2);
    final a = cur + toPrev / toPrev.distance * rr;
    final b = cur + toNext / toNext.distance * rr;
    i == 0 ? path.moveTo(a.dx, a.dy) : path.lineTo(a.dx, a.dy);
    path.quadraticBezierTo(cur.dx, cur.dy, b.dx, b.dy);
  }
  return path..close();
}

/// A chunky toy shape: coloured face, a darker edge underneath for
/// thickness, a soft shadow and a little shine.
class PiecePainter extends CustomPainter {
  PiecePainter(this.shape, this.color, {this.shadow = true});
  final String shape;
  final Color color;
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final depth = s * 0.05;
    final face = shapePath(shape, Rect.fromLTWH(0, 0, size.width, size.height - depth).deflate(s * 0.03));
    if (shadow) {
      canvas.drawPath(
        face.shift(Offset(0, depth * 1.8)),
        Paint()
          ..color = Palette.shadow
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.035),
      );
    }
    canvas.drawPath(face.shift(Offset(0, depth)), Paint()..color = Color.lerp(color, Palette.ink, 0.22)!);
    canvas.drawPath(face, Paint()..color = color);
    // Shine near the top-left of the face.
    canvas.save();
    canvas.clipPath(face);
    final b = face.getBounds();
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(b.left + b.width * 0.3, b.top + b.height * 0.26),
        width: b.width * 0.24,
        height: b.height * 0.16,
      ),
      Paint()..color = Palette.card.withValues(alpha: 0.4),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(PiecePainter old) => old.shape != shape || old.color != color || old.shadow != shadow;
}

/// A shape-shaped hole cut into the board: darker inside, shaded at the top
/// edge for depth, with a light lip along the bottom.
class HolePainter extends CustomPainter {
  HolePainter(this.shape, this.board);
  final String shape;
  final Color board;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final hole = shapePath(shape, (Offset.zero & size).deflate(s * 0.04));
    canvas.drawPath(hole.shift(Offset(0, s * 0.025)), Paint()..color = Color.lerp(board, Palette.card, 0.45)!);
    final inside = Color.lerp(board, Palette.ink, 0.5)!;
    canvas.drawPath(hole, Paint()..color = Color.lerp(inside, Palette.ink, 0.25)!);
    canvas.save();
    canvas.clipPath(hole);
    canvas.drawPath(hole.shift(Offset(0, s * 0.07)), Paint()..color = inside);
    canvas.restore();
  }

  @override
  bool shouldRepaint(HolePainter old) => old.shape != shape || old.board != board;
}

/// The sorter lid: a rounded plank with a thicker front edge and four
/// little pegs in the corners, like a wooden toy.
class BoardPainter extends CustomPainter {
  BoardPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final lip = h * 0.07;
    final r = Radius.circular(math.min(w, h) * 0.16);
    final top = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h - lip), r);
    canvas.drawRRect(
      top.shift(Offset(0, lip + 6)),
      Paint()
        ..color = Palette.shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawRRect(top.shift(Offset(0, lip)), Paint()..color = Color.lerp(color, Palette.ink, 0.2)!);
    canvas.drawRRect(top, Paint()..color = color);
    // Soft grain lines.
    canvas.save();
    canvas.clipRRect(top);
    final grain = Paint()
      ..color = Color.lerp(color, Palette.ink, 0.07)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, h * 0.012)
      ..strokeCap = StrokeCap.round;
    for (var k = 1; k <= 3; k++) {
      final y = (h - lip) * k / 4;
      final path = Path()..moveTo(w * 0.04, y);
      for (var x = 0.04; x <= 0.96; x += 0.08) {
        path.lineTo(w * x, y + math.sin(x * 20 + k) * h * 0.012);
      }
      canvas.drawPath(path, grain);
    }
    canvas.restore();
    final peg = Paint()..color = Color.lerp(color, Palette.ink, 0.28)!;
    final shine = Paint()..color = Palette.card.withValues(alpha: 0.5);
    final pr = math.max(4.0, math.min(w, h) * 0.035);
    for (final p in [
      Offset(pr * 2.6, pr * 2.6),
      Offset(w - pr * 2.6, pr * 2.6),
      Offset(pr * 2.6, h - lip - pr * 2.6),
      Offset(w - pr * 2.6, h - lip - pr * 2.6),
    ]) {
      canvas.drawCircle(p, pr, peg);
      canvas.drawCircle(p - Offset(pr * 0.3, pr * 0.3), pr * 0.35, shine);
    }
  }

  @override
  bool shouldRepaint(BoardPainter old) => old.color != color;
}
