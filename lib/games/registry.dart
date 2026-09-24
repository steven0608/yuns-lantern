import 'count_feed/count_feed.dart';
import 'shared/activity_scaffold.dart';

/// Every mini-game engine, keyed by the activity id in content/activities.json.
/// An activity without an engine here simply doesn't appear.
final Map<String, GameDef> gameRegistry = {
  for (final g in [
    countFeedGame,
  ])
    g.id: g,
};
