import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';
import 'tile_grid.dart';
import 'touch_target.dart';

/// Shell for the child's menus (Lands, a Land, Books): picture background,
/// a home button top-left, content kept clear of it. No titles — pictures only.
class MenuScaffold extends StatelessWidget {
  const MenuScaffold({
    super.key,
    required this.body,
    this.background,
    this.gradient = const [Color(0xFFFCEFD6), Color(0xFFF1DDB8)],
    this.onHome,
  });
  final Widget body;
  final String? background;
  final List<Color> gradient;
  final VoidCallback? onHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (background != null)
            Image.asset(background!, fit: BoxFit.cover)
          else
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradient,
                ),
              ),
            ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                // Home button edge (4 + slop + 88) + a 64px gap, minus the tiles' own slop.
                const rail =
                    4 +
                    kHitSlop / 2 +
                    kMinTouchTarget +
                    kMinTargetGap -
                    kHitSlop / 2;
                final insets = box.maxHeight < 560
                    ? const EdgeInsets.fromLTRB(rail, 8, 16, 8)
                    : const EdgeInsets.fromLTRB(32, rail, 32, 24);
                return Padding(padding: insets, child: body);
              },
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: RoundButton(
                  icon: Icons.home_rounded,
                  onTap: onHome ?? () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiles in pages of at most [perPage] (≤ 6 targets on screen, EXPANSION §4).
/// Swipe sideways or use the arrows — drag alone is hard to discover.
class PagedTiles extends StatefulWidget {
  const PagedTiles({
    super.key,
    required this.tiles,
    this.perPage = 6,
    this.maxTile = 150,
  });
  final List<TileSpec> tiles;
  final int perPage;
  final double maxTile;

  @override
  State<PagedTiles> createState() => _PagedTilesState();
}

class _PagedTilesState extends State<PagedTiles> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  int _per = 1;
  int get _count => (widget.tiles.length / _per).ceil();

  void _go(int delta) {
    final to = (_page + delta).clamp(0, _count - 1);
    _pages.animateToPage(
      to,
      duration: const Duration(milliseconds: 420),
      curve: kStandardCurve,
    );
  }

  /// How many tiles fit at a comfortable size: ≥104pt on phones, ≥120pt on
  /// tablets (HANDOFF §1), 64pt gaps, never more than [PagedTiles.perPage].
  int _capacity(double w, double h) {
    const gap = kMinTargetGap - kHitSlop;
    final tile = (h < 420 ? 104.0 : 120.0) + kHitSlop;
    final cols = ((w + gap) / (tile + gap)).floor();
    final rows = ((h + gap) / (tile + gap)).floor();
    return math.max(1, math.min(widget.perPage, cols * rows));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        const slot = kMinTouchTarget + kHitSlop,
            arrowGap = kMinTargetGap - kHitSlop;
        final full = _capacity(box.maxWidth, box.maxHeight);
        _per = widget.tiles.length <= full
            ? full
            : _capacity(box.maxWidth - 2 * (slot + arrowGap), box.maxHeight);
        _page = math.min(_page, _count - 1);
        final pages = [
          for (var i = 0; i < _count; i++)
            widget.tiles.sublist(
              i * _per,
              math.min(widget.tiles.length, (i + 1) * _per),
            ),
        ];
        final grid = PageView(
          controller: _pages,
          onPageChanged: (p) => setState(() => _page = p),
          children: [
            for (final p in pages) TileGrid(tiles: p, maxTile: widget.maxTile),
          ],
        );
        if (_count <= 1) return grid;
        return Row(
          children: [
            _Arrow(
              icon: Icons.chevron_left_rounded,
              visible: _page > 0,
              onTap: () => _go(-1),
            ),
            const SizedBox(width: arrowGap),
            Expanded(child: grid),
            const SizedBox(width: arrowGap),
            _Arrow(
              icon: Icons.chevron_right_rounded,
              visible: _page < _count - 1,
              onTap: () => _go(1),
            ),
          ],
        );
      },
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.icon,
    required this.visible,
    required this.onTap,
  });
  final IconData icon;
  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Keep the slot so the grid doesn't jump; an invisible arrow isn't a target.
    return SizedBox(
      width: kMinTouchTarget + kHitSlop,
      child: visible
          ? Center(
              child: RoundButton(
                icon: icon,
                onTap: onTap,
                color: Palette.card.withValues(alpha: 0.9),
              ),
            )
          : null,
    );
  }
}
