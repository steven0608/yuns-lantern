import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/audio/audio_service.dart';
import '../../core/tokens.dart';
import '../shared/activity_scaffold.dart';
import '../shared/cards.dart';
import '../shared/gentle_hint.dart';

/// Find the Same / 找相同 — Yun's magnifying glass holds one card; four
/// cards wait beside it. The child taps the one that looks exactly the same.
/// The match glides into the glass and lands right on top of its twin, the
/// glass gives a happy pop and a ring of stars, and Yun names it. Wrong cards
/// just wobble (ChoiceCard) — no fail state. Tapping the glass names the
/// thing in it.
final findTheSameGame = GameDef(
  id: 'find_the_same',
  build: (rc) => FindTheSame(rc: rc),
  prompt: (r) => r.vo,
  // The idle nudge is the question alone ("Which one looks exactly the same?").
  shortPrompt: (r) => r.vo.isEmpty ? const [] : [r.vo.first],
  background: const [Color(0xFFFDF1E0), Color(0xFFF4D6B6)],
);

/// On phones the home and replay buttons sit on side rails level with the
/// top of the game. Keeping this much room at each side leaves a 64px visible
/// gap between them and the cards (12 rail spare + 2 × 12 slop + 28).
const double _sideRoom = 28;

class FindTheSame extends StatefulWidget {
  const FindTheSame({super.key, required this.rc});
  final RoundContext rc;

  @override
  State<FindTheSame> createState() => _FindTheSameState();
}

class _FindTheSameState extends State<FindTheSame> with TickerProviderStateMixin {
  RoundContext get rc => widget.rc;
  late final String _ref = rc.round.str('reference');
  late final List<String> _choices;

  final _stackKey = GlobalKey();
  final _refKey = GlobalKey();
  final _answerKey = GlobalKey();

  late final AnimationController _float; // the glass drifts gently
  late final AnimationController _enter; // glass slides in, cards pop up
  late final AnimationController _poke; // a tap on the glass wiggles it
  late final AnimationController _fly; // the match glides into the glass
  late final AnimationController _match; // pop + ring of stars on landing

  bool _solved = false;
  bool _landed = false;
  Offset _flyFrom = Offset.zero, _flyTo = Offset.zero;
  double _flySizeFrom = 0, _flySizeTo = 0;

