// Where Is It?: plays real rounds by tapping the room that matches the
// spoken position.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuns_lantern/core/app_scope.dart';
import 'package:yuns_lantern/core/ui/touch_target.dart';
import 'package:yuns_lantern/games/shared/activity_scaffold.dart';
import 'package:yuns_lantern/games/shared/celebration.dart';
import 'package:yuns_lantern/games/shared/gentle_hint.dart';
import 'package:yuns_lantern/games/where_is_it/where_is_it.dart';

import '../helpers.dart';

Future<void> _openRound(WidgetTester tester, Services s, int idx, Size size) async {
  final n = s.content.activities[whereIsItGame.id]!.rounds.length;
  await tester.runAsync(() async => s.progress.roundCompleted(whereIsItGame.id, (idx - 1) % n, n));
  await pumpApp(tester, s, home: ActivitySession(key: ValueKey(idx), game: whereIsItGame), size: size);
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

HintController _hints(WidgetTester tester) => tester.widget<HintHandLayer>(find.byType(HintHandLayer)).hints;

/// The two rooms (the game's only touch targets).
Finder get _rooms => find.descendant(of: find.byType(WhereIsIt), matching: find.byType(TouchTarget));

Finder _right(WidgetTester tester) => find.byKey(_hints(tester).guide!()!.from);

Finder _wrong(WidgetTester tester) {
  final right = _hints(tester).guide!()!.from;
  return find.descendant(
    of: find.byType(WhereIsIt),
    matching: find.byWidgetPredicate((w) => w is TouchTarget && w.key != right),
  );
}

void main() {
  testWidgets('where_is_it: wrong room wobbles and escalates to the hand; right room completes', (tester) async {
    final s = await testServices();
    await _openRound(tester, s, 0, ipad);
    expect(_rooms, findsNWidgets(2));
    expectTouchTargetsCompliant(tester);

    final hints = _hints(tester);
    final wrong = _wrong(tester);
    expect(wrong, findsOneWidget);
    for (var miss = 1; miss <= 3; miss++) {
      await tester.tap(wrong);
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 600));
      }
      expect(find.byType(Celebration), findsNothing, reason: 'a wrong room must never complete the round');
    }
    // Third miss: the right room glows and the hand demonstrates the tap.
    expect(hints.level.value, 2);
    expect(hints.hand.value, isNotNull);
    expect((tester.getCenter(find.byKey(hints.hand.value!.from)) - tester.getCenter(_right(tester))).distance,
        lessThan(1));
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);

    await tester.tap(_right(tester));
    await _pumpUntilCelebration(tester);
    expect(find.byType(Celebration), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _settleAndClose(tester);
  });

  testWidgets('where_is_it: every round completes on iPhone, targets stay compliant', (tester) async {
    final s = await testServices(locale: 'zh');
    final n = s.content.activities[whereIsItGame.id]!.rounds.length;
    for (var idx = 0; idx < n; idx++) {
      await _openRound(tester, s, idx, iphone);
      expect(_rooms, findsNWidgets(2));
      expectTouchTargetsCompliant(tester);
      await tester.tap(_right(tester));
      await _pumpUntilCelebration(tester);
      expect(find.byType(Celebration), findsOneWidget, reason: 'round $idx did not complete');
      expect(tester.takeException(), isNull);
      await _settleAndClose(tester);
    }
  });
}
