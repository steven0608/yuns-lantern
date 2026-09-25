import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/tokens.dart';
import '../shared/activity_scaffold.dart';
import '../shared/cards.dart';
import '../shared/draggable_item.dart';
import '../shared/drop_target.dart';
import '../shared/gentle_hint.dart';

/// Big and Small / 比大小 — put things in order of real-world size on a
/// staircase that climbs small → big.
///
/// In the tray every card is the same size: the knowledge being practised is
/// what the child knows about the world, not what the picture shows. Once
/// placed, items scale up step by step (0.8 / 1.0 / 1.2) to reinforce it.
final bigAndSmallGame = GameDef(
  id: 'big_and_small',
  build: (rc) => BigAndSmall(rc: rc),
  prompt: (_) => const ['comparing.order_small_big'],
  background: const [Color(0xFFF4F0DA), Color(0xFFD9E4BE)],
);

class BigAndSmall extends StatefulWidget {
  const BigAndSmall({super.key, required this.rc});
  final RoundContext rc;

  @override
  State<BigAndSmall> createState() => _BigAndSmallState();
}

class _BigAndSmallState extends State<BigAndSmall>
    with SingleTickerProviderStateMixin {
  RoundContext get rc => widget.rc;

  late final List<String> _order = rc.round.strings('orderedSmallToLarge');
  late final List<String> _tray;
  late final Map<String, GlobalKey> _itemKeys = {
    for (final id in _order) id: GlobalKey(),
  };
  late final List<GlobalKey> _stepKeys = List.generate(
    _order.length,
    (_) => GlobalKey(),
  );
  final Set<String> _placed = {};
  String? _missed;

  /// Once all are placed they hop one after another, small → big.
  late final AnimationController _parade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  static const _stepColors = [
    Color(0xFFB9D98F),
    Color(0xFFF2C66D),
    Color(0xFFE9A07A),
  ];

  @override
  void initState() {
    super.initState();
    final t = rc.shuffled(_order);
    // Never hand the child a tray that is already in order.
    _tray = listEquals(t, _order) ? [...t.skip(1), t.first] : t;
    rc.hints.guide = () {
      final id = _focus;
      if (id == null) return null;
      return HintMove(_itemKeys[id]!, _stepKeys[_order.indexOf(id)]);
    };
  }

  @override
  void dispose() {
    _parade.dispose();
    super.dispose();
  }

  double _scaleOf(int i) =>
      _order.length < 2 ? 1 : 0.8 + 0.4 * i / (_order.length - 1);

  /// What the help is about: the item the child just tried to place, else
  /// the smallest one still waiting. Pulse and hand always agree on it, and
  /// both show a move that is correct right now.
  String? get _focus {
    if (_missed != null && !_placed.contains(_missed)) return _missed;
    for (final id in _order) {
      if (!_placed.contains(id)) return id;
    }
    return null;
  }

  void _accept(int i) {
    final id = _order[i];
    if (_placed.contains(id)) return;
    setState(() {
      _placed.add(id);
      _missed = null;
    });
    rc.hints.succeeded();
    if (_placed.length < _order.length) {
      rc.say(['item.$id']);
      return;
    }
    // All in order: each hops as it is named, small → big.
    Future.wait([
      rc.audio.playSequence([for (final x in _order) 'item.$x']),
      _parade.forward(),
    ]).then((_) {
      if (mounted) rc.complete();
    });
  }

  void _reject(String data) {
    setState(() => _missed = data);
    rc.hints.miss();
  }

  /// 0→1→0 hop height for step [i] during the parade.
  double _hop(int i) {
    final v = _parade.value;
    if (v == 0) return 0;
    final slot = 0.84 / _order.length;
    final u = ((v - 0.08 - i * slot) / (slot + 0.02)).clamp(0.0, 1.0);
    return math.sin(u * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        final n = _order.length;
        final card = (h * 0.15).clamp(kMinTouchTarget, 130.0);
        final trayH = card + kHitSlop + 24;
        final stairsH = h - trayH - 16;
        final stepW = math.min(card * 1.7, (w - 40) / n);
        final unit = ((stairsH - card * _scaleOf(n - 1) - 36) / n).clamp(
          18.0,
          card * 1.1,
        );
        return Column(
          children: [
            SizedBox(
              height: trayH,
              child: Center(child: _trayView(card)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _stairs(card: card, stepW: stepW, unit: unit),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _trayView(double card) {
    const gap = kMinTargetGap - kHitSlop;
    return Stack(
      children: [
        // Decoration only: taps on the empty tray fall through to the
        // scaffold's sparkle, so every touch still answers.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Palette.card.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Palette.paperDeep, width: 3),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, id) in _tray.indexed) ...[
                if (i > 0) const SizedBox(width: gap),
                // A placed item leaves its spot empty, so the others stay put.
                if (_placed.contains(id))
                  SizedBox.square(dimension: card + kHitSlop)
                else
                  KeyedSubtree(
                    key: _itemKeys[id],
                    child: DraggableItem(
                      key: ValueKey(id),
                      data: id,
                      size: Size.square(card),
                      onTouched: rc.hints.touched,
                      child: ItemCard(id: id, size: card),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _stairs({
    required double card,
    required double stepW,
    required double unit,
  }) {
    return ValueListenableBuilder<int>(
      valueListenable: rc.hints.level,
      builder: (_, level, _) {
        final focus = level >= 1 ? _focus : null;
        return AnimatedBuilder(
          animation: _parade,
          builder: (_, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < _order.length; i++)
                    _step(
                      i,
                      card: card,
                      stepW: stepW,
                      unit: unit,
                      pulse: focus == _order[i],
                    ),
                ],
              ),
              // The ground the staircase stands on.
              IgnorePointer(
                child: Container(
                  width: stepW * _order.length + 48,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Palette.leaf,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: const [
                      BoxShadow(
                        color: Palette.shadow,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _step(
    int i, {
    required double card,
    required double stepW,
    required double unit,
    required bool pulse,
  }) {
    final id = _order[i];
    final size = card * _scaleOf(i);
    final placed = _placed.contains(id);
    return SizedBox(
      width: stepW,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: Offset(0, -_hop(i) * card * 0.4),
            child: DropTarget(
              key: _stepKeys[i],
              id: 'step$i',
              radius: size * 0.26,
              pulse: pulse && !placed,
              willAccept: (data) => data == id && !placed,
              onAccept: (_) => _accept(i),
              onReject: _reject,
              child: IgnorePointer(
                child: SizedBox.square(
                  dimension: size,
                  child: placed
                      ? _Settle(
                          from: card / size,
                          child: ItemCard(id: id, size: size),
                        )
                      : CustomPaint(painter: _SeatPainter(radius: size * 0.26)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          IgnorePointer(
            child: _Block(
              width: stepW,
              height: unit * (i + 1),
              color: _stepColors[i % _stepColors.length],
            ),
          ),
        ],
      ),
    );
  }
}

/// One step of the staircase: a soft wooden-toy block.
class _Block extends StatelessWidget {
  const _Block({
    required this.width,
    required this.height,
    required this.color,
  });
  final double width, height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Palette.card, 0.3)!, color],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border.all(
          color: Palette.card.withValues(alpha: 0.8),
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Palette.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

/// An empty spot on a step, drawn at the size the item will take there:
/// small, medium, big.
class _SeatPainter extends CustomPainter {
  _SeatPainter({required this.radius});
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(2),
      Radius.circular(radius),
    );
    canvas.drawRRect(r, Paint()..color = Palette.card.withValues(alpha: 0.45));
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Palette.inkSoft.withValues(alpha: 0.5);
    for (final metric in (Path()..addRRect(r)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 18) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 10, metric.length)),
          dash,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SeatPainter old) => old.radius != radius;
}

/// A placed item lands at the dragged card's size, then springs to its
/// step's size.
class _Settle extends StatelessWidget {
  const _Settle({required this.from, required this.child});
  final double from;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: from, end: 1),
      duration: const Duration(milliseconds: 560),
      curve: Curves.elasticOut,
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: child,
    );
  }
}
