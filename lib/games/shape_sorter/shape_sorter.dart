import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/art/item_art.dart';
import '../../core/audio/audio_service.dart';
import '../../core/tokens.dart';
import '../shared/activity_scaffold.dart';
import '../shared/draggable_item.dart';
import '../shared/drop_target.dart';
import '../shared/gentle_hint.dart';
import 'pieces.dart';

/// Shape Sorter / 形状 — a wooden sorter lid with shape holes, and chunky
/// coloured pieces to drop in. Pieces are drawn already the right way up (a
/// 3-year-old can't rotate one). A piece that fits sinks into its hole, Yun
/// names the shape, and something that shape (from the round's examples)
/// pops out of the hole to say hello. Tapping a hole names its shape.
final shapeSorterGame = GameDef(
  id: 'shape_sorter',
  build: (rc) => ShapeSorter(rc: rc),
  // r.vo names the shapes and ends with shapes.intro; sort says what to do.
  prompt: (r) => [...r.vo, 'shapes.sort'],
  shortPrompt: (r) => const ['shapes.sort'],
  background: const [Color(0xFFF6F2E6), Color(0xFFD7E3E1)],
);

/// `variant` picks a colour set for the pieces, a board, and how the holes
/// sit on it. Colour is decoration here, never the answer; no red (a
/// "wrong" colour to many children).
const List<List<String>> _pieceColors = [
  ['orange', 'blue', 'green', 'yellow', 'purple'],
  ['pink', 'green', 'orange', 'blue', 'yellow'],
  ['purple', 'yellow', 'blue', 'pink', 'green'],
];

final List<Color> _boards = [
  Color.lerp(Palette.lantern, Palette.paperDeep, 0.38)!, // honey wood
  Color.lerp(Palette.water, Palette.card, 0.32)!, // sky
  Color.lerp(Palette.leaf, Palette.card, 0.3)!, // meadow
];

const Duration _popLength = Duration(milliseconds: 1500);
const int _cheerStaggerMs = 170;

class ShapeSorter extends StatefulWidget {
  const ShapeSorter({super.key, required this.rc});
  final RoundContext rc;

  @override
  State<ShapeSorter> createState() => _ShapeSorterState();
}

class _ShapeSorterState extends State<ShapeSorter> with TickerProviderStateMixin {
  RoundContext get rc => widget.rc;

  /// One piece and one hole per shape (duplicates would be ambiguous).
  late final List<String> _shapes =
      rc.round.strings('shapes').toSet().take(kMaxInteractiveItems).toList();
  late final int _variant = (rc.round.data['variant'] as int? ?? 0) % _pieceColors.length;

  late final List<int> _holeOrder; // left → right on the board
  late final List<int> _trayOrder; // order pieces come out to play
  late final List<String?> _example; // what pops out of each hole

  final List<int?> _slots = []; // tray spot → piece
  final Set<int> _placed = {};
  int? _missed;
  int _cheer = 0;

  late final List<GlobalKey> _pieceKeys = List.generate(_shapes.length, (_) => GlobalKey());
  late final List<GlobalKey> _holeKeys = List.generate(_shapes.length, (_) => GlobalKey());

  late final AnimationController _bob; // pieces breathe in the tray
  late final AnimationController _enter; // the board slides in
  late final AnimationController _finale; // the closing wave

  bool get _done => _shapes.isNotEmpty && _placed.length == _shapes.length;

  Color _colorOf(int piece) {
    final set = _pieceColors[_variant];
    return Palette.named[set[piece % set.length]] ?? Palette.lantern;
  }

