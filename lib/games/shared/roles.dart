import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/tokens.dart';

/// The visual grammar (design/UX_GRAMMAR.md). Every element on a game screen is
/// exactly one of four roles, and the marks are the same in all 15 engines, so
/// the grammar learned in Count and Feed transfers to Mirror Match.
///
/// The physical rule that carries it, and the reason a child reads it with no
/// instruction: **a shadow means you can lift it; a hole means something goes
/// in it.** Nothing outside this file may use those two shadows.
abstract final class Role {
  /// Take — you can pick this up or tap it.
  static const takeShadow = [BoxShadow(color: Color(0x294A3426), blurRadius: 0, offset: Offset(0, 7))];

  /// Hold — it goes here. Recessed, never raised.
  static const holdInset = BoxShadow(color: Color(0x334A3426), blurRadius: 0, offset: Offset(0, 3), spreadRadius: -1);

  /// Ask — this is the one the question is about.
  static const askHalo = [
    BoxShadow(color: Color(0x57E8A93C), spreadRadius: 10),
    BoxShadow(color: Color(0x24E8A93C), spreadRadius: 24),
  ];

  static const ghostOpacity = 0.18;
  static const dashColor = Color(0x739E4726); // rustDeep @ 45%
  static const shelf = Color(0xFFB5835A);
  static const shelfEdge = Color(0xFF8C6240);

  /// Entry choreography (§3): the eye is led before any sound arrives.
  static const entry = Duration(milliseconds: 1400);
  static const askPulseAt = Duration.zero;
  static const ghostsFadeAt = Duration(milliseconds: 300);
  static const trayBobAt = Duration(milliseconds: 700);
}

/// Drives the 1.4s entry choreography for one round. Role widgets read it and
/// pick their own window; nothing fades the whole screen in.
class RoundEntry extends InheritedWidget {
  const RoundEntry({super.key, required this.t, required super.child});

  /// Elapsed time since the round appeared.
  final Animation<double> t;

  static Animation<double>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RoundEntry>()?.t;

  /// 0 → 1 across [window] starting at [begin]; 1 when there is no entry
  /// animation (tests, or a widget rebuilt later in the round).
  static double phase(BuildContext context, Duration begin, {Duration window = const Duration(milliseconds: 400), int index = 0, Duration stagger = Duration.zero}) {
    final t = of(context);
    if (t == null) return 1;
    final start = begin.inMilliseconds + stagger.inMilliseconds * index;
    final ms = t.value * Role.entry.inMilliseconds;
    return ((ms - start) / window.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  bool updateShouldNotify(RoundEntry old) => old.t != t;
}

/// **Take** — a thing the child can pick up. Wrap the visual, not the gesture:
/// [DraggableItem] and [TouchTarget] still own the touch.
class TakeSurface extends StatelessWidget {
  const TakeSurface({super.key, required this.child, this.borderRadius, this.shape = BoxShape.rectangle, this.index = 0, this.bob = true});
  final Widget child;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  /// Position in the tray, for the staggered idle bob and the entry bob.
  final int index;
  final bool bob;

  @override
  Widget build(BuildContext context) {
    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: Role.takeShadow,
        borderRadius: shape == BoxShape.rectangle ? (borderRadius ?? BorderRadius.circular(26)) : null,
        shape: shape,
      ),
      child: child,
    );
    if (!bob) return decorated;
    return _IdleBob(index: index, child: decorated);
  }
}

/// The only continuous animation allowed (§5): -4px over 2.4s, staggered, so
/// takeable things look alive without competing with the hint.
class _IdleBob extends StatefulWidget {
  const _IdleBob({required this.child, required this.index});
  final Widget child;
  final int index;

  @override
  State<_IdleBob> createState() => _IdleBobState();
}

class _IdleBobState extends State<_IdleBob> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offset = widget.index * 0.05; // 120ms of a 2.4s cycle
    // Entry: the tray bobs once, left to right, before settling into the idle.
    final entry = RoundEntry.phase(context, Role.trayBobAt, window: const Duration(milliseconds: 420), index: widget.index, stagger: const Duration(milliseconds: 60));
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final idle = -4 * (0.5 - 0.5 * math.cos((_c.value + offset) * 2 * math.pi));
        final hop = entry > 0 && entry < 1 ? -14 * math.sin(entry * math.pi) : 0.0;
        return Transform.translate(offset: Offset(0, idle + hop), child: child);
      },
      child: widget.child,
    );
  }
}

/// **Hold** — where a thing goes. Recessed, dashed, and showing a ghost of what
/// belongs, so a child sees *what* goes there, not merely that something does.
class HoldSlot extends StatelessWidget {
  const HoldSlot({
    super.key,
    required this.size,
    this.ghost,
    this.filled,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.index = 0,
    this.highlight = false,
  });

