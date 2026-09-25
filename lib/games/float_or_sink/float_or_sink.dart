import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/art/item_art.dart';
import '../../core/audio/audio_service.dart';
import '../../core/tokens.dart';
import '../shared/activity_scaffold.dart';
import '../shared/cards.dart';
import '../shared/draggable_item.dart';
import '../shared/drop_target.dart';
import '../shared/gentle_hint.dart';
import 'water.dart';

/// Float or Sink / 沉与浮 — an open-ended water sandbox. The child drops
/// each object into the tank and watches what really happens: it bobs at the
/// surface or drifts down to the sand.
///
/// There are no wrong answers (CLAUDE.md "No fail states", and the point of
/// a science sandbox), so this game never calls rc.hints.miss(). The round
/// ends when everything on the dock is in the water.
final floatOrSinkGame = GameDef(
  id: 'float_or_sink',
  build: (rc) => FloatOrSink(rc: rc),
  prompt: (_) => const ['floatsink.intro'],
  background: const [Color(0xFFFCEEDD), Color(0xFFF1D6BE)],
);

class FloatOrSink extends StatefulWidget {
  const FloatOrSink({super.key, required this.rc});
  final RoundContext rc;

  @override
  State<FloatOrSink> createState() => _FloatOrSinkState();
}

class _FloatOrSinkState extends State<FloatOrSink> with SingleTickerProviderStateMixin {
  RoundContext get rc => widget.rc;

  late final Set<String> _floaters;
  late final List<String> _waiting; // still on the dock, in offer order
  late final int _lanes;
  final Map<String, GlobalKey> _itemKeys = {};
  final _tankKey = GlobalKey();

  final List<Drop> _drops = [];
  final List<Splash> _splashes = [];
  final List<Burst> _bursts = [];

  /// Seconds since the round appeared; drives every wave and bubble.
  late final Ticker _ticker;
  final ValueNotifier<double> _clock = ValueNotifier(0);
  double get _now => _clock.value;

  Size _tankSize = Size.zero;
  double _card = kMinTouchTarget;
  double _settleAt = double.infinity;
  bool _lastLineDone = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    final floats = rc.round.strings('floats');
    final sinks = rc.round.strings('sinks');
    // Never more than kMaxInteractiveItems (CLAUDE.md). Half from each list
    // so the child sees both outcomes, topped up from leftovers if one list
    // is short.
    const half = kMaxInteractiveItems ~/ 2;
    final f = rc.shuffled(floats), s = rc.shuffled(sinks);
    final picked = [...f.take(half), ...s.take(half)];
    picked.addAll([...f.skip(half), ...s.skip(half)].take(kMaxInteractiveItems - picked.length));
    _floaters = picked.where(floats.contains).toSet();
    _waiting = rc.shuffled(picked);
    _lanes = math.max(1, math.max(_floaters.length, picked.length - _floaters.length));
    for (final id in picked) {
      _itemKeys[id] = GlobalKey();
    }
    _ticker = createTicker(_tick)..start();
    // Idle demo: any remaining item → the water.
    rc.hints.guide = () => _waiting.isEmpty ? null : HintMove(_itemKeys[_waiting.first]!, _tankKey);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  WaterFrame _frame(Size size) => WaterFrame(
        geo: TankGeometry(size, _lanes),
        time: _now,
        drops: _drops,
        splashes: _splashes,
        bursts: _bursts,
      );

  void _tick(Duration elapsed) {
    _clock.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    for (final d in _drops) {
      // The "bloop" as a floater pops up, or as a sinker starts its trail.
      if (!d.bubbled && _now - d.t0 > (d.floats ? 0.55 : 0.3)) {
        d.bubbled = true;
        rc.audio.sfx(Sfx.bubble);
      }
    }
    // Finish only once the last thing has settled and been named, so the
    // celebration never covers the discovery.
    if (!_completed && _waiting.isEmpty && _lastLineDone && _now >= _settleAt) {
      _completed = true;
      rc.complete();
    }
  }

