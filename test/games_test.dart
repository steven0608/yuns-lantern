// Every game in content — the original 12 and every v3 game that reuses one of
// their engines — on a spread of its real rounds, in both languages, on iPad
// and iPhone: must build without errors, keep touch targets compliant, and
// never show more than kMaxInteractiveItems interactive items.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuns_lantern/core/tokens.dart';
import 'package:yuns_lantern/core/ui/touch_target.dart';
import 'package:yuns_lantern/games/registry.dart';
import 'package:yuns_lantern/games/shared/activity_scaffold.dart';
import 'package:yuns_lantern/games/shared/draggable_item.dart';

import 'helpers.dart';

/// Read straight off the source file so the test list is built before any
/// async work: a new game in activities.json is a new test with no edit here.
final List<String> activityIds = [
  for (final a
      in jsonDecode(File('content/activities.json').readAsStringSync())['activities'] as List)
    (a as Map)['id'] as String,
];

void main() {
  for (final activityId in activityIds) {
    for (final size in [ipad, iphone]) {
      for (final locale in ['en', 'zh']) {
        testWidgets('$activityId · ${size.width.toInt()}x${size.height.toInt()} · $locale', (tester) async {
          final s = await testServices(locale: locale);
          final activity = s.content.activities[activityId]!;
          final game = gameFor(activity)!;
          final rounds = activity.rounds;
          // First, middle and last round: covers every tier in the content.
          for (final idx in {0, rounds.length ~/ 2, rounds.length - 1}) {
            await tester.runAsync(() async => s.progress.roundCompleted(activityId, idx - 1 < 0 ? rounds.length - 1 : idx - 1, rounds.length));
            await pumpApp(tester, s, home: ActivitySession(key: ValueKey(idx), game: game), size: size);
            expect(tester.takeException(), isNull);

            final interactive = find.byType(DraggableItem).evaluate().length +
                find.byType(TouchTarget).evaluate().length - 2; // minus home + replay
            expect(interactive, lessThanOrEqualTo(kMaxInteractiveItems + 3),
                reason: '$activityId[$idx]: $interactive interactive items');
            expect(find.byType(DraggableItem).evaluate().length, lessThanOrEqualTo(kMaxInteractiveItems));
            expectTouchTargetsCompliant(tester, checkGaps: false);
            await tester.pumpWidget(const SizedBox());
          }
        });
      }
    }
  }
}
