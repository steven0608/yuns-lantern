import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/app_scope.dart';
import 'core/audio/audio_service.dart';
import 'core/content/content_loader.dart';
import 'core/iap/purchase_service.dart';
import 'core/locale/locale_controller.dart';
import 'core/progress/progress_service.dart';
import 'core/storage/prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Landscape only: every layout is designed for a device held sideways.
  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final services = await createServices();
  runApp(YunsLanternApp(services: services));
}

Future<Services> createServices({bool useAudioDevice = true}) async {
  final content = await Content.load();
  final settings = await Settings.load();
  final locale = LocaleController(settings);
  final audio = AudioService(content: content, locale: locale, settings: settings, useDevice: useAudioDevice);
  await audio.init();
  final purchases = PurchaseService(settings);
  purchases.init(); // not awaited: the child can play while the store answers
  return Services(
    content: content,
    settings: settings,
    locale: locale,
    audio: audio,
    progress: await ProgressService.load(),
    purchases: purchases,
  );
}
