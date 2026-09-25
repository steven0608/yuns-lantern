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
import '../l10n/app_localizations.dart';
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
            // Design canvas "Home" board: illustrated hills with the dark lantern on its peak.
            Image.asset('assets/images/ui/home_bg.png', fit: BoxFit.cover),
            SafeArea(
              child: LayoutBuilder(builder: (context, box) {
                final short = box.maxHeight < 560;
                final door = short ? 104.0 : (box.maxHeight * 0.24).clamp(120.0, 200.0);
                final left = short ? box.maxWidth * 0.26 : box.maxWidth * 0.3;
                return Row(children: [
                  SizedBox(
                    width: left,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _StoryDoor(size: door),
                      const SizedBox(height: kMinTargetGap - kHitSlop),
                      TouchTarget(
                        onTap: () => s.audio.playVO('ui.home'),
                        child: Yun(size: short ? 96 : door * 0.95, mood: YunMood.happy),
                      ),
                    ]),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: short ? 8 : 72, right: 16, bottom: 8),
                      child: _TileGrid(games: games, onOpen: _open),
                    ),
                  ),
                ]);
              }),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(padding: const EdgeInsets.all(4), child: _GrownUpsButton(onTap: () => openParentArea(context))),
              ),
            ),
          ]),
        );
      },
    );
  }
}

/// Lays the activity tiles out as large as the space allows (up to 150px),
/// keeping 88px targets and 64px gaps; falls back to a sideways-scrolling
/// strip on short phone screens rather than shrinking below the minimum.
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.games, required this.onOpen});
  final List<GameDef> games;
  final void Function(GameDef) onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      const gap = kMinTargetGap - kHitSlop; // + 2×12px slop = 64 visible
      final n = games.length;
      if (n == 0) return const SizedBox();
      double fit(int cols, int rows) => math.min(
            (box.maxWidth - (cols - 1) * gap) / cols - kHitSlop,
            (box.maxHeight - (rows - 1) * gap) / rows - kHitSlop,
          );
      var best = 0.0;
      var cols = 1;
      for (var c = 1; c <= math.min(n, 6); c++) {
        final t = math.min(fit(c, (n / c).ceil()), 150.0);
        if (t > best) {
          best = t;
          cols = c;
        }
      }
      if (best >= kMinTouchTarget) {
        return Center(
          child: SizedBox(
            width: cols * (best + kHitSlop) + (cols - 1) * gap,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: gap,
              runSpacing: gap,
              children: [for (final (i, g) in games.indexed) _ActivityTile(game: g, size: best, index: i, onTap: () => onOpen(g))],
            ),
          ),
        );
      }
      final rows = math.max(1, ((box.maxHeight + gap) / (kMinTouchTarget + kHitSlop + gap)).floor());
      final tile = math.max(kMinTouchTarget, (box.maxHeight - (rows - 1) * gap) / rows - kHitSlop);
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          height: box.maxHeight,
          child: Wrap(
            direction: Axis.vertical,
            alignment: WrapAlignment.center,
            spacing: gap,
            runSpacing: gap,
            children: [for (final (i, g) in games.indexed) _ActivityTile(game: g, size: tile, index: i, onTap: () => onOpen(g))],
          ),
        ),
      );
    });
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.game, required this.size, required this.index, required this.onTap});
  final GameDef game;
  final double size;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final art = context.services.content.art;
    final image = art.tileImage(game.id);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 70),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.scale(scale: t, child: child),
      child: TouchTarget(
        onTap: onTap,
        size: Size.square(size),
        semanticLabel: context.services.content.activities[game.id]!.name.of(context.lang),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.27),
            boxShadow: const [BoxShadow(color: Palette.shadow, offset: Offset(0, 7))],
          ),
          child: image != null
              ? Image.asset(image, width: size, height: size)
              : Container(
                  decoration: BoxDecoration(color: Palette.card, borderRadius: BorderRadius.circular(size * 0.27)),
                  alignment: Alignment.center,
                  child: Emoji(art.activityIcons[game.id] ?? '⭐', size: size * 0.5),
                ),
        ),
      ),
    );
  }
}

/// The way into story mode: the night sky with the white lantern, glowing
/// brighter as lights are collected.
class _StoryDoor extends StatelessWidget {
  const _StoryDoor({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final lights = s.progress.lightsCollected.length / s.content.story.chapters.length;
    final lantern = s.content.art.lightImage('white');
    return TouchTarget(
      onTap: () => Navigator.of(context).push(softRoute(const MapScreen())),
      size: Size.square(size),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Palette.night,
          boxShadow: [
            const BoxShadow(color: Color(0x4D3A3D6B), offset: Offset(0, 8)),
            BoxShadow(color: Palette.lantern.withValues(alpha: 0.2 + 0.5 * lights), blurRadius: 30, spreadRadius: 2),
          ],
        ),
        alignment: Alignment.center,
        child: lantern != null ? Image.asset(lantern, height: size * 0.72) : Emoji('🏮', size: size * 0.48),
      ),
    );
  }
}

/// For the parent, on the child's screen: understated, top-right, and it only
/// leads to the arithmetic gate.
class _GrownUpsButton extends StatelessWidget {
  const _GrownUpsButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.people_alt_outlined, color: Palette.ink, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                AppLocalizations.of(context).grownUps,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: const TextStyle(color: Palette.ink, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ]),
        ),
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
