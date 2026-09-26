import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

/// Parses all content files once at startup. Everything the child sees or
/// hears is looked up here — see CLAUDE.md "Content is data, not code".
class Content {
  Content._(
    this.vocab,
    this.phrases,
    this.activities,
    this.story,
    this.art, {
    this.engines = const {},
    this.catalog = const {},
    this.themes = const [],
    this.tales = const [],
  });

  final Map<String, VocabItem> vocab;
  final Map<String, Bilingual> phrases;
  final Map<String, Activity> activities; // insertion order = SPEC §5 order
  final Story story;
  final ArtCatalog art;

  /// v3 expansion (optional files; empty when absent).
  final Map<String, CatalogEngine> engines;
  final Map<String, CatalogGame> catalog;
  final List<TaleTheme> themes;
  final List<Tale> tales;

  static Future<Content> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    // Which art files exist, so real illustrations replace placeholders one
    // file at a time with no code change.
    Set<String> files = const {};
    try {
      files = (await AssetManifest.loadFromAssetBundle(b)).listAssets().toSet();
    } catch (_) {}
    // Decode on this isolate: loadString() hands files over 50KB to compute(),
    // which stalls under the widget-test clock and buys nothing for ~100KB.
    Future<Json> read(String path) async =>
        jsonDecode(utf8.decode((await b.load(path)).buffer.asUint8List()))
            as Json;

    final vocabJson = await read('content/vocab.json');
    final phrasesJson = await read('content/phrases.json');
    final actsJson = await read('content/activities.json');
    final storyJson = await read('content/story.json');
    final artJson = await read('assets/images/placeholder_art.json');
    Future<Json?> optional(String path) async {
      try {
        return await read(path);
      } catch (_) {
        return null;
      }
    }

    final catalogJson = await optional('content/catalog.json');
    final libraryJson = await optional('content/library.json');

    final vocab = {
      for (final i in vocabJson['items'] as List)
        (i as Json)['id'] as String: VocabItem(i),
    };
    final phrases = {
      for (final e in (phrasesJson['phrases'] as Json).entries)
        e.key: Bilingual.fromJson(e.value as Json),
    };
    final activities = {
      for (final a in actsJson['activities'] as List)
        (a as Json)['id'] as String: Activity(a),
    };
    return Content._(
      vocab,
      phrases,
      activities,
      Story(storyJson),
      ArtCatalog(artJson, files),
      engines: {
        for (final e in catalogJson?['engines'] as List? ?? const [])
          (e as Json)['id'] as String: CatalogEngine(e),
      },
      catalog: {
        for (final g in catalogJson?['games'] as List? ?? const [])
          (g as Json)['id'] as String: CatalogGame(g),
      },
      themes: [
        for (final t in libraryJson?['themes'] as List? ?? const [])
          TaleTheme(t as Json),
      ],
      tales: [
        for (final t in libraryJson?['tales'] as List? ?? const [])
          Tale(t as Json),
      ],
    );
  }

  VocabItem item(String id) =>
      vocab[id] ??
      (throw StateError('Unknown vocab id "$id" — fix content, not code'));

  /// The spoken copy for a VO key (phrases, item.*, story.*). Feeds the debug
  /// caption overlay and tests; never shown to the child in release builds.
  Bilingual? lineFor(String key) {
    if (key.startsWith('item.')) return vocab[key.substring(5)]?.name;
    if (key.startsWith('tales.')) {
      // tales.<taleId>.p<N>
      final parts = key.split('.');
      final tale = tales.where((t) => t.id == parts[1]).firstOrNull;
      final n = int.tryParse(parts[2].substring(1)) ?? 0;
      return (tale != null && n >= 1 && n <= tale.pages.length)
          ? tale.pages[n - 1]
          : null;
    }
    if (key.startsWith('story.')) {
      final parts = key.split('.');
      for (final c in story.chapters) {
        if (c.id == parts[1]) {
          return switch (parts[2]) {
            'open' => c.open,
            'beat' => c.beat,
            _ => c.close,
          };
        }
      }
    }
    return phrases[key];
  }
}

/// Placeholder art lookups (assets/images/placeholder_art.json).
class ArtCatalog {
  ArtCatalog(Json j, [this.files = const {}])
    : items = Map<String, String>.from(j['items'] as Json),
      categories = Map<String, String>.from(j['categories'] as Json),
      activityIcons = Map<String, String>.from(j['activities'] as Json),
      scenes = {
        for (final e in (j['scenes'] as Json).entries)
          e.key: SceneArt(e.key, e.value as Json, files),
      };
  final Map<String, String> items;
  final Map<String, String> categories;
  final Map<String, String> activityIcons;
  final Map<String, SceneArt> scenes;
  final Set<String> files;

  /// Illustration for a vocab/prop id, when one has been drawn.
  String? itemImage(String id) {
    final path = 'assets/images/items/$id.png';
    return files.contains(path) ? path : null;
  }

  /// A game's own icon (`design/png/games/{id}.png`) or, for the 12 v2
  /// activities, their home-screen tile.
  String? tileImage(String activityId) {
    for (final path in ['assets/images/games/$activityId.png', 'assets/images/tiles/$activityId.png']) {
      if (files.contains(path)) return path;
    }
    return null;
  }

  String? landImage(String engineId) {
    final path = 'assets/images/lands/$engineId.png';
    return files.contains(path) ? path : null;
  }

  String? taleArt(String path) => files.contains(path) ? path : null;

  String? lightImage(String name) {
    final path = 'assets/images/lights/$name.png';
    return files.contains(path) ? path : null;
  }
}

class SceneArt {
  SceneArt(this.id, Json j, Set<String> files)
    : image = files.contains('assets/images/scenes/$id.png')
          ? 'assets/images/scenes/$id.png'
          : null,
      emoji = List<String>.from(j['emoji'] as List),
      sky = _hex(j['sky'] as String),
      ground = _hex(j['ground'] as String);
  final String id;

  /// The chapter illustration (design canvas export), if present.
  final String? image;
  final List<String> emoji;
  final Color sky;
  final Color ground;
  static Color _hex(String s) =>
      Color(int.parse(s.substring(1), radix: 16) | 0xFF000000);
}
