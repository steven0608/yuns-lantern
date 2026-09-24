import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app.dart';
import '../core/app_scope.dart';
import '../core/art/item_art.dart';
import '../core/tokens.dart';
import '../core/ui/touch_target.dart';
import '../core/ui/yun.dart';
import '../games/registry.dart';
import '../games/shared/activity_scaffold.dart';
import '../story/map_screen.dart';
import 'parent/parent_gate.dart';

/// The child's home. No text: pictures and Yun's voice only (§9). Only
/// activities the child may play are shown — paid or too-old content is
/// simply absent, never padlocked (CLAUDE.md).
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
      WidgetsBinding.instance.addPostFrameCallback((_) => context.services.audio.playVO('ui.home'));
    }
  }

  void _open(GameDef g) {
    Navigator.of(context).push(softRoute(ActivitySession(game: g)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    return ListenableBuilder(
      listenable: Listenable.merge([s.settings, s.progress]),
      builder: (context, _) {
        final games = [
          for (final id in s.content.activities.keys)
            if (gameRegistry[id] != null && s.activityVisible(id)) gameRegistry[id]!,
        ];
        return Scaffold(
          body: Stack(fit: StackFit.expand, children: [
            const CustomPaint(painter: HillsPainter()),
            SafeArea(
              child: LayoutBuilder(builder: (context, box) {
                final short = box.maxHeight < 560;
                final tile = short ? 108.0 : 150.0;
                return Row(children: [
                  SizedBox(
                    width: box.maxWidth * (short ? 0.28 : 0.3),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      TouchTarget(
                        onTap: () => s.audio.playVO('ui.home'),
                        child: Yun(size: short ? 110 : 190),
                      ),
                      const SizedBox(height: kMinTargetGap - kHitSlop),
                      _MapButton(size: short ? 104 : 150),
                    ]),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SizedBox(
                          height: math.min(box.maxHeight, (tile + kMinTargetGap) * (short ? 2 : 3)),
                          child: Wrap(
                            direction: Axis.vertical,
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            spacing: kMinTargetGap - kHitSlop,
                            runSpacing: kMinTargetGap - kHitSlop,
                            children: [
                              for (final (i, g) in games.indexed) _ActivityTile(game: g, size: tile, index: i, onTap: () => _open(g)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ]);
              }),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  // Low-key on purpose: this leads to the grown-up area.
                  child: RoundButton(
                    icon: Icons.tune_rounded,
                    color: const Color(0x55FFF8EC),
                    iconColor: Palette.inkSoft,
                    onTap: () => openParentArea(context),
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

const _tileColors = [
  Color(0xFFF2B880), Color(0xFFA8D5A2), Color(0xFF9CC9E8), Color(0xFFF5A3A3),
  Color(0xFFC8B4E6), Color(0xFFF7D774), Color(0xFF8FD3C8), Color(0xFFF2A7C8),
];

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.game, required this.size, required this.index, required this.onTap});
  final GameDef game;
  final double size;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = context.services.content.art.activityIcons[game.id] ?? '⭐';
    final color = _tileColors[index % _tileColors.length];
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 70),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.scale(scale: t, child: child),
      child: TouchTarget(
        onTap: onTap,
        size: Size.square(size),
        semanticLabel: context.services.content.activities[game.id]!.name.of(context.lang),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size * 0.28),
            border: Border.all(color: Palette.card, width: 5),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          alignment: Alignment.center,
          child: Emoji(icon, size: size * 0.5),
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final lights = context.services.progress.lightsCollected.length;
    return TouchTarget(
      onTap: () => Navigator.of(context).push(softRoute(const MapScreen())),
      size: Size.square(size),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(colors: [Color(0xFFFFE2A0), Palette.lantern]),
          border: Border.all(color: Palette.card, width: 5),
          boxShadow: [BoxShadow(color: Palette.lantern.withValues(alpha: 0.35 + 0.08 * lights), blurRadius: 30, spreadRadius: 4)],
        ),
        alignment: Alignment.center,
        child: Emoji('🏮', size: size * 0.48),
      ),
    );
  }
}

/// Soft rolling hills under a warm sky. Shared by home and map.
class HillsPainter extends CustomPainter {
  const HillsPainter({this.sky = const [Color(0xFFFCE3C0), Color(0xFFF9EEDB)], this.hills = const [Color(0xFFBFD8A0), Color(0xFFA5C987)]});
  final List<Color> sky;
  final List<Color> hills;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sky).createShader(Offset.zero & s));
    canvas.drawCircle(Offset(s.width * 0.85, s.height * 0.18), s.shortestSide * 0.09, Paint()..color = const Color(0x55FFD27A));
    for (final (i, c) in hills.indexed) {
      final y = s.height * (0.72 + i * 0.1);
      final p = Path()..moveTo(0, y);
      for (var x = 0.0; x <= s.width; x += 20) {
        p.lineTo(x, y + math.sin(x / s.width * math.pi * (2 + i) + i) * s.height * 0.05);
      }
      p
        ..lineTo(s.width, s.height)
        ..lineTo(0, s.height)
        ..close();
      canvas.drawPath(p, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(HillsPainter o) => o.sky != sky || o.hills != hills;
}
