// Puzzle Pieces: plays real rounds by dragging pieces into the frame's holes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuns_lantern/core/app_scope.dart';
import 'package:yuns_lantern/games/puzzle_pieces/puzzle_pieces.dart';
import 'package:yuns_lantern/games/shared/activity_scaffold.dart';
import 'package:yuns_lantern/games/shared/celebration.dart';
import 'package:yuns_lantern/games/shared/draggable_item.dart';
import 'package:yuns_lantern/games/shared/drop_target.dart';
import 'package:yuns_lantern/games/shared/gentle_hint.dart';

import '../helpers.dart';

Future<String> _openRound(WidgetTester tester, Services s, int idx, Size size) async {
  final rounds = s.content.activities[puzzlePiecesGame.id]!.rounds;
  final n = rounds.length;
  await tester.runAsync(() async => s.progress.roundCompleted(puzzlePiecesGame.id, (idx - 1) % n, n));
  await pumpApp(tester, s, home: ActivitySession(key: ValueKey(idx), game: puzzlePiecesGame), size: size);
  return rounds[idx].str('scene');
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

Future<void> _settleAndClose(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 600));
  }
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 100));
}

Finder _piece(String data) => find.byWidgetPredicate((w) => w is DraggableItem && w.data == data);
Finder _hole(int q) => find.byWidgetPredicate((w) => w is DropTarget && w.id == 'hole$q');

List<String> _pieces(WidgetTester tester) =>
    [for (final e in find.byType(DraggableItem).evaluate()) (e.widget as DraggableItem).data];

/// Right pieces for this scene, as (data, quadrant).
List<(String, int)> _rightPieces(WidgetTester tester, String scene) => [
      for (final d in _pieces(tester))
        if (d.startsWith('piece:$scene:')) (d, int.parse(d.split(':').last)),
    ];

Future<void> _solve(WidgetTester tester, String scene) async {
  for (final (data, q) in _rightPieces(tester, scene)) {
    expect(find.byType(Celebration), findsNothing);
    await _dragTo(tester, _piece(data), tester.getCenter(_hole(q)));
  }
}

void main() {
  testWidgets('puzzle_pieces (missing): a decoy floats home and escalates help; the right piece completes',
      (tester) async {
    final s = await testServices();
    final scene = await _openRound(tester, s, 0, ipad);
    expect(find.byType(DraggableItem), findsNWidgets(3));
    final right = _rightPieces(tester, scene);
    expect(right, hasLength(1));
    final (rightData, q) = right.single;
    final decoys = _pieces(tester).where((d) => d != rightData).toList();
    expect(decoys, hasLength(2));
    expect(decoys.every((d) => !d.startsWith('piece:$scene:')), isTrue, reason: 'decoys come from other scenes');

    final hints = tester.widget<HintHandLayer>(find.byType(HintHandLayer)).hints;
    // Three decoy drops: each floats home, the round goes on, help escalates.
    for (var miss = 0; miss < 3; miss++) {
      final decoy = decoys[miss % 2];
      final home = tester.getCenter(_piece(decoy));
      await _dragTo(tester, _piece(decoy), tester.getCenter(_hole(q)));
      expect(tester.getCenter(_piece(decoy)), home);
      expect(find.byType(Celebration), findsNothing);
    }
    expect(hints.level.value, 2);
    final move = hints.hand.value!;
    expect((tester.getCenter(find.byKey(move.from)) - tester.getCenter(_piece(rightData))).distance, lessThan(1));
    expect((tester.getCenter(find.byKey(move.to!)) - tester.getCenter(_hole(q))).distance, lessThan(1));
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);

    await _dragTo(tester, _piece(rightData), tester.getCenter(_hole(q)));
    await _pumpUntilCelebration(tester);
    expect(find.byType(Celebration), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _settleAndClose(tester);
  });

  testWidgets('puzzle_pieces (four): a piece in the wrong hole floats home; all four complete', (tester) async {
    final s = await testServices();
    final scene = await _openRound(tester, s, 8, ipad);
    final right = _rightPieces(tester, scene);
    expect(right, hasLength(4));
    final (data, q) = right.first;
    final home = tester.getCenter(_piece(data));
    await _dragTo(tester, _piece(data), tester.getCenter(_hole((q + 1) % 4)));
    expect(tester.getCenter(_piece(data)), home);
    expect(find.byType(DraggableItem), findsNWidgets(4));

    await _solve(tester, scene);
    expect(find.byType(DraggableItem), findsNothing);
    await _pumpUntilCelebration(tester);
    expect(find.byType(Celebration), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _settleAndClose(tester);
  });

  testWidgets('puzzle_pieces: every round completes on iPhone', (tester) async {
    final s = await testServices(locale: 'zh');
    final n = s.content.activities[puzzlePiecesGame.id]!.rounds.length;
    for (var idx = 0; idx < n; idx++) {
      final scene = await _openRound(tester, s, idx, iphone);
      expect(_rightPieces(tester, scene), isNotEmpty);
      await _solve(tester, scene);
      await _pumpUntilCelebration(tester);
      expect(find.byType(Celebration), findsOneWidget, reason: 'round $idx did not complete');
      expect(tester.takeException(), isNull);
      await _settleAndClose(tester);
    }
  });
}
