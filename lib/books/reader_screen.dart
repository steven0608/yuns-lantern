import 'package:flutter/material.dart';

import '../core/audio/music_scope.dart';
import '../app.dart';
import '../core/app_scope.dart';
import '../core/audio/audio_service.dart';
import '../core/content/models.dart';
import '../core/tokens.dart';
import '../core/ui/scene_still.dart';
import '../core/ui/touch_target.dart';
import '../core/ui/yun.dart';
import '../games/shared/activity_scaffold.dart';
import '../play/catalog_view.dart';
import 'page_art.dart';

/// A Lantern Tale (docs/EXPANSION.md §5): read to me, tap the arrow to turn,
/// never auto-advance (CLAUDE.md). Narration follows the app language, or
/// "Both" (app language, then the other) from the parent area. The words
/// show under the picture for grown-ups; the child listens.
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.tale});
  final Tale tale;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  int _page = 1;
  bool _read = false; // narration of this page has finished
  bool _ended = false; // past the last page
  int _generation = 0;

  Tale get tale => widget.tale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_generation == 0) _narrate();
  }

  Future<void> _narrate() async {
    final gen = ++_generation;
    setState(() => _read = false);
    final s = context.services;
    final main = s.locale.code;
    final key = tale.pageKey(_page);
    await s.audio.playVO(key, lang: main);
    if (!mounted || gen != _generation) return;
    if (s.settings.bookLanguage == 'both') {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted || gen != _generation) return;
      await s.audio.playVO(key, lang: main == 'zh' ? 'en' : 'zh');
      if (!mounted || gen != _generation) return;
    }
    setState(() => _read = true);
  }

  void _turn(int delta) {
    final next = _page + delta;
    if (next > tale.pages.length) {
      context.services.audio
        ..stopVO()
        ..sfx(Sfx.success);
      setState(() => _ended = true);
      return;
    }
    if (next < 1) return;
    context.services.audio.sfx(Sfx.whoosh);
    setState(() {
      _page = next;
      _ended = false;
    });
    _narrate();
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MusicScope(
    track: Music.reader,
    child: Builder(builder: _body),
  );

  Widget _body(BuildContext context) {
    final s = context.services;
    final lang = context.lang;
    final art = s.content.art.taleArt(tale.pageArt(_page));
    final text = tale.pages[_page - 1];
    final both = s.settings.bookLanguage == 'both';

    return Scaffold(
      backgroundColor: Palette.paper,
      body: LayoutBuilder(
        builder: (context, box) {
          final short = box.maxHeight < 560;
          final strip = short ? 64.0 : 104.0;
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                bottom: strip,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  child: KeyedSubtree(
                    key: ValueKey(_page),
                    child: art != null
                        ? _Panned(child: Image.asset(art, fit: BoxFit.cover))
                        : AutoIllustration(tale: tale, page: _page),
                  ),
                ),
              ),
              // The words, for grown-ups reading along.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: strip,
                child: ColoredBox(
                  color: Palette.card,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: short ? kMinTouchTarget + 40 : 150,
                        vertical: 6,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              text.of(lang),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: short ? 15 : 22,
                                color: Palette.ink,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (both && !short)
                              Text(
                                text.of(lang == 'zh' ? 'en' : 'zh'),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: Palette.inkSoft,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Page dots: where we are in the book (decorative).
              Positioned(
                left: 0,
                right: 0,
                bottom: strip + 10,
                child: IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 1; i <= tale.pages.length; i++)
                        AnimatedContainer(
                          duration: kStandardEase,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 22 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: i <= _page ? Palette.lantern : Palette.card,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: RoundButton(
                      icon: Icons.home_rounded,
                      onTap: () {
                        s.audio.stopVO();
                        Navigator.of(context).maybePop();
                      },
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: RoundButton(
                      icon: Icons.volume_up_rounded,
                      onTap: _narrate,
                    ),
                  ),
                ),
              ),
              if (_page > 1)
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: RoundButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => _turn(-1),
                      ),
                    ),
                  ),
                ),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: AnimatedScale(
                      scale: _read ? 1.08 : 1.0,
                      duration: kStandardEase,
                      child: RoundButton(
                        icon: Icons.arrow_forward_rounded,
                        onTap: () => _turn(1),
                        color: _read ? Palette.lantern : Palette.cream,
                        iconColor: _read ? Palette.card : Palette.rustDeep,
                      ),
                    ),
                  ),
                ),
              ),
              if (_ended)
                _TheEnd(
                  tale: tale,
                  onAgain: () {
                    setState(() {
                      _ended = false;
                      _page = 1;
                    });
                    _narrate();
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Slow drift over finished page art (the same gentle pan as story scenes).
class _Panned extends StatefulWidget {
  const _Panned({required this.child});
  final Widget child;

  @override
  State<_Panned> createState() => _PannedState();
}

class _PannedState extends State<_Panned> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, child) => ClipRect(
      child: Transform.translate(
        offset: Offset(-_c.value * 24, 0),
        child: Transform.scale(scale: 1 + 0.04 * _c.value, child: child),
      ),
    ),
    child: widget.child,
  );
}

/// After the last page: Yun is happy, and the book's own game is one tap away
/// (EXPANSION §4: stories and games teach together). Read-again and home too.
class _TheEnd extends StatelessWidget {
  const _TheEnd({required this.tale, required this.onAgain});
  final Tale tale;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final game = tale.game == null ? null : s.playable(tale.game!);
    final tile = game == null ? null : s.content.art.tileImage(game.id);
    return ColoredBox(
      color: const Color(0xCCFBF1E1),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: kMinTargetGap - kHitSlop,
          runSpacing: 12,
          children: [
            const Yun(size: 150, mood: YunMood.happy),
            RoundButton(
              icon: Icons.replay_rounded,
              onTap: onAgain,
              diameter: 112,
            ),
            if (game != null)
              TouchTarget(
                size: const Size.square(150),
                onTap: () => Navigator.of(context)
                    .pushReplacement(softRoute(ActivitySession(game: game))),
                child: tile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset(tile),
                      )
                    : const SceneStill(art: null),
              ),
            RoundButton(
              icon: Icons.home_rounded,
              onTap: () => Navigator.of(context).maybePop(),
              diameter: 112,
            ),
          ],
        ),
      ),
    );
  }
}
