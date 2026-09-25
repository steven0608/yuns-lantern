// Plays real Pattern Parade rounds: wrong answers never complete the round
// (they escalate help instead); the right answer — dragged or tapped — does.
// Never pumpAndSettle: Yun animates forever.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuns_lantern/core/app_scope.dart';
import 'package:yuns_lantern/games/pattern_parade/pattern_parade.dart';
import 'package:yuns_lantern/games/shared/activity_scaffold.dart';
import 'package:yuns_lantern/games/shared/celebration.dart';
import 'package:yuns_lantern/games/shared/draggable_item.dart';
import 'package:yuns_lantern/games/shared/drop_target.dart';
import 'package:yuns_lantern/games/shared/gentle_hint.dart';

import '../helpers.dart';

const _id = 'pattern_parade';

Finder _draggable(String data) => find.byWidgetPredicate((w) => w is DraggableItem && w.data == data);

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

/// Opens [roundIndex] and returns its answer and a wrong choice.
Future<(String, String)> _open(WidgetTester tester, Services s, int roundIndex, Size size) async {
  final rounds = s.content.activities[_id]!.rounds;
  if (roundIndex > 0) {
    await tester.runAsync(() async => s.progress.roundCompleted(_id, roundIndex - 1, rounds.length));
  }
  await pumpApp(tester, s, home: ActivitySession(game: patternParadeGame), size: size);
  await tester.pump(const Duration(seconds: 1)); // let the parade march in
  final r = rounds[roundIndex];
  final answer = r.str('answer');
  return (answer, r.strings('choices').firstWhere((c) => c != answer));
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1)); // let in-flight VO sequences finish
}

void main() {
  for (final size in [ipad, iphone]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('wrong drops return softly and never complete; the right drop does · $tag', (tester) async {
      final s = await testServices();
      final (answer, wrong) = await _open(tester, s, 0, size);

      for (var i = 0; i < 2; i++) {
        await _drag(tester, _draggable(wrong), find.byType(DropTarget));
        expect(await _pumpUntilFound(tester, find.byType(Celebration), max: const Duration(seconds: 2)), isFalse);
        expect(_draggable(wrong), findsOneWidget, reason: 'a wrong card floats back to the tray');
      }

      // The hint hand would demonstrate: the right card → the empty slot.
      final hints = tester.widget<HintHandLayer>(find.byType(HintHandLayer)).hints;
      expect(hints.level.value, 1, reason: 'second miss glows the right card');
      final move = hints.guide!()!;
      expect(find.descendant(of: find.byKey(move.from), matching: _draggable(answer)), findsOneWidget);
      expect(tester.widget(find.byKey(move.to!)), isA<DropTarget>());

      await _drag(tester, _draggable(answer), find.byType(DropTarget));
      expect(await _pumpUntilFound(tester, find.byType(Celebration)), isTrue);
      expect(hints.guide!(), isNull, reason: 'nothing left to demonstrate');
      await _close(tester);
    });

    testWidgets('tapping works too: a wrong tap wobbles, the right tap completes · $tag', (tester) async {
      final s = await testServices(locale: 'zh');
      // A mid-sequence (ABABA?) round: the answer is not the first item.
      final (answer, wrong) = await _open(tester, s, 10, size);

      await tester.tap(_draggable(wrong));
      expect(await _pumpUntilFound(tester, find.byType(Celebration), max: const Duration(seconds: 2)), isFalse);
      expect(_draggable(wrong), findsOneWidget);

      await tester.tap(_draggable(answer));
      expect(await _pumpUntilFound(tester, find.byType(Celebration)), isTrue);
      await _close(tester);
    });
  }

  testWidgets('every round offers the answer among at most three choices', (tester) async {
    final s = await testServices();
    for (final r in s.content.activities[_id]!.rounds) {
      expect(r.strings('choices'), contains(r.str('answer')), reason: 'round ${r.index} is not completable');
      expect(r.strings('choices').length, lessThanOrEqualTo(3));
    }
  });
}
