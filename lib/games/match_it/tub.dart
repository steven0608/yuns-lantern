import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/art/item_art.dart';
import '../../core/tokens.dart';

/// Height ÷ width of a tub's box (the pile peeks out of the top part).
const double kTubAspect = 0.95;

/// Honey wicker for tubs that don't sort by colour. All three are the same,
/// so colour never hints at an answer the round isn't about.
final Color kWicker = Color.lerp(Palette.lantern, Palette.paperDeep, 0.42)!;

// Tub proportions, as fractions of the box height.
const double _rimTop = 0.30;
const double _rimH = 0.13;

/// A soft toy tub (the Match It tile, drawn flat and warm): a rounded rim,
/// a tapering body and a round badge on the front that says — in a picture —
/// what the tub collects. Sorted things sit in a little pile peeking over the
/// rim. A tap wiggles it (and the game names it); every new arrival squashes
/// it with a happy bounce.
class Tub extends StatefulWidget {
  const Tub({
    super.key,
    required this.width,
    required this.color,
    required this.woven,
    required this.badge,
    required this.pile,
    required this.capacity,
    required this.onTap,
    this.scale = 1,
  });

  final double width;
  final Color color;

  /// Draw a basket weave (tubs that don't sort by colour).
  final bool woven;
  final Widget badge;

  /// Vocab ids already sorted into this tub, oldest first.
  final List<String> pile;

  /// How many things will end up here: spaces the pile.
  final int capacity;
  final VoidCallback onTap;

  /// Visual scale (size rounds draw small → big tubs).
  final double scale;

  @override
  State<Tub> createState() => _TubState();
}

class _TubState extends State<Tub> with TickerProviderStateMixin {
  late final AnimationController _squash =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
  late final AnimationController _wiggle =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 480));

  @override
  void didUpdateWidget(Tub old) {
    super.didUpdateWidget(old);
    if (widget.pile.length > old.pile.length) _squash.forward(from: 0);
  }

  @override
  void dispose() {
    _squash.dispose();
    _wiggle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width, h = w * kTubAspect;
    final rimTop = h * _rimTop, rimH = h * _rimH;
    final cap = math.max(widget.capacity, widget.pile.length);
    final pileS = w * (cap <= 2 ? 0.34 : 0.26);
    final badgeD = math.min(w * 0.38, (h - rimTop - rimH) * 0.74);
    final badgeCY = (rimTop + rimH + h) / 2 - h * 0.02;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        _wiggle.forward(from: 0);
        widget.onTap();
      },
      child: SizedBox(
        width: w,
        height: h,
        child: AnimatedBuilder(
          animation: Listenable.merge([_squash, _wiggle]),
          builder: (_, child) {
            final s = _squash.value;
            final sq = s == 0 ? 0.0 : math.sin(s * math.pi * 2.5) * (1 - s);
            final wv = _wiggle.value;
            final wig = math.sin(wv * math.pi * 4) * 0.06 * (1 - wv);
            return Transform.rotate(
              angle: wig,
              alignment: Alignment.bottomCenter,
              child: Transform.scale(
                scaleX: widget.scale * (1 + 0.07 * sq),
                scaleY: widget.scale * (1 - 0.09 * sq),
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            );
          },
          child: Stack(clipBehavior: Clip.none, children: [
            // The pile sits behind the rim, so things look like they're in it.
            for (final (k, id) in widget.pile.indexed)
              Positioned(
                key: ValueKey('pile$k$id'),
                left: w / 2 + (k - (cap - 1) / 2) * pileS * 0.95 - pileS * 0.575,
                top: rimTop + rimH * 0.9 - pileS * 1.15,
                child: _DropIn(
                  distance: pileS * 0.9,
                  tilt: (k.isEven ? -1 : 1) * 0.14,
                  child: ItemArt(id, size: pileS),
                ),
              ),
            Positioned.fill(child: CustomPaint(painter: TubPainter(widget.color, woven: widget.woven))),
            Positioned(
              left: (w - badgeD) / 2,
              top: badgeCY - badgeD / 2,
              width: badgeD,
              height: badgeD,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Palette.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: Palette.paper, width: 3),
                  boxShadow: const [BoxShadow(color: Palette.shadow, blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Padding(padding: EdgeInsets.all(badgeD * 0.14), child: widget.badge),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// A sorted thing drops into the pile with a little bounce.
class _DropIn extends StatelessWidget {
  const _DropIn({required this.distance, required this.tilt, required this.child});
  final double distance, tilt;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      builder: (_, t, child) {
        final fall = Curves.bounceOut.transform(t);
        return Transform.translate(
          offset: Offset(0, -(1 - fall) * distance),
          child: Transform.rotate(angle: tilt * fall, child: child),
        );
      },
      child: child,
    );
  }
}

class TubPainter extends CustomPainter {
  TubPainter(this.color, {required this.woven});
  final Color color;
  final bool woven;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rimTop = h * _rimTop, rimH = h * _rimH;
    final bodyTop = rimTop + rimH * 0.5, bottom = h * 0.97;
    final light = color.computeLuminance() > 0.7;
    final outline = Paint()
      ..color = Palette.inkSoft.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, w * 0.01);

    // Soft shadow where it stands.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, bottom), width: w * 0.8, height: h * 0.07),
      Paint()
        ..color = Palette.shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final body = roundedPolygon([
      Offset(w * 0.07, bodyTop),
      Offset(w * 0.93, bodyTop),
      Offset(w * 0.84, bottom),
      Offset(w * 0.16, bottom),
    ], w * 0.09);
    canvas.drawPath(body, Paint()..color = color);
    canvas.save();
    canvas.clipPath(body);
    if (woven) {
      final band = Paint()
        ..color = Color.lerp(color, Palette.ink, 0.13)!
        ..strokeWidth = h * 0.014
        ..strokeCap = StrokeCap.round;
      for (var k = 1; k <= 3; k++) {
        final y = bodyTop + (bottom - bodyTop) * k / 4;
        canvas.drawLine(Offset(0, y), Offset(w, y), band);
      }
    }
    // A soft highlight down the left side.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.19, bodyTop + rimH * 0.7, w * 0.07, (bottom - bodyTop) * 0.55),
        Radius.circular(w * 0.04),
      ),
      Paint()..color = Palette.card.withValues(alpha: 0.24),
    );
    canvas.restore();
    if (light) canvas.drawPath(body, outline);

    final rim = RRect.fromRectAndRadius(Rect.fromLTWH(0, rimTop, w, rimH), Radius.circular(rimH / 2));
    canvas.drawRRect(rim, Paint()..color = Color.lerp(color, Palette.ink, 0.18)!);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rimH * 0.6, rimTop + rimH * 0.2, w * 0.32, rimH * 0.22),
        Radius.circular(rimH * 0.11),
      ),
      Paint()..color = Palette.card.withValues(alpha: 0.28),
    );
    if (light) canvas.drawRRect(rim, outline);
  }

  @override
  bool shouldRepaint(TubPainter old) => old.color != color || old.woven != woven;
}

