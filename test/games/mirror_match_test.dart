// Plays real Mirror Match rounds (2-row and 3-row grids): a piece dropped on
// the wrong row returns softly and escalates help; placing every mirrored
// piece in its own row completes the round. Never pumpAndSettle.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuns_lantern/core/app_scope.dart';
import 'package:yuns_lantern/core/tokens.dart';
import 'package:yuns_lantern/games/mirror_match/mirror_match.dart';
import 'package:yuns_lantern/games/shared/activity_scaffold.dart';
import 'package:yuns_lantern/games/shared/celebration.dart';
import 'package:yuns_lantern/games/shared/draggable_item.dart';
import 'package:yuns_lantern/games/shared/drop_target.dart';
import 'package:yuns_lantern/games/shared/gentle_hint.dart';

import '../helpers.dart';

const _id = 'mirror_match';

Finder _piece(int p) => find.byWidgetPredicate((w) => w is DraggableItem && w.data == 'piece:$p');
Finder _row(int r) => find.byWidgetPredicate((w) => w is DropTarget && w.id == 'row$r');

/// Pumps in small steps for up to [max]; true as soon as [f] shows up.
Future<bool> _pumpUntilFound(WidgetTester tester, Finder f, {Duration max = const Duration(seconds: 4)}) async {
  for (var t = Duration.zero; t < max; t += const Duration(milliseconds: 200)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (f.evaluate().isNotEmpty) return true;
  }
  return false;
}

Future<void> _drag(WidgetTester tester, Finder from, Finder to) async {
  final g = await tester.startGesture(tester.getCenter(from));
  await g.moveBy(const Offset(20, -20));
  await tester.pump();
  await g.moveTo(tester.getCenter(to));
  await tester.pump();
  await g.up();
}

Future<int> _open(WidgetTester tester, Services s, int roundIndex, Size size) async {
  final rounds = s.content.activities[_id]!.rounds;
  if (roundIndex > 0) {
    await tester.runAsync(() async => s.progress.roundCompleted(_id, roundIndex - 1, rounds.length));
  }
  await pumpApp(tester, s, home: ActivitySession(game: mirrorMatchGame), size: size);
  await tester.pump(const Duration(seconds: 1)); // tray pieces pop in
  return rounds[roundIndex].integer('cells') ~/ 2;
}

void main() {
  for (final size in [ipad, iphone]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';
    // Round 0 is "simple" (4 cells, 2 rows); round 8 is "detailed" (6 cells, 3 rows).
    for (final roundIndex in [0, 8]) {
      testWidgets('round $roundIndex: wrong rows never complete; every piece in its row does · $tag', (tester) async {
        final s = await testServices(locale: roundIndex == 0 ? 'en' : 'zh');
        final rows = await _open(tester, s, roundIndex, size);
        expect(find.byType(DraggableItem), findsNWidgets(rows));
        expect(rows, lessThanOrEqualTo(kMaxInteractiveItems));

        for (var i = 0; i < 2; i++) {
          await _drag(tester, _piece(0), _row(1));
          expect(await _pumpUntilFound(tester, find.byType(Celebration), max: const Duration(seconds: 2)), isFalse);
          expect(_piece(0), findsOneWidget, reason: 'a mismatched piece floats back to the tray');
        }

        // Help focuses on the piece the child just tried: piece 0 → row 0.
        final hints = tester.widget<HintHandLayer>(find.byType(HintHandLayer)).hints;
        expect(hints.level.value, 1, reason: 'second miss glows the right row');
        final move = hints.guide!()!;
        expect(find.descendant(of: find.byKey(move.from), matching: _piece(0)), findsOneWidget);
        expect((tester.widget(find.byKey(move.to!)) as DropTarget).id, 'row0');

        for (var p = rows - 1; p >= 0; p--) {
          await _drag(tester, _piece(p), _row(p));
          for (var i = 0; i < 3; i++) {
            await tester.pump(const Duration(milliseconds: 300)); // several frames: the snap glides in
          }
          expect(_piece(p), findsNothing, reason: 'piece $p settles into its row');
          if (p > 0) expect(find.byType(Celebration), findsNothing);
        }
        expect(await _pumpUntilFound(tester, find.byType(Celebration)), isTrue);
        expect(hints.guide!(), isNull, reason: 'nothing left to demonstrate');
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1)); // let in-flight VO sequences finish
      });
    }
  }
}
