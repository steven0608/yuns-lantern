// Day and Night: plays real rounds by dragging each card to its side, on iPad
// and iPhone; a wrong side never completes; `either` cards fit both sides.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuns_lantern/core/app_scope.dart';
import 'package:yuns_lantern/games/day_and_night/day_and_night.dart';
import 'package:yuns_lantern/games/shared/activity_scaffold.dart';
import 'package:yuns_lantern/games/shared/celebration.dart';
import 'package:yuns_lantern/games/shared/draggable_item.dart';
import 'package:yuns_lantern/games/shared/drop_target.dart';

import '../helpers.dart';

Future<void> _open(WidgetTester tester, Services s, int idx, Size size) async {
  final n = s.content.activities[dayAndNightGame.id]!.rounds.length;
  await tester.runAsync(() async => s.progress.roundCompleted(dayAndNightGame.id, (idx - 1) % n, n));
  await pumpApp(tester, s, home: ActivitySession(key: ValueKey(idx), game: dayAndNightGame), size: size);
}

Future<void> _drag(WidgetTester tester, Finder item, Offset to) async {
  final g = await tester.startGesture(tester.getCenter(item));
  await g.moveBy(const Offset(20, 0));
  await g.moveTo(to);
  await g.up();
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 600));
  }
}

Offset _side(WidgetTester tester, String id) =>
    tester.getCenter(find.byWidgetPredicate((w) => w is DropTarget && w.id == id));

Future<void> _finish(WidgetTester tester) async {
  for (var i = 0; i < 12 && find.byType(Celebration).evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 600));
  }
}

Future<void> _close(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 600));
  }
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  for (final size in [ipad, iphone]) {
    testWidgets('a whole round sorts to completion · ${size.width.toInt()}', (tester) async {
      final s = await testServices();
      final rounds = s.content.activities[dayAndNightGame.id]!.rounds;
      final idx = rounds.indexWhere((r) => r.strings('either').isNotEmpty);
      final r = rounds[idx];
      await _open(tester, s, idx, size);
      final night = r.strings('night').toSet();
      var drops = 0;
      while (find.byType(DraggableItem).evaluate().isNotEmpty) {
        expect(find.byType(Celebration), findsNothing);
        final card = find.byType(DraggableItem).first;
        final id = tester.widget<DraggableItem>(card).data;
        await _drag(tester, card, _side(tester, night.contains(id) ? 'night' : 'day'));
        expect(++drops, lessThanOrEqualTo(6));
      }
      await _finish(tester);
      expect(find.byType(Celebration), findsOneWidget);
      await _close(tester);
    });
  }

  testWidgets('a wrong side floats home and never completes', (tester) async {
    final s = await testServices();
    await _open(tester, s, 0, ipad);
    final r = s.content.activities[dayAndNightGame.id]!.rounds[0];
    final dayCard = find.byWidgetPredicate((w) => w is DraggableItem && r.strings('day').contains(w.data));
    final before = find.byType(DraggableItem).evaluate().length;
    await _drag(tester, dayCard.first, _side(tester, 'night'));
    expect(find.byType(DraggableItem).evaluate().length, before);
    expect(find.byType(Celebration), findsNothing);
    await _close(tester);
  });

  testWidgets('an either card is welcome on the night side too', (tester) async {
    final s = await testServices();
    final rounds = s.content.activities[dayAndNightGame.id]!.rounds;
    final idx = rounds.indexWhere((r) => r.strings('either').isNotEmpty);
    await _open(tester, s, idx, ipad);
    final either = rounds[idx].strings('either').first;
    final card = find.byWidgetPredicate((w) => w is DraggableItem && w.data == either);
    expect(card, findsOneWidget);
    final before = find.byType(DraggableItem).evaluate().length;
    await _drag(tester, card, _side(tester, 'night'));
    expect(find.byWidgetPredicate((w) => w is DraggableItem && w.data == either), findsNothing);
    expect(find.byType(DraggableItem).evaluate().length, lessThan(before + 1));
    await _close(tester);
  });
}