/// A splash of paint: the badge for a colour tub.
class BlobPainter extends CustomPainter {
  BlobPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.38;
    final blob = Path();
    const steps = 60;
    for (var k = 0; k <= steps; k++) {
      final a = k / steps * 2 * math.pi;
      final rr = r * (1 + 0.07 * math.sin(3 * a + 0.6) + 0.045 * math.cos(5 * a));
      final p = c + Offset(math.cos(a), math.sin(a)) * rr;
      k == 0 ? blob.moveTo(p.dx, p.dy) : blob.lineTo(p.dx, p.dy);
    }
    blob.close();
    final fill = Paint()..color = color;
    canvas.drawPath(blob, fill);
    // Two little droplets make it read as paint, not a ball.
    final drops = [c + Offset(r * 1.12, r * 0.62), c + Offset(-r * 1.02, r * 0.84)];
    canvas.drawCircle(drops[0], r * 0.16, fill);
    canvas.drawCircle(drops[1], r * 0.11, fill);
    if (color.computeLuminance() > 0.7) {
      final line = Paint()
        ..color = Palette.inkSoft.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.0, r * 0.07);
      canvas.drawPath(blob, line);
      canvas.drawCircle(drops[0], r * 0.16, line);
      canvas.drawCircle(drops[1], r * 0.11, line);
    }
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(-r * 0.34, -r * 0.4), width: r * 0.42, height: r * 0.26),
      Paint()..color = Palette.card.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(BlobPainter old) => old.color != color;
}

/// Draws one of the content's shapes (circle, square, triangle, rectangle,
/// semicircle), already the right way up.
class ShapeGlyphPainter extends CustomPainter {
  ShapeGlyphPainter(this.shape, {required this.fill, this.stroke, this.strokeWidth = 3});
  final String shape;
  final Color fill;
  final Color? stroke;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = shapePath(shape, (Offset.zero & size).deflate(strokeWidth));
    canvas.drawPath(path, Paint()..color = fill);
    if (stroke != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = stroke!
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(ShapeGlyphPainter old) =>
      old.shape != shape || old.fill != fill || old.stroke != stroke || old.strokeWidth != strokeWidth;
}

/// The badge for a size tub: nested squares small → big, with this tub's
/// size filled in.
class NestedSquaresPainter extends CustomPainter {
  NestedSquaresPainter({required this.rank, required this.count});
  final int rank, count;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide * 0.86;
    final base = size.height / 2 + s / 2;
    final cx = size.width / 2;
    RRect square(int j) {
      final side = s * (count <= 1 ? 1 : 0.36 + 0.64 * j / (count - 1));
      return RRect.fromRectAndRadius(Rect.fromLTWH(cx - side / 2, base - side, side, side), Radius.circular(side * 0.16));
    }

    canvas.drawRRect(square(rank), Paint()..color = Palette.lantern);
    final line = Paint()
      ..color = Palette.inkSoft.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.5, s * 0.04);
    for (var j = 0; j < math.max(1, count); j++) {
      canvas.drawRRect(square(j), line);
    }
  }

  @override
  bool shouldRepaint(NestedSquaresPainter old) => old.rank != rank || old.count != count;
}

/// [shape] fitted into [r], centred, in its natural proportions.
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
      return roundedPolygon([
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

/// A polygon with softly rounded corners — nothing in this app is sharp.
Path roundedPolygon(List<Offset> pts, double radius) {
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
