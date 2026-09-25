// Match It: plays real rounds by dragging every card into its tub. A wrong
// tub sends the card home and escalates help, never completes the round.
// Never pumpAndSettle: Yun animates forever.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuns_lantern/core/app_scope.dart';
import 'package:yuns_lantern/core/content/models.dart';
import 'package:yuns_lantern/core/tokens.dart';
import 'package:yuns_lantern/games/match_it/match_it.dart';
import 'package:yuns_lantern/games/shared/activity_scaffold.dart';
import 'package:yuns_lantern/games/shared/celebration.dart';
import 'package:yuns_lantern/games/shared/draggable_item.dart';
import 'package:yuns_lantern/games/shared/drop_target.dart';
import 'package:yuns_lantern/games/shared/gentle_hint.dart';

import '../helpers.dart';

const _id = 'match_it';

/// Tub index of every card, in the game's `match:<i>` numbering.
List<int> _binOf(Round r) => [
      for (final (b, bin) in (r.data['bins'] as List).indexed)
        for (final _ in (bin as Map)['items'] as List) b,
    ];

Finder _card(int i) => find.byWidgetPredicate((w) => w is DraggableItem && w.data == 'match:$i');
Finder _tub(int b) => find.byWidgetPredicate((w) => w is DropTarget && w.id == 'bin$b');

Iterable<int> _visible() => find
    .byType(DraggableItem)
    .evaluate()
    .map((e) => int.parse((e.widget as DraggableItem).data.split(':').last));

Future<Round> _open(WidgetTester tester, Services s, int idx, Size size) async {
  final rounds = s.content.activities[_id]!.rounds;
  await tester.runAsync(() async => s.progress.roundCompleted(_id, (idx - 1) % rounds.length, rounds.length));
  await pumpApp(tester, s, home: ActivitySession(key: ValueKey(idx), game: matchItGame), size: size);
  await tester.pump(const Duration(seconds: 1)); // cards pop in, tubs rise
  return rounds[idx];
}

Future<void> _drag(WidgetTester tester, Finder from, Finder to) async {
  final g = await tester.startGesture(tester.getCenter(from));
  await g.moveBy(const Offset(20, -20));
  await tester.pump();
  await g.moveTo(tester.getCenter(to));
  await tester.pump();
  await g.up();
  // The card glides into the tub (or home) and settles.
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<bool> _pumpUntilCelebration(WidgetTester tester, {int steps = 12}) async {
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

/// Sorts every card (refills included) into its own tub.
Future<void> _sortAll(WidgetTester tester, List<int> binOf) async {
  for (var guard = 0; guard < binOf.length && _visible().isNotEmpty; guard++) {
    expect(find.byType(Celebration), findsNothing);
    final i = _visible().first;
    await _drag(tester, _card(i), _tub(binOf[i]));
    expect(_card(i), findsNothing, reason: 'card $i should now be in tub ${binOf[i]}');
  }
}

void main() {
  for (final size in [ipad, iphone]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('a wrong tub sends the card home; sorting all six completes · $tag', (tester) async {
      final s = await testServices();
      final round = await _open(tester, s, 0, size);
      final binOf = _binOf(round);
      expect(find.byType(DraggableItem).evaluate().length, lessThanOrEqualTo(kMaxInteractiveItems));
      final hints = tester.widget<HintHandLayer>(find.byType(HintHandLayer)).hints;

      final i = _visible().first;
      final wrong = (binOf[i] + 1) % 3;
      final home = tester.getCenter(_card(i));
      for (var miss = 0; miss < 2; miss++) {
        await _drag(tester, _card(i), _tub(wrong));
        expect(_card(i), findsOneWidget, reason: 'a wrong drop floats back');
        expect((tester.getCenter(_card(i)) - home).distance, lessThan(8));
        expect(find.byType(Celebration), findsNothing);
      }

      // Two misses: the right tub glows, and the hand would move this very
      // card into it.
      expect(hints.level.value, 1);
      final move = hints.guide!()!;
      expect(find.descendant(of: find.byKey(move.from), matching: _card(i)), findsOneWidget);
      expect((tester.getCenter(find.byKey(move.to!)) - tester.getCenter(_tub(binOf[i]))).distance, lessThan(1));
      // The demonstrating hand paints without errors.
      hints.demonstrate();
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull);

      await _sortAll(tester, binOf);
      expect(await _pumpUntilCelebration(tester), isTrue);
      expect(hints.guide!(), isNull, reason: 'nothing left to demonstrate');
      expect(tester.takeException(), isNull);
      await _close(tester);
    });
  }

  testWidgets('every round completes on iPhone (cards top up as they are sorted)', (tester) async {
    final s = await testServices(locale: 'zh');
    final rounds = s.content.activities[_id]!.rounds;
    for (var idx = 0; idx < rounds.length; idx++) {
      final round = await _open(tester, s, idx, iphone);
      expectTouchTargetsCompliant(tester);
      await _sortAll(tester, _binOf(round));
      expect(await _pumpUntilCelebration(tester), isTrue, reason: 'round $idx did not complete');
      expect(tester.takeException(), isNull);
      await _close(tester);
    }
  });

  testWidgets('content: every card has a tub, at most six per round', (tester) async {
    final s = await testServices();
    for (final r in s.content.activities[_id]!.rounds) {
      final bins = r.data['bins'] as List;
      expect(bins.length, 3, reason: 'round ${r.index}');
      expect(_binOf(r).length, lessThanOrEqualTo(kMaxInteractiveItems), reason: 'round ${r.index}');
    }
  });
}
