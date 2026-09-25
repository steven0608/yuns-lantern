import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/art/item_art.dart';
import '../../core/audio/audio_service.dart';
import '../../core/tokens.dart';
import '../../core/ui/touch_target.dart';
import '../shared/activity_scaffold.dart';
import '../shared/gentle_hint.dart';
import 'vessel_art.dart';

/// Where Is It? / 在哪里 — two little rooms, the same animal and container in
/// each, arranged by the two words of the round's `pair`. The voice names the
/// animal and one position; the child taps the room that shows it.
///
/// Each relation is drawn so a 3-year-old can't misread it:
///  * up / down — the container sits on a table; the animal is on top of it
///    (high) or on the floor under the table (low);
///  * inside / outside — the animal sits *between* the container's back wall
///    and front wall (legs hidden), or stands on the floor beside it;
///  * in front / behind — in front the animal is big, low and whole,
///    overlapping the container; behind it is smaller, higher on the floor,
///    muted, and mostly hidden by the container.
final whereIsItGame = GameDef(
  id: 'where_is_it',
  build: (rc) => WhereIsIt(rc: rc),
  prompt: (r) => ['item.${r.str('actor')}', 'position.${r.str('target')}'],
  background: const [Color(0xFFEFF0DE), Color(0xFFD6DDBC)],
);

class WhereIsIt extends StatefulWidget {
  const WhereIsIt({super.key, required this.rc});
  final RoundContext rc;

  @override
  State<WhereIsIt> createState() => _WhereIsItState();
}

class _WhereIsItState extends State<WhereIsIt> with TickerProviderStateMixin {
  RoundContext get rc => widget.rc;
  String get _target => rc.round.str('target');

  late final List<String> _order;
  final _answerKey = GlobalKey();
  bool _solved = false;

  /// Idle life: animals breathe, peek and sway so the rooms feel alive.
  late final AnimationController _life =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

  /// Rooms pop in one after the other.
  late final AnimationController _enter =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();

  /// The found animal hops for joy.
  late final AnimationController _cheer =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    // Which side each room is on is shuffled per round (deterministic).
    _order = rc.shuffled(rc.round.strings('pair'));
    rc.hints.guide = () => _solved ? null : HintMove(_answerKey);
  }

  @override
  void dispose() {
    _life.dispose();
    _enter.dispose();
    _cheer.dispose();
    super.dispose();
  }

  void _chosen(String relation) {
    if (_solved) return;
    if (relation != _target) {
      rc.hints.miss();
      return;
    }
    rc.hints.succeeded();
    setState(() => _solved = true);
    _cheer.forward();
    // Name the position again as the animal hops, then hand over to the
    // scaffold's celebration.
    Future.wait([
      rc.audio.playSequence(['position.$_target']),
      Future<void>.delayed(const Duration(milliseconds: 900)),
    ]).then((_) {
      if (mounted) rc.complete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final clear = _cornerClearance(MediaQuery.sizeOf(context));
    return LayoutBuilder(builder: (context, box) {
      final short = box.maxHeight < 500;
      // A roomy visible gap between the two rooms (never under kMinTargetGap).
      final gap = short ? kMinTargetGap : kMinTargetGap + 24;
      final side = math
          .min((box.maxWidth - 2 * clear - 2 * kHitSlop - gap) / 2, box.maxHeight - kHitSlop)
          .clamp(kMinTouchTarget, 600.0);
      return Center(
        child: IgnorePointer(
          ignoring: _solved,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (final (i, relation) in _order.indexed) ...[
              if (i > 0) SizedBox(width: gap - kHitSlop),
              AnimatedBuilder(
                animation: _enter,
                builder: (_, child) {
                  final t = Interval(i * 0.25, 0.75 + i * 0.25, curve: Curves.easeOutBack).transform(_enter.value);
                  return Opacity(opacity: t.clamp(0.0, 1.0), child: Transform.scale(scale: 0.85 + 0.15 * t, child: child));
                },
                child: _RoomCard(
                  relation: relation,
                  actor: rc.round.str('actor'),
                  vessel: Vessel.of(rc.round.str('container')),
                  correct: relation == _target,
                  solved: _solved,
                  size: side,
                  hints: rc.hints,
                  hintKey: relation == _target ? _answerKey : null,
                  life: _life,
                  cheer: _cheer,
                  onTap: () => _chosen(relation),
                ),
              ),
            ],
          ]),
        ),
      );
    });
  }
}

