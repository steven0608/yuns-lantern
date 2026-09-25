import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

enum YunMood { idle, happy, sleepy }

/// Yun the red panda (story.json hero). Placeholder vector drawing until the
/// Phase 4 illustration lands: rounded silhouette, kind eyes, paper lantern.
/// Never frightened, never scolds — there is no "sad" mood on purpose.
class Yun extends StatefulWidget {
  const Yun({
    super.key,
    this.size = 140,
    this.mood = YunMood.idle,
    this.lanternColor,
  });
  final double size;
  final YunMood mood;
  final Color? lanternColor;

  @override
  State<Yun> createState() => _YunState();
}

class _YunState extends State<Yun> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final t = _c.value * 2 * math.pi;
          final happy = widget.mood == YunMood.happy;
          final bob = happy
              ? -(math.sin(t * 2).abs()) * 0.10
              : math.sin(t) * 0.02;
          return Transform.translate(
            offset: Offset(0, bob * widget.size),
            child: CustomPaint(
              size: Size(widget.size, widget.size * 1.1),
              painter: _YunPainter(
                mood: widget.mood,
                blink: widget.mood != YunMood.sleepy && _c.value > 0.93,
                sway: math.sin(t) * 0.08,
                lantern: widget.lanternColor ?? Palette.lantern,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _YunPainter extends CustomPainter {
  _YunPainter({
    required this.mood,
    required this.blink,
    required this.sway,
    required this.lantern,
  });
  final YunMood mood;
  final bool blink;
  final double sway;
  final Color lantern;

  static const fur = Color(0xFFC65F32);
  static const furDark = Color(0xFF7A3419);
  static const cream = Color(0xFFFFEBD1);
  static const eye = Color(0xFF3A2418);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final p = Paint()..isAntiAlias = true;

    // tail, striped
    final tail = Path()
      ..moveTo(w * 0.62, w * 0.92)
      ..quadraticBezierTo(w * 1.02, w * 0.95, w * 0.92, w * 0.62)
      ..quadraticBezierTo(w * 0.88, w * 0.82, w * 0.60, w * 0.82)
      ..close();
    canvas.drawPath(tail, p..color = fur);
    p.color = furDark;
    canvas.drawCircle(Offset(w * 0.90, w * 0.75), w * 0.04, p);
    canvas.drawCircle(Offset(w * 0.80, w * 0.88), w * 0.04, p);

    // body
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, w * 0.86),
        width: w * 0.56,
        height: w * 0.42,
      ),
      p..color = fur,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, w * 0.90),
        width: w * 0.30,
        height: w * 0.26,
      ),
      p..color = const Color(0xFF8C3E1E),
    );
    // feet
    p.color = furDark;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.38, w * 1.05),
        width: w * 0.16,
        height: w * 0.09,
      ),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.62, w * 1.05),
        width: w * 0.16,
        height: w * 0.09,
      ),
      p,
    );

    // lantern on a stick, swaying
    canvas.save();
    canvas.translate(w * 0.20, w * 0.62);
    canvas.rotate(sway);
    final stick = Paint()
      ..color = const Color(0xFF6B4A2B)
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(-w * 0.10, -w * 0.22), stick);
    canvas.drawLine(
      Offset(-w * 0.10, -w * 0.22),
      Offset(-w * 0.10, -w * 0.12),
      stick..strokeWidth = w * 0.01,
    );
    final lr = Rect.fromCenter(
      center: Offset(-w * 0.10, -w * 0.02),
      width: w * 0.17,
      height: w * 0.2,
    );
    canvas.drawOval(
      lr.inflate(w * 0.05),
      Paint()..color = lantern.withValues(alpha: 0.25),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lr, Radius.circular(w * 0.07)),
      Paint()..color = lantern,
    );
    final rib = Paint()
      ..color = const Color(0x55000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.008;
    canvas.drawLine(lr.topCenter, lr.bottomCenter, rib);
    canvas.drawRect(
      Rect.fromCenter(center: lr.topCenter, width: w * 0.1, height: w * 0.025),
      Paint()..color = const Color(0xFF6B4A2B),
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: lr.bottomCenter,
        width: w * 0.1,
        height: w * 0.025,
      ),
      Paint()..color = const Color(0xFF6B4A2B),
    );
    canvas.restore();
    // paw holding the stick
    canvas.drawCircle(Offset(w * 0.22, w * 0.64), w * 0.06, p..color = furDark);

    // ears
    for (final dx in [-1.0, 1.0]) {
      final ear = Path()
        ..moveTo(w * (0.5 + dx * 0.34), w * 0.14)
        ..quadraticBezierTo(
          w * (0.5 + dx * 0.38),
          w * 0.02,
          w * (0.5 + dx * 0.20),
          w * 0.12,
        )
        ..quadraticBezierTo(
          w * (0.5 + dx * 0.25),
          w * 0.30,
          w * (0.5 + dx * 0.34),
          w * 0.14,
        )
        ..close();
      canvas.drawPath(ear, p..color = fur);
      canvas.drawCircle(
        Offset(w * (0.5 + dx * 0.30), w * 0.13),
        w * 0.05,
        p..color = cream,
      );
    }

    // head
    final head = Rect.fromCenter(
      center: Offset(w * 0.5, w * 0.40),
      width: w * 0.78,
      height: w * 0.60,
    );
    canvas.drawOval(head, p..color = fur);
    // cream face markings
    p.color = cream;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, w * 0.52),
        width: w * 0.36,
        height: w * 0.26,
      ),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.32, w * 0.30),
        width: w * 0.14,
        height: w * 0.08,
      ),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.68, w * 0.30),
        width: w * 0.14,
        height: w * 0.08,
      ),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.22, w * 0.50),
        width: w * 0.16,
        height: w * 0.16,
      ),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.78, w * 0.50),
        width: w * 0.16,
        height: w * 0.16,
      ),
      p,
    );
    // tear marks
    p.color = const Color(0xFF9A4524);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.36, w * 0.50),
        width: w * 0.07,
        height: w * 0.14,
      ),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.64, w * 0.50),
        width: w * 0.07,
        height: w * 0.14,
      ),
      p,
    );

    // eyes
    final eyeY = w * 0.40;
    if (blink || mood == YunMood.sleepy) {
      final lid = Paint()
        ..color = eye
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.022
        ..strokeCap = StrokeCap.round;
      for (final x in [0.36, 0.64]) {
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(w * x, eyeY),
            width: w * 0.09,
            height: w * 0.06,
          ),
          0.2,
          math.pi - 0.4,
          false,
          lid,
        );
      }
    } else {
      for (final x in [0.36, 0.64]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * x, eyeY),
            width: w * 0.085,
            height: w * (mood == YunMood.happy ? 0.08 : 0.10),
          ),
          Paint()..color = eye,
        );
        canvas.drawCircle(
          Offset(w * (x + 0.015), eyeY - w * 0.02),
          w * 0.015,
          Paint()..color = const Color(0xFFFFF6E8),
        );
      }
    }
    // cheeks
    p.color = const Color(0x55F28A8A);
    canvas.drawCircle(Offset(w * 0.27, w * 0.55), w * 0.04, p);
    canvas.drawCircle(Offset(w * 0.73, w * 0.55), w * 0.04, p);
    // nose + mouth
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, w * 0.49),
        width: w * 0.08,
        height: w * 0.055,
      ),
      Paint()..color = eye,
    );
    final mouth = Paint()
      ..color = eye
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.015
      ..strokeCap = StrokeCap.round;
    final open = mood == YunMood.happy;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.46, w * 0.535),
        width: w * 0.08,
        height: w * (open ? 0.08 : 0.05),
      ),
      0,
      math.pi,
      false,
      mouth,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.54, w * 0.535),
        width: w * 0.08,
        height: w * (open ? 0.08 : 0.05),
      ),
      0,
      math.pi,
      false,
      mouth,
    );

    if (mood == YunMood.sleepy) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'z z',
          style: TextStyle(
            color: Palette.inkSoft,
            fontSize: w * 0.12,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(w * 0.78, w * 0.02));
    }
  }

  @override
  bool shouldRepaint(_YunPainter o) =>
      o.mood != mood ||
      o.blink != blink ||
      o.sway != sway ||
      o.lantern != lantern;
}
