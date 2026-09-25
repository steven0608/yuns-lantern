// Every non-game screen at iPad and iPhone landscape, both languages: builds
// without errors, fills the screen, and keeps touch targets compliant.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuns_lantern/books/books_screen.dart';
import 'package:yuns_lantern/books/reader_screen.dart';
import 'package:yuns_lantern/core/ui/touch_target.dart';
import 'package:yuns_lantern/play/catalog_view.dart';
import 'package:yuns_lantern/play/lands_screen.dart';
import 'package:yuns_lantern/screens/home_screen.dart';
import 'package:yuns_lantern/screens/parent/parent_area.dart';
import 'package:yuns_lantern/screens/parent/parent_gate.dart';
import 'package:yuns_lantern/screens/web_shell.dart';
import 'package:yuns_lantern/story/map_screen.dart';
import 'package:yuns_lantern/story/scene_player.dart';

import 'helpers.dart';

void main() {
  for (final size in [ipad, const Size(1194, 834), iphone, const Size(667, 375)]) {
    for (final locale in ['en', 'zh']) {
      final tag = '${size.width.toInt()}x${size.height.toInt()} $locale';

      testWidgets('home · $tag', (tester) async {
        final s = await testServices(locale: locale);
        await pumpApp(tester, s, home: const HomeScreen(), size: size);
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        expectTouchTargetsCompliant(tester);
      });

      testWidgets('story map · $tag · every lantern on screen', (tester) async {
        final s = await testServices(locale: locale);
        await pumpApp(tester, s, home: const MapScreen(), size: size);
        expect(tester.takeException(), isNull);
        // 8 lanterns + home, all fully visible.
        final targets = find.byType(TouchTarget).evaluate().toList();
        expect(targets.length, 9);
        for (final e in targets) {
          final box = e.renderObject! as RenderBox;
          final r = box.localToGlobal(Offset.zero) & box.size;
          // Vertically always on screen; narrow phones may scroll the trail sideways.
          expect(Rect.fromLTRB(0, 0, 2000, size.height), _contains(r.deflate(12)), reason: 'off-screen target $r');
        }
        expectTouchTargetsCompliant(tester);
      });

      testWidgets('play: lands and a land · $tag', (tester) async {
        final s = await testServices(locale: locale);
        expect(s.lands, isNotEmpty);
        await pumpApp(tester, s, home: const LandsScreen(), size: size);
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        // ≤ 6 lands + home + page arrows on screen (EXPANSION §4)
        expect(find.byType(TouchTarget).hitTestable().evaluate().length, lessThanOrEqualTo(6 + 3));
        expectTouchTargetsCompliant(tester);
        final multi = s.lands.firstWhere((l) => s.gamesInLand(l.id).length > 1);
        await pumpApp(tester, s, home: LandScreen(land: multi), size: size);
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        expectTouchTargetsCompliant(tester);
      });

      testWidgets('books: shelf and every page of every tale · $tag', (tester) async {
        final s = await testServices(locale: locale);
        expect(s.shelves, isNotEmpty);
        await pumpApp(tester, s, home: const BooksScreen(), size: size);
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        expectTouchTargetsCompliant(tester);
        for (final tale in s.content.tales.where(s.taleVisible)) {
          await pumpApp(tester, s, home: ReaderScreen(tale: tale), size: size);
          for (var p = 1; p <= tale.pages.length; p++) {
            expect(tester.takeException(), isNull, reason: '${tale.id} p$p');
            expectTouchTargetsCompliant(tester, checkGaps: false);
            await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
            await tester.pump(const Duration(milliseconds: 600));
          }
          expect(find.byIcon(Icons.replay_rounded), findsOneWidget, reason: 'the end panel after ${tale.id}');
        }
      });

      testWidgets('story scene · $tag', (tester) async {
        final s = await testServices(locale: locale);
        final ch = s.content.story.chapters.first;
        await pumpApp(tester, s, home: ScenePlayer(chapter: ch, part: 'open', onDone: () {}, onHome: () {}), size: size);
        expect(tester.takeException(), isNull);
        expectTouchTargetsCompliant(tester, checkGaps: false);
      });

      testWidgets('parental gate + parent area · $tag', (tester) async {
        final s = await testServices(locale: locale);
        await pumpApp(tester, s, home: const ParentGate(), size: size);
        expect(tester.takeException(), isNull);
        await pumpApp(tester, s, home: const ParentArea(), size: size);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('reader: Both mode shows both languages on tablets', (tester) async {
    final s = await testServices(locale: 'zh');
    s.settings.bookLanguage = 'both';
    final tale = s.content.tales.firstWhere(s.taleVisible);
    await pumpApp(tester, s, home: ReaderScreen(tale: tale));
    expect(find.text(tale.pages.first.zh), findsOneWidget);
    expect(find.text(tale.pages.first.en), findsOneWidget);
  });

  testWidgets('home v3: three doors', (tester) async {
    final s = await testServices();
    await pumpApp(tester, s, home: const HomeScreen());
    await tester.pump(const Duration(seconds: 2));
    // Story, Play, Books + Yun + grown-ups
    expect(find.byType(TouchTarget).evaluate().length, 5);
  });

  testWidgets('web: portrait phone shows the turn-your-phone picture, no text', (tester) async {
    final s = await testServices();
    await pumpApp(tester, s, home: const WebStage(force: true, child: HomeScreen()), size: const Size(390, 844));
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('web: start screen waits for a tap on Yun', (tester) async {
    final s = await testServices();
    await pumpApp(tester, s, home: const WebStartGate(force: true, child: HomeScreen()));
    expect(find.byType(HomeScreen), findsNothing);
    await tester.tap(find.byType(TouchTarget));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}

Matcher _contains(Rect inner) => predicate<Rect>(
      (outer) => outer.contains(inner.topLeft) && outer.contains(inner.bottomRight - const Offset(0.01, 0.01)),
      'contains $inner',
    );