/// On phones the scaffold's home/replay buttons sit in side rails whose inner
/// edge is only 24px from our content, level with our top row. Keep every
/// target a full kMinTargetGap (CLAUDE.md) from them by narrowing the layout.
double _cornerClearance(Size screen) {
  const buttonEdge = 4 + kHitSlop / 2 + kMinTouchTarget; // ActivityScaffold's corner buttons
  final insets = ActivityScaffold.contentInsets(screen);
  if (insets.top >= buttonEdge) return 0; // buttons sit above the content
  return math.max(0.0, kMinTargetGap - (insets.left - buttonEdge));
}

/// One tappable room. Wrong taps wobble softly (no red, no X) and escalate
/// help; the right room glows gold while the animal hops.
class _RoomCard extends StatefulWidget {
  const _RoomCard({
    required this.relation,
    required this.actor,
    required this.vessel,
    required this.correct,
    required this.solved,
    required this.size,
    required this.hints,
    required this.life,
    required this.cheer,
    required this.onTap,
    this.hintKey,
  });

  final String relation, actor;
  final Vessel vessel;
  final bool correct, solved;
  final double size;
  final HintController hints;
  final Animation<double> life, cheer;
  final VoidCallback onTap;
  final GlobalKey? hintKey;

  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard> with SingleTickerProviderStateMixin {
  late final AnimationController _wobble =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 460));

  @override
  void dispose() {
    _wobble.dispose();
    super.dispose();
  }

  void _tap() {
    if (!widget.correct) _wobble.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final radius = s * 0.12;
    final won = widget.solved && widget.correct;
    final border = s * 0.025;
    return ValueListenableBuilder<int>(
      valueListenable: widget.hints.level,
      builder: (_, level, child) =>
          GentlePulse(active: widget.correct && !widget.solved && level >= 1, radius: radius, child: child!),
      child: AnimatedBuilder(
        animation: _wobble,
        builder: (_, child) {
          final t = _wobble.value;
          return Transform.rotate(angle: 0.06 * (1 - t) * math.sin(t * 16), child: child);
        },
        child: AnimatedOpacity(
          opacity: widget.solved && !widget.correct ? 0.4 : 1,
          duration: kStandardEase,
          child: AnimatedScale(
            scale: won ? 1.05 : 1,
            duration: kStandardEase,
            curve: Curves.easeOutBack,
            child: TouchTarget(
              key: widget.hintKey,
              onTap: _tap,
              sound: widget.correct ? Sfx.snap : Sfx.tap,
              size: Size.square(s),
              child: AnimatedContainer(
                duration: kStandardEase,
                decoration: BoxDecoration(
                  color: won ? Palette.lantern : Palette.card,
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: won ? Palette.lantern.withValues(alpha: 0.5) : Palette.shadow,
                      blurRadius: won ? 28 : 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(border),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius - border),
                  child: _Room(
                    relation: widget.relation,
                    actor: widget.actor,
                    vessel: widget.vessel,
                    size: s - 2 * border,
                    life: widget.life,
                    cheer: widget.correct ? widget.cheer : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// How one relation is staged, in fractions of the room's side.
class _Stage {
  const _Stage({
    required this.vesselX,
    required this.vesselBottom,
    required this.actorX,
    required this.actorSize,
    this.vesselScale = 1,
    this.table = false,
    this.closed = false,
  });
  final double vesselX, vesselBottom, actorX, actorSize, vesselScale;
  final bool table, closed;
}

const double _floorY = 0.62; // wall meets floor
const double _tableTop = 0.56;

_Stage _stageFor(String relation) => switch (relation) {
      'up' || 'down' => const _Stage(
          vesselX: 0.5, vesselBottom: _tableTop, actorX: 0.5, actorSize: 0.26,
          vesselScale: 0.8, table: true, closed: true),
      'inside' => const _Stage(vesselX: 0.5, vesselBottom: 0.84, actorX: 0.5, actorSize: 0.34),
      'outside' => const _Stage(vesselX: 0.33, vesselBottom: 0.84, actorX: 0.77, actorSize: 0.3),
      'front' => const _Stage(
          vesselX: 0.44, vesselBottom: 0.78, actorX: 0.54, actorSize: 0.32, vesselScale: 1.1, closed: true),
      'behind' => const _Stage(
          vesselX: 0.44, vesselBottom: 0.8, actorX: 0.66, actorSize: 0.27, vesselScale: 1.1, closed: true),
      // Unknown relation from future content: show the pair plainly side by side.
      _ => const _Stage(vesselX: 0.33, vesselBottom: 0.84, actorX: 0.77, actorSize: 0.3),
    };

/// Softens an animal that is further away: muted and a little hazy, so
/// "behind" also reads as "further back".
const _distant = ColorFilter.matrix([
  0.62, 0.12, 0.06, 0, 40, //
  0.08, 0.66, 0.06, 0, 38, //
  0.08, 0.12, 0.60, 0, 36, //
  0, 0, 0, 1, 0,
]);

class _Room extends StatelessWidget {
  const _Room({
    required this.relation,
    required this.actor,
    required this.vessel,
    required this.size,
    required this.life,
    this.cheer,
  });

  final String relation, actor;
  final Vessel vessel;
  final double size;
  final Animation<double> life;
  final Animation<double>? cheer;

  @override
  Widget build(BuildContext context) {
    final s = size;
    final st = _stageFor(relation);
    final vw = vessel.width * s * st.vesselScale;
    final vh = vessel.height * s * st.vesselScale;
    final vLeft = st.vesselX * s - vw / 2;
    final vTop = st.vesselBottom * s - vh;

    var a = st.actorSize * s;
    if (relation == 'inside') a = math.min(a, vw * 0.8); // must fit the opening
    // Where the actor's box bottom sits. Emoji art has ~8% padding, so boxes
    // overlap surfaces slightly to look grounded.
    final double actorBottom = switch (relation) {
      'up' => vTop + vessel.topSurfaceY(vw, vh) + a * 0.04,
      'down' => 0.9 * s,
      'inside' => vTop + 2 * vessel.openingY(vw, vh) + a * vessel.insideSink, // front rim hides the legs
      'front' => 0.97 * s,
      'behind' => vTop + a * 0.66,
      _ => 0.88 * s,
    };
    // Behind: tucked in at the container's edge so about two thirds of the
    // animal is hidden whatever the container's width.
    final actorCx = relation == 'behind' ? vLeft + vw - a * 0.15 : st.actorX * s;
    final actorOnFloor = relation == 'down' || relation == 'outside' || relation == 'front';

    Widget vesselLayer(VesselLayer layer) => Positioned(
          left: vLeft,
          top: vTop,
          width: vw,
          height: vh,
          child: CustomPaint(painter: vessel.painter(layer, closed: st.closed)),
        );

    Widget shadow(double cx, double y, double w) => Positioned(
          left: cx - w / 2,
          top: y - s * 0.025,
          width: w,
          height: s * 0.05,
          child: const DecoratedBox(
            decoration: ShapeDecoration(shape: OvalBorder(), color: Color(0x2E4A3426)),
          ),
        );

    final actorWidget = Positioned(
      left: actorCx - a / 2,
      top: actorBottom - a,
      width: a,
      height: a,
      child: _Alive(
        relation: relation,
        life: life,
        cheer: cheer,
        size: a,
        child: relation == 'behind'
            ? ColorFiltered(colorFilter: _distant, child: ItemArt(actor, size: a / 1.15))
            : ItemArt(actor, size: a / 1.15),
      ),
    );

    final table = Positioned(
      left: s * 0.2,
      top: _tableTop * s,
      width: s * 0.6,
      height: s * (0.9 - _tableTop),
      child: const CustomPaint(painter: TablePainter()),
    );

    return SizedBox.square(
      dimension: s,
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        const Positioned.fill(child: CustomPaint(painter: RoomPainter(floorY: _floorY))),
        if (st.table) ...[
          shadow(s * 0.5, s * 0.9, s * 0.66),
          table,
        ] else
          shadow(vLeft + vw / 2, vTop + vh, vw * 1.15),
        if (actorOnFloor) shadow(actorCx, actorBottom - a * 0.08, a * 0.8),
        // Paint order *is* the spatial relation.
        if (relation == 'behind') ...[
          shadow(actorCx, actorBottom - a * 0.08, a * 0.7),
          actorWidget,
        ],
        vesselLayer(VesselLayer.back),
        if (relation == 'inside') actorWidget,
        vesselLayer(VesselLayer.front),
        if (relation != 'inside' && relation != 'behind') actorWidget,
      ]),
    );
  }
}

/// Gentle idle motion that never blurs the relation: the animal inside peeks
/// up out of the opening, the one behind leans out to look, others breathe.
class _Alive extends StatelessWidget {
  const _Alive({required this.relation, required this.life, required this.size, required this.child, this.cheer});
  final String relation;
  final Animation<double> life;
  final Animation<double>? cheer;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cheer = this.cheer;
    return AnimatedBuilder(
      animation: cheer == null ? life : Listenable.merge([life, cheer]),
      builder: (_, child) {
        final wave = math.sin(life.value * 2 * math.pi);
        var dx = 0.0, dy = 0.0;
        if (relation == 'inside') dy = -size * 0.05 * math.max(0, wave);
        if (relation == 'behind') dx = size * 0.05 * wave;
        if (cheer != null) dy -= size * 0.28 * math.sin(cheer.value * 2 * math.pi).abs();
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scaleY: 1 + 0.035 * wave,
            scaleX: 1 - 0.015 * wave,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