  void _accept(String id, int lane) {
    if (!_waiting.contains(id)) return;
    final floats = _floaters.contains(id);
    final taken = {for (final d in _drops) if (d.floats == floats) d.slot};
    final free = [for (var i = 0; i < _lanes; i++) if (!taken.contains(i)) i]
      ..sort((a, b) => (a - lane).abs().compareTo((b - lane).abs()));
    setState(() {
      _waiting.remove(id);
      _drops.add(Drop(id: id, floats: floats, lane: lane, slot: free.first, t0: _now, seed: _drops.length * 7 + lane));
      _splashes
        ..removeWhere((s) => _now - s.t0 > 3)
        ..add(Splash(x: (lane + 0.5) / _lanes, t0: _now));
    });
    rc.audio.sfx(Sfx.splash);
    rc.hints.succeeded();
    // "Apple… it floats!" — the name, then what the child just saw happen.
    final line = rc.audio.playSequence(['item.$id', floats ? 'floatsink.floats' : 'floatsink.sinks']);
    if (_waiting.isEmpty) {
      _settleAt = _now + (floats ? Drop.floatIn : Drop.sinkIn) + 0.5;
      line.then((_) => _lastLineDone = true);
    }
  }

  /// Every touch on the water answers: a settled item dunks or wiggles and
  /// is named again; open water ripples or fizzes.
  void _tapWater(Offset p) {
    rc.hints.touched();
    if (_tankSize.isEmpty) return;
    final f = _frame(_tankSize);
    Drop? hit;
    var best = f.geo.itemSize * 0.8; // generous: well over the 88px minimum
    for (final d in _drops) {
      if (_now - d.t0 < d.settle) continue;
      final dist = (f.pose(d).$1 - p).distance;
      if (dist < best) {
        best = dist;
        hit = d;
      }
    }
    final at = Offset(p.dx / _tankSize.width, p.dy / _tankSize.height);
    _bursts.removeWhere((b) => _now - b.t0 > 3);
    if (hit != null) {
      hit.pokedAt = _now;
      if (hit.floats) _splashes.add(Splash(x: f.pose(hit).$1.dx / _tankSize.width, t0: _now, strength: 0.5));
      rc.audio.sfx(hit.floats ? Sfx.splash : Sfx.bubble);
      rc.say(['item.${hit.id}', hit.floats ? 'floatsink.floats' : 'floatsink.sinks']);
    } else if (p.dy < f.surfaceAt(p.dx) + 16) {
      _splashes.add(Splash(x: at.dx, t0: _now, strength: 0.5));
      rc.audio.sfx(Sfx.splash);
    } else {
      _bursts.add(Burst(at: at, t0: _now));
      rc.audio.sfx(Sfx.bubble);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      // Phones in landscape are short: the dock becomes a column beside the
      // tank and offers fewer items at a time (it refills), so every item
      // keeps its 88px size and 64px gap instead of shrinking to fit.
      final side = h < 520;
      final card = side ? kMinTouchTarget : (h * 0.13).clamp(kMinTouchTarget, 120.0);
      const gap = kMinTargetGap - kHitSlop;
      final room = (side ? h : w) - 24;
      final cap = ((room + gap) / (card + kHitSlop + gap)).floor().clamp(1, kMaxInteractiveItems);
      _card = card;
      final dock = _dock(card: card, cap: cap, vertical: side);
      final tank = _tank();
      return side
          ? Row(children: [dock, const SizedBox(width: 16), Expanded(child: tank)])
          : Column(children: [dock, const SizedBox(height: 16), Expanded(child: tank)]);
    });
  }

  Widget _dock({required double card, required int cap, required bool vertical}) {
    const gap = kMinTargetGap - kHitSlop;
    final cell = card + kHitSlop;
    // Fixed size, so the tank never shifts as the dock empties.
    final along = cap * cell + (cap - 1) * gap + 24;
    final across = cell + 24;
    final shown = _waiting.take(cap).toList();
    return SizedBox(
      width: vertical ? across : along,
      height: vertical ? along : across,
      child: Stack(children: [
        // Decoration only: taps on the empty dock fall through to the
        // scaffold's sparkle, so every touch still answers.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Palette.card.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Palette.paperDeep, width: 3),
              ),
            ),
          ),
        ),
        Center(
          child: Flex(
            direction: vertical ? Axis.vertical : Axis.horizontal,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, id) in shown.indexed) ...[
                if (i > 0) const SizedBox(width: gap, height: gap),
                KeyedSubtree(
                  key: _itemKeys[id],
                  child: _PopIn(
                    child: DraggableItem(
                      key: ValueKey(id),
                      data: id,
                      size: Size.square(card),
                      onTouched: rc.hints.touched,
                      child: ItemCard(id: id, size: card),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ]),
    );
  }

  Widget _tank() {
    return ValueListenableBuilder<int>(
      valueListenable: rc.hints.level,
      builder: (_, level, child) => GentlePulse(active: level >= 1, radius: kTankRadius, child: child!),
      child: DecoratedBox(
        key: _tankKey,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kTankRadius),
          boxShadow: const [BoxShadow(color: Palette.shadow, blurRadius: 16, offset: Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kTankRadius),
          child: LayoutBuilder(builder: (context, box) {
            _tankSize = box.biggest;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _tapWater(d.localPosition),
              child: Stack(fit: StackFit.expand, children: [
                ValueListenableBuilder<double>(
                  valueListenable: _clock,
                  builder: (_, _, _) => _water(box.biggest),
                ),
                // Invisible lanes: wherever the child lets go over the tank,
                // the item goes in right there. Every lane accepts anything.
                Row(children: [
                  for (var i = 0; i < _lanes; i++)
                    Expanded(
                      child: DropTarget(
                        id: 'lane$i',
                        radius: 0,
                        willAccept: (_) => true,
                        onAccept: (id) => _accept(id, i),
                        child: const _LaneGlow(),
                      ),
                    ),
                ]),
              ]),
            );
          }),
        ),
      ),
    );
  }

  Widget _water(Size size) {
    final f = _frame(size);
    return Stack(fit: StackFit.expand, children: [
      CustomPaint(painter: TankBackPainter(f)),
      for (final d in _drops) _inWater(d, f),
      CustomPaint(painter: TankFrontPainter(f)),
    ]);
  }

  /// A dropped item. It arrives on its dock card (that's what the child let
  /// go of); the card melts away as the water takes it.
  Widget _inWater(Drop d, WaterFrame f) {
    final (c, tilt) = f.pose(d);
    final a = f.time - d.t0;
    final grow = Curves.easeOut.transform((a / 0.45).clamp(0.0, 1.0));
    final box = lerpDouble(_card, f.geo.itemSize, grow)!;
    final cardFade = 1 - (a / 0.3).clamp(0.0, 1.0);
    return Positioned(
      left: c.dx - box / 2,
      top: c.dy - box / 2,
      width: box,
      height: box,
      child: Transform.rotate(
        angle: tilt,
        child: Stack(alignment: Alignment.center, children: [
          if (cardFade > 0) Opacity(opacity: cardFade, child: ItemCard(size: box, elevated: false)),
          ItemArt(d.id, size: box * lerpDouble(0.58, 0.86, grow)!),
        ]),
      ),
    );
  }
}

/// A soft shaft of light down the lane an item is hovering over: "it will
/// go in here".
class _LaneGlow extends StatelessWidget {
  const _LaneGlow();

  @override
  Widget build(BuildContext context) {
    final lane = context.findAncestorStateOfType<DropTargetState>();
    if (lane == null) return const SizedBox.expand();
    return ValueListenableBuilder<bool>(
      valueListenable: lane.hovered,
      builder: (_, over, _) => AnimatedOpacity(
        opacity: over ? 1 : 0,
        duration: kStandardEase,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x8CFFF8EC), Color(0x00FFF8EC)],
            ),
          ),
        ),
      ),
    );
  }
}

/// New dock items spring into place.
class _PopIn extends StatelessWidget {
  const _PopIn({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.elasticOut,
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: child,
    );
  }
}
