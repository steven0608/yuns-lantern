import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../content/content_loader.dart';
import '../locale/locale_controller.dart';
import '../storage/prefs.dart';

/// Placeholder SFX set produced by tools/build_sfx.py. None of them is a
/// "wrong" sound — CLAUDE.md forbids buzzers and fail states.
enum Sfx {
  tap,
  pickup,
  snap,
  softReturn,
  sparkle,
  success,
  light,
  splash,
  bubble,
  whoosh,
  pencil,
  paint,
  drum,
  bell,
  cardFlip,
  pour,
}

extension on Sfx {
  String get file => switch (this) {
    Sfx.softReturn => 'soft_return',
    Sfx.cardFlip => 'card_flip',
    _ => name,
  };
}

/// Music loops and stings from the design session (design/audio, −18 LUFS).
abstract final class Music {
  static const home = 'home',
      storyMap = 'story_map',
      lands = 'lands',
      reader = 'reader',
      bedtime = 'bedtime';
  static const celebrate = 'celebrate',
      lightFound = 'light_found'; // one-shot stings
}

/// VO + SFX. Child-facing instruction is carried by audio, not text (§9), so
/// this service is the app's real UI.
///
/// * VO is locale-routed: `playVO('counting.ask')` →
///   `assets/audio/vo/{en|zh}/counting/ask.mp3`.
/// * Interrupt-safe: starting a new line or sequence cancels the previous one.
/// * Ducking: effects drop to half volume while a voice line plays.
/// * Missing recordings (true until Phase 4) are timed from the copy length so
///   pacing stays realistic, and in debug builds shown as a caption.
class AudioService {
  AudioService({
    required this.content,
    required this.locale,
    required this.settings,
    this.useDevice = true,
  });

  final Content content;
  final LocaleController locale;
  final Settings settings;

  /// False in widget tests: no platform channels, lines resolve immediately.
  final bool useDevice;

  final ValueNotifier<String?> caption = ValueNotifier(null);
  final ValueNotifier<bool> speaking = ValueNotifier(false);

  Set<String> _assets = const {};
  AudioPlayer? _vo;
  AudioPlayer? _music;
  final List<(int, String)> _musicStack = [];
  String? _musicPlaying;
  int _musicTokens = 0;
  final List<AudioPlayer> _sfx = [];
  int _sfxNext = 0;
  int _generation = 0;

  Future<void> init() async {
    if (!useDevice) return;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _assets = manifest.listAssets().toSet();
      _vo = AudioPlayer();
      _music = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
      speaking.addListener(_duck);
      settings.addListener(_duck);
      for (var i = 0; i < 4; i++) {
        _sfx.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
      }
    } catch (_) {
      // Audio is best-effort; the app must still work silently.
    }
  }

  String voPath(String key, [String? lang]) =>
      'assets/audio/vo/${lang ?? locale.code}/${key.replaceAll('.', '/')}.mp3';

  /// Speak one line. Completes when the line ends or is interrupted.
  Future<void> playVO(String key, {String? lang}) =>
      playSequence([key], lang: lang);

  /// Speak lines back-to-back. Cancels anything already speaking. [lang]
  /// overrides the app language (the book reader's "Both" mode).
  Future<void> playSequence(
    List<String> keys, {
    String? lang,
    Duration gap = const Duration(milliseconds: 180),
  }) async {
    final gen = ++_generation;
    await _stopVoPlayer();
    speaking.value = true;
    for (final key in keys) {
      if (gen != _generation) return;
      await _speak(key, gen, lang ?? locale.code);
      if (gen != _generation) return;
      if (useDevice) await Future<void>.delayed(gap);
    }
    if (gen == _generation) {
      speaking.value = false;
      caption.value = null;
    }
  }

  void stopVO() {
    _generation++;
    _stopVoPlayer();
    speaking.value = false;
    caption.value = null;
  }

  Future<void> _speak(String key, int gen, String lang) async {
    final line = content.lineFor(key)?.of(lang);
    if (kDebugMode) caption.value = line ?? key;
    final path = voPath(key, lang);
    final player = _vo;
    if (useDevice && player != null && _assets.contains(path)) {
      try {
        await player.setVolume(settings.voVolume);
        await player.play(AssetSource(path.substring('assets/'.length)));
        await player.onPlayerComplete.first.timeout(
          const Duration(seconds: 12),
        );
        return;
      } catch (_) {
        /* fall through to timed silence */
      }
    }
    if (!useDevice) return;
    // No recording yet: hold for roughly the time the line would take to say.
    final chars = (line ?? key).length;
    final ms = 300 + chars * (lang == 'zh' ? 230 : 65);
    await Future<void>.delayed(Duration(milliseconds: ms.clamp(500, 5000)));
  }

  Future<void> _stopVoPlayer() async {
    try {
      await _vo?.stop();
    } catch (_) {}
  }

  void sfx(Sfx s) {
    if (!useDevice || _sfx.isEmpty) return;
    final vol = settings.sfxVolume * (speaking.value ? 0.5 : 1.0);
    if (vol <= 0) return;
    final p = _sfx[_sfxNext];
    _sfxNext = (_sfxNext + 1) % _sfx.length;
    () async {
      try {
        await p.stop();
        await p.setVolume(vol);
        await p.play(AssetSource('audio/sfx/${s.file}.wav'));
      } catch (_) {}
    }();
  }

  // ------------------------------------------------------------------ music

  /// The screen now showing wants [track] looping. Returns a token for
  /// [popMusic]; the previous screen's track resumes when it's popped.
  int pushMusic(String track) {
    final token = ++_musicTokens;
    _musicStack.add((token, track));
    _applyMusic();
    return token;
  }

  void popMusic(int token) {
    _musicStack.removeWhere((e) => e.$1 == token);
    _applyMusic();
  }

  /// Music ducks ~12 dB (×0.25) under any voice line, so narration and
  /// prompts always carry (design session audio notes).
  double get _musicVolume =>
      settings.musicVolume * (speaking.value ? 0.25 : 1.0);

  void _duck() {
    try {
      _music?.setVolume(_musicVolume);
    } catch (_) {}
  }

  void _applyMusic() {
    final player = _music;
    if (!useDevice || player == null) return;
    final want = _musicStack.isEmpty ? null : _musicStack.last.$2;
    if (want == _musicPlaying) return;
    _musicPlaying = want;
    () async {
      try {
        await player.stop();
        if (want == null || settings.musicVolume <= 0) return;
        await player.setVolume(_musicVolume);
        await player.play(AssetSource('audio/music/$want.mp3'));
      } catch (_) {
        /* e.g. web before the first tap: stays silent */
      }
    }();
  }

  /// One-shot musical sting (celebration, a light found).
  void sting(String name) {
    if (!useDevice || _sfx.isEmpty) return;
    final vol = settings.sfxVolume;
    if (vol <= 0) return;
    final p = _sfx[_sfxNext];
    _sfxNext = (_sfxNext + 1) % _sfx.length;
    () async {
      try {
        await p.stop();
        await p.setVolume(vol);
        await p.play(AssetSource('audio/music/$name.mp3'));
      } catch (_) {}
    }();
  }
}
