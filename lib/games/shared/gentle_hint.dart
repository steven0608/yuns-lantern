import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/tokens.dart';

/// What the demonstrating hand should do: slide from [from] to [to] (a drag),
/// or tap [from] when [to] is null.
class HintMove {
  const HintMove(this.from, [this.to]);
  final GlobalKey from;
  final GlobalKey? to;
}

/// Miss escalation + idle prompting (SPEC §7.3–7.4). The child always
/// eventually succeeds: every path ends with a hand showing the answer.
///
///  miss 1 → item returns, neutral sound, a "try another" line
///  miss 2 → the correct target pulses          ([level] 1)
///  miss 3 → a hand animates the correct move   ([level] 2)
///  idle 8s → replay the short prompt; idle 20s → demonstrate.
class HintController {
  HintController({
    required this.speak,
    required this.onIdlePrompt,
    math.Random? random,
  }) : _rng = random ?? math.Random();

  /// Plays a VO line (injected so this stays testable without audio).
  final void Function(String key) speak;
  final VoidCallback onIdlePrompt;
  final math.Random _rng;

  /// 0 = no help, 1 = pulse the correct target, 2 = hand demonstration.
  final ValueNotifier<int> level = ValueNotifier(0);
  final ValueNotifier<HintMove?> hand = ValueNotifier(null);

  /// The game describes its current correct move here; null = nothing to show.
  HintMove? Function()? guide;

  int _misses = 0;
  Timer? _idle;
  bool _active = false;
  final Map<String, String> _lastLine = {};

  static const _retry = ['feedback.retry1', 'feedback.retry2'];
  static const _help = ['feedback.hint1', 'feedback.hint2'];

  /// Rotate lines so the same one never plays twice running (§7.3).
  String rotate(List<String> pool) {
    final key = pool.join('|');
    final options = pool.where((l) => l != _lastLine[key]).toList();
    final pick = options[_rng.nextInt(options.length)];
    _lastLine[key] = pick;
    return pick;
  }

  void start() {
    _active = true;
    _restartIdle();
  }

  void stop() {
    _active = false;
    _idle?.cancel();
    hand.value = null;
  }

  /// Any touch counts as activity and pushes the idle prompt back.
  void touched() {
    if (_active) _restartIdle();
  }

  void miss() {
    _misses++;
    touched();
    if (_misses == 1) {
      speak(rotate(_retry));
    } else if (_misses == 2) {
      level.value = 1;
      speak(rotate(_retry));
    } else {
      demonstrate();
    }
  }

  /// Call after each correct step: help resets for the next goal.
  void succeeded() {
    _misses = 0;
    level.value = 0;
    hand.value = null;
    touched();
  }

  void demonstrate() {
    level.value = 2;
    speak(rotate(_help));
    hand.value = guide?.call();
  }

  void _restartIdle() {
    _idle?.cancel();
    _idle = Timer(kIdleHintDelay, () {
      if (!_active) return;
      onIdlePrompt();
      _idle = Timer(kIdleHintRepeat, () {
        if (_active) demonstrate();
      });
    });
  }

  void dispose() {
    _idle?.cancel();
    level.dispose();
    hand.dispose();
  }
}

/// Soft breathing glow around the correct target when [active]. Never red,
/// never flashing — a gentle invitation, not a warning.
class GentlePulse extends StatefulWidget {
  const GentlePulse({super.key, required this.active, required this.child, this.radius = 28});
  final bool active;
  final Widget child;
  final double radius;

  @override
  State<GentlePulse> createState() => _GentlePulseState();
}

class _GentlePulseState extends State<GentlePulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(GentlePulse old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) _c.repeat(reverse: true);
    if (!widget.active && _c.isAnimating) _c.animateTo(0, duration: kStandardEase);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.scale(
          scale: 1 + 0.06 * t,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: [
                BoxShadow(color: Palette.lantern.withValues(alpha: 0.65 * t), blurRadius: 30 * t, spreadRadius: 10 * t),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Draws the demonstrating hand for [HintController.hand]. Lives in the
/// activity scaffold's overlay layer, above the game.
class HintHandLayer extends StatefulWidget {
  const HintHandLayer({super.key, required this.hints});
  final HintController hints;

  @override
  State<HintHandLayer> createState() => _HintHandLayerState();
}

class _HintHandLayerState extends State<HintHandLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  HintMove? _move;
  int _loops = 0;
  Timer? _loop; // pause between demonstrations; cancelled on dispose

  @override
  void initState() {
    super.initState();
    widget.hints.hand.addListener(_changed);
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && _move != null && ++_loops < 3) {
        _loop?.cancel();
        _loop = Timer(const Duration(milliseconds: 350), () {
          if (mounted && _move != null) _c.forward(from: 0);
        });
      }
    });
  }

  void _changed() {
    setState(() {
      _move = widget.hints.hand.value;
      _loops = 0;
    });
    if (_move != null) _c.forward(from: 0);
  }

  @override
  void dispose() {
    widget.hints.hand.removeListener(_changed);
    _loop?.cancel();
    _c.dispose();
    super.dispose();
  }

  final GlobalKey _layer = GlobalKey();

  /// Centre of [k] in this layer's coordinates. Only valid after layout, so it
  /// is called from paint — reading render boxes during build asserts.
  Offset? _centerOf(GlobalKey? k) {
    final box = k?.currentContext?.findRenderObject() as RenderBox?;
    final me = _layer.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || me == null || !box.attached || !me.attached || !box.hasSize) return null;
    return me.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  }

  @override
  Widget build(BuildContext context) {
    if (_move == null) return const SizedBox.expand();
    return IgnorePointer(
      child: CustomPaint(key: _layer, size: Size.infinite, painter: _HandPainter(this)),
    );
  }
}

class _HandPainter extends CustomPainter {
  _HandPainter(this.state) : super(repaint: state._c);
  final _HintHandLayerState state;

  static final TextPainter _hand = TextPainter(
    text: const TextSpan(text: '👆', style: TextStyle(fontSize: 64, shadows: [Shadow(color: Palette.shadow, blurRadius: 8)])),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final move = state._move;
    if (move == null) return;
    final a = state._centerOf(move.from);
    if (a == null) return;
    final b = state._centerOf(move.to) ?? a;
    final t = state._c.value;
    // press (0–.2), travel (.2–.75), release (.75–1)
    final travel = Curves.easeInOut.transform(((t - 0.2) / 0.55).clamp(0.0, 1.0));
    final pos = Offset.lerp(a, b, travel)!;
    final press = t < 0.2 ? t / 0.2 : (t > 0.75 ? 1 - (t - 0.75) / 0.25 : 1.0);
    final opacity = (t > 0.9 ? (1 - t) / 0.1 : math.min(1.0, t / 0.08)).clamp(0.0, 1.0);
    canvas.save();
    canvas.translate(pos.dx - 10, pos.dy - 6);
    canvas.scale(1.0 - 0.15 * press);
    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
    _hand.paint(canvas, Offset.zero);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HandPainter old) => true;
}
