// Shape Sorter: plays real rounds by dropping every piece into its hole. A
// piece dropped on the wrong hole floats home and escalates help instead.
// Never pumpAndSettle: Yun animates forever.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuns_lantern/core/app_scope.dart';
import 'package:yuns_lantern/core/art/item_art.dart';
import 'package:yuns_lantern/core/content/models.dart';
import 'package:yuns_lantern/core/tokens.dart';
import 'package:yuns_lantern/games/shape_sorter/shape_sorter.dart';
import 'package:yuns_lantern/games/shared/activity_scaffold.dart';
import 'package:yuns_lantern/games/shared/celebration.dart';
import 'package:yuns_lantern/games/shared/draggable_item.dart';
import 'package:yuns_lantern/games/shared/drop_target.dart';
import 'package:yuns_lantern/games/shared/gentle_hint.dart';

import '../helpers.dart';

const _id = 'shape_sorter';

Finder _piece(int p) => find.byWidgetPredicate((w) => w is DraggableItem && w.data == 'shape:$p');
Finder _hole(int p) => find.byWidgetPredicate((w) => w is DropTarget && w.id == 'hole$p');

Iterable<int> _visible() => find
    .byType(DraggableItem)
    .evaluate()
    .map((e) => int.parse((e.widget as DraggableItem).data.split(':').last));

Future<Round> _open(WidgetTester tester, Services s, int idx, Size size) async {
  final rounds = s.content.activities[_id]!.rounds;
  await tester.runAsync(() async => s.progress.roundCompleted(_id, (idx - 1) % rounds.length, rounds.length));
  await pumpApp(tester, s, home: ActivitySession(key: ValueKey(idx), game: shapeSorterGame), size: size);
  await tester.pump(const Duration(seconds: 1)); // board slides in, pieces pop up
  return rounds[idx];
}

Future<void> _drag(WidgetTester tester, Finder from, Finder to) async {
  final g = await tester.startGesture(tester.getCenter(from));
  await g.moveBy(const Offset(20, -20));
  await tester.pump();
  await g.moveTo(tester.getCenter(to));
  await tester.pump();
  await g.up();
  // The piece glides into the hole (or home) and settles.
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<bool> _pumpUntilCelebration(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
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

Future<void> _sortAll(WidgetTester tester, int pieces) async {
  for (var guard = 0; guard < pieces && _visible().isNotEmpty; guard++) {
    expect(find.byType(Celebration), findsNothing);
    final p = _visible().first;
    await _drag(tester, _piece(p), _hole(p));
    expect(_piece(p), findsNothing, reason: 'piece $p should now be in its hole');
  }
}

void main() {
  for (final size in [ipad, iphone]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('a wrong hole sends the piece home; filling every hole completes · $tag', (tester) async {
      final s = await testServices();
      // The biggest round: five shapes (the phone tray tops up).
      final round = await _open(tester, s, 7, size);
      final n = round.strings('shapes').length;
      expect(n, 5);
      expect(find.byType(DropTarget), findsNWidgets(n));
      expect(find.byType(DraggableItem).evaluate().length, lessThanOrEqualTo(kMaxInteractiveItems));
      final hints = tester.widget<HintHandLayer>(find.byType(HintHandLayer)).hints;

      final p = _visible().first;
      final wrong = (p + 1) % n;
      final home = tester.getCenter(_piece(p));
      for (var miss = 0; miss < 2; miss++) {
        await _drag(tester, _piece(p), _hole(wrong));
        expect(_piece(p), findsOneWidget, reason: 'a wrong drop floats back');
        expect((tester.getCenter(_piece(p)) - home).distance, lessThan(8));
        expect(find.byType(Celebration), findsNothing);
      }

      // Two misses: the right hole glows, and the hand would move this very
      // piece into it.
      expect(hints.level.value, 1);
      final move = hints.guide!()!;
      expect(find.descendant(of: find.byKey(move.from), matching: _piece(p)), findsOneWidget);
      expect((tester.getCenter(find.byKey(move.to!)) - tester.getCenter(_hole(p))).distance, lessThan(1));
      hints.demonstrate();
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull);

      // The first right drop pops that shape's example out of the hole.
      await _drag(tester, _piece(p), _hole(p));
      expect(_piece(p), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.descendant(of: _hole(p), matching: find.byType(ItemArt)), findsOneWidget);

      await _sortAll(tester, n);
      expect(await _pumpUntilCelebration(tester), isTrue);
      expect(hints.guide!(), isNull, reason: 'nothing left to demonstrate');
      expect(tester.takeException(), isNull);
      await _close(tester);
    });
  }

  testWidgets('every round completes on iPhone', (tester) async {
    final s = await testServices(locale: 'zh');
    final rounds = s.content.activities[_id]!.rounds;
    for (var idx = 0; idx < rounds.length; idx++) {
      final round = await _open(tester, s, idx, iphone);
      expectTouchTargetsCompliant(tester);
      await _sortAll(tester, round.strings('shapes').length);
      expect(await _pumpUntilCelebration(tester), isTrue, reason: 'round $idx did not complete');
      expect(tester.takeException(), isNull);
      await _close(tester);
    }
  });
}
