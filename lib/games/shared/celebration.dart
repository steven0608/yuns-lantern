import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/tokens.dart';
import '../../core/ui/yun.dart';

/// ~1.8s of joy after a round (SPEC §7.6): a burst of warm stars and lantern
/// sparks with Yun hopping up. No score, no stars-out-of-three, nothing to
/// compare — every completion is celebrated the same.
class Celebration extends StatefulWidget {
  const Celebration({super.key, this.onDone, this.lightColor});
  final VoidCallback? onDone;
  final Color? lightColor;

  @override
  State<Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<Celebration> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: kCelebrationLength)
    ..forward().whenComplete(() => widget.onDone?.call());
  late final List<_Spark> _sparks;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    final colors = Palette.named.values.where((c) => c != Palette.named['black']).toList();
    _sparks = List.generate(46, (i) {
      final angle = rng.nextDouble() * math.pi * 2;
      return _Spark(
        dir: Offset(math.cos(angle), math.sin(angle) - 0.35),
        speed: 0.35 + rng.nextDouble() * 0.55,
        color: colors[i % colors.length],
        size: 10 + rng.nextDouble() * 16,
        spin: rng.nextDouble() * 6 - 3,
        star: i.isEven,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final t = _c.value;
          final rise = Curves.elasticOut.transform((t / 0.55).clamp(0.0, 1.0));
          return Stack(fit: StackFit.expand, children: [
            CustomPaint(painter: _BurstPainter(_sparks, t)),
            Align(
              alignment: Alignment(0, 1.4 - 1.25 * rise),
              child: Opacity(
                opacity: t > 0.85 ? (1 - t) / 0.15 : 1,
                child: Yun(size: 180, mood: YunMood.happy, lanternColor: widget.lightColor),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class _Spark {
  _Spark({required this.dir, required this.speed, required this.color, required this.size, required this.spin, required this.star});
  final Offset dir;
  final double speed, size, spin;
  final Color color;
  final bool star;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.sparks, this.t);
  final List<_Spark> sparks;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.55);
    final reach = size.shortestSide * 0.75;
    final ease = Curves.easeOutCubic.transform(t);
    for (final s in sparks) {
      final gravity = Offset(0, 0.45 * t * t) * reach;
      final p = origin + s.dir * (reach * s.speed * ease) + gravity;
      final fade = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
      final paint = Paint()..color = s.color.withValues(alpha: fade.clamp(0, 1));
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(s.spin * t);
      if (s.star) {
        canvas.drawPath(_star(s.size), paint);
      } else {
        canvas.drawCircle(Offset.zero, s.size * 0.4, paint);
      }
      canvas.restore();
    }
  }

  Path _star(double r) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = Offset(math.cos(a) * rad, math.sin(a) * rad);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  @override
  bool shouldRepaint(_BurstPainter o) => o.t != t;
}

/// Small sparkle where a child taps empty space — every touch responds (§7.5).
class TapSparkle extends StatefulWidget {
  const TapSparkle({super.key, required this.at, required this.onDone});
  final Offset at;
  final VoidCallback onDone;

  @override
  State<TapSparkle> createState() => _TapSparkleState();
}

class _TapSparkleState extends State<TapSparkle> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
    ..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.at.dx - 40,
      top: widget.at.dy - 40,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(size: const Size(80, 80), painter: _SparklePainter(_c.value)),
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()..color = Palette.lantern.withValues(alpha: (1 - t) * 0.9);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      final p = c + Offset(math.cos(a), math.sin(a)) * (10 + 26 * Curves.easeOut.transform(t));
      canvas.drawCircle(p, 5 * (1 - t) + 1, paint);
    }
    canvas.drawCircle(c, 14 * (1 - t), Paint()..color = Palette.cream.withValues(alpha: 1 - t));
  }

  @override
  bool shouldRepaint(_SparklePainter o) => o.t != t;
}
