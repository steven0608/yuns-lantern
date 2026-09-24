import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuns_lantern/core/tokens.dart';
import 'package:yuns_lantern/games/shared/activity_scaffold.dart';
import 'package:yuns_lantern/games/shared/cards.dart';
import 'package:yuns_lantern/games/shared/celebration.dart';
import 'package:yuns_lantern/games/shared/draggable_item.dart';
import 'package:yuns_lantern/games/shared/drop_target.dart';
import 'package:yuns_lantern/games/shared/gentle_hint.dart';
import 'package:yuns_lantern/screens/home_screen.dart';
import 'package:yuns_lantern/screens/parent/parent_gate.dart';

import 'helpers.dart';

void main() {
  group('HintController', () {
    test('escalates: retry → pulse → hand, and never repeats a line twice running', () {
      final spoken = <String>[];
      final h = HintController(speak: spoken.add, onIdlePrompt: () {});
      h.miss();
      expect(h.level.value, 0);
      h.miss();
      expect(h.level.value, 1);
      h.miss();
      expect(h.level.value, 2);
      expect(spoken.first.startsWith('feedback.retry'), isTrue);
      expect(spoken.last.startsWith('feedback.hint'), isTrue);
      expect(spoken[0], isNot(spoken[1]));
      h.succeeded();
      expect(h.level.value, 0);
      h.dispose();
    });

    testWidgets('idle: short prompt at 8s, demonstration at 20s', (tester) async {
      var prompts = 0;
      final h = HintController(speak: (_) {}, onIdlePrompt: () => prompts++)..start();
      await tester.pump(kIdleHintDelay + const Duration(milliseconds: 10));
      expect(prompts, 1);
      await tester.pump(kIdleHintRepeat + const Duration(milliseconds: 10));
      expect(h.level.value, 2);
      h.dispose();
    });
  });

  group('DraggableItem + DropTarget', () {
    Widget board({required bool accept, required List<String> log}) => ActivityScaffold(
          onHome: () {},
          body: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            DraggableItem(data: 'apple', child: const ItemCard(id: 'apple')),
            DropTarget(
              id: 'bin',
              willAccept: (_) => accept,
              onAccept: (d) => log.add('accept:$d'),
              onReject: (d) => log.add('reject:$d'),
              child: const SizedBox(width: 200, height: 200),
            ),
          ]),
        );

    Future<void> dragToBin(WidgetTester tester) async {
      final from = tester.getCenter(find.byType(ItemCard));
      final to = tester.getCenter(find.byType(DropTarget));
      final g = await tester.startGesture(from);
      await g.moveBy(const Offset(20, 0));
      await g.moveTo(to);
      await g.up();
      await tester.pump(const Duration(milliseconds: 600)); await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('accepted drop snaps in', (tester) async {
      final s = await testServices();
      final log = <String>[];
      await pumpApp(tester, s, home: board(accept: true, log: log));
      await dragToBin(tester);
      expect(log, ['accept:apple']);
    });

    testWidgets('rejected drop floats home softly, reporting a miss', (tester) async {
      final s = await testServices();
      final log = <String>[];
      await pumpApp(tester, s, home: board(accept: false, log: log));
      final home = tester.getCenter(find.byType(ItemCard));
      await dragToBin(tester);
      expect(log, ['reject:apple']);
      expect(tester.getCenter(find.byType(ItemCard)), home);
    });
  });

  testWidgets('Celebration runs ~1.8s then calls onDone', (tester) async {
    final s = await testServices();
    var done = false;
    await pumpApp(tester, s, home: Scaffold(body: Celebration(onDone: () => done = true)));
    await tester.pump(kCelebrationLength + const Duration(milliseconds: 50));
    expect(done, isTrue);
  });

  testWidgets('home screen touch targets are compliant on iPad and iPhone', (tester) async {
    for (final size in [ipad, iphone]) {
      final s = await testServices();
      await pumpApp(tester, s, home: const HomeScreen(), size: size);
      await tester.pump(const Duration(seconds: 2));
      expectTouchTargetsCompliant(tester);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('parental gate: wrong answer returns silently to the child', (tester) async {
    final s = await testServices();
    await pumpApp(tester, s, home: const HomeScreen());
    await tester.pump(const Duration(seconds: 2));
    openParentArea(tester.element(find.byType(HomeScreen)));
    await tester.pump(const Duration(milliseconds: 600)); await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(ParentGate), findsOneWidget);
    await tester.tap(find.text('1'));
    await tester.tap(find.text('OK'));
    await tester.pump(const Duration(milliseconds: 600)); await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(ParentGate), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
