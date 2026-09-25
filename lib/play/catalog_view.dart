import '../core/app_scope.dart';
import '../core/content/models.dart';
import '../games/registry.dart';
import '../games/shared/activity_scaffold.dart';

/// What the child can reach right now, derived from content + settings.
/// Everything the child sees goes through here, so locked, too-old or
/// not-yet-built content is simply absent — never padlocked (CLAUDE.md).
extension CatalogView on Services {
  /// A game the child can play now, or null.
  GameDef? playable(String activityId) {
    final a = content.activities[activityId];
    if (a == null || !activityVisible(activityId)) return null;
    return gameFor(a);
  }

  /// Games of one Lantern Land (engine), in catalog order. Falls back to
  /// activities.json alone when there is no catalog.
  List<GameDef> gamesInLand(String engineId) => [
    for (final g in content.catalog.values)
      if (g.engine == engineId && playable(g.id) != null) playable(g.id)!,
  ];

  /// Lands with at least one playable game.
  List<CatalogEngine> get lands => [
    for (final e in content.engines.values)
      if (gamesInLand(e.id).isNotEmpty) e,
  ];

  /// Every playable game, catalog order (or activities order without a catalog).
  List<GameDef> get allPlayable => content.catalog.isEmpty
      ? [
          for (final id in content.activities.keys)
            if (playable(id) != null) playable(id)!,
        ]
      : [
          for (final g in content.catalog.values)
            if (playable(g.id) != null) playable(g.id)!,
        ];

  bool taleVisible(Tale t) =>
      t.written && t.pages.isNotEmpty && (t.free || settings.fullAccess);

  List<Tale> talesIn(String themeId) => [
    for (final t in content.tales)
      if (t.theme == themeId && taleVisible(t)) t,
  ];

  List<TaleTheme> get shelves => [
    for (final th in content.themes)
      if (talesIn(th.id).isNotEmpty) th,
  ];
}
