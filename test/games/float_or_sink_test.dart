// Float or Sink: plays real rounds by dragging every item into the tank.
// There are no wrong answers, so nothing here ever expects a miss.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuns_lantern/core/app_scope.dart';
import 'package:yuns_lantern/core/tokens.dart';
import 'package:yuns_lantern/games/float_or_sink/float_or_sink.dart';
import 'package:yuns_lantern/games/shared/activity_scaffold.dart';
import 'package:yuns_lantern/games/shared/celebration.dart';
import 'package:yuns_lantern/games/shared/draggable_item.dart';
import 'package:yuns_lantern/games/shared/drop_target.dart';
import 'package:yuns_lantern/games/shared/gentle_hint.dart';

import '../helpers.dart';

Future<void> _openRound(WidgetTester tester, Services s, int idx, Size size) async {
  final n = s.content.activities[floatOrSinkGame.id]!.rounds.length;
  await tester.runAsync(() async => s.progress.roundCompleted(floatOrSinkGame.id, (idx - 1) % n, n));
  await pumpApp(tester, s, home: ActivitySession(key: ValueKey(idx), game: floatOrSinkGame), size: size);
}

Future<void> _dragTo(WidgetTester tester, Finder item, Offset to) async {
  final g = await tester.startGesture(tester.getCenter(item));
  await g.moveBy(const Offset(20, 0));
  await g.moveTo(to);
  await g.up();
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 600));
  }
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

/// Drops whatever is first on the dock into the middle of the tank until
/// the dock is empty. Returns how many items went in.
Future<int> _dropEverything(WidgetTester tester) async {
  var drops = 0;
  while (find.byType(DraggableItem).evaluate().isNotEmpty) {
    expect(find.byType(Celebration), findsNothing, reason: 'completed before every item was in the water');
    final tank = tester.getRect(find.byType(DropTarget).first).center;
    await _dragTo(tester, find.byType(DraggableItem).first, tank);
    drops++;
    expect(drops, lessThanOrEqualTo(kMaxInteractiveItems));
  }
  return drops;
}

void main() {
  testWidgets('float_or_sink: every item into the water completes the round (iPad)', (tester) async {
    final s = await testServices();
    await _openRound(tester, s, 0, ipad);
    expect(find.byType(DraggableItem), findsNWidgets(kMaxInteractiveItems));

    // The idle demo always has a real move to show: dock item → tank.
    // Calls the game's hint contract directly: showing the hand itself trips
    // a shared HintHandLayer bug (reads a detached render box on first show).
    final hints = tester.widget<HintHandLayer>(find.byType(HintHandLayer)).hints;
    final move = hints.guide!()!;
    expect((tester.getCenter(find.byKey(move.from)) - tester.getCenter(find.byType(DraggableItem).first)).distance, lessThan(1));
    expect(move.to?.currentContext, isNotNull);

    final drops = await _dropEverything(tester);
    expect(drops, kMaxInteractiveItems);
    await _pumpUntilCelebration(tester);
    expect(find.byType(Celebration), findsOneWidget);
    expect(hints.guide!(), isNull); // nothing left to demonstrate
    expect(hints.level.value, 0);
    expect(tester.takeException(), isNull);
    await _settleAndClose(tester);
  });

  testWidgets('float_or_sink: letting go outside the tank just floats home — never a miss', (tester) async {
    final s = await testServices();
    await _openRound(tester, s, 0, ipad);
    final hints = tester.widget<HintHandLayer>(find.byType(HintHandLayer)).hints;
    final item = find.byType(DraggableItem).first;
    final home = tester.getCenter(item);
    // Far corner, away from the tank.
    await _dragTo(tester, item, const Offset(40, 40));
    expect(tester.getCenter(find.byType(DraggableItem).first), home);
    expect(find.byType(DraggableItem), findsNWidgets(kMaxInteractiveItems));
    expect(hints.level.value, 0);
    expect(find.byType(Celebration), findsNothing);
    await _settleAndClose(tester);
  });

  testWidgets('float_or_sink: every round completes on iPhone, where the dock refills', (tester) async {
    final s = await testServices(locale: 'zh');
    final n = s.content.activities[floatOrSinkGame.id]!.rounds.length;
    for (var idx = 0; idx < n; idx++) {
      await _openRound(tester, s, idx, iphone);
      expect(find.byType(DraggableItem).evaluate().length, lessThan(kMaxInteractiveItems));
      final drops = await _dropEverything(tester);
      expect(drops, greaterThan(0));
      await _pumpUntilCelebration(tester);
      expect(find.byType(Celebration), findsOneWidget, reason: 'round $idx did not complete');
      expect(tester.takeException(), isNull);
      await _settleAndClose(tester);
    }
  });
}
