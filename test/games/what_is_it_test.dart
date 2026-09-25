// What Is It?: plays real rounds by tapping the choice cards.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuns_lantern/core/app_scope.dart';
import 'package:yuns_lantern/games/shared/activity_scaffold.dart';
import 'package:yuns_lantern/games/shared/cards.dart';
import 'package:yuns_lantern/games/shared/celebration.dart';
import 'package:yuns_lantern/games/shared/gentle_hint.dart';
import 'package:yuns_lantern/games/what_is_it/what_is_it.dart';

import '../helpers.dart';

Future<void> _openRound(WidgetTester tester, Services s, int idx, Size size) async {
  final n = s.content.activities[whatIsItGame.id]!.rounds.length;
  await tester.runAsync(() async => s.progress.roundCompleted(whatIsItGame.id, (idx - 1) % n, n));
  await pumpApp(tester, s, home: ActivitySession(key: ValueKey(idx), game: whatIsItGame), size: size);
}

Future<void> _pumpUntilCelebration(WidgetTester tester) async {
  for (var i = 0; i < 10 && find.byType(Celebration).evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 600));
  }
}

/// Lets the celebration and its voice lines finish, then tears down, so no
/// audio timers are left pending.
Future<void> _settleAndClose(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 600));
  }
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 100));
}

final _right = find.byWidgetPredicate((w) => w is ChoiceCard && w.correct);
final _wrong = find.byWidgetPredicate((w) => w is ChoiceCard && !w.correct);

void main() {
  for (final (idx, tier) in [(0, 'silhouette'), (12, 'reveal')]) {
    testWidgets('what_is_it ($tier): wrong guesses wobble, the right one completes', (tester) async {
      final s = await testServices();
      expect(s.content.activities[whatIsItGame.id]!.rounds[idx].str('tier'), tier);
      await _openRound(tester, s, idx, ipad);
      expect(find.byType(ChoiceCard), findsNWidgets(3));
      expect(_right, findsOneWidget);
      expectTouchTargetsCompliant(tester);

      final hints = tester.widget<HintHandLayer>(find.byType(HintHandLayer)).hints;
      for (var miss = 0; miss < 2; miss++) {
        await tester.tap(_wrong.at(miss));
        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 600));
        }
        expect(find.byType(Celebration), findsNothing);
      }
      // Two misses → the right card pulses, and the hand would point at it.
      // Calls the game's hint contract directly: showing the hand itself
      // trips a shared HintHandLayer bug (reads a detached render box).
      expect(hints.level.value, 1);
      final move = hints.guide!()!;
      expect((tester.getCenter(find.byKey(move.from)) - tester.getCenter(_right)).distance, lessThan(1));

      await tester.tap(_right);
      await _pumpUntilCelebration(tester);
      expect(find.byType(Celebration), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _settleAndClose(tester);
    });
  }

  testWidgets('what_is_it: every round completes on iPhone, targets stay compliant', (tester) async {
    final s = await testServices(locale: 'zh');
    final n = s.content.activities[whatIsItGame.id]!.rounds.length;
    for (var idx = 0; idx < n; idx++) {
      await _openRound(tester, s, idx, iphone);
      expectTouchTargetsCompliant(tester);
      await tester.tap(_right);
      await _pumpUntilCelebration(tester);
      expect(find.byType(Celebration), findsOneWidget, reason: 'round $idx did not complete');
      expect(tester.takeException(), isNull);
      await _settleAndClose(tester);
    }
  });
}
