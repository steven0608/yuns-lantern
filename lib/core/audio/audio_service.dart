import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../content/content_loader.dart';
import '../locale/locale_controller.dart';
import '../storage/prefs.dart';

/// Placeholder SFX set produced by tools/build_sfx.py. None of them is a
/// "wrong" sound — CLAUDE.md forbids buzzers and fail states.
enum Sfx { tap, pickup, snap, softReturn, sparkle, success, light, splash, bubble, whoosh }

extension on Sfx {
  String get file => switch (this) {
        Sfx.softReturn => 'soft_return',
        _ => name,
      };
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
  final List<AudioPlayer> _sfx = [];
  int _sfxNext = 0;
  int _generation = 0;

  Future<void> init() async {
    if (!useDevice) return;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _assets = manifest.listAssets().toSet();
      _vo = AudioPlayer();
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
  Future<void> playVO(String key) => playSequence([key]);

  /// Speak lines back-to-back. Cancels anything already speaking.
  Future<void> playSequence(List<String> keys, {Duration gap = const Duration(milliseconds: 180)}) async {
    final gen = ++_generation;
    await _stopVoPlayer();
    speaking.value = true;
    for (final key in keys) {
      if (gen != _generation) return;
      await _speak(key, gen);
      if (gen != _generation) return;
      await Future<void>.delayed(useDevice ? gap : Duration.zero);
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

  Future<void> _speak(String key, int gen) async {
    final lang = locale.code;
    final line = content.lineFor(key)?.of(lang);
    if (kDebugMode) caption.value = line ?? key;
    final path = voPath(key, lang);
    final player = _vo;
    if (useDevice && player != null && _assets.contains(path)) {
      try {
        await player.setVolume(settings.voVolume);
        await player.play(AssetSource(path.substring('assets/'.length)));
        await player.onPlayerComplete.first.timeout(const Duration(seconds: 12));
        return;
      } catch (_) {/* fall through to timed silence */}
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
}
