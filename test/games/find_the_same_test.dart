// Find the Same: plays real rounds by tapping the card that matches the one
// in the magnifying glass. Wrong cards wobble and escalate help; they never
// complete the round. Never pumpAndSettle: Yun animates forever.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuns_lantern/core/app_scope.dart';
import 'package:yuns_lantern/games/find_the_same/find_the_same.dart';
import 'package:yuns_lantern/games/shared/activity_scaffold.dart';
import 'package:yuns_lantern/games/shared/cards.dart';
import 'package:yuns_lantern/games/shared/celebration.dart';
import 'package:yuns_lantern/games/shared/gentle_hint.dart';

import '../helpers.dart';

const _id = 'find_the_same';

final _right = find.byWidgetPredicate((w) => w is ChoiceCard && w.correct);
final _wrong = find.byWidgetPredicate((w) => w is ChoiceCard && !w.correct);

Future<void> _open(WidgetTester tester, Services s, int idx, Size size) async {
  final n = s.content.activities[_id]!.rounds.length;
  await tester.runAsync(() async => s.progress.roundCompleted(_id, (idx - 1) % n, n));
  await pumpApp(tester, s, home: ActivitySession(key: ValueKey(idx), game: findTheSameGame), size: size);
  await tester.pump(const Duration(seconds: 1)); // glass slides in, cards pop up
}

Future<bool> _pumpUntilCelebration(WidgetTester tester, {int steps = 10}) async {
  for (var i = 0; i < steps; i++) {
    if (find.byType(Celebration).evaluate().isNotEmpty) return true;
    await tester.pump(const Duration(milliseconds: 300));
  }
  return find.byType(Celebration).evaluate().isNotEmpty;
}

Future<void> _close(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 600));
  }
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  for (final (size, idx, tier) in [(ipad, 0, 'easy'), (iphone, 25, 'hard')]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('find_the_same ($tier): wrong cards wobble, the twin completes · $tag', (tester) async {
      final s = await testServices();
      expect(s.content.activities[_id]!.rounds[idx].str('tier'), tier);
      await _open(tester, s, idx, size);
      expect(find.byType(ChoiceCard), findsNWidgets(4));
      expect(_right, findsOneWidget);
      expectTouchTargetsCompliant(tester);
      final hints = tester.widget<HintHandLayer>(find.byType(HintHandLayer)).hints;

      for (var miss = 0; miss < 2; miss++) {
        await tester.tap(_wrong.at(miss));
        expect(await _pumpUntilCelebration(tester, steps: 5), isFalse);
      }
      // Two misses: the twin glows, and the hand would tap it.
      expect(hints.level.value, 1);
      final move = hints.guide!()!;
      expect(move.to, isNull, reason: 'a tap, not a drag');
      expect((tester.getCenter(find.byKey(move.from)) - tester.getCenter(_right)).distance, lessThan(1));
      hints.demonstrate();
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull);

      await tester.tap(_right);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ChoiceCard), findsNWidgets(3), reason: 'the twin flies into the glass');
      expect(await _pumpUntilCelebration(tester), isTrue);
      expect(hints.guide!(), isNull, reason: 'nothing left to demonstrate');
      expect(tester.takeException(), isNull);
      await _close(tester);
    });
  }

  testWidgets('every round completes on iPhone; targets and gaps stay compliant', (tester) async {
    final s = await testServices(locale: 'zh');
    final rounds = s.content.activities[_id]!.rounds;
    for (var idx = 0; idx < rounds.length; idx++) {
      await _open(tester, s, idx, iphone);
      expectTouchTargetsCompliant(tester);
      expect(find.byType(ChoiceCard), findsNWidgets(4), reason: 'round $idx');
      await tester.tap(_right);
      expect(await _pumpUntilCelebration(tester), isTrue, reason: 'round $idx did not complete');
      expect(tester.takeException(), isNull);
      await _close(tester);
    }
  });
}
