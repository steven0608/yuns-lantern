import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

/// Parses all content files once at startup. Everything the child sees or
/// hears is looked up here — see CLAUDE.md "Content is data, not code".
class Content {
  Content._(this.vocab, this.phrases, this.activities, this.story, this.art);

  final Map<String, VocabItem> vocab;
  final Map<String, Bilingual> phrases;
  final Map<String, Activity> activities; // insertion order = SPEC §5 order
  final Story story;
  final ArtCatalog art;

  static Future<Content> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    // Decode on this isolate: loadString() hands files over 50KB to compute(),
    // which stalls under the widget-test clock and buys nothing for ~100KB.
    Future<Json> read(String path) async =>
        jsonDecode(utf8.decode((await b.load(path)).buffer.asUint8List())) as Json;

    final vocabJson = await read('content/vocab.json');
    final phrasesJson = await read('content/phrases.json');
    final actsJson = await read('content/activities.json');
    final storyJson = await read('content/story.json');
    final artJson = await read('assets/images/placeholder_art.json');

    final vocab = {
      for (final i in vocabJson['items'] as List) (i as Json)['id'] as String: VocabItem(i),
    };
    final phrases = {
      for (final e in (phrasesJson['phrases'] as Json).entries)
        e.key: Bilingual.fromJson(e.value as Json),
    };
    final activities = {
      for (final a in actsJson['activities'] as List) (a as Json)['id'] as String: Activity(a),
    };
    return Content._(vocab, phrases, activities, Story(storyJson), ArtCatalog(artJson));
  }

  VocabItem item(String id) =>
      vocab[id] ?? (throw StateError('Unknown vocab id "$id" — fix content, not code'));

  /// The spoken copy for a VO key (phrases, item.*, story.*). Feeds the debug
  /// caption overlay and tests; never shown to the child in release builds.
  Bilingual? lineFor(String key) {
    if (key.startsWith('item.')) return vocab[key.substring(5)]?.name;
    if (key.startsWith('story.')) {
      final parts = key.split('.');
      for (final c in story.chapters) {
        if (c.id == parts[1]) {
          return switch (parts[2]) { 'open' => c.open, 'beat' => c.beat, _ => c.close };
        }
      }
    }
    return phrases[key];
  }
}

/// Placeholder art lookups (assets/images/placeholder_art.json).
class ArtCatalog {
  ArtCatalog(Json j)
      : items = Map<String, String>.from(j['items'] as Json),
        categories = Map<String, String>.from(j['categories'] as Json),
        activityIcons = Map<String, String>.from(j['activities'] as Json),
        scenes = {
          for (final e in (j['scenes'] as Json).entries) e.key: SceneArt(e.value as Json),
        };
  final Map<String, String> items;
  final Map<String, String> categories;
  final Map<String, String> activityIcons;
  final Map<String, SceneArt> scenes;
}

class SceneArt {
  SceneArt(Json j)
      : emoji = List<String>.from(j['emoji'] as List),
        sky = _hex(j['sky'] as String),
        ground = _hex(j['ground'] as String);
  final List<String> emoji;
  final Color sky;
  final Color ground;
  static Color _hex(String s) => Color(int.parse(s.substring(1), radix: 16) | 0xFF000000);
}
