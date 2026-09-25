import 'big_and_small/big_and_small.dart';
import 'count_feed/count_feed.dart';
import 'day_and_night/day_and_night.dart';
import 'find_the_same/find_the_same.dart';
import 'float_or_sink/float_or_sink.dart';
import 'match_it/match_it.dart';
import 'mirror_match/mirror_match.dart';
import 'pattern_parade/pattern_parade.dart';
import 'puzzle_pieces/puzzle_pieces.dart';
import 'shape_sorter/shape_sorter.dart';
import 'what_is_it/what_is_it.dart';
import 'where_is_it/where_is_it.dart';
import '../core/content/models.dart';
import 'shared/activity_scaffold.dart';

/// Every mini-game engine, keyed by engine id (a v2 activity id). Look games
/// up through [gameFor], never directly: an activity plays on the engine its
/// `engine` field names. An activity without an engine here simply doesn't appear.
final Map<String, GameDef> gameRegistry = {
  for (final g in [
    countFeedGame,
    matchItGame,
    bigAndSmallGame,
    shapeSorterGame,
    findTheSameGame,
    whereIsItGame,
    puzzlePiecesGame,
    dayAndNightGame,
    floatOrSinkGame,
    whatIsItGame,
    patternParadeGame,
    mirrorMatchGame,
  ])
    g.id: g,
};

/// The engine for an activity in content/activities.json, bound to that
/// activity's rounds; null when no engine can play it yet.
GameDef? gameFor(Activity activity) =>
    gameRegistry[activity.engine]?.forActivity(activity.id);
