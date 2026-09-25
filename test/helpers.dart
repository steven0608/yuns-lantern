import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yuns_lantern/app.dart';
import 'package:yuns_lantern/core/app_scope.dart';
import 'package:yuns_lantern/core/tokens.dart';
import 'package:yuns_lantern/core/ui/touch_target.dart';
import 'package:yuns_lantern/main.dart';

/// iPad landscape and iPhone landscape: every layout must work on both.
const ipad = Size(1366, 1024);
const iphone = Size(844, 390);

Future<Services> testServices({String locale = 'en', bool fullAccess = true, int age = 5}) async {
  SharedPreferences.setMockInitialValues({
    'locale': locale,
    'purchased': fullAccess,
    'childAge': age,
  });
  return createServices(useAudioDevice: false);
}

Future<void> setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> pumpApp(WidgetTester tester, Services s, {Widget? home, Size size = ipad}) async {
  await setSurface(tester, size);
  await tester.pumpWidget(YunsLanternApp(services: s, home: home));
  await tester.pump(const Duration(milliseconds: 800));
}

/// Fails if any on-screen TouchTarget is under the 88px minimum or two targets
/// sit closer than the 64px minimum gap (CLAUDE.md "Enforce in code").
void expectTouchTargetsCompliant(WidgetTester tester, {bool checkGaps = true}) {
  final rects = <Rect>[];
  // Only targets a finger can reach: skips pages a PageView keeps off-screen.
  for (final e in find.byType(TouchTarget).hitTestable().evaluate()) {
    final box = e.renderObject! as RenderBox;
    if (!box.hasSize || !box.attached) continue;
    // Visible area = padded box minus hit slop.
    final r = (box.localToGlobal(Offset.zero) & box.size).deflate(kHitSlop / 2);
    expect(r.width, greaterThanOrEqualTo(kMinTouchTarget - 0.5), reason: 'touch target too narrow: $r');
    expect(r.height, greaterThanOrEqualTo(kMinTouchTarget - 0.5), reason: 'touch target too short: $r');
    rects.add(r);
  }
  if (!checkGaps) return;
  for (var i = 0; i < rects.length; i++) {
    for (var j = i + 1; j < rects.length; j++) {
      final a = rects[i], b = rects[j];
      final dx = [0.0, b.left - a.right, a.left - b.right].reduce((x, y) => x > y ? x : y);
      final dy = [0.0, b.top - a.bottom, a.top - b.bottom].reduce((x, y) => x > y ? x : y);
      final gap = dx > dy ? dx : dy;
      expect(gap, greaterThanOrEqualTo(kMinTargetGap - 0.5),
          reason: 'targets too close ($gap px): $a vs $b');
    }
  }
}
