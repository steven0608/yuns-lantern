import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/item_art.dart';
import '../tokens.dart';
import 'touch_target.dart';

/// One big picture button in a [TileGrid]: an image (design export) or,
/// until the art exists, an emoji on a warm card.
class TileSpec {
  const TileSpec({
    required this.onTap,
    this.image,
    this.emoji = '⭐',
    this.color = Palette.card,
    this.semanticLabel,
    this.dimmed = false,
  });
  final VoidCallback onTap;
  final String? image;
  final String emoji;
  final Color color;
  final String? semanticLabel;

  /// Softened (e.g. a book already read) — still fully tappable.
  final bool dimmed;
}

/// Lays tiles out as large as the space allows (up to [maxTile]), keeping
/// 88px targets and 64px visible gaps (CLAUDE.md); falls back to a
/// sideways-scrolling strip on short phone screens rather than shrinking
/// below the minimum. Callers page long lists so no more than
/// [kMaxInteractiveItems] tiles show at once (docs/EXPANSION.md §4).
class TileGrid extends StatelessWidget {
  const TileGrid({super.key, required this.tiles, this.maxTile = 150});
  final List<TileSpec> tiles;
  final double maxTile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        const gap = kMinTargetGap - kHitSlop; // + 2×12px slop = 64 visible
        final n = tiles.length;
        if (n == 0) return const SizedBox();
        double fit(int cols, int rows) => math.min(
          (box.maxWidth - (cols - 1) * gap) / cols - kHitSlop,
          (box.maxHeight - (rows - 1) * gap) / rows - kHitSlop,
        );
        var best = 0.0;
        var cols = 1;
        for (var c = 1; c <= math.min(n, 6); c++) {
          final t = math.min(fit(c, (n / c).ceil()), maxTile);
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
                children: [
                  for (final (i, t) in tiles.indexed)
                    PictureTile(spec: t, size: best, index: i),
                ],
              ),
            ),
          );
        }
        final rows = math.max(
          1,
          ((box.maxHeight + gap) / (kMinTouchTarget + kHitSlop + gap)).floor(),
        );
        final size = math.max(
          kMinTouchTarget,
          (box.maxHeight - (rows - 1) * gap) / rows - kHitSlop,
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            height: box.maxHeight,
            child: Wrap(
              direction: Axis.vertical,
              alignment: WrapAlignment.center,
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final (i, t) in tiles.indexed)
                  PictureTile(spec: t, size: size, index: i),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PictureTile extends StatelessWidget {
  const PictureTile({
    super.key,
    required this.spec,
    required this.size,
    this.index = 0,
  });
  final TileSpec spec;
  final double size;
  final int index;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.27);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 70),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.scale(scale: t, child: child),
      child: TouchTarget(
        onTap: spec.onTap,
        size: Size.square(size),
        semanticLabel: spec.semanticLabel,
        child: Opacity(
          opacity: spec.dimmed ? 0.75 : 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: const [
                BoxShadow(color: Palette.shadow, offset: Offset(0, 7)),
              ],
            ),
            child: spec.image != null
                ? ClipRRect(
                    borderRadius: radius,
                    child: Image.asset(
                      spec.image!,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: spec.color,
                      borderRadius: radius,
                      border: Border.all(color: Palette.card, width: 5),
                    ),
                    alignment: Alignment.center,
                    child: Emoji(spec.emoji, size: size * 0.5),
                  ),
          ),
        ),
      ),
    );
  }
}
