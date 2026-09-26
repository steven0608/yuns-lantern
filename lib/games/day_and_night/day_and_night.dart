import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/art/item_art.dart';
import '../../core/tokens.dart';
import '../shared/activity_scaffold.dart';
import '../shared/cards.dart';
import '../shared/draggable_item.dart';
import '../shared/drop_target.dart';
import '../shared/gentle_hint.dart';

/// Day and Night / 白天黑夜 (4+) — sort things into the sunny half or the
/// starry half. `either` things (docs/GAME_DESIGN.md) belong to both: any side
/// is right, and Yun says "This one can be either! You choose."
final dayAndNightGame = GameDef(
  id: 'day_and_night',
  build: (rc) => DayAndNight(rc: rc),
  prompt: (r) => const ['daynight.intro'],
  shortPrompt: (r) => const ['item.sun', 'item.moon'],
  background: const [Color(0xFFF6E3C3), Color(0xFFD9CBB8)],
);

enum _Side { day, night }

class DayAndNight extends StatefulWidget {
  const DayAndNight({super.key, required this.rc});
  final RoundContext rc;

  @override
  State<DayAndNight> createState() => _DayAndNightState();
}

class _DayAndNightState extends State<DayAndNight> {
  RoundContext get rc => widget.rc;

  late final Set<String> _day = rc.round.strings('day').toSet();
  late final Set<String> _night = rc.round.strings('night').toSet();
  late final Set<String> _either = rc.round.strings('either').toSet();

  /// Cards not yet placed, in the order they come into the tray.
  late final List<String> _queue = rc.shuffled(
    [..._day, ..._night, ..._either].take(kMaxInteractiveItems),
  );
  final Map<_Side, List<String>> _placed = {_Side.day: [], _Side.night: []};
  int _trayMax = kMaxInteractiveItems;

  final _dayKey = GlobalKey(),
      _nightKey = GlobalKey(),
      _firstCardKey = GlobalKey();

  List<String> get _tray => _queue.take(_trayMax).toList();

  _Side _home(String id) => _night.contains(id) ? _Side.night : _Side.day;

  bool _belongs(String id, _Side side) =>
      _either.contains(id) || _home(id) == side;

  @override
  void initState() {
    super.initState();
    rc.hints.guide = () {
      if (_queue.isEmpty) return null;
      return HintMove(
        _firstCardKey,
        _home(_queue.first) == _Side.day ? _dayKey : _nightKey,
      );
    };
  }

