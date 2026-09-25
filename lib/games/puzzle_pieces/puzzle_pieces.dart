import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/content/content_loader.dart';
import '../../core/tokens.dart';
import '../../core/ui/scene_still.dart';
import '../shared/activity_scaffold.dart';
import '../shared/draggable_item.dart';
import '../shared/drop_target.dart';
import '../shared/gentle_hint.dart';
import 'puzzle_layout.dart';

/// Puzzle Pieces / 拼图 — a chapter scene cut into a 2×2 frame.
///  * `missing`: one quadrant is a hole; the tray holds the right piece plus
///    the same quadrant cut from other chapters' scenes.
///  * `four`: every quadrant is a hole, over a faint ghost of the picture so
///    a 3-year-old can see where each piece belongs.
/// Pieces are exactly the size of their hole, so "it fits" is visible before
/// the child even lifts one. When the last piece lands the seams melt away
/// and the picture drifts gently to life.
final puzzlePiecesGame = GameDef(
  id: 'puzzle_pieces',
  build: (rc) => PuzzlePieces(rc: rc),
  prompt: (r) => r.vo,
  background: const [Color(0xFFE9F1EE), Color(0xFFC7DBD6)],
);

class PuzzlePieces extends StatefulWidget {
  const PuzzlePieces({super.key, required this.rc});
  final RoundContext rc;

  @override
  State<PuzzlePieces> createState() => _PuzzlePiecesState();
}

/// One piece: quadrant [q] (0 TL, 1 TR, 2 BL, 3 BR) of chapter scene [scene].
class _Piece {
  const _Piece(this.scene, this.q);
  final String scene;
  final int q;
  String get data => 'piece:$scene:$q';
}

class _PuzzlePiecesState extends State<PuzzlePieces> with TickerProviderStateMixin {
  RoundContext get rc => widget.rc;
  String get _scene => rc.round.str('scene');
  SceneArt? _art(String scene) => rc.content.art.scenes[scene];

  late final Set<int> _holes;
  final Set<int> _filled = {};
  late final List<_Piece> _tray;
  final Map<String, GlobalKey> _pieceKeys = {};
  final List<GlobalKey> _holeKeys = List.generate(4, (_) => GlobalKey());

  /// The piece the child last tried and missed with: help is about it.
  String? _focus;
  bool _done = false;

  /// Picture comes alive on completion.
  late final AnimationController _alive =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void initState() {
    super.initState();
    final pieces = rc.round.integer('pieces').clamp(1, 4);
    if (pieces >= 4) {
      _holes = {0, 1, 2, 3};
    } else {
      // Holes come from the bottom row first: that's where every chapter
      // scene keeps its distinctive content. Top quadrants are mostly sky,
      // and skies look alike across chapters, so a top hole could be
      // ambiguous against decoys.
      final order = [...rc.shuffled([2, 3]), ...rc.shuffled([0, 1])];
      _holes = order.take(pieces).toSet();
    }
    final right = [for (final q in _holes) _Piece(_scene, q)];
    final wanted = math.min(rc.round.integer('candidates'), kMaxInteractiveItems) - right.length;
    final decoyScenes = _decoyScenes();
    final decoys = [
      for (var i = 0; i < wanted && decoyScenes.isNotEmpty; i++)
        _Piece(decoyScenes[i % decoyScenes.length], right[i % right.length].q),
    ];
    _tray = rc.shuffled([...right, ...decoys]);
    for (final p in _tray) {
      _pieceKeys[p.data] = GlobalKey();
    }
    rc.hints.guide = () {
      final p = _guided();
      return p == null ? null : HintMove(_pieceKeys[p.data]!, _holeKeys[p.q]);
    };
  }

  @override
  void dispose() {
    _alive.dispose();
    super.dispose();
  }

  /// Other chapters' scenes, the most different-looking first (by sky and
  /// ground colour), so a decoy is never a near-twin of the right piece.
  List<String> _decoyScenes() {
    final scenes = rc.content.art.scenes;
    final me = scenes[_scene];
    double dist(String id) {
      final o = scenes[id]!;
      if (me == null) return 0;
      return _colorDistance(me.sky, o.sky) + _colorDistance(me.ground, o.ground);
    }

    final others = scenes.keys.where((k) => k != _scene).toList()..sort((a, b) => dist(b).compareTo(dist(a)));
    // Vary rounds among the few most distinct.
    return rc.shuffled(others.take(4));
  }

