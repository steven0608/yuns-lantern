import 'package:flutter/widgets.dart';

import 'audio/audio_service.dart';
import 'content/content_loader.dart';
import 'iap/purchase_service.dart';
import 'locale/locale_controller.dart';
import 'progress/progress_service.dart';
import 'storage/prefs.dart';

/// All app services, created once in main() and handed down the tree.
class Services {
  Services({
    required this.content,
    required this.settings,
    required this.locale,
    required this.audio,
    required this.progress,
    required this.purchases,
  });
  final Content content;
  final Settings settings;
  final LocaleController locale;
  final AudioService audio;
  final ProgressService progress;
  final PurchaseService purchases;

  /// What the child may see. Locked content is invisible, never padlocked
  /// (CLAUDE.md): this is the single filter every child-facing list uses.
  bool activityVisible(String id) {
    final a = content.activities[id];
    if (a == null) return false;
    if (!(a.free || settings.fullAccess)) return false;
    if (a.minAge > settings.childAge) return false;
    return !settings.hiddenActivities.contains(id);
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});
  final Services services;

  static Services of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope old) => old.services != services;
}

extension ServicesX on BuildContext {
  Services get services => AppScope.of(this);
  String get lang => AppScope.of(this).locale.code;
}
