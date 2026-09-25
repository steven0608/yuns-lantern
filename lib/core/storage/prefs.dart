import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Parent-controlled settings. Stored only on this device (no accounts, no
/// sync) — CLAUDE.md forbids any personal-data collection or network use.
class Settings extends ChangeNotifier {
  Settings(this._p);
  final SharedPreferences _p;

  static Future<Settings> load() async =>
      Settings(await SharedPreferences.getInstance());

  double get voVolume => _p.getDouble('voVolume') ?? 1.0;
  set voVolume(double v) => _set(() => _p.setDouble('voVolume', v));

  double get musicVolume => _p.getDouble('musicVolume') ?? 0.5;
  set musicVolume(double v) => _set(() => _p.setDouble('musicVolume', v));

  double get sfxVolume => _p.getDouble('sfxVolume') ?? 0.7;
  set sfxVolume(double v) => _set(() => _p.setDouble('sfxVolume', v));

  /// Drives minAge gating (SPEC §5). Defaults to 3 so a new install fits the
  /// youngest child; 4+ activities appear once the parent says so.
  int get childAge => _p.getInt('childAge') ?? (allFree ? 5 : 3);
  set childAge(int v) => _set(() => _p.setInt('childAge', v));

  Set<String> get hiddenActivities =>
      (_p.getStringList('hidden') ?? const []).toSet();
  void setActivityHidden(String id, bool hidden) {
    final s = hiddenActivities;
    hidden ? s.add(id) : s.remove(id);
    _set(() => _p.setStringList('hidden', s.toList()..sort()));
  }

  /// 0 = off. Suggests a break after a round; never locks mid-activity (§11).
  int get breakMinutes => _p.getInt('breakMinutes') ?? 0;
  set breakMinutes(int v) => _set(() => _p.setInt('breakMinutes', v));

  /// 'auto' | 'en' | 'zh'.
  String get localeOverride => _p.getString('locale') ?? 'auto';
  set localeOverride(String v) => _set(() => _p.setString('locale', v));

  /// Lantern Tales narration: 'app' (the app language) or 'both' (the app
  /// language, then the other one — the Mandarin-learning mode, EXPANSION §1).
  String get bookLanguage => _p.getString('bookLanguage') ?? 'app';
  set bookLanguage(String v) => _set(() => _p.setString('bookLanguage', v));

  bool get purchased => _p.getBool('purchased') ?? false;
  set purchased(bool v) => _set(() => _p.setBool('purchased', v));

  /// Debug builds only — lets QA reach paid content without StoreKit.
  bool get devUnlock => kDebugMode && (_p.getBool('devUnlock') ?? false);
  set devUnlock(bool v) => _set(() => _p.setBool('devUnlock', v));

  /// Test builds (web demo, TestFlight) unlock everything so all content can
  /// be tested: `--dart-define=YL_ALL_FREE=true`. App Store release builds
  /// leave it off and keep the real free tier + purchase.
  static const allFree = bool.fromEnvironment('YL_ALL_FREE');

  bool get fullAccess => allFree || purchased || devUnlock;

  void _set(Future<bool> Function() write) {
    write();
    notifyListeners();
  }
}