  static double _colorDistance(Color a, Color b) =>
      math.sqrt(math.pow(a.r - b.r, 2) + math.pow(a.g - b.g, 2) + math.pow(a.b - b.b, 2));

  bool _fits(_Piece p) => p.scene == _scene && _holes.contains(p.q) && !_filled.contains(p.q);

  /// The piece the hand would demonstrate: the one just tried, else the first
  /// right piece still in the tray.
  _Piece? _guided() {
    if (_done) return null;
    final open = _tray.where(_fits).toList();
    if (open.isEmpty) return null;
    return open.firstWhere((p) => p.data == _focus, orElse: () => open.first);
  }

  void _accept(int q) {
    setState(() {
      _filled.add(q);
      _focus = null;
    });
    rc.hints.succeeded();
    if (_filled.containsAll(_holes)) {
      setState(() => _done = true);
      _alive.forward();
      Future<void>.delayed(const Duration(milliseconds: 1100), () {
        if (mounted) rc.complete();
      });
    }
  }

  void _reject(String data) {
    setState(() => _focus = data);
    rc.hints.miss();
  }

  @override
  Widget build(BuildContext context) {
    final clear = cornerClearance(MediaQuery.sizeOf(context));
    return LayoutBuilder(builder: (context, box) {
      final l = PuzzleLayout.solve(box.biggest, pieces: _tray.length, clearance: clear);
      final frame = _frame(l);
      final tray = _trayPanel(l);
      if (l.below) {
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            frame,
            const SizedBox(height: PuzzleLayout.gap),
            tray,
          ]),
        );
      }
      return Padding(
        // Keep the tray a full target gap from the corner buttons on phones.
        padding: EdgeInsets.only(right: clear),
        child: Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            frame,
            const SizedBox(width: PuzzleLayout.gap),
            tray,
          ]),
        ),
      );
    });
  }

  // ── The frame ─────────────────────────────────────────────────────────
  Widget _frame(PuzzleLayout l) {
    final art = _art(_scene);
    final cw = l.pieceW, ch = l.pieceH;
    final ghost = _holes.length > 2;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(PuzzleLayout.border),
      decoration: BoxDecoration(
        color: _done ? Palette.lantern : const Color(0xFFEAD6B4),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _done ? Palette.lantern.withValues(alpha: 0.55) : Palette.shadow,
            blurRadius: _done ? 30 : 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      // Décor only: taps fall through to the scaffold's ambient sparkle.
      // Holes still receive drops (DropZoneScope uses geometry, not hits).
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22 - PuzzleLayout.border),
          child: SizedBox(
            width: l.frameW,
            height: l.frameH,
            child: Stack(children: [
              if (ghost && !_done)
                Positioned.fill(
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(Color(0x33FBF1E1), BlendMode.srcATop),
                    child: SceneStill(art: art),
                  ),
                ),
              for (var q = 0; q < 4; q++)
                Positioned(left: (q % 2) * cw, top: (q ~/ 2) * ch, width: cw, height: ch, child: _cell(q, l, ghost)),
              if (_done)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _alive,
                    builder: (_, _) => SceneStill(art: art, pan: Curves.easeInOut.transform(_alive.value) * 0.6),
                  ),
                ),
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: _done ? 0 : 1,
                  duration: const Duration(milliseconds: 400),
                  child: const CustomPaint(painter: _SeamPainter()),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _cell(int q, PuzzleLayout l, bool ghost) {
    final art = _art(_scene);
    if (!_holes.contains(q)) return Quadrant(art: art, q: q, width: l.pieceW, height: l.pieceH);
    if (_filled.contains(q)) {
      // A placed piece settles with a tiny bounce.
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.9, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.elasticOut,
        builder: (_, s, child) => Transform.scale(scale: s, child: child),
        child: Quadrant(art: art, q: q, width: l.pieceW, height: l.pieceH),
      );
    }
    return ValueListenableBuilder<int>(
      valueListenable: rc.hints.level,
      builder: (_, level, _) => DropTarget(
        key: _holeKeys[q],
        id: 'hole$q',
        pulse: level >= 1 && _guided()?.q == q,
        radius: 10,
        willAccept: (d) => d == _Piece(_scene, q).data,
        onAccept: (_) => _accept(q),
        onReject: _reject,
        child: _Hole(seeThrough: ghost),
      ),
    );
  }

  // ── The tray ──────────────────────────────────────────────────────────
  Widget _trayPanel(PuzzleLayout l) {
    final slotW = l.pieceW + kHitSlop, slotH = l.pieceH + kHitSlop;
    return Container(
      width: l.trayW,
      decoration: BoxDecoration(
        color: const Color(0x2E3F7F74),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: PuzzleLayout.spacing,
        runSpacing: PuzzleLayout.spacing,
        children: [
          for (final (i, p) in _tray.indexed)
            SizedBox(
              width: slotW,
              height: slotH,
              child: p.scene == _scene && _filled.contains(p.q)
                  ? null // placed: its spot stays so the other pieces don't jump
                  : TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 380 + 90 * i),
                      curve: Curves.easeOutBack,
                      builder: (_, t, child) => Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
                      ),
                      child: KeyedSubtree(
                        key: _pieceKeys[p.data],
                        child: DraggableItem(
                          data: p.data,
                          size: Size(l.pieceW, l.pieceH),
                          onTouched: rc.hints.touched,
                          child: _PieceTile(art: _art(p.scene), q: p.q, width: l.pieceW, height: l.pieceH),
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

/// Quadrant [q] of a scene rendered at twice the cell size and clipped, so
/// the four cells line up into exactly the whole picture.
class Quadrant extends StatelessWidget {
  const Quadrant({super.key, required this.art, required this.q, required this.width, required this.height});
  final SceneArt? art;
  final int q;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment(q.isEven ? -1 : 1, q < 2 ? -1 : 1),
          minWidth: width * 2,
          maxWidth: width * 2,
          minHeight: height * 2,
          maxHeight: height * 2,
          child: SceneStill(art: art),
        ),
      ),
    );
  }
}

class _PieceTile extends StatelessWidget {
  const _PieceTile({required this.art, required this.q, required this.width, required this.height});
  final SceneArt? art;
  final int q;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    const r = BorderRadius.all(Radius.circular(10));
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: r,
        boxShadow: [BoxShadow(color: Palette.shadow, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(borderRadius: r, border: Border.all(color: Palette.card, width: 3)),
        child: ClipRRect(borderRadius: r, child: Quadrant(art: art, q: q, width: width, height: height)),
      ),
    );
  }
}

/// An empty hole: soft paper with a dashed outline. In the full puzzle it is
/// see-through so the ghost picture shows where pieces go.
class _Hole extends StatelessWidget {
  const _Hole({required this.seeThrough});
  final bool seeThrough;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HolePainter(seeThrough: seeThrough),
      child: const SizedBox.expand(),
    );
  }
}

class _HolePainter extends CustomPainter {
  const _HolePainter({required this.seeThrough});
  final bool seeThrough;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.paper.withValues(alpha: seeThrough ? 0.62 : 0.94));
    final r = RRect.fromRectAndRadius((Offset.zero & size).deflate(size.shortestSide * 0.07), const Radius.circular(12));
    final dash = Paint()
      ..color = Palette.inkSoft.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final metric in (Path()..addRRect(r)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 18) {
        canvas.drawPath(metric.extractPath(d, d + 9), dash);
      }
    }
  }

  @override
  bool shouldRepaint(_HolePainter o) => o.seeThrough != seeThrough;
}

/// Soft cream seams between the four cells while the puzzle is unfinished.
class _SeamPainter extends CustomPainter {
  const _SeamPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Palette.card.withValues(alpha: 0.9)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), p);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), p);
  }

  @override
  bool shouldRepaint(_SeamPainter o) => false;
}
