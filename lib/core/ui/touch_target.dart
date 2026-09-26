import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../audio/audio_service.dart';
import '../tokens.dart';

/// Toggle with the debug overlay button to draw every target's bounds.
final ValueNotifier<bool> showTargetBounds = ValueNotifier(false);

/// The only way child UI becomes tappable. Guarantees (CLAUDE.md, enforced in
/// code not review):
///  * visible size ≥ [kMinTouchTarget], plus [kHitSlop] invisible slop;
///  * single tap only — no double-tap / long-press recognisers exist here;
///  * immediate feedback: scale bump + soft sound on every touch.
/// Widget tests find every [TouchTarget] and assert these sizes.
class TouchTarget extends StatefulWidget {
  const TouchTarget({
    super.key,
    required this.child,
    required this.onTap,
    this.size,
    this.sound = Sfx.tap,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Size? size;
  final Sfx? sound;
  final String? semanticLabel;

  @override
  State<TouchTarget> createState() => _TouchTargetState();
}

class _TouchTargetState extends State<TouchTarget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void dispose() {
    _bump.dispose();
    super.dispose();
  }

  void _down() {
    _bump.forward(from: 0);
    if (widget.sound != null) context.services.audio.sfx(widget.sound!);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    Widget visible = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: kMinTouchTarget,
        minHeight: kMinTouchTarget,
      ),
      child: s == null
          ? widget.child
          : SizedBox.fromSize(size: s, child: widget.child),
    );
    visible = AnimatedBuilder(
      animation: _bump,
      builder: (_, child) {
        final t = _bump.value;
        final scale = 1 + 0.12 * (t < 0.4 ? t / 0.4 : (1 - t) / 0.6);
        return Transform.scale(scale: scale, child: child);
      },
      child: visible,
    );
    if (kDebugMode) {
      visible = ValueListenableBuilder<bool>(
        valueListenable: showTargetBounds,
        builder: (_, on, child) => on
            ? DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE040FB), width: 2),
                ),
                child: child,
              )
            : child!,
        child: visible,
      );
    }
    // Hit slop: an invisible margin that still receives the tap. Negative
    // margins don't exist in Flutter, so parents lay out the padded size.
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _down(),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(kHitSlop / 2),
          child: visible,
        ),
      ),
    );
  }
}

/// A round, friendly icon button for chrome (home, replay, next).
class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = Palette.cream,
    this.iconColor = Palette.rustDeep,
    this.diameter = kMinTouchTarget,
    this.semanticLabel,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;
  final double diameter;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return TouchTarget(
      onTap: onTap,
      semanticLabel: semanticLabel,
      size: Size.square(diameter),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Palette.shadow,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
          border: Border.all(color: Palette.paper, width: 4),
        ),
        child: Icon(icon, color: iconColor, size: diameter * 0.5),
      ),
    );
  }
}

/// The house button always means Home — never "back one screen". A child who
/// taps it from a game inside a land inside Play lands on the three doors.
void goHome(BuildContext context) {
  context.services.audio.stopVO();
  Navigator.of(context).popUntil((route) => route.isFirst);
}
