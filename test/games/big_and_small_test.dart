// Big and Small: plays real rounds by dragging each item onto its step.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuns_lantern/core/app_scope.dart';
import 'package:yuns_lantern/games/big_and_small/big_and_small.dart';
import 'package:yuns_lantern/games/shared/activity_scaffold.dart';
import 'package:yuns_lantern/games/shared/celebration.dart';
import 'package:yuns_lantern/games/shared/draggable_item.dart';
import 'package:yuns_lantern/games/shared/drop_target.dart';
import 'package:yuns_lantern/games/shared/gentle_hint.dart';

import '../helpers.dart';

Future<List<String>> _openRound(WidgetTester tester, Services s, int idx, Size size) async {
  final rounds = s.content.activities[bigAndSmallGame.id]!.rounds;
  final n = rounds.length;
  await tester.runAsync(() async => s.progress.roundCompleted(bigAndSmallGame.id, (idx - 1) % n, n));
  await pumpApp(tester, s, home: ActivitySession(key: ValueKey(idx), game: bigAndSmallGame), size: size);
  return rounds[idx].strings('orderedSmallToLarge');
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

Finder _item(String id) => find.byWidgetPredicate((w) => w is DraggableItem && w.data == id);
Finder _step(int i) => find.byWidgetPredicate((w) => w is DropTarget && w.id == 'step$i');

void main() {
  testWidgets('big_and_small: a wrong step sends the item home; small → big completes', (tester) async {
    final s = await testServices();
    final order = await _openRound(tester, s, 0, ipad);
    expect(find.byType(DraggableItem), findsNWidgets(order.length));
    final hints = tester.widget<HintHandLayer>(find.byType(HintHandLayer)).hints;

    // Before any try, help is about the smallest item → the first step.
    var move = hints.guide!()!;
    expect((tester.getCenter(find.byKey(move.from)) - tester.getCenter(_item(order.first))).distance, lessThan(1));

    // The biggest thing onto the smallest step: floats back, round goes on.
    final home = tester.getCenter(_item(order.last));
    await _dragTo(tester, _item(order.last), tester.getCenter(_step(0)));
    expect(tester.getCenter(_item(order.last)), home);
    expect(find.byType(DraggableItem), findsNWidgets(order.length));
    expect(find.byType(Celebration), findsNothing);

    // Now help is about the item the child just tried → its own step.
    // Calls the game's hint contract directly: showing the hand itself trips
    // a shared HintHandLayer bug (reads a detached render box on first show).
    move = hints.guide!()!;
    expect((tester.getCenter(find.byKey(move.from)) - home).distance, lessThan(1));
    expect((tester.getCenter(find.byKey(move.to!)) - tester.getCenter(_step(order.length - 1))).distance, lessThan(1));

    for (var i = 0; i < order.length; i++) {
      expect(find.byType(Celebration), findsNothing);
      await _dragTo(tester, _item(order[i]), tester.getCenter(_step(i)));
    }
    expect(find.byType(DraggableItem), findsNothing);
    await _pumpUntilCelebration(tester);
    expect(find.byType(Celebration), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _settleAndClose(tester);
  });

  testWidgets('big_and_small: every round completes on iPhone, biggest first', (tester) async {
    final s = await testServices(locale: 'zh');
    final n = s.content.activities[bigAndSmallGame.id]!.rounds.length;
    for (var idx = 0; idx < n; idx++) {
      final order = await _openRound(tester, s, idx, iphone);
      for (var i = order.length - 1; i >= 0; i--) {
        await _dragTo(tester, _item(order[i]), tester.getCenter(_step(i)));
      }
      expect(find.byType(DraggableItem), findsNothing, reason: 'round $idx: not every item placed');
      await _pumpUntilCelebration(tester);
      expect(find.byType(Celebration), findsOneWidget, reason: 'round $idx did not complete');
      expect(tester.takeException(), isNull);
      await _settleAndClose(tester);
    }
  });
}
