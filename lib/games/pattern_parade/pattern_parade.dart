import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/audio/audio_service.dart';
import '../../core/tokens.dart';
import '../shared/activity_scaffold.dart';
import '../shared/cards.dart';
import '../shared/draggable_item.dart';
import '../shared/drop_target.dart';
import '../shared/gentle_hint.dart';

/// Pattern Parade / 排排队 (4+) — a line of item cards marches along under
/// festive bunting and ends in an empty dashed spot. The child finds what
/// comes next and drags it (or simply taps it) into the spot; then the whole
/// line hops one after another. The question itself is carried by audio.
final patternParadeGame = GameDef(
  id: 'pattern_parade',
  build: (rc) => PatternParade(rc: rc),
  prompt: (r) => r.vo,
  // The idle nudge only needs the question ("What comes next?").
  shortPrompt: (r) => r.vo.isEmpty ? const [] : [r.vo.last],
  background: const [Color(0xFFFDEBDC), Color(0xFFF3CDB0)],
);

/// Space between parade cards, as a fraction of a card.
const double _gapRatio = 0.16;

/// Stagger between neighbours when the line hops in celebration.
const int _hopStaggerMs = 90;
const int _hopMs = 420;

class PatternParade extends StatefulWidget {
  const PatternParade({super.key, required this.rc});
  final RoundContext rc;

  @override
  State<PatternParade> createState() => _PatternParadeState();
}

class _PatternParadeState extends State<PatternParade> with TickerProviderStateMixin {
  RoundContext get rc => widget.rc;
  late final List<String> _sequence = rc.round.strings('sequence');
  late final String _answer = rc.round.str('answer');
  // Content always has 3 choices; never show more than the interactive cap.
  late final List<String> _choices = rc.round.strings('choices').take(kMaxInteractiveItems).toList();

  final _stackKey = GlobalKey();
  final _slotKey = GlobalKey();
  late final List<GlobalKey> _choiceKeys = [for (final _ in _choices) GlobalKey()];

  late final AnimationController _march; // endless marching sway
  late final AnimationController _enter; // cards march in at round start
  late final AnimationController _cheer; // the success hop wave
  late final AnimationController _fly; // a tapped choice gliding to the slot

  bool _placed = false;
  int? _flying;
  Offset _flyFrom = Offset.zero, _flyTo = Offset.zero;
  double _flySizeFrom = 0, _flySizeTo = 0;

  int get _lineLength => _sequence.length + 1;

  @override
  void initState() {
    super.initState();
    _march = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _enter = AnimationController(vsync: this, duration: Duration(milliseconds: 500 + 90 * _lineLength))..forward();
    _cheer = AnimationController(vsync: this, duration: Duration(milliseconds: _hopStaggerMs * _lineLength + _hopMs));
    _fly = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
    rc.hints.guide = () {
      final i = _choices.indexOf(_answer);
      if (_placed || _flying != null || i < 0) return null;
      return HintMove(_choiceKeys[i], _slotKey);
    };
  }

  @override
  void dispose() {
    _march.dispose();
    _enter.dispose();
    _cheer.dispose();
    _fly.dispose();
    super.dispose();
  }

  Offset _centerInStack(GlobalKey key) {
    final stack = _stackKey.currentContext!.findRenderObject()! as RenderBox;
    final box = key.currentContext!.findRenderObject()! as RenderBox;
    return stack.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  }

