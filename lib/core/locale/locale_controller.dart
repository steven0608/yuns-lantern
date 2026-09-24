import 'package:flutter/widgets.dart';

import '../storage/prefs.dart';

/// Locale order (SPEC §9): parent override → device locale → en.
class LocaleController extends ChangeNotifier {
  LocaleController(this._settings) {
    _settings.addListener(notifyListeners);
  }
  final Settings _settings;

  static const supported = [Locale('en'), Locale('zh')];

  Locale get locale {
    final o = _settings.localeOverride;
    if (o == 'en' || o == 'zh') return Locale(o);
    final device = WidgetsBinding.instance.platformDispatcher.locale;
    return device.languageCode == 'zh' ? const Locale('zh') : const Locale('en');
  }

  String get code => locale.languageCode;

  @override
  void dispose() {
    _settings.removeListener(notifyListeners);
    super.dispose();
  }
}
