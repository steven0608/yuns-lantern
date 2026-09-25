import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/art/item_art.dart';
import '../../core/audio/audio_service.dart';
import '../../core/tokens.dart';
import '../shared/activity_scaffold.dart';
import '../shared/cards.dart';
import '../shared/gentle_hint.dart';

/// What Is It? / 猜一猜 — a mystery panel shows a thing as a silhouette
/// (tier "silhouette") or behind mist that slowly clears (tier "reveal");
/// the child taps the matching card. The right card flips the panel to full
/// colour and Yun names it. Wrong cards just wobble (ChoiceCard) — no fail.
final whatIsItGame = GameDef(
  id: 'what_is_it',
  build: (rc) => WhatIsIt(rc: rc),
  // Only the question: the answer's name must never be spoken up front.
  prompt: (_) => const ['whatisit.intro'],
  background: const [Color(0xFFFBEDE3), Color(0xFFEBD2D4)],
);

class WhatIsIt extends StatefulWidget {
  const WhatIsIt({super.key, required this.rc});
  final RoundContext rc;

  @override
  State<WhatIsIt> createState() => _WhatIsItState();
}

class _WhatIsItState extends State<WhatIsIt> with TickerProviderStateMixin {
  RoundContext get rc => widget.rc;
  String get _answer => rc.round.str('answer');
  bool get _misty => rc.round.str('tier') == 'reveal';

  late final List<String> _choices;
  late final HintController _hints;
  final _answerKey = GlobalKey();
  bool _solved = false;

  /// Reveal tier: 0 = fully misted, 1 = clear. About 10s on its own.
  late final AnimationController _clear = AnimationController(vsync: this, duration: const Duration(seconds: 10));
  late final AnimationController _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  late final AnimationController _wiggle = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void initState() {
    super.initState();
    _choices = rc.shuffled([_answer, ...rc.round.strings('distractors')]);
    _hints = rc.hints;
    _hints.guide = () => _solved ? null : HintMove(_answerKey);
    _hints.level.addListener(_helpChanged);
    if (_misty) _clear.forward();
  }

  @override
  void dispose() {
    _hints.level.removeListener(_helpChanged);
    _clear.dispose();
    _flip.dispose();
    _wiggle.dispose();
    _idle.dispose();
    super.dispose();
  }

  /// More help → the mist thins faster (and a silhouette shows a hint of
  /// colour, see [_mystery]). Never all at once: it stays the child's find.
  void _helpChanged() {
    if (!_misty || _solved || _hints.level.value < 1) return;
    final remaining = 1 - _clear.value;
    _clear.animateTo(1, duration: Duration(milliseconds: (remaining * 3500).round() + 200), curve: Curves.easeOut);
  }

  void _solve() {
    if (_solved) return;
    setState(() => _solved = true);
    _clear.stop();
    Future.wait([_flip.forward(), rc.audio.playSequence(['item.$_answer'])]).then((_) {
      if (mounted) rc.complete();
    });
  }

