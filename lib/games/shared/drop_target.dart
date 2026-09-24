import 'package:flutter/material.dart';

import '../../core/tokens.dart';
import 'gentle_hint.dart';

/// Registry of the drop targets on screen, so a released [DraggableItem] can
/// find the nearest one. Provided by ActivityScaffold.
class DropZoneScope extends InheritedWidget {
  DropZoneScope({super.key, required super.child});

  final List<DropTargetState> _targets = [];

  /// True while any item is being dragged: a second finger can't start
  /// another drag (no multi-finger anywhere — CLAUDE.md).
  final ValueNotifier<bool> dragging = ValueNotifier(false);

  static DropZoneScope? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DropZoneScope>();

  /// Target whose bounds, grown by [kSnapRadius], contain [global]. Where
  /// several overlap, the nearest centre wins.
  DropTargetState? targetAt(Offset global) {
    DropTargetState? best;
    var bestDist = double.infinity;
    for (final t in _targets) {
      final r = t.globalRect;
      if (r == null || !t.widget.enabled) continue;
      if (!r.inflate(kSnapRadius).contains(global)) continue;
      final d = (r.center - global).distanceSquared;
      if (d < bestDist) {
        bestDist = d;
        best = t;
      }
    }
    return best;
  }

  @override
  bool updateShouldNotify(DropZoneScope old) => false;
}

/// A place items can be dropped. The game decides what's correct via
/// [willAccept]; a wrong drop calls [onReject] (the game then escalates help
/// through its [HintController]) and the item floats home — no penalty.
class DropTarget extends StatefulWidget {
  const DropTarget({
    super.key,
    required this.id,
    required this.child,
    required this.willAccept,
    required this.onAccept,
    this.onReject,
    this.pulse = false,
    this.enabled = true,
    this.radius = 28,
  });

  final String id;
  final Widget child;
  final bool Function(String data) willAccept;
  final void Function(String data) onAccept;
  final void Function(String data)? onReject;

  /// Hint level ≥1 on the correct target.
  final bool pulse;
  final bool enabled;
  final double radius;

  @override
  State<DropTarget> createState() => DropTargetState();
}

class DropTargetState extends State<DropTarget> {
  DropZoneScope? _scope;
  final ValueNotifier<bool> hovered = ValueNotifier(false);

  Rect? get globalRect {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope?._targets.remove(this);
    _scope = DropZoneScope.of(context);
    _scope?._targets.add(this);
  }

  @override
  void dispose() {
    _scope?._targets.remove(this);
    hovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GentlePulse(
      active: widget.pulse,
      radius: widget.radius,
      child: ValueListenableBuilder<bool>(
        valueListenable: hovered,
        builder: (_, over, child) => AnimatedScale(
          scale: over ? 1.06 : 1.0,
          duration: kStandardEase,
          curve: kStandardCurve,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