  @override
  void initState() {
    super.initState();
    // The reference plus its distractors, never a duplicate of it, never
    // more than the interactive cap.
    final distractors = rc.round.strings('distractors').where((d) => d != _ref).toSet();
    _choices = rc.shuffled([_ref, ...distractors.take(kMaxInteractiveItems - 1)]);

    _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))..repeat();
    _enter = AnimationController(vsync: this, duration: Duration(milliseconds: 700 + 110 * _choices.length))..forward();
    _poke = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _fly = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
    _match = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    rc.hints.guide = () => _solved ? null : HintMove(_answerKey);
  }

  @override
  void dispose() {
    _float.dispose();
    _enter.dispose();
    _poke.dispose();
    _fly.dispose();
    _match.dispose();
    super.dispose();
  }

  String? get _nameLine {
    final key = 'item.$_ref';
    return rc.round.vo.contains(key) ? key : null;
  }

  Offset _centerInStack(GlobalKey key) {
    final stack = _stackKey.currentContext!.findRenderObject()! as RenderBox;
    final box = key.currentContext!.findRenderObject()! as RenderBox;
    return stack.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  }

  /// The right card glides along a little arc into the glass, onto its twin.
  void _found(double cardSize, double refSize) {
    if (_solved) return;
    rc.audio.sfx(Sfx.whoosh);
    setState(() {
      _flyFrom = _centerInStack(_answerKey);
      _flyTo = _centerInStack(_refKey);
      _flySizeFrom = cardSize;
      _flySizeTo = refSize;
      _solved = true;
    });
    _fly.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      rc.audio.sfx(Sfx.sparkle);
      setState(() => _landed = true);
      Future.wait([_match.forward(from: 0), rc.audio.playSequence(['item.$_ref'])]).then((_) {
        if (mounted) rc.complete();
      });
    });
  }

  void _pokeGlass() {
    rc.hints.touched();
    rc.audio.sfx(Sfx.sparkle);
    _poke.forward(from: 0);
    final line = _nameLine;
    if (line != null && !_solved) rc.say([line]);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      final card = (h * 0.24).clamp(kMinTouchTarget, 160.0);
      final extent = card + kHitSlop; // a card plus its slop padding
      const gap = kMinTargetGap - kHitSlop; // + slop = 64px visible gap
      final cols = _choices.length > 1 ? 2 : 1;
      final rows = (_choices.length / cols).ceil();
      final gridW = cols * extent + (cols - 1) * gap;
      final spacing = math.max(32.0, w * 0.045);
      final lens = math.max(0.0, math.min(math.min(h, w - 2 * _sideRoom - gridW - spacing), 560.0));
      final refSize = lens * 0.44;

      return Stack(key: _stackKey, clipBehavior: Clip.none, children: [
        Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _glass(lens, refSize),
            SizedBox(width: spacing),
            IgnorePointer(
              ignoring: _solved,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                for (var r = 0; r < rows; r++) ...[
                  if (r > 0) const SizedBox(height: gap),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    for (var c = 0; c < cols; c++) ...[
                      if (c > 0) const SizedBox(width: gap),
                      if (r * cols + c < _choices.length)
                        _choiceAt(r * cols + c, card, extent, refSize)
                      else
                        SizedBox.square(dimension: extent),
                    ],
                  ]),
                ],
              ]),
            ),
          ]),
        ),
        if (_solved && !_landed) _flyer(),
      ]);
    });
  }

  Widget _choiceAt(int i, double card, double extent, double refSize) {
    final id = _choices[i];
    final correct = id == _ref;
    // The match has left for the glass: keep its place so nothing shifts.
    if (correct && _solved) return SizedBox.square(dimension: extent);
    return AnimatedBuilder(
      animation: _enter,
      builder: (_, child) {
        final ms = _enter.value * _enter.duration!.inMilliseconds;
        final t = ((ms - 300 - i * 110) / 420).clamp(0.0, 1.0);
        return Opacity(
          opacity: Curves.easeOut.transform(t),
          child: Transform.translate(offset: Offset(0, (1 - Curves.easeOutBack.transform(t)) * card * 0.3), child: child),
        );
      },
      child: ChoiceCard(
        key: ValueKey('choice$i'),
        id: id,
        correct: correct,
        hints: rc.hints,
        size: card,
        hintKey: correct ? _answerKey : null,
        onCorrect: () => _found(card, refSize),
      ),
    );
  }

  Widget _glass(double s, double refSize) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _pokeGlass(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_float, _enter, _poke, _match]),
        builder: (_, child) {
          final e = Curves.easeOutCubic.transform((_enter.value * 1.6).clamp(0.0, 1.0));
          final f = _float.value * 2 * math.pi;
          final pv = _poke.value;
          final wig = math.sin(pv * math.pi * 4) * 0.05 * (1 - pv);
          final m = _match.value;
          final pop = 1 + 0.08 * math.sin(math.pi * Curves.easeOut.transform(m));
          return Opacity(
            opacity: e,
            child: Transform.translate(
              offset: Offset(-(1 - e) * s * 0.25, math.sin(f) * s * 0.012),
              child: Transform.rotate(
                angle: math.sin(f * 0.5) * 0.02 + wig,
                child: Transform.scale(scale: pop, child: child),
              ),
            ),
          );
        },
        child: SizedBox.square(
          dimension: s,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(child: CustomPaint(painter: _MagnifierPainter(_float, _match))),
            // The reference card, centred in the glass.
            Positioned(
              left: s * _lensC - refSize / 2,
              top: s * _lensC - refSize / 2,
              child: Stack(clipBehavior: Clip.none, children: [
                ItemCard(key: _refKey, id: _ref, size: refSize),
                // Its twin, once it has landed on top.
                if (_landed)
                  Transform.rotate(angle: -0.06, child: ItemCard(id: _ref, size: refSize)),
              ]),
            ),
            Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _StarRingPainter(_match)))),
          ]),
        ),
      ),
    );
  }

  Widget _flyer() {
    return AnimatedBuilder(
      animation: _fly,
      builder: (_, _) {
        final t = Curves.easeInOutCubic.transform(_fly.value);
        final size = _flySizeFrom + (_flySizeTo - _flySizeFrom) * t;
        final lift = math.sin(math.pi * t) * _flySizeFrom * 0.7;
        final c = Offset.lerp(_flyFrom, _flyTo, t)! - Offset(0, lift);
        return Positioned(
          left: c.dx - size / 2,
          top: c.dy - size / 2,
          child: IgnorePointer(
            child: Transform.rotate(angle: -0.06 * t, child: ItemCard(id: _ref, size: size)),
          ),
        );
      },
    );
  }
}

// Magnifier geometry, as fractions of its square box.
const double _lensC = 0.42; // glass centre (x and y)
const double _lensR = 0.4; // outer radius of the rim
const double _rimW = 0.065;

