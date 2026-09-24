// Static guards for CLAUDE.md rules that must never regress. These read the
// source tree rather than the running app so they catch problems in code paths
// a widget test might never reach.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart') && !f.path.contains('${Platform.pathSeparator}l10n${Platform.pathSeparator}'));

void main() {
  test('no forbidden SDKs in the dependency graph', () {
    final lock = File('pubspec.lock').readAsStringSync().toLowerCase();
    const banned = [
      'firebase', 'crashlytics', 'sentry', 'amplitude', 'mixpanel', 'posthog', 'segment',
      'admob', 'google_mobile_ads', 'applovin', 'unity_ads', 'ironsource', 'facebook', 'tiktok',
      'revenuecat', 'purchases_flutter', 'appsflyer', 'adjust', 'branch', 'advertising_id',
      'device_info', 'geolocator', 'location', 'camera', 'image_picker', 'contacts', 'dio:',
    ];
    // Audited exception: `http` arrives transitively via audioplayers (the
    // engine under the spec's flame_audio) to support remote URL sources. We
    // only ever play bundled AssetSource files; the next test bans UrlSource.
    for (final b in banned) {
      expect(lock.contains('\n  $b'), isFalse, reason: 'banned package family "$b" in pubspec.lock');
    }
  });

  test('child UI uses tap and drag only — no pinch, rotate, double-tap, long-press', () {
    final banned = RegExp(r'onDoubleTap|onLongPress|onScale(Start|Update|End)|ScaleGestureRecognizer|InteractiveViewer|RotationGesture');
    for (final f in [...dartFiles('lib/games'), ...dartFiles('lib/story'), ...dartFiles('lib/core'), File('lib/screens/home_screen.dart')]) {
      final hits = banned.allMatches(f.readAsStringSync()).map((m) => m.group(0)).toList();
      expect(hits, isEmpty, reason: '${f.path} uses $hits');
    }
  });

  test('no hardcoded user-facing strings in widgets', () {
    // A Text/label with a literal containing letters (Latin or CJK). Emoji-only
    // literals (placeholder art) are allowed. Debug-only UI must be marked.
    final literal = RegExp(r'''(Text|semanticLabel:|tooltip:|label:)\s*\(?\s*['"][^'"$]*[A-Za-z一-鿿]''');
    for (final f in dartFiles('lib')) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('// debug-only')) continue;
        expect(literal.hasMatch(lines[i]), isFalse, reason: '${f.path}:${i + 1} hardcodes UI text: ${lines[i].trim()}');
      }
    }
  });

  test('no network, no links out, no fail-state UI', () {
    final banned = RegExp(r'''HttpClient|package:http/|UrlSource|setSourceUrl|url_launcher|WebSocket|launchUrl|Icons\.close_rounded.*miss|Colors\.red\b|countdown''');
    for (final f in [...dartFiles('lib/games'), ...dartFiles('lib/story'), ...dartFiles('lib/core')]) {
      final hits = banned.allMatches(f.readAsStringSync()).map((m) => m.group(0)).toList();
      expect(hits, isEmpty, reason: '${f.path} contains $hits');
    }
  });

  test('games never import each other (each depends only on core/ and shared/)', () {
    final games = Directory('lib/games').listSync().whereType<Directory>().map((d) => d.path.split(Platform.pathSeparator).last).where((n) => n != 'shared').toSet();
    for (final g in games) {
      for (final f in dartFiles('lib/games/$g')) {
        for (final other in games.difference({g})) {
          expect(f.readAsStringSync().contains("'../$other/"), isFalse, reason: '${f.path} imports game $other');
        }
      }
    }
  });

  test('VO trees mirror exactly across en/ and zh/', () {
    List<String> tree(String lang) {
      final root = Directory('assets/audio/vo/$lang');
      return root
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => f.path.substring(root.path.length).replaceAll('\\', '/'))
          .where((p) => !p.endsWith('.keep'))
          .toList()
        ..sort();
    }

    expect(tree('en'), equals(tree('zh')));
  });
}
