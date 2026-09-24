import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/audio/audio_service.dart';
import '../../core/content/content_loader.dart';
import '../../core/content/models.dart';
import '../../core/tokens.dart';
import '../../core/ui/touch_target.dart';
import '../../core/ui/yun.dart';
import 'celebration.dart';
import 'drop_target.dart';
import 'gentle_hint.dart';

/// Everything a game needs for one round. Games depend only on this, core/
/// and games/shared/ — never on each other (CLAUDE.md "Style").
class RoundContext {
  RoundContext({
    required this.round,
    required this.hints,
    required this.audio,
    required this.content,
    required this.lang,
    required this.complete,
  }) : rng = math.Random(round.activityId.hashCode ^ round.index);

  final Round round;
  final HintController hints;
  final AudioService audio;
  final Content content;
  final String lang;

  /// Call once when the round is solved.
  final VoidCallback complete;

  /// Deterministic per round: layout shuffles are stable for golden tests.
  final math.Random rng;

  /// Speak without blocking; interrupts any line already playing.
  void say(List<String> keys) => audio.playSequence(keys);

  List<T> shuffled<T>(Iterable<T> xs) => xs.toList()..shuffle(rng);
}

/// A mini-game's entry in the registry.
class GameDef {
  const GameDef({
    required this.id,
    required this.build,
    required this.prompt,
    this.shortPrompt,
    this.background = const [Color(0xFFFBEBD2), Color(0xFFF6D9B0)],
  });

  final String id;
  final Widget Function(RoundContext rc) build;

  /// VO keys spoken when the round starts (and on the replay button).
  final List<String> Function(Round r) prompt;

  /// Shortened prompt for the 8s idle nudge; defaults to [prompt].
  final List<String> Function(Round r)? shortPrompt;
  final List<Color> background;
}

/// Standard shell (SPEC §7.7): home button top-left, replay-the-question
/// button top-right, game in the middle. No score, no timer, no text.
class ActivityScaffold extends StatefulWidget {
  const ActivityScaffold({
    super.key,
    required this.body,
    required this.onHome,
    this.onReplay,
    this.hints,
    this.background = const [Color(0xFFFBEBD2), Color(0xFFF6D9B0)],
    this.overlay,
  });

  final Widget body;
  final VoidCallback onHome;
  final VoidCallback? onReplay;
  final HintController? hints;
  final List<Color> background;
  final Widget? overlay;

  /// Padding that keeps game content clear of the corner buttons. Phones in
  /// landscape are short, so buttons move to side rails there.
  static EdgeInsets contentInsets(Size s) {
    const rail = kMinTouchTarget + kHitSlop + 16;
    return s.height < 560
        ? const EdgeInsets.fromLTRB(rail, 8, rail, 8)
        : const EdgeInsets.fromLTRB(24, rail - 8, 24, 24);
  }

  @override
  State<ActivityScaffold> createState() => _ActivityScaffoldState();
}

class _ActivityScaffoldState extends State<ActivityScaffold> {
  final List<Offset> _sparkles = [];

  void _ambientTap(TapDownDetails d) {
    widget.hints?.touched();
    context.services.audio.sfx(Sfx.sparkle);
    setState(() => _sparkles.add(d.localPosition));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.background.first,
      body: DropZoneScope(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: widget.background),
          ),
          child: LayoutBuilder(builder: (context, box) {
            final insets = ActivityScaffold.contentInsets(box.biggest);
            return Stack(fit: StackFit.expand, children: [
              // Taps on empty space still sparkle (§7.5).
              GestureDetector(behavior: HitTestBehavior.opaque, onTapDown: _ambientTap),
              SafeArea(child: Padding(padding: insets, child: widget.body)),
              for (final p in List.of(_sparkles))
                TapSparkle(key: ObjectKey(p), at: p, onDone: () => setState(() => _sparkles.remove(p))),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: RoundButton(icon: Icons.home_rounded, onTap: widget.onHome),
                  ),
                ),
              ),
              if (widget.onReplay != null)
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: RoundButton(icon: Icons.volume_up_rounded, onTap: widget.onReplay!),
                    ),
                  ),
                ),
              if (widget.hints != null) HintHandLayer(hints: widget.hints!),
              if (widget.overlay != null) widget.overlay!,
              if (kDebugMode) const _DebugCaption(),
            ]);
          }),
        ),
      ),
    );
  }
}

enum _Phase { playing, celebrating, choosing }

/// Runs rounds of one activity. From the home screen it offers next-round or
/// home after each round; in story mode it hands control back via [onFinished].
/// Never auto-advances (§7.6): moving on always takes a tap.
class ActivitySession extends StatefulWidget {
  const ActivitySession({
    super.key,
    required this.game,
    this.onFinished,
    this.lightColor,
  });

  final GameDef game;

  /// Story mode: called when the child taps "continue" after one round.
  final VoidCallback? onFinished;
  final Color? lightColor;

