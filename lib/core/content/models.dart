// Typed views over content/*.json. The app never invents content: every
// word, round and story line on screen comes from these models.

typedef Json = Map<String, dynamic>;

class Bilingual {
  const Bilingual(this.en, this.zh);
  final String en;
  final String zh;
  factory Bilingual.fromJson(Json j) =>
      Bilingual(j['en'] as String, j['zh'] as String);
  String of(String languageCode) => languageCode == 'zh' ? zh : en;
}

class VocabItem {
  VocabItem(this.json)
    : id = json['id'] as String,
      name = Bilingual.fromJson(json);
  final Json json;
  final String id;
  final Bilingual name;
  String get category => json['category'] as String;
  String get color => json['color'] as String;
  String get shape => json['shape'] as String;
  String get size => json['size'] as String;
  bool? get floats => json['floats'] as bool?;
  String? get timeOfDay => json['timeOfDay'] as String?;
}

/// One playable round. Each activity reads its own fields from [data]; the
/// shape of [data] is documented per builder in tools/build_content.py.
class Round {
  Round(this.activityId, this.index, this.data)
    : vo = List<String>.from(data['vo'] as List? ?? const []);
  final String activityId;
  final int index;
  final Json data;
  final List<String> vo;

  String str(String k) => data[k] as String;
  int integer(String k) => data[k] as int;
  List<String> strings(String k) =>
      List<String>.from(data[k] as List? ?? const []);
}

class Activity {
  Activity(Json j)
    : id = j['id'] as String,
      name = Bilingual.fromJson(j['name'] as Json),
      skill = j['skill'] as String,
      minAge = j['minAge'] as int,
      free = j['free'] as bool,
      engine = j['engine'] as String? ?? j['id'] as String,
      rounds = [] {
    final raw = j['rounds'] as List;
    for (var i = 0; i < raw.length; i++) {
      rounds.add(Round(id, i, raw[i] as Json));
    }
  }
  final String id;
  final Bilingual name;
  final String skill;
  final int minAge;
  final bool free;

  /// Which engine plays this activity. v2 activities are their own engine;
  /// v3 games reuse one (e.g. birthday_candles → count_feed).
  final String engine;
  final List<Round> rounds;
}

class Chapter {
  Chapter(Json j)
    : number = j['number'] as int,
      id = j['id'] as String,
      region = Bilingual.fromJson(j['region'] as Json),
      lightColor = j['lightColor'] as String,
      free = j['free'] as bool,
      open = Bilingual.fromJson(j['open'] as Json),
      beat = Bilingual.fromJson(j['beat'] as Json),
      close = Bilingual.fromJson(j['close'] as Json),
      activities = List<String>.from(j['activities'] as List);
  final int number;
  final String id;
  final Bilingual region;
  final String lightColor;
  final bool free;
  final Bilingual open, beat, close;
  final List<String> activities;

  /// VO keys follow tools/build_vo_script.py: story.{chapterId}.{open|beat|close}.
  String voKey(String part) => 'story.$id.$part';
}

class Story {
  Story(Json j)
    : title = Bilingual.fromJson(j['title'] as Json),
      premise = Bilingual.fromJson(j['premise'] as Json),
      chapters = [for (final c in j['chapters'] as List) Chapter(c as Json)];
  final Bilingual title;
  final Bilingual premise;
  final List<Chapter> chapters;
}

// ---------------------------------------------------------------- v3 expansion
// content/catalog.json and content/library.json (docs/EXPANSION.md), written by
// tools/build_expansion.py. The catalog says which games exist and how they
// group into Lantern Lands; a game is playable only once activities.json has
// its rounds and an engine is registered for it.

class CatalogEngine {
  CatalogEngine(Json j)
    : id = j['id'] as String,
      name = Bilingual.fromJson(j['name'] as Json),
      skill = Bilingual.fromJson(j['skill'] as Json);
  final String id;
  final Bilingual name;
  final Bilingual skill;
}

class CatalogGame {
  CatalogGame(Json j)
    : id = j['id'] as String,
      number = j['number'] as int,
      engine = j['engine'] as String,
      name = Bilingual.fromJson(j['name'] as Json),
      minAge = j['minAge'] as int,
      goal = j['goal'] as String?,
      free = j['free'] as bool;
  final String id;
  final int number;
  final String engine;
  final Bilingual name;
  final int minAge;

  /// One line for the parent: what this game asks the child to do.
  final String? goal;
  final bool free;
}

class TaleTheme {
  TaleTheme(Json j)
    : id = j['id'] as String,
      name = Bilingual.fromJson(j['name'] as Json);
  final String id;
  final Bilingual name;
}

/// A Lantern Tale: 6–8 illustrated pages, read aloud, tap to turn.
class Tale {
  Tale(Json j)
    : id = j['id'] as String,
      number = j['number'] as int,
      theme = j['theme'] as String,
      title = Bilingual.fromJson(j['title'] as Json),
      game = j['game'] as String?,
      free = j['free'] as bool? ?? (j['number'] as int) <= 5,
      written = j['status'] == 'written',
      pages = [
        for (final p in j['pages'] as List? ?? const [])
          Bilingual.fromJson(p as Json),
      ];
  final String id;
  final int number;
  final String theme;
  final Bilingual title;

  /// The catalog game this tale leads into from its last page.
  final String? game;

  /// Free tier: the first five tales unless library.json says otherwise.
  final bool free;
  final bool written;
  final List<Bilingual> pages;

  /// VO key for page [n] (1-based): `tales.{id}.p{n}` →
  /// `assets/audio/vo/{lang}/tales/{id}/p{n}.mp3` (docs/EXPANSION.md §5).
  String pageKey(int n) => 'tales.$id.p$n';
  String pageArt(int n) => 'assets/images/tales/$id/p$n.png';
}
