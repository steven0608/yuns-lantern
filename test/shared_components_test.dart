import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuns_lantern/core/tokens.dart';
import 'package:yuns_lantern/games/registry.dart';
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

  testWidgets('hint hand demonstrates a drag without errors', (tester) async {
    final s = await testServices();
    final from = GlobalKey(), to = GlobalKey();
    final hints = HintController(speak: (_) {}, onIdlePrompt: () {});
    hints.guide = () => HintMove(from, to);
    await pumpApp(tester, s, home: ActivityScaffold(
      onHome: () {},
      hints: hints,
      body: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        SizedBox(key: from, width: 100, height: 100),
        SizedBox(key: to, width: 100, height: 100),
      ]),
    ));
    hints.demonstrate();
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(tester.takeException(), isNull);
    expect(hints.hand.value, isNotNull);
    await tester.pumpWidget(const SizedBox());
    hints.dispose();
  });

  testWidgets('first game on an engine demonstrates the move once, silently', (tester) async {
    final s = await testServices(firstPlay: true);
    final game = gameRegistry['count_feed']!;
    await pumpApp(tester, s, home: ActivitySession(game: game));
    // Nothing yet: the eye is being led (1.4s) and then the prompt plays.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 600));
    }
    final hints = tester.widget<HintHandLayer>(find.byType(HintHandLayer)).hints;
    expect(hints.hand.value, isNotNull, reason: 'the hand should show the move on a new engine');
    expect(s.progress.engineIsNew('count_feed'), isFalse);

    // Second game on the same engine: no demonstration.
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, s, home: ActivitySession(game: game));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 600));
    }
    expect(tester.widget<HintHandLayer>(find.byType(HintHandLayer)).hints.hand.value, isNull);
    await tester.pumpWidget(const SizedBox());
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
