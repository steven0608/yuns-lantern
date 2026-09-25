import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/art/item_art.dart';
import '../../core/audio/audio_service.dart';
import '../../core/tokens.dart';
import '../shared/activity_scaffold.dart';
import '../shared/cards.dart';
import '../shared/draggable_item.dart';
import '../shared/drop_target.dart';
import '../shared/gentle_hint.dart';
import 'tub.dart';

/// Match It / 配对 — sort things into three tubs by one attribute: colour,
/// shape, kind (category) or size. Cards lie scattered above; the tubs wait
/// along the bottom, each showing what it collects as a picture on its front
/// badge (never a word). A sorted thing drops into its tub and peeks over
/// the rim with the others. Tapping a tub names what it holds.
final matchItGame = GameDef(
  id: 'match_it',
  build: (rc) => MatchIt(rc: rc),
  prompt: (r) => r.vo,
  // The idle nudge is the instruction alone ("Put the same colours together").
  shortPrompt: (r) => r.vo.isEmpty ? const [] : [r.vo.first],
  background: const [Color(0xFFFCF3DC), Color(0xFFEFDDB0)],
);

/// Mirrors SIZE_ORDER in tools/build_content.py: lets a size tub draw where
/// its size sits among the round's three.
const _sizeOrder = ['tiny', 'small', 'medium', 'large', 'huge'];

/// On phones the home and replay buttons sit on side rails level with the
/// table. This much room at each side leaves a 64px visible gap to them
/// (12 rail spare + 2 × 12 slop + 28).
const double _sideRoom = 28;

/// Stagger between neighbouring tubs in the closing hop.
const int _hopStaggerMs = 260;
const int _hopMs = 520;

class _Thing {
  const _Thing(this.id, this.bin);
  final String id;
  final int bin;
}

class _Bin {
  const _Bin(this.key, this.size);
  final String key;

  /// How many things belong in it (spaces the pile).
  final int size;
}

class MatchIt extends StatefulWidget {
  const MatchIt({super.key, required this.rc});
  final RoundContext rc;

  @override
  State<MatchIt> createState() => _MatchItState();
}

class _MatchItState extends State<MatchIt> with TickerProviderStateMixin {
  RoundContext get rc => widget.rc;
  late final String _attribute = rc.round.str('attribute');
  final List<_Bin> _bins = [];
  final List<_Thing> _things = [];

  /// Order things come out to play in (shuffled once, deterministic).
  late final List<int> _order;

  /// The spot on the table each visible thing sits in. A spot keeps its thing
  /// until it's sorted, then takes the next waiting one — nothing else moves.
  final List<int?> _slots = [];
  final List<int> _placed = []; // in the order they were sorted
  int? _missed;

  late final List<GlobalKey> _thingKeys;
  late final List<GlobalKey> _binKeys;

  /// Per-spot scatter: a little offset and tilt so the table looks played-on.
  late final List<(double, double, double)> _jitter;

  late final AnimationController _bob; // cards breathe on the table
  late final AnimationController _enter; // tubs rise in at round start
  late final AnimationController _cheer; // the closing hop wave

  bool get _done => _things.isNotEmpty && _placed.length == _things.length;