  @override
  void initState() {
    super.initState();
    final idx = List.generate(_shapes.length, (i) => i);
    _holeOrder = rc.shuffled(idx);
    final tray = rc.shuffled(idx);
    // A tray lined up exactly like the holes would give the game away.
    var same = tray.length > 1;
    for (var i = 0; i < tray.length && same; i++) {
      same = tray[i] == _holeOrder[i];
    }
    _trayOrder = same ? [...tray.skip(1), tray.first] : tray;
    final examples = rc.round.data['examples'] as Map? ?? const {};
    _example = [
      for (final s in _shapes)
        switch (examples[s]) {
          final List l when l.isNotEmpty => l[rc.rng.nextInt(l.length)] as String,
          _ => null,
        },
    ];

    _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _finale = AnimationController(
      vsync: this,
      duration: _popLength + Duration(milliseconds: _cheerStaggerMs * _shapes.length),
    );
    rc.hints.guide = () {
      final p = _focus;
      return p == null ? null : HintMove(_pieceKeys[p], _holeKeys[p]);
    };
    if (_shapes.isEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => rc.complete());
  }

  @override
  void dispose() {
    _bob.dispose();
    _enter.dispose();
    _finale.dispose();
    super.dispose();
  }

  /// What help is about: the piece the child just tried, else the first one
  /// waiting in the tray. Pulse and hand always agree.
  int? get _focus {
    if (_done) return null;
    if (_missed != null && _slots.contains(_missed) && !_placed.contains(_missed)) return _missed;
    for (final p in _slots) {
      if (p != null && !_placed.contains(p)) return p;
    }
    return null;
  }

  /// Tops up empty tray spots. Idempotent, so it is safe from build.
  void _fill(int capacity) {
    if (_slots.length != capacity) {
      final waiting = _trayOrder.where((p) => !_placed.contains(p)).toList();
      _slots
        ..clear()
        ..addAll([for (var s = 0; s < capacity; s++) s < waiting.length ? waiting[s] : null]);
      return;
    }
    for (var s = 0; s < capacity; s++) {
      final p = _slots[s];
      if (p != null && !_placed.contains(p)) continue;
      _slots[s] = _trayOrder.cast<int?>().firstWhere(
            (q) => !_placed.contains(q) && !_slots.contains(q),
            orElse: () => null,
          );
    }
  }

  static int? _pieceOf(String data) => data.startsWith('shape:') ? int.tryParse(data.substring(6)) : null;

  String? _shapeLine(int p) {
    final key = 'shape.${_shapes[p]}';
    return rc.round.vo.contains(key) ? key : null;
  }

  void _accept(int p) {
    if (_placed.contains(p)) return;
    setState(() {
      _placed.add(p);
      _missed = null;
      if (_done) _cheer++;
    });
    rc.hints.succeeded();
    final line = _shapeLine(p);
    if (!_done) {
      if (line != null) rc.say([line]);
      return;
    }
    // All home: every hole's friend pops up in a wave, then celebrate.
    rc.audio.sfx(Sfx.sparkle);
    Future.wait([
      rc.audio.playSequence([?line]),
      _finale.forward(from: 0),
    ]).then((_) {
      if (mounted) rc.complete();
    });
  }

  void _reject(String data) {
    setState(() => _missed = _pieceOf(data));
    rc.hints.miss();
  }

  void _tapHole(int p) {
    rc.hints.touched();
    rc.audio.sfx(Sfx.tap);
    final line = _shapeLine(p);
    if (line != null) rc.say([line]);
  }

  // ---------------------------------------------------------------- layout

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      final n = math.max(1, _shapes.length);
      final piece = (h * 0.2).clamp(kMinTouchTarget, 140.0);
      final extent = piece + kHitSlop; // a piece plus its slop padding
      const gap = kMinTargetGap - kHitSlop; // + slop = 64px visible gap
      const trayPad = 10.0;
      final capacity = math.max(
        1,
        math.min(math.min(_shapes.length, kMaxInteractiveItems), ((w - 2 * trayPad + gap) / (extent + gap)).floor()),
      );
      _fill(capacity);
      final trayH = extent + trayPad * 2;
      const spacing = 16.0;

