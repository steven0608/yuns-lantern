import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/art/item_art.dart';
import '../../core/audio/audio_service.dart';
import '../../core/tokens.dart';
import '../../core/ui/touch_target.dart';
import 'gentle_hint.dart';

/// The soft rounded card every item sits on. Purely visual.
class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    this.id,
    this.child,
    this.size = 104,
    this.color = Palette.card,
    this.silhouette = false,
    this.elevated = true,
  });
  final String? id;
  final Widget? child;
  final double size;
  final Color color;
  final bool silhouette;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(color: Palette.paper, width: 3),
        boxShadow: elevated ? const [BoxShadow(color: Palette.shadow, blurRadius: 10, offset: Offset(0, 6))] : null,
      ),
      alignment: Alignment.center,
      child: child ?? (id == null ? null : ItemArt(id!, size: size * 0.58, silhouette: silhouette)),
    );
  }
}

/// A tap-to-answer card for tap games (Find the Same, What Is It?, …).
/// Wrong taps wobble gently and escalate help; there is no red, no X.
class ChoiceCard extends StatefulWidget {
  const ChoiceCard({
    super.key,
    required this.id,
    required this.correct,
    required this.hints,
    required this.onCorrect,
    this.size = 120,
    this.child,
    this.hintKey,
  });

  final String id;
  final bool correct;
  final HintController hints;
  final VoidCallback onCorrect;
  final double size;
  final Widget? child;

  /// Attach so the hint hand can point at the right answer.
  final GlobalKey? hintKey;

  @override
  State<ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<ChoiceCard> with SingleTickerProviderStateMixin {
  late final AnimationController _wobble = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void dispose() {
    _wobble.dispose();
    super.dispose();
  }

  void _tap() {
    if (widget.correct) {
      widget.hints.succeeded();
      widget.onCorrect();
    } else {
      _wobble.forward(from: 0);
      widget.hints.miss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.hints.level,
      builder: (_, level, child) => GentlePulse(active: widget.correct && level >= 1, child: child!),
      child: AnimatedBuilder(
        animation: _wobble,
        builder: (_, child) {
          final t = _wobble.value;
          return Transform.rotate(angle: 0.08 * (1 - t) * math.sin(t * 18), child: child);
        },
        child: TouchTarget(
          key: widget.hintKey,
          onTap: _tap,
          sound: widget.correct ? Sfx.snap : Sfx.tap,
          size: Size.square(widget.size),
          child: ItemCard(id: widget.id, size: widget.size, child: widget.child),
        ),
      ),
    );
  }

}