  void _accept(String id, _Side side) {
    setState(() {
      _queue.remove(id);
      _placed[side]!.add(id);
    });
    rc.hints.succeeded();
    final line = _either.contains(id)
        ? ['item.$id', 'daynight.either']
        : ['item.$id'];
    if (_queue.isEmpty) {
      rc.audio.playSequence(line).then((_) => rc.complete());
    } else {
      rc.say(line);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final short = box.maxHeight < 420;
        final card = short
            ? kMinTouchTarget + 8
            : (box.maxHeight * 0.18).clamp(kMinTouchTarget, 128.0);
        // Phones: three cards at a time, refilled as they're placed.
        _trayMax = short ? 3 : kMaxInteractiveItems;
        final trayH = card + kHitSlop + 16;
        final level = rc.hints.level;

        Widget half(_Side side, GlobalKey key) => Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: level,
            builder: (_, lv, _) {
              final pulse =
                  lv >= 1 &&
                  _queue.isNotEmpty &&
                  _belongs(_queue.first, side) &&
                  !_either.contains(_queue.first);
              return DropTarget(
                key: key,
                id: side.name,
                radius: 36,
                pulse: pulse,
                willAccept: (id) => _belongs(id, side),
                onAccept: (id) => _accept(id, side),
                onReject: (_) => rc.hints.miss(),
                child: _Sky(
                  side: side,
                  placed: _placed[side]!,
                  itemSize: card * 0.55,
                ),
              );
            },
          ),
        );

        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  half(_Side.day, _dayKey),
                  const SizedBox(width: 16),
                  half(_Side.night, _nightKey),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: trayH,
              child: Center(
                child: Wrap(
                  spacing: kMinTargetGap - kHitSlop,
                  children: [
                    for (final (i, id) in _tray.indexed)
                      KeyedSubtree(
                        key: i == 0 ? _firstCardKey : ValueKey('slot$id'),
                        child: DraggableItem(
                          key: ValueKey(id),
                          data: id,
                          size: Size.square(card),
                          onTouched: rc.hints.touched,
                          child: ItemCard(id: id, size: card),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One half of the world: warm day sky with a slowly turning sun, or a
/// night sky with a moon and twinkling stars. Placed things settle in with
/// a small hop.
class _Sky extends StatefulWidget {
  const _Sky({
    required this.side,
    required this.placed,
    required this.itemSize,
  });
  final _Side side;
  final List<String> placed;
  final double itemSize;

  @override
  State<_Sky> createState() => _SkyState();
}

class _SkyState extends State<_Sky> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.side == _Side.day;
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: day
                ? const [Color(0xFFFFE3A3), Color(0xFFF7C98B)]
                : const [Color(0xFF2E3160), Palette.night],
          ),
          border: Border.all(color: Palette.card, width: 5),
          borderRadius: BorderRadius.circular(36),
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final orb = math.min(box.maxWidth, box.maxHeight) * 0.3;
            return Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: _c,
                  builder: (_, _) => CustomPaint(
                    painter: day
                        ? _DayPainter(_c.value)
                        : _NightPainter(_c.value),
                  ),
                ),
                Align(
                  alignment: day
                      ? const Alignment(0.75, -0.7)
                      : const Alignment(-0.75, -0.7),
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (_, child) => Transform.rotate(
                      angle: day
                          ? _c.value * math.pi * 2 * 0.25
                          : math.sin(_c.value * math.pi * 2) * 0.08,
                      child: child,
                    ),
                    child: ItemArt(day ? 'sun' : 'moon', size: orb),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, 0.75),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final id in widget.placed)
                          TweenAnimationBuilder<double>(
                            key: ValueKey(id),
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 520),
                            curve: Curves.elasticOut,
                            builder: (_, t, child) => Transform.scale(
                              scale: 0.4 + 0.6 * t,
                              child: child,
                            ),
                            child: ItemArt(id, size: widget.itemSize),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DayPainter extends CustomPainter {
  _DayPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size s) {
    // drifting clouds + a green hill
    final cloud = Paint()..color = const Color(0xCCFFF8EC);
    for (final (i, y) in [0.22, 0.38].indexed) {
      final x = ((t + i * 0.5) % 1.0) * (s.width + 120) - 60;
      final c = Offset(x, s.height * y);
      canvas.drawCircle(c, 18, cloud);
      canvas.drawCircle(c + const Offset(20, -8), 22, cloud);
      canvas.drawCircle(c + const Offset(42, 0), 17, cloud);
    }
    final hill = Path()
      ..moveTo(0, s.height * 0.82)
      ..quadraticBezierTo(
        s.width * 0.45,
        s.height * 0.62,
        s.width,
        s.height * 0.8,
      )
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xFFA9CC85));
  }

  @override
  bool shouldRepaint(_DayPainter o) => o.t != t;
}

class _NightPainter extends CustomPainter {
  _NightPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size s) {
    final rng = math.Random(7);
    for (var i = 0; i < 26; i++) {
      final p = Offset(
        rng.nextDouble() * s.width,
        rng.nextDouble() * s.height * 0.6,
      );
      final twinkle =
          0.45 + 0.55 * (0.5 + 0.5 * math.sin((t * 6 + i * 0.7) * math.pi));
      canvas.drawCircle(
        p,
        1.2 + rng.nextDouble() * 1.8,
        Paint()..color = Color.fromRGBO(255, 243, 214, twinkle),
      );
    }
    final hill = Path()
      ..moveTo(0, s.height * 0.8)
      ..quadraticBezierTo(
        s.width * 0.55,
        s.height * 0.64,
        s.width,
        s.height * 0.82,
      )
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xFF3F5B4A));
  }

  @override
  bool shouldRepaint(_NightPainter o) => o.t != t;
}
