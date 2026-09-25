import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/art/item_art.dart';
import '../../core/tokens.dart';
import '../shared/activity_scaffold.dart';
import '../shared/cards.dart';
import '../shared/draggable_item.dart';
import '../shared/drop_target.dart';
import '../shared/gentle_hint.dart';

/// Count and Feed / 数一数 — drag exactly N foods to a hungry animal.
/// The plate shows N empty spots, one per food: 1:1 correspondence made
/// visible, so the child never has to read a numeral.
final countFeedGame = GameDef(
  id: 'count_feed',
  build: (rc) => CountFeed(rc: rc),
  prompt: (r) => [
    'item.${r.str('feeder')}',
    'counting.ask',
    'number.${r.integer('target')}',
  ],
  shortPrompt: (r) => [
    'number.${r.integer('target')}',
    'item.${r.str('item')}',
  ],
  background: const [Color(0xFFFCEFD6), Color(0xFFEBD8A8)],
);

class CountFeed extends StatefulWidget {
  const CountFeed({super.key, required this.rc});
  final RoundContext rc;

  @override
  State<CountFeed> createState() => _CountFeedState();
}

class _CountFeedState extends State<CountFeed> {
  RoundContext get rc => widget.rc;
  int get target => rc.round.integer('target');
  int get supply => rc.round.integer('supply');
  String get food => rc.round.str('item');
  String get feeder => rc.round.str('feeder');

  int _fed = 0;
  int _nextTag = 0;
  late List<int> _tray;
  final _feederKey = GlobalKey();
  final _firstItemKey = GlobalKey();
  bool _munch = false;

  @override
  void initState() {
    super.initState();
    // Never more than kMaxInteractiveItems on screen; the basket refills as
    // food is given, so counts up to 10 still work.
    final visible = math.min(supply, kMaxInteractiveItems);
    _tray = List.generate(visible, (_) => _nextTag++);
    rc.hints.guide = () => HintMove(_firstItemKey, _feederKey);
  }

  void _accept(String data) {
    setState(() {
      _fed++;
      _munch = true;
      _tray.remove(int.parse(data.split('#').last));
      final remainingSupply = supply - _fed - _tray.length;
      if (remainingSupply > 0 && _tray.length < kMaxInteractiveItems) {
        _tray.add(_nextTag++);
      }
    });
    rc.hints.succeeded();
    Future.delayed(const Duration(milliseconds: 260), () {
      if (mounted) setState(() => _munch = false);
    });
    if (_fed == target) {
      rc.audio
          .playSequence(['number.$_fed', 'counting.enough'])
          .then((_) => rc.complete());
    } else {
      rc.say(['number.$_fed']); // counting aloud, one word per food
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        final card = (h * 0.2).clamp(kMinTouchTarget, 120.0);
        final feederSize = (h * 0.36).clamp(110.0, 240.0);
        final dot = (h * 0.07).clamp(20.0, 40.0);
        final wide = box.maxWidth > box.maxHeight * 1.15;

        final feederSide = DropTarget(
          key: _feederKey,
          id: 'feeder',
          pulse: false,
          willAccept: (_) => _fed < target,
          onAccept: _accept,
          child: ValueListenableBuilder<int>(
            valueListenable: rc.hints.level,
            builder: (_, level, child) =>
                GentlePulse(active: level >= 1, radius: 200, child: child!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: _munch ? 1.12 : 1,
                  duration: const Duration(milliseconds: 160),
                  child: ItemArt(feeder, size: feederSize * 0.62),
                ),
                const SizedBox(height: 8),
                _Plate(total: target, filled: _fed, food: food, dot: dot),
              ],
            ),
          ),
        );

        final tray = Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x33A0703A),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: kMinTargetGap - kHitSlop,
            runSpacing: kMinTargetGap - kHitSlop,
            children: [
              for (final (i, tag) in _tray.indexed)
                KeyedSubtree(
                  key: i == 0 ? _firstItemKey : ValueKey(tag),
                  child: DraggableItem(
                    key: ValueKey('food$tag'),
                    data: '$food#$tag',
                    size: Size.square(card),
                    onTouched: rc.hints.touched,
                    child: ItemCard(id: food, size: card),
                  ),
                ),
            ],
          ),
        );

        return wide
            ? Row(
                children: [
                  Expanded(child: Center(child: feederSide)),
                  Expanded(
                    child: Center(child: SingleChildScrollView(child: tray)),
                  ),
                ],
              )
            : Column(
                children: [
                  Expanded(child: Center(child: feederSide)),
                  Expanded(child: Center(child: tray)),
                ],
              );
      },
    );
  }
}

/// N spots on a plate; each fills with the food as it's given.
class _Plate extends StatelessWidget {
  const _Plate({
    required this.total,
    required this.filled,
    required this.food,
    required this.dot,
  });
  final int total, filled;
  final String food;
  final double dot;

  @override
  Widget build(BuildContext context) {
    final perRow = total > 5 ? 5 : total;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dot * 0.8, vertical: dot * 0.5),
      decoration: BoxDecoration(
        color: Palette.card,
        borderRadius: BorderRadius.circular(dot * 2),
        border: Border.all(color: Palette.paperDeep, width: 4),
        boxShadow: const [
          BoxShadow(color: Palette.shadow, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: SizedBox(
        width: perRow * dot * 1.5,
        child: Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < total; i++)
              SizedBox(
                width: dot * 1.5,
                height: dot * 1.5,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: kStandardEase,
                    transitionBuilder: (c, a) =>
                        ScaleTransition(scale: a, child: c),
                    child: i < filled
                        ? ItemArt(food, key: const ValueKey('full'), size: dot)
                        : Container(
                            key: const ValueKey('empty'),
                            width: dot,
                            height: dot,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Palette.inkSoft.withValues(alpha: 0.5),
                                width: 3,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