      // Holes: as big as the piece (a little roomier), fitted to the board.
      final amp = _variant == 0 ? 0.0 : 0.24; // hole lift, in holes
      final boardH = h - trayH - spacing;
      final hole = math.max(
        0.0,
        math.min(math.min(piece * 1.1, w / (n + 0.32 * (n - 1) + 0.9)), boardH / (1 + amp + 0.75)),
      );
      return Column(children: [
        Expanded(child: Center(child: _board(hole, amp))),
        const SizedBox(height: spacing),
        _tray(piece, extent, gap, trayPad),
      ]);
    });
  }

  /// 0 (low) → 1 (high) lift of the hole in board position [k].
  double _lift(int k, int n) => switch (_variant) {
        1 => math.sin(math.pi * (k + 0.5) / n), // an arch
        2 => k.isEven ? 1.0 : 0.0, // a zig-zag
        _ => 0.0,
      };

  Widget _board(double hole, double amp) {
    final n = _holeOrder.length;
    final padX = hole * 0.45, padY = hole * 0.3, holeGap = hole * 0.32;
    final lip = hole * 0.14;
    final boardW = padX * 2 + n * hole + (n - 1) * holeGap;
    final boardH = padY * 2 + hole * (1 + amp) + lip;
    final color = _boards[_variant % _boards.length];

    return ValueListenableBuilder<int>(
      valueListenable: rc.hints.level,
      builder: (_, level, _) {
        final focus = level >= 1 ? _focus : null;
        return AnimatedBuilder(
          animation: Listenable.merge([_enter, _finale]),
          builder: (_, child) {
            final t = Curves.easeOutCubic.transform(_enter.value);
            // A happy little rock when everything is home.
            final f = _finale.value;
            final rock = math.sin(f * math.pi * 6) * 0.02 * (1 - f);
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, -(1 - t) * 40),
                child: Transform.rotate(angle: rock, child: child),
              ),
            );
          },
          child: SizedBox(
            width: boardW,
            height: boardH,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: BoardPainter(color)))),
              for (var k = 0; k < n; k++)
                Positioned(
                  left: padX + k * (hole + holeGap),
                  top: padY + hole * amp * (1 - _lift(k, n)),
                  width: hole,
                  height: hole,
                  child: _holeAt(_holeOrder[k], k, hole, color, focus == _holeOrder[k]),
                ),
            ]),
          ),
        );
      },
    );
  }

  Widget _holeAt(int p, int k, double hole, Color board, bool pulse) {
    return DropTarget(
      key: _holeKeys[p],
      id: 'hole$p',
      radius: hole * 0.22,
      pulse: pulse,
      enabled: !_done,
      willAccept: (data) => _pieceOf(data) == p && !_placed.contains(p),
      onAccept: (_) => _accept(p),
      onReject: _reject,
      child: _Hole(
        shape: _shapes[p],
        board: board,
        size: hole,
        color: _colorOf(p),
        filled: _placed.contains(p),
        example: _example[p],
        cheer: _cheer,
        cheerDelay: Duration(milliseconds: _cheerStaggerMs * k),
        onTap: () => _tapHole(p),
      ),
    );
  }

  Widget _tray(double piece, double extent, double gap, double pad) {
    return Stack(children: [
      // Backdrop only: taps between pieces fall through to the sparkle.
      Positioned.fill(
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Palette.card.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Palette.paperDeep, width: 3),
            ),
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.all(pad),
        child: AnimatedBuilder(
          animation: _bob,
          builder: (_, _) => Row(mainAxisSize: MainAxisSize.min, children: [
            for (var s = 0; s < _slots.length; s++) ...[
              if (s > 0) SizedBox(width: gap),
              _slotAt(s, piece, extent),
            ],
          ]),
        ),
      ),
    ]);
  }

  Widget _slotAt(int s, double piece, double extent) {
    final p = _slots[s];
    if (p == null || _placed.contains(p)) return SizedBox.square(key: ValueKey('empty$s'), dimension: extent);
    // Translation only above the DraggableItem (it drags by local deltas).
    final dy = math.sin(_bob.value * 2 * math.pi + s * 1.9) * piece * 0.03;
    return Transform.translate(
      key: ValueKey('piece$p'),
      offset: Offset(0, dy),
      child: _PopIn(
        delay: Duration(milliseconds: _enter.isAnimating && _placed.isEmpty ? 250 + 110 * s : 60),
        rise: piece * 0.35,
        child: KeyedSubtree(
          key: _pieceKeys[p],
          child: DraggableItem(
            data: 'shape:$p',
            size: Size.square(piece),
            onTouched: rc.hints.touched,
            child: CustomPaint(painter: PiecePainter(_shapes[p], _colorOf(p))),
          ),
        ),
      ),
    );
  }
}