  final Size size;

  /// The art of the item that belongs here, drawn at 18%.
  final Widget? ghost;

  /// Once filled, the dash and ghost go and the item is raised instead.
  final Widget? filled;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final int index;

  /// The hint is pointing here (level ≥ 1): the slot warms, never flashes.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final radius = shape == BoxShape.rectangle ? (borderRadius ?? BorderRadius.circular(22)) : null;
    if (filled != null) {
      return SizedBox.fromSize(
        size: size,
        child: DecoratedBox(
          decoration: BoxDecoration(boxShadow: Role.takeShadow, borderRadius: radius, shape: shape),
          child: filled,
        ),
      );
    }
    final fade = RoundEntry.phase(context, Role.ghostsFadeAt, index: index, stagger: const Duration(milliseconds: 80));
    return SizedBox.fromSize(
      size: size,
      child: CustomPaint(
        painter: _HoldPainter(radius: radius, circle: shape == BoxShape.circle, warm: highlight),
        child: ghost == null
            ? null
            : Center(
                child: Opacity(
                  opacity: Role.ghostOpacity * fade,
                  child: ghost,
                ),
              ),
      ),
    );
  }
}

class _HoldPainter extends CustomPainter {
  _HoldPainter({required this.radius, required this.circle, required this.warm});
  final BorderRadius? radius;
  final bool circle;
  final bool warm;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path();
    if (circle) {
      path.addOval(rect);
    } else {
      path.addRRect((radius ?? BorderRadius.circular(22)).toRRect(rect));
    }
    // sunk into the surface: a soft dark lip along the top inside edge
    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(
      path.shift(const Offset(0, 3)),
      Paint()
        ..color = warm ? const Color(0x22E8A93C) : const Color(0x1F4A3426)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(path, Paint()..color = warm ? const Color(0x1AE8A93C) : const Color(0x0F4A3426));
    canvas.restore();
    _dash(canvas, path, Paint()
      ..color = warm ? Palette.lantern : Role.dashColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round);
  }

  /// 10-on / 8-off dashes: "something goes here", the app's only use of dashes.
  void _dash(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 10, metric.length)), paint);
        d += 18;
      }
    }
  }

  @override
  bool shouldRepaint(_HoldPainter o) => o.warm != warm || o.circle != circle;
}

/// **Ask** — the one the question is about: two soft cream rings, alone at top
/// centre, slightly larger than the choices. Never dashed.
class AskSpotlight extends StatefulWidget {
  const AskSpotlight({super.key, required this.child, this.shape = BoxShape.circle, this.borderRadius});
  final Widget child;
  final BoxShape shape;
  final BorderRadius? borderRadius;

  @override
  State<AskSpotlight> createState() => _AskSpotlightState();
}

class _AskSpotlightState extends State<AskSpotlight> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        // one pulse on entry, then it simply sits there haloed
        final p = math.sin(Curves.easeOut.transform(_pulse.value) * math.pi);
        return Transform.scale(
          scale: 1.06 + 0.04 * p,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: widget.shape,
              borderRadius: widget.shape == BoxShape.rectangle ? (widget.borderRadius ?? BorderRadius.circular(28)) : null,
              boxShadow: [
                BoxShadow(color: const Color(0xFFE8A93C).withValues(alpha: 0.34 + 0.2 * p), spreadRadius: 10 + 6 * p),
                BoxShadow(color: const Color(0xFFE8A93C).withValues(alpha: 0.14 + 0.1 * p), spreadRadius: 24 + 10 * p),
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

/// **Scene** — décor. No shadow of any kind, so it can never be mistaken for
/// something to touch.
class SceneLayer extends StatelessWidget {
  const SceneLayer({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Opacity(
          opacity: 0.88,
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.9111, 0.0779, 0.0110, 0, 0, //
              0.0289, 0.9601, 0.0110, 0, 0,
              0.0289, 0.0779, 0.8932, 0, 0,
              0, 0, 0, 1, 0,
            ]),
            child: child,
          ),
        ),
      );
}

/// The shelf the takeable things rest on. A bare row of floating pictures does
/// not read as "these are mine to move"; a surface does. The only horizontal
/// line in the lower third.
class TrayShelf extends StatelessWidget {
  const TrayShelf({super.key, required this.children, this.spacing = kMinTargetGap - kHitSlop});
  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(height: 12, decoration: const BoxDecoration(color: Role.shelf, borderRadius: BorderRadius.all(Radius.circular(6)))),
              Container(
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: const BoxDecoration(color: Role.shelfEdge, borderRadius: BorderRadius.vertical(bottom: Radius.circular(4))),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: spacing,
              runSpacing: 8,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
