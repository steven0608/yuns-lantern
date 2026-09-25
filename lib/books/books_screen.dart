import 'package:flutter/material.dart';

import '../app.dart';
import '../core/app_scope.dart';
import '../core/content/models.dart';
import '../core/ui/menu_scaffold.dart';
import '../core/ui/tile_grid.dart';
import '../play/catalog_view.dart';
import 'page_art.dart';
import 'reader_screen.dart';

/// Books → theme shelves → a book (docs/EXPANSION.md §4). With a single shelf
/// the books show straight away: one fewer tap for a three-year-old.
class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    return ListenableBuilder(
      listenable: s.settings,
      builder: (context, _) {
        final shelves = s.shelves;
        if (shelves.length == 1) return ShelfScreen(theme: shelves.single);
        return MenuScaffold(
          body: PagedTiles(
            tiles: [
              for (final th in shelves)
                TileSpec(
                  emoji: coverGlyph(s.content, s.talesIn(th.id).first),
                  color: themeColor(th.id),
                  semanticLabel: th.name.of(context.lang),
                  onTap: () =>
                      Navigator.of(context)
                          .push(softRoute(ShelfScreen(theme: th))),
                ),
            ],
          ),
        );
      },
    );
  }
}

class ShelfScreen extends StatelessWidget {
  const ShelfScreen({super.key, required this.theme});
  final TaleTheme theme;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    return MenuScaffold(
      gradient: [
        themeColor(theme.id).withValues(alpha: 0.35),
        themeColor(theme.id).withValues(alpha: 0.7),
      ],
      body: PagedTiles(
        maxTile: 170,
        tiles: [
          for (final t in s.talesIn(theme.id))
            TileSpec(
              image: s.content.art.taleArt(
                'assets/images/tales/${t.id}/cover.png',
              ),
              emoji: coverGlyph(s.content, t),
              color: themeColor(theme.id),
              semanticLabel: t.title.of(context.lang),
              onTap: () =>
                  Navigator.of(context).push(softRoute(ReaderScreen(tale: t))),
            ),
        ],
      ),
    );
  }
}