/// One hole on the board. Once its piece is home the piece sits flush in it
/// with a little bounce, and an example thing of that shape pops out to say
/// hello, then ducks back in.
class _Hole extends StatefulWidget {
  const _Hole({
    required this.shape,
    required this.board,
    required this.size,
    required this.color,
    required this.filled,
    required this.example,
    required this.cheer,
    required this.cheerDelay,
    required this.onTap,
  });

  final String shape;
  final Color board, color;
  final double size;
  final bool filled;
  final String? example;

  /// Bumped once when the round is solved: every hole pops again in a wave.
  final int cheer;
  final Duration cheerDelay;
  final VoidCallback onTap;

  @override
  State<_Hole> createState() => _HoleState();
}

class _HoleState extends State<_Hole> with TickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(vsync: this, duration: _popLength);
  late final AnimationController _settle =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
  late final AnimationController _wiggle =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
  double _popStart = 0; // fraction of _pop spent waiting (the wave's delay)

  @override
  void didUpdateWidget(_Hole old) {
    super.didUpdateWidget(old);
    if (widget.filled && !old.filled) _settle.forward(from: 0);
    if (widget.cheer != old.cheer) {
      final total = widget.cheerDelay + _popLength;
      _popStart = widget.cheerDelay.inMicroseconds / total.inMicroseconds;
      _pop
        ..duration = total
        ..forward(from: 0);
    } else if (widget.filled && !old.filled) {
      _popStart = 0;
      _pop
        ..duration = _popLength
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    _settle.dispose();
    _wiggle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        _wiggle.forward(from: 0);
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_pop, _settle, _wiggle]),
        builder: (_, _) {
          final wv = _wiggle.value;
          final wig = math.sin(wv * math.pi * 4) * 0.08 * (1 - wv);
          final settle = _settle.value == 0 ? 1.0 : 1.18 - 0.18 * Curves.elasticOut.transform(_settle.value);

          // The example rises out (0–30%), waves (to 72%), ducks back in.
          final u = _popStart >= 1 ? 0.0 : ((_pop.value - _popStart) / (1 - _popStart)).clamp(0.0, 1.0);
          final up = Curves.easeOutBack.transform((u / 0.3).clamp(0.0, 1.0));
          final down = Curves.easeInCubic.transform(((u - 0.72) / 0.28).clamp(0.0, 1.0));
          final hf = up * (1 - down);
          final art = s * 0.62;

          return SizedBox.square(
            dimension: s,
            child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
              Transform.rotate(angle: wig, child: CustomPaint(size: Size.square(s), painter: HolePainter(widget.shape, widget.board))),
              if (widget.filled)
                Transform.scale(
                  scale: settle,
                  child: CustomPaint(
                    size: Size.square(s * 0.9),
                    painter: PiecePainter(widget.shape, widget.color, shadow: false),
                  ),
                ),
              if (widget.example != null && hf > 0.01)
                Positioned(
                  left: (s - art * 1.15) / 2,
                  top: (s - art * 1.15) / 2 - s * 0.85 * hf,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: hf.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.3 + 0.7 * hf,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Palette.card.withValues(alpha: 0.7),
                            boxShadow: const [BoxShadow(color: Palette.shadow, blurRadius: 10, offset: Offset(0, 4))],
                          ),
                          child: ItemArt(widget.example!, size: art),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          );
        },
      ),
    );
  }
}

/// Fades and rises its child in after [delay] (no scale: see [_slotAt]).
class _PopIn extends StatefulWidget {
  const _PopIn({required this.delay, required this.rise, required this.child});
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