  @override
  State<ActivitySession> createState() => _ActivitySessionState();
}

class _ActivitySessionState extends State<ActivitySession> {
  late Activity _activity;
  late int _roundIndex;
  late HintController _hints;
  _Phase _phase = _Phase.playing;
  bool _suggestBreak = false;
  int _generation = 0;

  Services get _s => context.services;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_generation == 0) {
      _activity = _s.content.activities[widget.game.id]!;
      _roundIndex = _s.progress.nextRound(_activity.id, _activity.rounds.length);
      _startRound();
    }
  }

  Round get _round => _activity.rounds[_roundIndex];

  void _startRound() {
    _generation++;
    _hints = HintController(
      speak: (k) => _s.audio.playVO(k),
      onIdlePrompt: () => _s.audio.playSequence((widget.game.shortPrompt ?? widget.game.prompt)(_round)),
    );
    _phase = _Phase.playing;
    final gen = _generation;
    _s.audio.playSequence(widget.game.prompt(_round)).then((_) {
      if (mounted && gen == _generation && _phase == _Phase.playing) _hints.start();
    });
  }

  void _complete() {
    if (_phase != _Phase.playing) return;
    _hints.stop();
    _s.progress.roundCompleted(_activity.id, _roundIndex, _activity.rounds.length);
    _s.audio.sfx(Sfx.success);
    _s.audio.playVO(_hints.rotate(const ['feedback.success1', 'feedback.success2', 'feedback.success3', 'feedback.success4']));
    final mins = _s.settings.breakMinutes;
    _suggestBreak = mins > 0 && DateTime.now().difference(_s.progress.sessionStart).inMinutes >= mins;
    setState(() => _phase = _Phase.celebrating);
  }

  void _celebrationDone() {
    if (!mounted) return;
    setState(() => _phase = _Phase.choosing);
    if (_suggestBreak) {
      _s.audio.playVO('ui.break');
    } else if (widget.onFinished == null) {
      _s.audio.playVO('ui.again');
    }
  }

  void _next() {
    if (widget.onFinished != null) return widget.onFinished!();
    final old = _hints;
    setState(() {
      _roundIndex = _s.progress.nextRound(_activity.id, _activity.rounds.length);
      _startRound();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  void _home() {
    _s.audio.stopVO();
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _hints.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rc = RoundContext(
      round: _round,
      hints: _hints,
      audio: _s.audio,
      content: _s.content,
      lang: context.lang,
      complete: _complete,
    );
    return ActivityScaffold(
      hints: _hints,
      background: widget.game.background,
      onHome: _home,
      onReplay: () {
        _hints.touched();
        _s.audio.playSequence(widget.game.prompt(_round));
      },
      body: IgnorePointer(
        ignoring: _phase != _Phase.playing,
        child: KeyedSubtree(key: ValueKey('${_activity.id}/$_roundIndex/$_generation'), child: widget.game.build(rc)),
      ),
      overlay: switch (_phase) {
        _Phase.playing => null,
        _Phase.celebrating => Celebration(onDone: _celebrationDone, lightColor: widget.lightColor),
        _Phase.choosing => _ChoicePanel(
            storyMode: widget.onFinished != null,
            sleepy: _suggestBreak,
            onNext: _next,
            onHome: _home,
          ),
      },
    );
  }
}

class _ChoicePanel extends StatelessWidget {
  const _ChoicePanel({required this.storyMode, required this.sleepy, required this.onNext, required this.onHome});
  final bool storyMode;
  final bool sleepy;
  final VoidCallback onNext;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: kStandardEase,
      curve: kStandardCurve,
      builder: (_, t, child) => Opacity(opacity: t, child: child),
      child: ColoredBox(
        color: const Color(0x66FBEBD2),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Yun(size: 150, mood: sleepy ? YunMood.sleepy : YunMood.happy),
            const SizedBox(height: 16),
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (!storyMode) ...[
                RoundButton(icon: Icons.home_rounded, onTap: onHome, diameter: 112),
                const SizedBox(width: kMinTargetGap),
              ],
              RoundButton(
                icon: storyMode ? Icons.arrow_forward_rounded : Icons.replay_rounded,
                onTap: onNext,
                diameter: 128,
                color: Palette.lantern,
                iconColor: Palette.card,
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// Debug builds only: shows what the (not yet recorded) voice is saying, so
/// the app can be tested before Phase 4 VO exists. Never in release.
class _DebugCaption extends StatelessWidget {
  const _DebugCaption();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<String?>(
        valueListenable: context.services.audio.caption,
        builder: (_, line, _) => AnimatedOpacity(
          opacity: line == null ? 0 : 1,
          duration: const Duration(milliseconds: 150),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xCC2B2B2B), borderRadius: BorderRadius.circular(12)),
              child: Text('🔊 ${line ?? ''}', style: const TextStyle(color: Color(0xFFFFF3E0), fontSize: 15)),
            ),
          ),
        ),
      ),
    );
  }
}