  void _pokePanel() {
    rc.hints.touched();
    rc.audio.sfx(Sfx.sparkle);
    _wiggle.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      final card = (h * 0.18).clamp(kMinTouchTarget, 150.0);
      const gap = kMinTargetGap - kHitSlop;
      final row = card + kHitSlop;
      final panelH = math.min(h - row - 24, 560.0);
      final panelW = math.min(w * 0.9, panelH * 1.45);
      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(width: panelW, height: panelH, child: _panel(panelH)),
        const SizedBox(height: 20),
        IgnorePointer(
          ignoring: _solved,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (final (i, id) in _choices.indexed) ...[
              if (i > 0) const SizedBox(width: gap),
              ChoiceCard(
                id: id,
                correct: id == _answer,
                hints: rc.hints,
                onCorrect: _solve,
                size: card,
                hintKey: id == _answer ? _answerKey : null,
              ),
            ],
          ]),
        ),
      ]);
    });
  }

  Widget _panel(double panelH) {
    final art = math.min(panelH * 0.56, 300.0);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _pokePanel(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_flip, _wiggle, _clear, _idle, rc.hints.level]),
        builder: (_, _) {
          final f = _flip.value;
          final front = f <= 0.5;
          final wig = math.sin(_wiggle.value * math.pi * 4) * 0.035 * (1 - _wiggle.value);
          // Card-flip: the mystery side turns away, the colour side turns in.
          final m = Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY((front ? f : f - 1) * math.pi)
            ..rotateZ(wig);
          final pop = front ? 1.0 : 1 + 0.07 * math.sin((f - 0.5) * 2 * math.pi);
          return Transform(
            alignment: Alignment.center,
            transform: m,
            child: Transform.scale(scale: pop, child: _face(front: front, art: art)),
          );
        },
      ),
    );
  }

  Widget _face({required bool front, required double art}) {
    final breathe = 1 + 0.03 * math.sin(_idle.value * 2 * math.pi);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 0.85,
          colors: front
              ? const [Color(0xFFFFF3E3), Color(0xFFE9D6E4)]
              : const [Color(0xFFFFF1CF), Color(0xFFF4D7AE)],
        ),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Palette.card, width: 6),
        boxShadow: const [BoxShadow(color: Palette.shadow, blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(fit: StackFit.expand, children: [
          CustomPaint(painter: _TwinklePainter(_idle.value, warm: !front)),
          Center(
            child: front
                ? Transform.scale(scale: breathe, child: _mystery(art))
                : ItemArt(_answer, size: art),
          ),
        ]),
      ),
    );
  }

  Widget _mystery(double art) {
    if (_misty) {
      final c = Curves.easeInOut.transform(_clear.value);
      final sigma = (1 - c) * art * 0.12;
      Widget item = ItemArt(_answer, size: art);
      if (sigma > 0.3) {
        item = ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal),
          child: item,
        );
      }
      return SizedBox.square(
        dimension: art * 1.6,
        child: Stack(alignment: Alignment.center, children: [
          item,
          IgnorePointer(child: CustomPaint(size: Size.square(art * 1.6), painter: _MistPainter(c, _idle.value))),
        ]),
      );
    }
    // Silhouette; once help is on, a hint of colour seeps through.
    return Stack(alignment: Alignment.center, children: [
      ItemArt(_answer, size: art, silhouette: true),
      AnimatedOpacity(
        opacity: rc.hints.level.value >= 1 ? 0.3 : 0,
        duration: const Duration(milliseconds: 600),
        child: ItemArt(_answer, size: art),
      ),
    ]);
  }
}

/// Soft puffs of mist over the mystery item. They drift apart and fade as
/// [clear] goes 0 → 1.
class _MistPainter extends CustomPainter {
  _MistPainter(this.clear, this.t);
  final double clear, t;

  @override
  void paint(Canvas canvas, Size size) {
    if (clear >= 1) return;
    final c = size.center(Offset.zero);
    final r = size.shortestSide;
    final paint = Paint()
      ..color = Palette.card.withValues(alpha: 0.85 * (1 - clear))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.06);
    for (var i = 0; i < 7; i++) {
      final a = i * 2 * math.pi / 7 + math.sin(t * 2 * math.pi + i) * 0.08;
      final dist = r * (0.12 + 0.45 * clear) + (i.isEven ? r * 0.05 : 0);
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * dist, r * (0.2 - 0.08 * clear), paint);
    }
    canvas.drawCircle(c, r * 0.22 * (1 - clear), paint);
  }

  @override
  bool shouldRepaint(_MistPainter old) => old.clear != clear || old.t != t;
}

/// A few gentle twinkles around the panel — it's a little stage.
class _TwinklePainter extends CustomPainter {
  _TwinklePainter(this.t, {required this.warm});
  final double t;
  final bool warm;

  static const _spots = [(0.1, 0.16), (0.88, 0.12), (0.08, 0.82), (0.92, 0.78), (0.5, 0.07), (0.74, 0.9)];

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide * 0.035;
    for (final (i, (fx, fy)) in _spots.indexed) {
      final s = math.sin(t * 2 * math.pi + i * 1.1);
      final glow = 0.25 + 0.5 * s * s;
      final r = unit * (0.7 + 0.5 * s * s) * (warm ? 1.3 : 1);
      final c = Offset(size.width * fx, size.height * fy);
      final p = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
        ..close();
      canvas.drawPath(p, Paint()..color = Palette.lantern.withValues(alpha: glow));
    }
  }

  @override
  bool shouldRepaint(_TwinklePainter old) => old.t != t || old.warm != warm;
}
