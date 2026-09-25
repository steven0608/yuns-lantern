import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/audio/audio_service.dart';
import '../core/tokens.dart';
import '../core/ui/touch_target.dart';
import '../core/ui/yun.dart';

/// Web-only framing (design/HANDOFF.md §1). On iPhone/iPad this is a no-op:
/// the app is landscape-locked and fills the screen.
///  * Desktop: the stage is capped at 1366×1024 and centred on paper, never stretched.
///  * Portrait phone: a picture of Yun turning a phone — no text for pre-readers.
class WebStage extends StatelessWidget {
  const WebStage({super.key, required this.child, this.force = false});
  final Widget child;

  /// Tests set this to exercise the web framing on the VM.
  final bool force;

  static const maxStage = Size(1366, 1024);

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && !force) return child;
    final size = MediaQuery.sizeOf(context);
    if (size.height > size.width) return const _TurnYourPhone();
    final w = math.min(size.width, maxStage.width);
    final h = math.min(size.height, maxStage.height);
    if (w == size.width && h == size.height) return child;
    return ColoredBox(
      color: Palette.paper,
      child: Center(
        child: SizedBox(
          width: w,
          height: h,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: MediaQuery(data: MediaQuery.of(context).copyWith(size: Size(w, h)), child: child),
          ),
        ),
      ),
    );
  }
}

class _TurnYourPhone extends StatefulWidget {
  const _TurnYourPhone();

  @override
  State<_TurnYourPhone> createState() => _TurnYourPhoneState();
}

class _TurnYourPhoneState extends State<_TurnYourPhone> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Palette.paper,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Yun(size: 150, mood: YunMood.happy),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _c,
            builder: (_, child) {
              // hold upright, turn a quarter, hold sideways, turn back
              final t = _c.value;
              final turn = t < 0.25 ? 0.0 : t < 0.5 ? Curves.easeInOut.transform((t - 0.25) / 0.25) : t < 0.8 ? 1.0 : 1 - Curves.easeInOut.transform((t - 0.8) / 0.2);
              return Transform.rotate(angle: -math.pi / 2 * turn, child: child);
            },
            child: Container(
              width: 70,
              height: 120,
              decoration: BoxDecoration(
                color: Palette.night,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Palette.ink, width: 4),
              ),
              padding: const EdgeInsets.all(6),
              child: DecoratedBox(
                decoration: BoxDecoration(color: Palette.lantern, borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Web start screen: browsers only allow sound after a user gesture, so the
/// first thing the child does is tap Yun — which is also a friendly hello.
class WebStartGate extends StatefulWidget {
  const WebStartGate({super.key, required this.child, this.force = false});
  final Widget child;
  final bool force;

  @override
  State<WebStartGate> createState() => _WebStartGateState();
}

class _WebStartGateState extends State<WebStartGate> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    if ((!kIsWeb && !widget.force) || _started) return widget.child;
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/images/ui/home_bg.png', fit: BoxFit.cover),
        Center(
          child: TouchTarget(
            sound: Sfx.sparkle,
            onTap: () {
              setState(() => _started = true);
              context.services.audio.playVO('ui.home');
            },
            child: const _Breathing(child: Yun(size: 220, mood: YunMood.happy)),
          ),
        ),
      ]),
    );
  }
}

class _Breathing extends StatefulWidget {
  const _Breathing({required this.child});
  final Widget child;

  @override
  State<_Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<_Breathing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: Tween(begin: 0.96, end: 1.04).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Palette.lantern.withValues(alpha: 0.35), blurRadius: 60, spreadRadius: 10)],
          ),
          child: widget.child,
        ),
      );
}