  /// Tap-to-place: the right card glides along a little arc into the slot.
  void _tapCorrect(int index, double choiceSize, double cardSize) {
    if (_placed || _flying != null) return;
    rc.hints.touched();
    rc.audio.sfx(Sfx.whoosh);
    setState(() {
      _flyFrom = _centerInStack(_choiceKeys[index]);
      _flyTo = _centerInStack(_slotKey);
      _flySizeFrom = choiceSize;
      _flySizeTo = cardSize;
      _flying = index;
    });
    _fly.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      rc.audio.sfx(Sfx.snap);
      _land();
    });
  }

  void _land() {
    if (_placed) return;
    setState(() {
      _placed = true;
      _flying = null;
    });
    rc.hints.succeeded();
    // Name the item that completed the pattern while the line hops, then
    // hand over to the scaffold's celebration.
    Future.wait([rc.audio.playVO('item.$_answer'), _cheer.forward(from: 0)]).then((_) {
      if (mounted) rc.complete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      final choice = (h * 0.2).clamp(kMinTouchTarget, 140.0);
      const trayPad = 10.0;
      const spacing = 12.0;
      final trayH = choice + kHitSlop + trayPad * 2;
      final paradeH = math.max(0.0, h - trayH - spacing);
      // Parade cards are look-only, so on a phone they may be smaller than a
      // touch target; the draggable choices below never are.
      final card = math.min(
        math.min((w - 32) / (_lineLength + (_lineLength - 1) * _gapRatio), paradeH * 0.5),
        156.0,
      );

      return Stack(key: _stackKey, clipBehavior: Clip.none, children: [
        Column(children: [
          // The parade is look-only: taps fall through to the scaffold's
          // sparkle so every touch still answers (drop targets find items by
          // their bounds, not by hit testing).
          Expanded(child: Center(child: IgnorePointer(child: _parade(card)))),
          const SizedBox(height: spacing),
          _tray(choice, card, trayPad),
        ]),
        if (_flying != null) _flyer(),
      ]);
    });
  }

  Widget _parade(double card) {
    final gap = card * _gapRatio;
    final lineW = _lineLength * card + (_lineLength - 1) * gap;
    final cards = <Widget>[
      for (final id in _sequence) ItemCard(id: id, size: card),
      _slot(card),
    ];

    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: lineW + card,
        height: card * 0.55,
        child: CustomPaint(painter: _BuntingPainter(_march)),
      ),
      SizedBox(height: card * 0.3),
      SizedBox(
        width: lineW,
        height: card,
        child: Stack(clipBehavior: Clip.none, children: [
          // The parade road the cards march along.
          Positioned(
            left: -card * 0.3,
            right: -card * 0.3,
            bottom: -card * 0.16,
            height: card * 0.38,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Palette.rust.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(card),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: Listenable.merge([_march, _enter, _cheer]),
            builder: (_, _) => Row(children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                _marching(i, card, cards[i]),
              ],
            ]),
          ),
        ]),
      ),
    ]);
  }

  /// A travelling wave of little steps: each card lifts and tilts slightly
  /// after its neighbour, so the line reads as marching. The empty slot stays
  /// still (it's waiting) until the answer arrives and joins in.
  Widget _marching(int i, double card, Widget child) {
    final isSlot = i == _lineLength - 1;
    final enterMs = _enter.value * _enter.duration!.inMilliseconds;
    final enterT = Curves.easeOutCubic.transform(((enterMs - i * 90) / 420).clamp(0.0, 1.0));

    var dy = 0.0, tilt = 0.0;
    if (!isSlot || _placed) {
      final phase = _march.value * math.pi * 2 - i * 0.9;
      dy = -card * 0.05 * (math.sin(phase) * 0.5 + 0.5);
      tilt = 0.035 * math.cos(phase);
    }
    final cheerMs = _cheer.value * _cheer.duration!.inMilliseconds;
    final hop = math.sin(math.pi * ((cheerMs - i * _hopStaggerMs) / _hopMs).clamp(0.0, 1.0));
    dy -= card * 0.42 * hop;

    return Opacity(
      opacity: enterT,
      child: Transform.translate(
        offset: Offset(-(1 - enterT) * card * 1.2, dy),
        child: Transform.rotate(angle: tilt, child: Transform.scale(scale: 1 + 0.08 * hop, child: child)),
      ),
    );
  }

  Widget _slot(double card) {
    return DropTarget(
      key: _slotKey,
      id: 'slot',
      enabled: !_placed && _flying == null,
      radius: card * 0.26,
      willAccept: (data) => data == _answer,
      onAccept: (_) => _land(),
      onReject: (_) => rc.hints.miss(),
      child: SizedBox.square(
        dimension: card,
        child: _placed
            ? TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.18, end: 1.0),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutBack,
                builder: (_, s, child) => Transform.scale(scale: s, child: child),
                child: ItemCard(id: _answer, size: card),
              )
            : AnimatedBuilder(
                animation: _march,
                builder: (_, child) => Transform.scale(
                  scale: 1 + 0.035 * math.sin(_march.value * math.pi * 2),
                  child: child,
                ),
                child: CustomPaint(painter: _DashedSlotPainter(radius: card * 0.26)),
              ),
      ),
    );
  }

  Widget _tray(double choice, double card, double pad) {
    return AnimatedBuilder(
      animation: _enter,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(((_enter.value - 0.45) / 0.55).clamp(0.0, 1.0));
        return Opacity(opacity: t, child: Transform.translate(offset: Offset(0, (1 - t) * 24), child: child));
      },
      child: Stack(children: [
        // Backdrop only: taps between cards fall through to the sparkle.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Palette.card.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: pad * 2, vertical: pad),
          // Nothing to pick once the answer is on its way or in place.
          child: IgnorePointer(
            ignoring: _placed || _flying != null,
            child: ValueListenableBuilder<int>(
              valueListenable: rc.hints.level,
              builder: (_, level, _) => Row(mainAxisSize: MainAxisSize.min, children: [
                for (var i = 0; i < _choices.length; i++) ...[
                  // Spacer + each item's 12px slop each side = 64px visible gap.
                  if (i > 0) const SizedBox(width: kMinTargetGap - kHitSlop),
                  _choiceAt(i, choice, card, level),
                ],
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _choiceAt(int i, double choice, double card, int level) {
    final id = _choices[i];
    final gone = (id == _answer && _placed) || _flying == i;
    if (gone) return SizedBox.square(dimension: choice + kHitSlop);
    final correct = id == _answer;
    return KeyedSubtree(
      key: _choiceKeys[i],
      child: _ChoiceTile(
        key: ValueKey('choice$i'),
        id: id,
        size: choice,
        correct: correct,
        pulse: correct && level >= 1,
        hints: rc.hints,
        onTapCorrect: () => _tapCorrect(i, choice, card),
      ),
    );
  }

  Widget _flyer() {
    return AnimatedBuilder(
      animation: _fly,
      builder: (_, _) {
        final t = Curves.easeInOutCubic.transform(_fly.value);
        final size = _flySizeFrom + (_flySizeTo - _flySizeFrom) * t;
        final lift = math.sin(math.pi * t) * _flySizeFrom * 0.6;
        final c = Offset.lerp(_flyFrom, _flyTo, t)! - Offset(0, lift);
        return Positioned(
          left: c.dx - size / 2,
          top: c.dy - size / 2,
          child: IgnorePointer(child: ItemCard(id: _answer, size: size)),
        );
      },
    );
  }
}

/// One answer card: drag it, or tap it. A wrong tap wobbles gently and
/// escalates help — never an X, never red (CLAUDE.md "No fail states").
class _ChoiceTile extends StatefulWidget {
  const _ChoiceTile({
    super.key,
    required this.id,
    required this.size,
    required this.correct,
    required this.pulse,
    required this.hints,
    required this.onTapCorrect,
  });
  final String id;
  final double size;
  final bool correct, pulse;
  final HintController hints;
  final VoidCallback onTapCorrect;

  @override
  State<_ChoiceTile> createState() => _ChoiceTileState();
}

class _ChoiceTileState extends State<_ChoiceTile> with SingleTickerProviderStateMixin {
  late final AnimationController _wobble =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void dispose() {
    _wobble.dispose();
    super.dispose();
  }

  void _tap() {
    if (widget.correct) {
      widget.onTapCorrect();
    } else {
      _wobble.forward(from: 0);
      widget.hints.miss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GentlePulse(
      active: widget.pulse,
      radius: widget.size * 0.26 + kHitSlop / 2,
      child: AnimatedBuilder(
        animation: _wobble,
        builder: (_, child) {
          final t = _wobble.value;
          return Transform.rotate(angle: 0.08 * (1 - t) * math.sin(t * 18), child: child);
        },
        // A still touch is a tap (the drag recogniser yields); any movement
        // becomes a drag. The drag already plays the touch sound on down.
        child: GestureDetector(
          onTap: _tap,
          child: DraggableItem(
            data: widget.id,
            size: Size.square(widget.size),
            onTouched: widget.hints.touched,
            child: ItemCard(id: widget.id, size: widget.size),
          ),
        ),
      ),
    );
  }
}

/// The empty spot at the end of the line: a soft dashed card outline.
class _DashedSlotPainter extends CustomPainter {
  _DashedSlotPainter({required this.radius});
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius((Offset.zero & size).deflate(3), Radius.circular(radius));
    canvas.drawRRect(rrect, Paint()..color = Palette.card.withValues(alpha: 0.55));
    final stroke = Paint()
      ..color = Palette.rust.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3, size.width * 0.035)
      ..strokeCap = StrokeCap.round;
    final dash = size.width * 0.09;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash * 2) {
        canvas.drawPath(metric.extractPath(d, math.min(d + dash, metric.length)), stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedSlotPainter old) => old.radius != radius;
}

/// A string of little pennants swaying above the parade.
class _BuntingPainter extends CustomPainter {
  _BuntingPainter(this.sway) : super(repaint: sway);
  final Animation<double> sway;

  // Decoration only; colour never carries meaning here. No red (CLAUDE.md).
  static final List<Color> _colors = [
    for (final c in ['orange', 'yellow', 'green', 'blue', 'purple', 'pink']) Palette.named[c]!,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final start = Offset(0, h * 0.12), end = Offset(w, h * 0.12), control = Offset(w / 2, h * 0.62);
    Offset at(double t) =>
        start * ((1 - t) * (1 - t)) + control * (2 * t * (1 - t)) + end * (t * t);

    final string = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    canvas.drawPath(
      string,
      Paint()
        ..color = Palette.inkSoft.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final count = (w / (h * 1.1)).floor().clamp(5, 16);
    final flagW = w / count * 0.62;
    for (var k = 0; k < count; k++) {
      final p = at((k + 0.5) / count);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(math.sin(sway.value * math.pi * 2 + k * 0.8) * 0.09);
      final flag = Path()
        ..moveTo(-flagW / 2, 0)
        ..lineTo(flagW / 2, 0)
        ..lineTo(0, h * 0.5)
        ..close();
      canvas.drawPath(flag, Paint()..color = _colors[k % _colors.length].withValues(alpha: 0.85));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BuntingPainter old) => false;
}
