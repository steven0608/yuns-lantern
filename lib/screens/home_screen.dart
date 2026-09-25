import 'dart:math' as math;

import '../core/audio/music_scope.dart';
import '../core/audio/audio_service.dart';

import 'package:flutter/material.dart';

import '../app.dart';
import '../books/books_screen.dart';
import '../core/app_scope.dart';
import '../core/art/item_art.dart';
import '../core/tokens.dart';
import '../core/ui/touch_target.dart';
import '../core/ui/yun.dart';
import '../l10n/app_localizations.dart';
import '../play/catalog_view.dart';
import '../play/lands_screen.dart';
import '../story/map_screen.dart';
import 'parent/parent_gate.dart';

/// The child's home (docs/EXPANSION.md §4): three big doors — Story (the
/// lantern map), Play (Lantern Lands) and Books (Lantern Tales). No text:
/// pictures and Yun's voice only. A door with nothing behind it (e.g. no
/// readable books yet) simply isn't there — never a locked door.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _greeted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_greeted) {
      _greeted = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.services.audio.playVO('ui.home'),
      );
    }
  }

  @override
  Widget build(BuildContext context) => MusicScope(
    track: Music.home,
    child: Builder(builder: _body),
  );

  Widget _body(BuildContext context) {
    final s = context.services;
    return ListenableBuilder(
      listenable: Listenable.merge([s.settings, s.progress]),
      builder: (context, _) {
        final doors = <Widget Function(double)>[
          (d) => _StoryDoor(size: d),
          if (s.allPlayable.isNotEmpty) (d) => _PlayDoor(size: d),
          if (s.shelves.isNotEmpty) (d) => _BooksDoor(size: d),
        ];
        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Design canvas "Home" board: illustrated hills, the dark lantern on the peak.
              Image.asset('assets/images/ui/home_bg.png', fit: BoxFit.cover),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, box) {
                    // HANDOFF §1: size class by the short side. On phones the
                    // grown-ups pill sits in the left column and Yun is décor, so
                    // the doors keep their full height.
                    final short = box.maxHeight < 560;
                    const gap = kMinTargetGap - kHitSlop;
                    final compact = short && box.maxWidth < 720; // iPhone SE-class
                final left = compact ? kMinTouchTarget + kHitSlop + 8 : (short ? 200.0 : box.maxWidth * 0.24);
                    final avail = box.maxWidth - left - 32 - kMinTargetGap;
                    final door = math
                        .min(
                          (avail - (doors.length - 1) * gap) / doors.length -
                              kHitSlop,
                          short ? box.maxHeight * 0.52 : box.maxHeight * 0.34,
                        )
                        .clamp(kMinTouchTarget, 260.0);
                    final grownUps = _GrownUpsButton(
                      compact: compact,
                      onTap: () => openParentArea(context),
                    );
                    return Stack(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: left,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (short) ...[
                                    grownUps,
                                    const SizedBox(height: gap),
                                  ],
                                  if (short)
                                    Expanded(
                                      child: IgnorePointer(
                                        child: FittedBox(
                                          child: Yun(
                                            size: 110,
                                            mood: YunMood.happy,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    TouchTarget(
                                      onTap: () => s.audio.playVO('ui.home'),
                                      child: Yun(
                                        size: math.min(
                                          left * 0.8,
                                          box.maxHeight * 0.34,
                                        ),
                                        mood: YunMood.happy,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: kMinTargetGap,
                                  right: 16,
                                  top: short ? 0 : 96,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (final (i, build)
                                          in doors.indexed) ...[
                                        if (i > 0) const SizedBox(width: gap),
                                        _Entrance(index: i, child: build(door)),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!short)
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: grownUps,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Entrance extends StatelessWidget {
  const _Entrance({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 450 + index * 120),
    curve: Curves.easeOutBack,
    builder: (_, t, c) => Transform.scale(scale: t, child: c),
    child: child,
  );
}

/// A big round door with a soft coloured rim and drop shadow.
class _Door extends StatelessWidget {
  const _Door({
    required this.size,
    required this.color,
    required this.onTap,
    required this.child,
    this.glow = 0.2,
  });
  final double size;
  final Color color;
  final VoidCallback onTap;
  final Widget child;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return TouchTarget(
      onTap: onTap,
      size: Size.square(size),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Palette.card, width: size * 0.035),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              offset: Offset(0, size * 0.045),
            ),
            BoxShadow(
              color: Palette.lantern.withValues(alpha: glow),
              blurRadius: 36,
              spreadRadius: 2,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// Story: the night sky with the white lantern, glowing brighter as lights
/// are collected.
class _StoryDoor extends StatelessWidget {
  const _StoryDoor({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final lights =
        s.progress.lightsCollected.length / s.content.story.chapters.length;
    final lantern = s.content.art.lightImage('white');
    return _Door(
      size: size,
      color: Palette.night,
      glow: 0.2 + 0.5 * lights,
      onTap: () => Navigator.of(context).push(softRoute(const MapScreen())),
      child: lantern != null
          ? Image.asset(lantern, height: size * 0.66)
          : Emoji('🏮', size: size * 0.45),
    );
  }
}

/// Play: a peek at four games through a warm round window.
class _PlayDoor extends StatelessWidget {
  const _PlayDoor({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final peek = [
      for (final g in s.allPlayable)
        if (s.content.art.tileImage(g.id) != null)
          s.content.art.tileImage(g.id)!,
    ].take(4).toList();
    final cell = size * 0.3;
    return _Door(
      size: size,
      color: const Color(0xFFF2B880),
      onTap: () => Navigator.of(context).push(softRoute(const LandsScreen())),
      child: peek.length < 4
          ? Emoji('🎈', size: size * 0.45)
          : SizedBox(
              width: cell * 2 + size * 0.04,
              child: Wrap(
                spacing: size * 0.04,
                runSpacing: size * 0.04,
                children: [
                  for (final p in peek)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(cell * 0.27),
                      child: Image.asset(p, width: cell, height: cell),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Books: an open storybook on the shelf colour.
class _BooksDoor extends StatelessWidget {
  const _BooksDoor({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return _Door(
      size: size,
      color: const Color(0xFF9CC9E8),
      onTap: () => Navigator.of(context).push(softRoute(const BooksScreen())),
      child: CustomPaint(
        size: Size.square(size * 0.62),
        painter: _BookPainter(),
      ),
    );
  }
}

class _BookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final cover = Paint()..color = Palette.rust;
    final pageP = Paint()..color = Palette.card;
    final line = Paint()
      ..color = Palette.paperDeep
      ..strokeWidth = h * 0.03
      ..strokeCap = StrokeCap.round;
    // cover behind, two page fans in front
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.2, w, h * 0.62),
        Radius.circular(w * 0.06),
      ),
      cover,
    );
    for (final left in [true, false]) {
      final p = Path()
        ..moveTo(w * 0.5, h * 0.28)
        ..quadraticBezierTo(
          w * (left ? 0.28 : 0.72),
          h * 0.14,
          w * (left ? 0.06 : 0.94),
          h * 0.2,
        )
        ..lineTo(w * (left ? 0.06 : 0.94), h * 0.74)
        ..quadraticBezierTo(
          w * (left ? 0.28 : 0.72),
          h * 0.68,
          w * 0.5,
          h * 0.8,
        )
        ..close();
      canvas.drawPath(p, pageP);
      for (var i = 0; i < 3; i++) {
        final y = h * (0.36 + i * 0.12);
        canvas.drawLine(
          Offset(w * (left ? 0.14 : 0.58), y),
          Offset(w * (left ? 0.42 : 0.86), y),
          line,
        );
      }
    }
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.12),
      w * 0.07,
      Paint()..color = Palette.lantern,
    );
  }

  @override
  bool shouldRepaint(_BookPainter o) => false;
}

/// For the parent, on the child's screen: understated, and it only leads to
/// the arithmetic gate.
class _GrownUpsButton extends StatelessWidget {
  const _GrownUpsButton({required this.onTap, this.compact = false});
  final VoidCallback onTap;

  /// Icon only, for the narrowest phones.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return RoundButton(
        icon: Icons.people_alt_outlined,
        onTap: onTap,
        color: const Color(0xEBFFF8EC),
        iconColor: Palette.ink,
        semanticLabel: AppLocalizations.of(context).grownUps,
      );
    }
    return TouchTarget(
      onTap: onTap,
      size: const Size(176, kMinTouchTarget),
      child: Center(
        child: Container(
          height: 52,
          padding: const EdgeInsets.fromLTRB(14, 0, 18, 0),
          decoration: BoxDecoration(
            color: const Color(0xEBFFF8EC),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFE0CDB0), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.people_alt_outlined,
                color: Palette.ink,
                size: 22,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppLocalizations.of(context).grownUps,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: const TextStyle(
                    color: Palette.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
