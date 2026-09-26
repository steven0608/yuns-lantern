import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only progress. Deliberately stores counts, never scores or accuracy:
/// the parent view says "played 12 times", not "70% correct" (SPEC §11).
class ProgressService extends ChangeNotifier {
  ProgressService(this._p);
  final SharedPreferences _p;

  /// When the app was opened; drives the parent's optional break reminder.
  final DateTime sessionStart = DateTime.now();

  static Future<ProgressService> load() async =>
      ProgressService(await SharedPreferences.getInstance());

  /// Next round to offer for an activity; wraps around.
  int nextRound(String activityId, int roundCount) =>
      (_p.getInt('next.$activityId') ?? 0) % roundCount;

  int timesPlayed(String activityId) => _p.getInt('played.$activityId') ?? 0;

  void roundCompleted(String activityId, int roundIndex, int roundCount) {
    _p.setInt('next.$activityId', (roundIndex + 1) % roundCount);
    _p.setInt('played.$activityId', timesPlayed(activityId) + 1);
    notifyListeners();
  }

  /// True the first time a child ever opens a game on this engine. The silent
  /// demonstration teaches the grammar, not the content, so it plays once per
  /// engine — otherwise it repeats five times inside one land.
  bool engineIsNew(String engineId) =>
      !(_p.getStringList('engines') ?? const []).contains(engineId);

  void markEngineSeen(String engineId) {
    final seen = (_p.getStringList('engines') ?? const []).toSet()
      ..add(engineId);
    _p.setStringList('engines', seen.toList()..sort());
  }

  Set<String> get lightsCollected =>
      (_p.getStringList('lights') ?? const []).toSet();

  void collectLight(String chapterId) {
    _p.setStringList(
      'lights',
      (lightsCollected..add(chapterId)).toList()..sort(),
    );
    notifyListeners();
  }
}
