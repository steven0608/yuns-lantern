import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../app.dart';
import '../core/app_scope.dart';
import '../core/audio/audio_service.dart';
import '../core/content/models.dart';
import '../core/tokens.dart';
import '../core/ui/touch_target.dart';
import '../core/ui/yun.dart';
import 'scene_player.dart';

/// The eight lanterns on the path up Lantern Hill (SPEC §8), laid out as on the
/// design canvas "Story map" board (1194×834). Collected lights glow in their
/// colour; the next chapter is ringed and Yun waits beside it. Chapters the
/// family hasn't bought sit in mist — unreachable, never padlocked, never a
/// sales pitch. Tapping mist just swirls it.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  /// Lantern centres on the 1194×834 design board, chapter 1 → 8.
  static const _stops = [
    Offset(150, 700),
    Offset(330, 592),
    Offset(520, 668),
    Offset(660, 495), // 4 nudged up 10 from the board: keeps the 64px gap to 3
    Offset(470, 385), Offset(640, 262), Offset(860, 330), Offset(1010, 150),
  ];
  static const _board = Size(1194, 834);

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    return ListenableBuilder(
      listenable: Listenable.merge([s.progress, s.settings]),
      builder: (context, _) {
        final chapters = s.content.story.chapters;
        final lights = s.progress.lightsCollected;
        bool reachable(Chapter c) => c.free || s.settings.fullAccess;
        final next = chapters
            .where((c) => reachable(c) && !lights.contains(c.id))
            .firstOrNull;
        return Scaffold(
          backgroundColor: const Color(0xFFF8EAD3),
          body: LayoutBuilder(
            builder: (context, box) {
              // Tablets: the design board's stops under the same "cover" mapping
              // as the background, so lanterns sit on the painted path. Phones
              // (short side < 560): that board would crop chapter 1 off-screen and
              // crowd targets, so lanterns climb a two-row trail instead.
              final short = box.maxHeight < 560;
              final scale = math.max(
                box.maxWidth / _board.width,
                box.maxHeight / _board.height,
              );
              final origin = Offset(
                (box.maxWidth - _board.width * scale) / 2,
                (box.maxHeight - _board.height * scale) / 2,
              );
              final node = short
                  ? kMinTouchTarget
                  : math.max(kMinTouchTarget, 104 * scale);
              // Phone trail: a 2×4 snake. The top row is shifted half a step
              // right, and the whole trail starts far enough in that the top row
              // clears the home button by 64px; narrow phones (SE) scroll sideways.
              const pitch =
                  kMinTouchTarget +
                  kMinTargetGap; // centre-to-centre, 64px visible gap
              const trailW = 3 * pitch + pitch / 2 + kMinTouchTarget;
              const homeClear =
                  4 +
                  kHitSlop / 2 +
                  kMinTouchTarget +
                  kMinTargetGap; // left edge of the top row
              final trailLeft = math.max(
                homeClear - pitch / 2,
                (box.maxWidth - trailW) / 2,
              );
              final contentW = short
                  ? math.max(box.maxWidth, trailLeft + trailW + 16)
                  : box.maxWidth;
              Offset at(int i) {
                if (!short) return origin + _stops[i] * scale;
                final row = i ~/ 4, col = row == 0 ? i % 4 : 3 - i % 4;
                return Offset(
                  trailLeft +
                      kMinTouchTarget / 2 +
                      col * pitch +
                      (row == 0 ? 0 : pitch / 2),
                  box.maxHeight * (row == 0 ? 0.78 : 0.36),
                );
              }

              final mistAll = !chapters.every(reachable);

              final world = SizedBox(
                width: contentW,
                height: box.maxHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/ui/map.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (short)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _TrailPainter([
                            for (var i = 0; i < chapters.length; i++) at(i),
                          ]),
                        ),
                      ),
                    if (mistAll) ..._mist(chapters, reachable, at, scale),
                    for (final (i, c) in chapters.indexed)
                      Positioned(
                        left:
                            at(i).dx -
                            (i == 7 && !short ? node * 1.2 : node) / 2 -
                            kHitSlop / 2,
                        top:
                            at(i).dy -
                            (i == 7 && !short ? node * 1.2 : node) / 2 -
                            kHitSlop / 2,
                        child: _ChapterLantern(
                          chapter: c,
                          size: i == 7 && !short ? node * 1.2 : node,
                          lit: lights.contains(c.id),
                          reachable: reachable(c),
                          isNext: c == next,
                        ),
                      ),
                    if (next != null)
                      Positioned(
                        left: at(chapters.indexOf(next)).dx + node * 0.45,
                        top: at(chapters.indexOf(next)).dy - node * 1.05,
                        child: IgnorePointer(
                          child: Yun(size: math.max(80, 110 * scale)),
                        ),
                      ),
                  ],
                ),
              );
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (contentW > box.maxWidth)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: world,
                    )
                  else
                    world,
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: RoundButton(
                          icon: Icons.home_rounded,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Soft fog banks over the unreached part of the hill.
  List<Widget> _mist(
    List<Chapter> chapters,
    bool Function(Chapter) reachable,
    Offset Function(int) at,
    double scale,
  ) => [
    for (final (i, c) in chapters.indexed)
      if (!reachable(c))
        Positioned(
          left: at(i).dx - 150 * scale,
          top: at(i).dy - 110 * scale,
          child: IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: 300 * scale,
                height: 220 * scale,
                decoration: const BoxDecoration(
                  color: Color(0xE6F3F0EB),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
  ];
}

class _ChapterLantern extends StatelessWidget {
  const _ChapterLantern({
    required this.chapter,
    required this.size,
    required this.lit,
    required this.reachable,
    required this.isNext,
  });
  final Chapter chapter;
  final double size;
  final bool lit;
  final bool reachable;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final art = context.services.content.art;
    final image = art.lightImage(
      lit ? chapter.lightColor : (reachable ? 'unlit' : 'misty'),
    );
    final glow = Palette.lantern;
    return TouchTarget(
      size: Size.square(size),
      sound: reachable ? Sfx.tap : Sfx.whoosh,
      onTap: reachable
          ? () =>
                Navigator.of(context)
                    .push(softRoute(ChapterRunner(chapter: chapter)))
          : () {}, // mist swirls (bump + whoosh); nothing to buy here
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: !reachable || lit
              ? null
              : Palette.card.withValues(alpha: isNext ? 0.92 : 0.7),
          boxShadow: [
            if (isNext)
              BoxShadow(color: glow.withValues(alpha: 0.38), spreadRadius: 8),
            if (isNext)
              BoxShadow(color: glow.withValues(alpha: 0.16), spreadRadius: 20),
            if (lit)
              BoxShadow(
                color: (Palette.named[chapter.lightColor] ?? glow).withValues(
                  alpha: 0.6,
                ),
                blurRadius: 30,
                spreadRadius: 4,
              ),
          ],
        ),
        alignment: Alignment.center,
        child: Opacity(
          opacity: reachable ? 1 : 0.9,
          child: image != null
              ? Image.asset(image, height: size * 0.85)
              : Icon(
                  Icons.light_rounded,
                  size: size * 0.6,
                  color: Palette.named[chapter.lightColor],
                ),
        ),
      ),
    );
  }
}

/// The phone trail: a soft dotted path linking the lanterns in order.
class _TrailPainter extends CustomPainter {
  _TrailPainter(this.points);
  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      path.quadraticBezierTo(
        (a.dx + b.dx) / 2,
        math.min(a.dy, b.dy) - 18,
        b.dx,
        b.dy,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xCCF3E1BD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TrailPainter o) =>
      o.points.first != points.first || o.points.last != points.last;
}