/// Yun's magnifying glass (the Find the Same tile): a warm dark rim, a
/// handle with a grip band, and glass with a slow travelling sheen. Once the
/// twins meet, the glass glows lantern-warm.
class _MagnifierPainter extends CustomPainter {
  _MagnifierPainter(this.sheen, this.glow) : super(repaint: Listenable.merge([sheen, glow]));
  final Animation<double> sheen, glow;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(s * _lensC, s * _lensC);
    final r = s * _lensR, rim = s * _rimW;

    // Handle, out towards the bottom right.
    final dir = const Offset(1, 1) / math.sqrt2;
    final hStart = c + dir * (r - rim * 0.3), hEnd = Offset(s * 0.95, s * 0.95);
    canvas.drawLine(
      hStart + Offset(0, s * 0.02),
      hEnd + Offset(0, s * 0.02),
      Paint()
        ..color = Palette.shadow
        ..strokeWidth = s * 0.1
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.015),
    );
    canvas.drawLine(
      hStart,
      hEnd,
      Paint()
        ..color = Palette.ink
        ..strokeWidth = s * 0.1
        ..strokeCap = StrokeCap.round,
    );
    final grip = Offset.lerp(hStart, hEnd, 0.42)!;
    canvas.drawLine(
      grip,
      Offset.lerp(hStart, hEnd, 0.62)!,
      Paint()
        ..color = Palette.rust
        ..strokeWidth = s * 0.1
        ..strokeCap = StrokeCap.butt,
    );

    // Soft shadow under the glass, then the glass itself.
    canvas.drawCircle(
      c + Offset(0, s * 0.025),
      r,
      Paint()
        ..color = Palette.shadow
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.025),
    );
    final g = Curves.easeOut.transform(glow.value);
    final glass = Rect.fromCircle(center: c, radius: r - rim / 2);
    canvas.drawCircle(
      c,
      r - rim / 2,
      Paint()
        ..shader = RadialGradient(colors: [
          Color.lerp(Palette.card, Palette.cream, g)!,
          Color.lerp(Color.lerp(Palette.card, Palette.water, 0.22)!, Palette.lantern.withValues(alpha: 0.9), g * 0.6)!,
        ]).createShader(glass),
    );

    // A sheen that drifts across the glass now and then.
    canvas.save();
    canvas.clipPath(Path()..addOval(glass));
    final sweep = (sheen.value * 1.6 - 0.3) * s;
    canvas.drawPath(
      Path()
        ..moveTo(sweep - s * 0.1, 0)
        ..lineTo(sweep + s * 0.02, 0)
        ..lineTo(sweep - s * 0.3, s)
        ..lineTo(sweep - s * 0.42, s)
        ..close(),
      Paint()..color = Palette.card.withValues(alpha: 0.35),
    );
    canvas.restore();

    // The rim, with a curved glint on the upper left.
    canvas.drawCircle(
      c,
      r - rim / 2,
      Paint()
        ..color = Palette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = rim,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - rim * 1.6),
      math.pi * 1.08,
      math.pi * 0.34,
      false,
      Paint()
        ..color = Palette.card.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = rim * 0.45
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_MagnifierPainter old) => false;
}

/// A ring of little stars bursting out of the glass when the twins meet.
class _StarRingPainter extends CustomPainter {
  _StarRingPainter(this.t) : super(repaint: t);
  final Animation<double> t;

  static final List<Color> _colors = [
    for (final c in ['yellow', 'orange', 'pink', 'blue', 'green', 'purple']) Palette.named[c]!,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    if (v <= 0 || v >= 1) return;
    final s = size.shortestSide;
    final c = Offset(s * _lensC, s * _lensC);
    final reach = s * (_lensR + 0.06 + 0.16 * Curves.easeOutCubic.transform(v));
    final fade = v < 0.6 ? 1.0 : 1 - (v - 0.6) / 0.4;
    const n = 12;
    for (var k = 0; k < n; k++) {
      final a = k * 2 * math.pi / n + v * 0.6;
      final p = c + Offset(math.cos(a), math.sin(a)) * reach;
      final r = s * 0.028 * (k.isEven ? 1.0 : 0.7);
      final star = Path();
      for (var i = 0; i < 10; i++) {
        final rad = i.isEven ? r : r * 0.45;
        final b = -math.pi / 2 + i * math.pi / 5 + v * 2;
        final pt = p + Offset(math.cos(b), math.sin(b)) * rad;
        i == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(star..close(), Paint()..color = _colors[k % _colors.length].withValues(alpha: fade));
    }
  }

  @override
  bool shouldRepaint(_StarRingPainter old) => false;
}
