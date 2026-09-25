import 'package:flutter/material.dart';

import '../core/audio/music_scope.dart';
import '../core/audio/audio_service.dart';
import '../app.dart';
import '../core/app_scope.dart';
import '../core/content/models.dart';
import '../core/ui/menu_scaffold.dart';
import '../core/ui/tile_grid.dart';
import '../games/shared/activity_scaffold.dart';
import 'catalog_view.dart';

const _landColors = [
  Color(0xFFF5C2A8),
  Color(0xFFBFE0B4),
  Color(0xFFB9D7EE),
  Color(0xFFF3D38A),
  Color(0xFFD9C6EE),
  Color(0xFFF6B8C8),
  Color(0xFFA9DCD3),
  Color(0xFFF2C79B),
  Color(0xFFC9D8A8),
  Color(0xFFE8C4A0),
];

/// Play → Lantern Lands: one land per engine that has something to play
/// (docs/EXPANSION.md §4). A land with a single game opens it directly.
class LandsScreen extends StatelessWidget {
  const LandsScreen({super.key});

  @override
  Widget build(BuildContext context) => MusicScope(
    track: Music.lands,
    child: Builder(builder: _body),
  );

  Widget _body(BuildContext context) {
    final s = context.services;
    return ListenableBuilder(
      listenable: Listenable.merge([s.settings, s.progress]),
      builder: (context, _) {
        final lands = s.lands;
        return MenuScaffold(
          background: 'assets/images/ui/home_bg.png',
          body: PagedTiles(
            tiles: [
              for (final (i, land) in lands.indexed)
                TileSpec(
                  image:
                      s.content.art.landImage(land.id) ??
                      s.content.art.tileImage(s.gamesInLand(land.id).first.id),
                  color: _landColors[i % _landColors.length],
                  semanticLabel: land.name.of(context.lang),
                  onTap: () => openLand(context, land),
                ),
            ],
          ),
        );
      },
    );
  }
}

void openLand(BuildContext context, CatalogEngine land) {
  final games = context.services.gamesInLand(land.id);
  if (games.length == 1) {
    Navigator.of(context).push(softRoute(ActivitySession(game: games.single)));
  } else {
    Navigator.of(context).push(softRoute(LandScreen(land: land)));
  }
}

/// One land: its (up to five) games.
class LandScreen extends StatelessWidget {
  const LandScreen({super.key, required this.land});
  final CatalogEngine land;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    return ListenableBuilder(
      listenable: s.settings,
      builder: (context, _) => MenuScaffold(
        background: 'assets/images/ui/home_bg.png',
        body: PagedTiles(
          tiles: [
            for (final (i, g) in s.gamesInLand(land.id).indexed)
              TileSpec(
                image: s.content.art.tileImage(g.id),
                emoji: s.content.art.activityIcons[g.id] ?? '⭐',
                color: _landColors[(i + 3) % _landColors.length],
                semanticLabel: s.content.activities[g.id]?.name.of(
                  context.lang,
                ),
                onTap: () =>
                    Navigator.of(context)
                        .push(softRoute(ActivitySession(game: g))),
              ),
          ],
        ),
      ),
    );
  }
}
