import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/art/item_art.dart';
import '../core/audio/audio_service.dart';
import '../core/content/content_loader.dart';
import '../core/content/models.dart';
import '../core/tokens.dart';
import '../core/ui/touch_target.dart';
import '../core/ui/yun.dart';

/// Shelf colour per theme: presentation only, cycles through the palette.
Color themeColor(String themeId) {
  const colors = [
    Color(0xFFF2B880),
    Color(0xFFA8D5A2),
    Color(0xFF9CC9E8),
    Color(0xFFF5A3A3),
    Color(0xFFC8B4E6),
    Color(0xFFF7D774),
    Color(0xFF8FD3C8),
    Color(0xFFF2A7C8),
  ];
  return colors[themeId.codeUnits.fold<int>(0, (a, b) => a + b) %
      colors.length];
}

/// Scene illustration used behind auto-illustrated pages, by theme.
const _themeScene = {
  'numbers': 'orchard',
  'shapes_colors': 'shapevillage',
  'sizes': 'bigmountain',
  'patterns_order': 'starrymeadow',
  'position': 'mistyforest',
  'nature': 'rainbowriver',
  'animals': 'orchard',
  'science': 'rainbowriver',
  'feelings': 'mirrorlake',
  'routines': 'shapevillage',
  'festivals': 'lighthouse',
  'words': 'starrymeadow',
  'family': 'shapevillage',
  'music': 'starrymeadow',
  'kindness': 'mirrorlake',
};

/// Who and what a page talks about, read from its English text: vocab items
/// (singular or plural), Yun, and the biggest number word — so "Four apples,
/// five apples" draws five apples. Content stays the source of truth: the
/// picture follows the words.
class PageCast {
  PageCast(this.items, this.count, this.yun);
  final List<String> items;
  final int count;
  final bool yun;

  static const _numbers = [
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'ten',
  ];

  factory PageCast.of(Content content, String en) {
    final words = RegExp(r"[a-z]+")
        .allMatches(en.toLowerCase())
        .map((m) => m.group(0)!)
        .toList();
    final found = <String>[];
    for (final w in words) {
      for (final item in content.vocab.values) {
        final name = item.name.en.toLowerCase();
        if (name.contains(' ')) continue;
        if ((w == name || w == '${name}s' || w == '${name}es') &&
            !found.contains(item.id)) {
          found.add(item.id);
        }
      }
    }
    final count = words
        .map(_numbers.indexOf)
        .fold<int>(0, (a, i) => math.max(a, i + 1));
    return PageCast(found, count, words.contains('yun'));
  }
}

String coverGlyph(Content content, Tale tale) {
  final cast = PageCast.of(content, tale.title.en);
  final id = cast.items.isNotEmpty ? cast.items.first : null;
  return (id != null ? content.art.items[id] : null) ?? '📖';
}

/// Placeholder page illustration until `assets/images/tales/<id>/p<N>.png`
/// exists: the theme's scene, softened, with the page's cast on top. Every
/// character is tappable and says its word (EXPANSION §5); a group of the same
/// thing counts aloud as it's tapped.
class AutoIllustration extends StatefulWidget {
  const AutoIllustration({super.key, required this.tale, required this.page});
  final Tale tale;
  final int page; // 1-based

  @override
  State<AutoIllustration> createState() => _AutoIllustrationState();
}

class _AutoIllustrationState extends State<AutoIllustration> {
  final Map<String, int> _taps = {};

  void _tap(String id, int copies) {
    final audio = context.services.audio;
    if (copies > 1) {
      final n = (_taps[id] ?? 0) % copies + 1;
      _taps[id] = n;
      audio.playVO('number.$n');
    } else {
      audio.playVO('item.$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = context.services.content;
    final page = widget.tale.pages[widget.page - 1];
    final cast = PageCast.of(content, page.en);
    final scene =
        content.art.scenes[_themeScene[widget.tale.theme] ?? 'orchard']?.image;
    // At most 6 interactive items (CLAUDE.md): one group, or up to three kinds.
    final kinds = cast.items.take(3).toList();
    final copies = kinds.length == 1
        ? math.min(math.max(cast.count, 1), kMaxInteractiveItems)
        : 1;

    return LayoutBuilder(
      builder: (context, box) {
        final card = (box.maxHeight * 0.26).clamp(kMinTouchTarget, 150.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            if (scene != null) Image.asset(scene, fit: BoxFit.cover),
            const ColoredBox(color: Color(0x59FBF1E1)),
            if (cast.yun || kinds.isEmpty)
              Align(
                alignment: const Alignment(-0.78, 0.55),
                child: IgnorePointer(
                  child: Yun(size: box.maxHeight * 0.34, mood: YunMood.happy),
                ),
              ),
            Align(
              alignment: const Alignment(0.2, 0.1),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: kMinTargetGap - kHitSlop,
                runSpacing: kMinTargetGap - kHitSlop,
                children: [
                  for (final id in kinds)
                    for (var i = 0; i < copies; i++)
                      TouchTarget(
                        key: ValueKey('$id$i'),
                        sound: Sfx.pickup,
                        onTap: () => _tap(id, copies),
                        child: _Floaty(
                          seed: i + id.length,
                          child: ItemArt(id, size: card * 0.8),
                        ),
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Gentle idle bob so page characters feel alive.
class _Floaty extends StatefulWidget {
  const _Floaty({required this.child, required this.seed});
  final Widget child;
  final int seed;

  @override
  State<_Floaty> createState() => _FloatyState();
}

class _FloatyState extends State<_Floaty> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 2200 + widget.seed * 170),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, child) => Transform.translate(
      offset: Offset(0, math.sin(_c.value * math.pi * 2) * 5),
      child: child,
    ),
    child: widget.child,
  );
}
