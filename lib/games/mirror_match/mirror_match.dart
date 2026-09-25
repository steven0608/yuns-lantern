import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/art/item_art.dart';
import '../../core/audio/audio_service.dart';
import '../../core/tokens.dart';
import '../shared/activity_scaffold.dart';
import '../shared/draggable_item.dart';
import '../shared/drop_target.dart';
import '../shared/gentle_hint.dart';

/// Mirror Match / 照镜子 (4+) — a picture cut into a 2-column grid with a
/// shiny mirror line down the middle. The left half is shown; the right half
/// is glassy and empty. The tray holds the left pieces flipped horizontally
/// (true symmetry), shuffled; the child drags each into its row. When both
/// sides match, the picture flaps like wings and Yun names it.
final mirrorMatchGame = GameDef(
  id: 'mirror_match',
  build: (rc) => MirrorMatch(rc: rc),
  prompt: (r) => r.vo,
  background: const [Color(0xFFFBE8E4), Color(0xFFEBCFD8)],
);

class MirrorMatch extends StatefulWidget {
  const MirrorMatch({super.key, required this.rc});
  final RoundContext rc;

  @override
  State<MirrorMatch> createState() => _MirrorMatchState();
}

class _MirrorMatchState extends State<MirrorMatch>
    with TickerProviderStateMixin {
  RoundContext get rc => widget.rc;
  late final String _subject = rc.round.str('subject');

  /// 2 columns × rows: `cells` 4 → 2 rows, 6 → 3 rows. One tray piece per
  /// row, so the interactive cap bounds the rows too.
  late final int _rows = (rc.round.integer('cells') ~/ 2).clamp(
    1,
    kMaxInteractiveItems,
  );

  late final List<int> _trayOrder;
  late final List<GlobalKey> _tileKeys = List.generate(
    _rows,
    (_) => GlobalKey(),
  );
  late final List<GlobalKey> _slotKeys = List.generate(
    _rows,
    (_) => GlobalKey(),
  );
  final Set<int> _placed = {};

  /// The piece last dropped on the wrong row: help focuses on it.
  int? _missed;

  late final AnimationController _shine; // glints travelling over the glass
  late final AnimationController _enter; // tray pieces pop in
  late final AnimationController _flap; // the finished picture flaps

  bool get _done => _placed.length == _rows;

  /// Which piece help is about: the one the child just tried, else the
  /// topmost piece still missing.
  int? get _focus {
    if (_missed != null && !_placed.contains(_missed)) return _missed;
    for (var r = 0; r < _rows; r++) {
      if (!_placed.contains(r)) return r;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final order = rc.shuffled(List.generate(_rows, (i) => i));
    // A tray already in slot order would give the answer away: rotate it.
    var sorted = true;
    for (var i = 0; i < order.length; i++) {
      if (order[i] != i) sorted = false;
    }
    _trayOrder = sorted && _rows > 1 ? [...order.skip(1), order.first] : order;

    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _enter = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500 + 120 * _rows),
    )..forward();
    _flap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    rc.hints.guide = () {
      final p = _focus;
      return p == null ? null : HintMove(_tileKeys[p], _slotKeys[p]);
    };
  }

  @override
  void dispose() {
    _shine.dispose();
    _enter.dispose();
    _flap.dispose();
    super.dispose();
  }

  static int? _pieceOf(String data) => int.tryParse(data.split(':').last);

  void _accept(int row) {
    setState(() => _placed.add(row));
    rc.hints.succeeded();
    if (!_done) return;
    rc.audio.sfx(Sfx.sparkle);
    Future.wait([rc.audio.playVO('item.$_subject'), _flap.forward(from: 0)])
        .then((_) {
          if (mounted) rc.complete();
        });
  }

  void _reject(String data) {
    setState(() => _missed = _pieceOf(data));
    rc.hints.miss();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        final wide = w >= h;
        final tile = (math.min(w, h) * 0.2).clamp(kMinTouchTarget, 150.0);
        final extent = tile + kHitSlop; // a tile plus its slop padding
        const gap = kMinTargetGap - kHitSlop; // + slop = 64px visible gap
        const trayPad = 10.0;
        const spacing = 32.0;

        // As few tray columns as fit: a phone in landscape needs two for 3 rows.
        double span(int n) => n * extent + (n - 1) * gap + trayPad * 2;
        var cols = wide ? 1 : _rows;
        while (wide && cols < _rows && span((_rows / cols).ceil()) > h) {
          cols++;
        }
        final trayW = span(cols);
        final trayH = span((_rows / cols).ceil());
        final frame = math.max(
          0.0,
          wide
              ? math.min(math.min(h, w - trayW - spacing), 680.0)
              : math.min(math.min(w, h - trayH - spacing), 680.0),
        );
        final pad = frame * 0.045;
        final art = math.max(0.0, frame - pad * 2 - 8); // minus the 4px border
        final pieceSize = Size(art / 2, art / _rows);

        // The mirror is look-only: taps fall through to the scaffold's sparkle
        // (drop targets find pieces by their bounds, not by hit testing).
        final mirror = IgnorePointer(
          child: _mirror(frame, pad, art, pieceSize, tile),
        );
        final tray = _tray(tile, trayW - trayPad * 2, trayPad, pieceSize);
        return Center(
          child: wide
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    mirror,
                    const SizedBox(width: spacing),
                    tray,
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    mirror,
                    const SizedBox(height: spacing),
                    tray,
                  ],
                ),
        );
      },
    );
  }

  Widget _mirror(
    double frame,
    double pad,
    double art,
    Size piece,
    double tile,
  ) {
    final seam = math.max(6.0, art * 0.022);
    // Scale of a tray tile's picture relative to the slot, so a dropped piece
    // grows smoothly from tray size to full size.
    final tileScale = math.min(
      tile * 0.84 / math.max(piece.width, 1),
      tile * 0.84 / math.max(piece.height, 1),
    );

    return Container(
      width: frame,
      height: frame,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Palette.card,
        borderRadius: BorderRadius.circular(frame * 0.08),
        border: Border.all(color: Palette.paperDeep, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Palette.shadow,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The right half is the glassy mirror side.
          Positioned(
            left: art / 2,
            top: 0,
            width: art / 2,
            height: art,
            child: ClipRRect(
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(frame * 0.05),
              ),
              child: CustomPaint(painter: _GlassPainter(_shine)),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _RowLinesPainter(_rows))),
          ValueListenableBuilder<int>(
            valueListenable: rc.hints.level,
            builder: (_, level, _) => AnimatedBuilder(
              animation: _flap,
              builder: (_, child) {
                // Two soft wing-beats around the mirror line.
                final t = _flap.value;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translateByDouble(
                      0,
                      -art * 0.04 * math.sin(math.pi * t),
                      0,
                      1,
                    )
                    ..scaleByDouble(
                      1 - 0.14 * (1 - math.cos(t * math.pi * 4)) / 2,
                      1,
                      1,
                      1,
                    ),
                  child: child,
                );
              },
              child: Row(
                children: [
                  Column(
                    children: [
                      for (var r = 0; r < _rows; r++)
                        SizedBox.fromSize(
                          size: piece,
                          child: _Piece(
                            subject: _subject,
                            art: art,
                            rows: _rows,
                            row: r,
                          ),
                        ),
                    ],
                  ),
                  Column(
                    children: [
                      for (var r = 0; r < _rows; r++)
                        _slot(r, piece, art, tileScale, level),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // The mirror line itself; it softens once both sides match.
          Positioned(
            left: art / 2 - seam / 2,
            width: seam,
            top: -pad * 0.4,
            bottom: -pad * 0.4,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _done ? 0.2 : 1,
                duration: const Duration(milliseconds: 500),
                child: CustomPaint(painter: _SeamPainter(_shine)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slot(int r, Size piece, double art, double tileScale, int level) {
    final placed = _placed.contains(r);
    final hinted = !placed && level >= 1 && _focus == r;
    final mirrored = _Piece(
      subject: _subject,
      art: art,
      rows: _rows,
      row: r,
      flipped: true,
    );
    return DropTarget(
      key: _slotKeys[r],
      id: 'row$r',
      enabled: !placed,
      pulse: hinted,
      radius: 16,
      willAccept: (data) => _pieceOf(data) == r,
      onAccept: (_) => _accept(r),
      onReject: _reject,
      child: SizedBox.fromSize(
        size: piece,
        child: placed
            ? TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 620),
                builder: (_, t, child) => Stack(
                  fit: StackFit.expand,
                  children: [
                    Transform.scale(
                      scale:
                          tileScale +
                          (1 - tileScale) * Curves.easeOutBack.transform(t),
                      child: child,
                    ),
                    CustomPaint(painter: _GlintPainter(t)),
                  ],
                ),
                child: mirrored,
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _DashedCellPainter()),
                  // Second-miss help: a faint reflection shows what belongs here.
                  AnimatedOpacity(
                    opacity: hinted ? 0.28 : 0,
                    duration: kStandardEase,
                    child: mirrored,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _tray(double tile, double innerW, double pad, Size piece) {
    return Stack(
      children: [
        // Backdrop only: taps between pieces fall through to the sparkle.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Palette.card.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(36),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(pad),
          child: SizedBox(
            width: innerW,
            child: Wrap(
              alignment: WrapAlignment.center,
              // Spacing + each piece's 12px slop each side = 64px visible gap.
              spacing: kMinTargetGap - kHitSlop,
              runSpacing: kMinTargetGap - kHitSlop,
              children: [
                for (final (i, p) in _trayOrder.indexed)
                  _tile(i, p, tile, piece),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tile(int slotInTray, int p, double tile, Size piece) {
    if (_placed.contains(p)) return SizedBox.square(dimension: tile + kHitSlop);
    return AnimatedBuilder(
      animation: _enter,
      builder: (_, child) {
        final ms = _enter.value * _enter.duration!.inMilliseconds;
        final t = ((ms - 200 - slotInTray * 120) / 380).clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.6 + 0.4 * Curves.easeOutBack.transform(t),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: _tileKeys[p],
        child: DraggableItem(
          key: ValueKey('piece$p'),
          data: 'piece:$p',
          size: Size.square(tile),
          enabled: !_done,
          onTouched: rc.hints.touched,
          child: _GlassTile(
            size: tile,
            child: FittedBox(
              child: SizedBox.fromSize(
                size: piece,
                child: _Piece(
                  subject: _subject,
                  art: piece.width * 2,
                  rows: _rows,
                  row: p,
                  flipped: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One row of the left half of [subject]'s picture, optionally mirrored.
/// The whole picture is laid out at [art]×[art] and clipped to the cell.
class _Piece extends StatelessWidget {
  const _Piece({
    required this.subject,
    required this.art,
    required this.rows,
    required this.row,
    this.flipped = false,
  });
  final String subject;
  final double art;
  final int rows, row;
  final bool flipped;

  @override
  Widget build(BuildContext context) {
    final y = rows == 1 ? 0.0 : -1 + 2 * row / (rows - 1);
    final Widget half = ClipRect(
      child: OverflowBox(
        minWidth: art,
        maxWidth: art,
        minHeight: art,
        maxHeight: art,
        alignment: Alignment(-1, y),
        child: Center(child: ItemArt(subject, size: art * 0.84)),
      ),
    );
    // True symmetry: the right side is the left side flipped (scale x = -1).
    return flipped ? Transform.flip(flipX: true, child: half) : half;
  }
}

/// A tray piece: a small pane of mirror glass holding a reflected piece.
class _GlassTile extends StatelessWidget {
  const _GlassTile({required this.size, required this.child});
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(color: Palette.paper, width: 3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              Palette.water.withValues(alpha: 0.28),
              Palette.card,
            ),
            Color.alphaBlend(
              Palette.water.withValues(alpha: 0.12),
              Palette.card,
            ),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Palette.shadow,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Pale blue glass with the two diagonal streaks everyone reads as "mirror",
/// plus a slow glint that sweeps across every few seconds.
class _GlassPainter extends CustomPainter {
  _GlassPainter(this.shine) : super(repaint: shine);
  final Animation<double> shine;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Palette.water.withValues(alpha: 0.32),
            Palette.water.withValues(alpha: 0.14),
          ],
        ).createShader(rect),
    );
    final streak = Paint()
      ..color = Palette.card.withValues(alpha: 0.6)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final w = size.width, h = size.height;
    canvas.drawLine(
      Offset(w * 0.52, h * 0.3),
      Offset(w * 0.86, h * 0.1),
      streak..strokeWidth = math.max(6, w * 0.08),
    );
    canvas.drawLine(
      Offset(w * 0.62, h * 0.38),
      Offset(w * 0.9, h * 0.22),
      streak..strokeWidth = math.max(3, w * 0.035),
    );

    // Glint: sweeps during the first third of each cycle, then rests.
    final t = shine.value / 0.35;
    if (t < 1) {
      final x = -0.3 + 1.6 * Curves.easeInOut.transform(t);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Palette.card.withValues(alpha: 0),
              Palette.card.withValues(alpha: 0.45),
              Palette.card.withValues(alpha: 0),
            ],
            stops: [
              (x - 0.12).clamp(0.0, 1.0),
              x.clamp(0.0, 1.0),
              (x + 0.12).clamp(0.0, 1.0),
            ],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_GlassPainter old) => false;
}

/// The mirror line: a silvery capsule with a light bead gliding along it.
class _SeamPainter extends CustomPainter {
  _SeamPainter(this.shine) : super(repaint: shine);
  final Animation<double> shine;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.width / 2),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Palette.waterDeep, Palette.card, Palette.water],
        ).createShader(rect),
    );
    final y = size.height * Curves.easeInOut.transform(shine.value);
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawCircle(
      Offset(size.width / 2, y),
      size.width * 1.6,
      Paint()
        ..color = Palette.card.withValues(alpha: 0.85)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SeamPainter old) => false;
}

/// Faint dashed lines between rows, so each left piece visibly lines up
/// with the empty cell it mirrors.
class _RowLinesPainter extends CustomPainter {
  _RowLinesPainter(this.rows);
  final int rows;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.inkSoft.withValues(alpha: 0.2)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var r = 1; r < rows; r++) {
      final y = size.height * r / rows;
      for (var x = 6.0; x < size.width - 6; x += 16) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 8, size.width - 6), y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RowLinesPainter old) => old.rows != rows;
}

/// An empty mirror cell: a soft dashed outline waiting for its piece.
class _DashedCellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final inset = math.max(5.0, size.shortestSide * 0.06);
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(inset),
      Radius.circular(size.shortestSide * 0.14),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = Palette.card.withValues(alpha: 0.3),
    );
    final stroke = Paint()
      ..color = Palette.waterDeep.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const dash = 9.0;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash * 2) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedCellPainter old) => false;
}

/// A bright band that sweeps once across a freshly placed piece, like light
/// catching the glass.
class _GlintPainter extends CustomPainter {
  _GlintPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final rect = Offset.zero & size;
    final x = -0.2 + 1.4 * t;
    final fade = 1 - t;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Palette.card.withValues(alpha: 0),
            Palette.card.withValues(alpha: 0.7 * fade),
            Palette.card.withValues(alpha: 0),
          ],
          stops: [
            (x - 0.15).clamp(0.0, 1.0),
            x.clamp(0.0, 1.0),
            (x + 0.15).clamp(0.0, 1.0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlintPainter old) => old.t != t;
}