  @override
  void initState() {
    super.initState();
    for (final raw in rc.round.data['bins'] as List? ?? const []) {
      final b = raw as Map<String, dynamic>;
      final items = List<String>.from(b['items'] as List);
      for (final id in items) {
        _things.add(_Thing(id, _bins.length));
      }
      _bins.add(_Bin(b['key'] as String, items.length));
    }
    _order = rc.shuffled(List.generate(_things.length, (i) => i));
    _thingKeys = List.generate(_things.length, (_) => GlobalKey());
    _binKeys = List.generate(_bins.length, (_) => GlobalKey());
    _jitter = List.generate(kMaxInteractiveItems, (_) {
      double r() => rc.rng.nextDouble() * 2 - 1;
      return (r(), r(), r());
    });

    _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _cheer = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _hopStaggerMs * _bins.length + _hopMs),
    );
    rc.hints.guide = () {
      final i = _focus;
      return i == null ? null : HintMove(_thingKeys[i], _binKeys[_things[i].bin]);
    };
    // Defensive: a round with nothing to sort is already solved.
    if (_things.isEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => rc.complete());
  }

  @override
  void dispose() {
    _bob.dispose();
    _enter.dispose();
    _cheer.dispose();
    super.dispose();
  }

  /// What help is about: the thing the child just tried, else the first one
  /// still on the table. Pulse and hand always agree on it.
  int? get _focus {
    if (_done) return null;
    if (_missed != null && _slots.contains(_missed) && !_placed.contains(_missed)) return _missed;
    for (final i in _slots) {
      if (i != null && !_placed.contains(i)) return i;
    }
    return null;
  }

  /// Puts a waiting thing into every empty spot. Idempotent, so it is safe
  /// to call from build; the capacity only changes if the window does.
  void _fill(int capacity) {
    if (_slots.length != capacity) {
      final waiting = _order.where((i) => !_placed.contains(i)).toList();
      _slots
        ..clear()
        ..addAll([for (var s = 0; s < capacity; s++) s < waiting.length ? waiting[s] : null]);
      return;
    }
    for (var s = 0; s < capacity; s++) {
      final i = _slots[s];
      if (i != null && !_placed.contains(i)) continue;
      _slots[s] = _order.cast<int?>().firstWhere(
            (j) => !_placed.contains(j) && !_slots.contains(j),
            orElse: () => null,
          );
    }
  }

  static int? _thingOf(String data) => data.startsWith('match:') ? int.tryParse(data.substring(6)) : null;

  String get _voPrefix => _attribute;

  /// The tub's spoken name ("red", "animals"…), only if the round has it.
  String? _binLine(int b) {
    final key = '$_voPrefix.${_bins[b].key}';
    return rc.round.vo.contains(key) ? key : null;
  }

  void _accept(int i) {
    if (_placed.contains(i)) return;
    setState(() {
      _placed.add(i);
      _missed = null;
    });
    rc.hints.succeeded();
    final said = 'item.${_things[i].id}';
    if (!_done) {
      rc.say([said]);
      return;
    }
    // All sorted: name the last one, then the tubs hop one after another as
    // each is named — a little recap of the round's words.
    rc.audio.sfx(Sfx.sparkle);
    Future.wait([
      rc.audio.playSequence([said, for (var b = 0; b < _bins.length; b++) ?_binLine(b)]),
      _cheer.forward(from: 0),
    ]).then((_) {
      if (mounted) rc.complete();
    });
  }

  void _reject(String data) {
    setState(() => _missed = _thingOf(data));
    rc.hints.miss();
  }

  void _tapTub(int b) {
    rc.hints.touched();
    rc.audio.sfx(Sfx.tap);
    final line = _binLine(b);
    if (line != null) rc.say([line]);
  }

  // ---------------------------------------------------------------- layout

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      // Phones in landscape get one row of cards (topped up as things are
      // sorted); taller screens get a staggered 3 + 3.
      final rows = h >= 480 ? 2 : 1;
      final card = (h * (rows == 2 ? 0.15 : 0.235)).clamp(kMinTouchTarget, 136.0);
      final extent = card + kHitSlop; // a card plus its slop padding
      final jx = rows == 2 ? card * 0.08 : 0.0; // scatter room each side
      final jy = card * 0.05;
      final tiltRoom = card * 0.06; // a tilted card's corners reach out a bit
      // Spacer + each card's 12px slop each side = 64px visible gap, even
      // when two neighbours scatter towards each other.
      final pitchMin = extent + (kMinTargetGap - kHitSlop) + 2 * jx + tiltRoom;
      final stagger = rows == 2 ? 0.5 : 0.0;

      double rowWidth(int cols, double pitch) => (cols - 1 + stagger) * pitch + extent + 2 * jx;
      // Side room keeps a 64px visible gap to the home / replay buttons,
      // which sit on side rails level with the table on phones.
      final usable = w - 2 * _sideRoom;
      var cols = rows == 2 ? (kMaxInteractiveItems / 2).ceil() : kMaxInteractiveItems;
      while (cols > 1 && rowWidth(cols, pitchMin) > usable) {
        cols--;
      }
      final capacity = math.min(math.min(rows * cols, kMaxInteractiveItems), _things.length);
      _fill(capacity);
      final usedRows = math.max(1, (capacity / cols).ceil());
      final pitchX = cols + stagger - 1 <= 0
          ? 0.0
          : math.max(pitchMin, math.min((usable - extent - 2 * jx) / (cols - 1 + stagger), extent * 2.0));
      final pitchY = extent + (kMinTargetGap - kHitSlop) + 2 * jy + tiltRoom;
      final tableH = (usedRows - 1) * pitchY + extent + 2 * jy;

      // Tubs share the rest of the height, never too big for the width.
      final n = math.max(1, _bins.length);
      const binGap = kMinTargetGap;
      final spacing = rows == 2 ? 24.0 : 8.0;
      final binW = math.max(
        0.0,
        math.min(math.min((w - (n - 1) * binGap) / n, (h - tableH - spacing) / kTubAspect), 300.0),
      );

      final table = _table(
        card: card,
        extent: extent,
        cols: cols,
        pitchX: pitchX,
        pitchY: pitchY,
        stagger: stagger,
        jx: jx,
        jy: jy,
        width: w,
        height: math.max(tableH, h - binW * kTubAspect - spacing),
        rowWidth: rowWidth(cols, pitchX),
        usedRows: usedRows,
      );
      return Column(children: [
        Expanded(child: table),
        SizedBox(height: spacing),
        _tubs(binW, binGap),
      ]);
    });
  }

  Widget _table({
    required double card,
    required double extent,
    required int cols,
    required double pitchX,
    required double pitchY,
    required double stagger,
    required double jx,
    required double jy,
    required double width,
    required double height,
    required double rowWidth,
    required int usedRows,
  }) {
    final left0 = (width - rowWidth) / 2 + jx;
    final top0 = (height - ((usedRows - 1) * pitchY + extent)) / 2;
    return AnimatedBuilder(
      animation: _bob,
      builder: (_, _) => Stack(clipBehavior: Clip.none, children: [
        for (var s = 0; s < _slots.length; s++)
          if (_slots[s] case final i? when !_placed.contains(i))
            _spot(
              s: s,
              i: i,
              card: card,
              left: left0 + (s % cols + (s ~/ cols).isOdd.toInt() * stagger) * pitchX + _jitter[s].$1 * jx,
              top: top0 + (s ~/ cols) * pitchY + _jitter[s].$2 * jy,
            ),
      ]),
    );
  }

  Widget _spot({required int s, required int i, required double card, required double left, required double top}) {
    // Each card breathes on its own beat, so the table feels alive.
    final phase = _bob.value * 2 * math.pi + s * 1.7;
    final dy = math.sin(phase) * card * 0.025;
    final tilt = _jitter[s].$3 * 0.045 + math.cos(phase) * 0.012;
    final isFirst = _placed.isEmpty && _enter.isAnimating;
    return Positioned(
      // Keyed, so a sorted neighbour leaving never rebuilds this card.
      key: ValueKey('spot$i'),
      left: left,
      top: top + dy,
      // No scale or rotation above the DraggableItem: it moves by local-space
      // deltas, so a transformed ancestor would make the card lag the finger.
      // The tilt lives on the card itself instead.
      child: _PopIn(
        key: ValueKey('pop$i'),
        rise: card * 0.35,
        delay: Duration(milliseconds: isFirst ? 120 + 90 * s : 60),
        child: KeyedSubtree(
          key: _thingKeys[i],
          child: DraggableItem(
            key: ValueKey('thing$i'),
            data: 'match:$i',
            size: Size.square(card),
            onTouched: rc.hints.touched,
            child: Transform.rotate(angle: tilt, child: _card(i, card)),
          ),
        ),
      ),
    );
  }

  /// The card shows the thing, and makes the attribute being sorted by easy
  /// to see: a colour wash for colour, the shape behind it for shape, a
  /// picture sized small → big for size. Placeholder art doesn't always show
  /// the vocab colour or shape, so the card carries it (see report).
  Widget _card(int i, double size) {
    final t = _things[i];
    final own = _attributeOf(t);
    switch (_attribute) {
      case 'color':
        final c = Palette.named[own];
        return ItemCard(id: t.id, size: size, color: c == null ? Palette.card : Color.lerp(Palette.card, c, 0.5)!);
      case 'shape':
        return ItemCard(
          size: size,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(
              size: Size.square(size * 0.8),
              painter: ShapeGlyphPainter(own, fill: Palette.paperDeep, stroke: Palette.lantern.withValues(alpha: 0.55)),
            ),
            ItemArt(t.id, size: size * 0.5),
          ]),
        );
      case 'size':
        final (rank, of) = _sizeRank(own);
        final scale = of <= 1 ? 0.58 : 0.4 + 0.32 * rank / (of - 1);
        return ItemCard(size: size, child: ItemArt(t.id, size: size * scale));
      default:
        return ItemCard(id: t.id, size: size);
    }
  }

  /// The thing's own value for this round's attribute (vocab), falling back
  /// to its tub's key.
  String _attributeOf(_Thing t) {
    final v = rc.content.vocab[t.id]?.json[_attribute];
    return v is String ? v : _bins[t.bin].key;
  }

  /// Where [size] sits among this round's sizes, small → big.
  (int, int) _sizeRank(String size) {
    final keys = {for (final b in _bins) b.key}.toList()
      ..sort((a, b) => _sizeOrder.indexOf(a).compareTo(_sizeOrder.indexOf(b)));
    return (math.max(0, keys.indexOf(size)), keys.length);
  }

  Widget _tubs(double binW, double gap) {
    return ValueListenableBuilder<int>(
      valueListenable: rc.hints.level,
      builder: (_, level, _) {
        final focus = _focus;
        final focusBin = level >= 1 && focus != null ? _things[focus].bin : null;
        return AnimatedBuilder(
          animation: Listenable.merge([_enter, _cheer]),
          builder: (_, _) => Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var b = 0; b < _bins.length; b++) ...[
                if (b > 0) SizedBox(width: gap),
                _tubAt(b, binW, focusBin == b),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _tubAt(int b, double binW, bool pulse) {
    // Tubs rise in one after another.
    final enterMs = _enter.value * _enter.duration!.inMilliseconds;
    final rise = Curves.easeOutBack.transform(((enterMs - b * 120) / 520).clamp(0.0, 1.0));
    // The closing hop wave.
    final cheerMs = _cheer.value * _cheer.duration!.inMilliseconds;
    final hop = math.sin(math.pi * ((cheerMs - b * _hopStaggerMs) / _hopMs).clamp(0.0, 1.0));

    final bin = _bins[b];
    final pile = [for (final i in _placed) if (_things[i].bin == b) _things[i].id];
    var tubScale = 1.0;
    if (_attribute == 'size') {
      final (rank, of) = _sizeRank(bin.key);
      if (of > 1) tubScale = 0.84 + 0.16 * rank / (of - 1);
    }
    final color = _attribute == 'color' ? Palette.named[bin.key] ?? kWicker : kWicker;

    return Opacity(
      opacity: rise.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - rise) * binW * 0.3 - hop * binW * 0.18),
        child: DropTarget(
          key: _binKeys[b],
          id: 'bin$b',
          radius: binW * 0.2,
          pulse: pulse,
          enabled: !_done,
          willAccept: (data) {
            final i = _thingOf(data);
            return i != null && i < _things.length && _things[i].bin == b && !_placed.contains(i);
          },
          onAccept: (data) => _accept(_thingOf(data)!),
          onReject: _reject,
          child: Tub(
            width: binW,
            scale: tubScale,
            color: color,
            woven: _attribute != 'color',
            pile: pile,
            capacity: bin.size,
            onTap: () => _tapTub(b),
            badge: _badge(bin, binW),
          ),
        ),
      ),
    );
  }

  /// What the tub collects, as a picture (never a word).
  Widget _badge(_Bin bin, double binW) {
    switch (_attribute) {
      case 'color':
        return CustomPaint(painter: BlobPainter(Palette.named[bin.key] ?? Palette.inkSoft));
      case 'shape':
        return CustomPaint(
          painter: ShapeGlyphPainter(
            bin.key,
            fill: Palette.inkSoft.withValues(alpha: 0.22),
            stroke: Palette.inkSoft,
            strokeWidth: math.max(3.0, binW * 0.018),
          ),
        );
      case 'size':
        final (rank, of) = _sizeRank(bin.key);
        return CustomPaint(painter: NestedSquaresPainter(rank: rank, count: of));
      default:
        final glyph = rc.content.art.categories[bin.key];
        return LayoutBuilder(
          builder: (_, c) => Center(child: Emoji(glyph ?? '❔', size: c.maxWidth * 0.56)),
        );
    }
  }
}

extension on bool {
  int toInt() => this ? 1 : 0;
}

/// Springs its child in after [delay] — the entrance, and a new thing taking
/// an empty spot on the table. Fade and rise only (no scale): see [_spot].
class _PopIn extends StatefulWidget {
  const _PopIn({super.key, required this.delay, required this.rise, required this.child});
  final Duration delay;
  final double rise;
  final Widget child;

  @override
  State<_PopIn> createState() => _PopInState();
}

class _PopInState extends State<_PopIn> with SingleTickerProviderStateMixin {
  static const _grow = Duration(milliseconds: 480);
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.delay + _grow)..forward();
  late final double _start = widget.delay.inMicroseconds / (widget.delay + _grow).inMicroseconds;
  late final Animation<double> _up = CurvedAnimation(parent: _c, curve: Interval(_start, 1, curve: Curves.easeOutBack));
  late final Animation<double> _fade = CurvedAnimation(parent: _c, curve: Interval(_start, math.min(1, _start + 0.3)));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Opacity(
        opacity: _fade.value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - _up.value) * widget.rise), child: child),
      ),
      child: widget.child,
    );
  }
}
