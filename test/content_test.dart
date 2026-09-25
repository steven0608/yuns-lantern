import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yuns_lantern/core/content/content_loader.dart';
import 'package:yuns_lantern/games/registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads all content into typed models', () async {
    final c = await Content.load();
    // Counts come from the source files: content grows (E2 adds vocab and games).
    final vocab = jsonDecode(File('content/vocab.json').readAsStringSync())['items'] as List;
    final acts = jsonDecode(File('content/activities.json').readAsStringSync())['activities'] as List;
    expect(c.vocab.length, vocab.length);
    expect(c.vocab.length, greaterThanOrEqualTo(64));
    expect(c.activities.length, acts.length);
    expect(c.activities.length, greaterThanOrEqualTo(12));
    expect(c.activities.values.fold<int>(0, (n, a) => n + a.rounds.length),
        acts.fold<int>(0, (n, a) => n + ((a as Map)['rounds'] as List).length));
    expect(c.story.chapters.length, 8);
  });

  test('every VO key used by content has copy in both languages', () async {
    final c = await Content.load();
    for (final a in c.activities.values) {
      for (final r in a.rounds) {
        for (final k in r.vo) {
          final line = c.lineFor(k);
          expect(line, isNotNull, reason: '${a.id}[${r.index}] uses VO key $k with no copy');
          expect(line!.en.isNotEmpty && line.zh.isNotEmpty, isTrue);
        }
      }
    }
    for (final ch in c.story.chapters) {
      for (final part in ['open', 'beat', 'close']) {
        expect(c.lineFor(ch.voKey(part)), isNotNull);
      }
    }
  });

  test('every vocab item has placeholder art', () async {
    final c = await Content.load();
    for (final id in c.vocab.keys) {
      expect(c.art.items.containsKey(id), isTrue, reason: 'no art for $id');
    }
  });

  test('all 12 activities have an engine registered', () async {
    final c = await Content.load();
    final missing = c.activities.keys.where((id) => !gameRegistry.containsKey(id)).toList();
    expect(missing, isEmpty, reason: 'activities without an engine: $missing');
  });
}
