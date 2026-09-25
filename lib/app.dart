import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_scope.dart';
import 'core/locale/locale_controller.dart';
import 'core/tokens.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';

class YunsLanternApp extends StatelessWidget {
  const YunsLanternApp({super.key, required this.services, this.home});
  final Services services;
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: ListenableBuilder(
        listenable: Listenable.merge([services.locale, services.settings]),
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
          locale: services.locale.locale,
          supportedLocales: LocaleController.supported,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Palette.rust, surface: Palette.paper),
            scaffoldBackgroundColor: Palette.paper,
            // Bundled fonts only (CLAUDE.md): Fredoka for Latin, Noto Sans SC subset for 中文.
            fontFamily: 'Fredoka',
            fontFamilyFallback: const ['NotoSansSC'],
            pageTransitionsTheme: const PageTransitionsTheme(builders: {
              TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            }),
          ),
          home: home ?? const HomeScreen(),
        ),
      ),
    );
  }
}

/// Gentle fade-and-scale route used for all child navigation.
Route<T> softRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, a, _, child) {
        final c = CurvedAnimation(parent: a, curve: kStandardCurve);
        return FadeTransition(
          opacity: c,
          child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(c), child: child),
        );
      },
    );
