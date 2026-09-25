import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/tokens.dart';
import '../shared/activity_scaffold.dart';

/// Sizes the puzzle frame and tray for the space available.
///
/// Rules, in priority order:
///  1. pieces are exactly the size of a hole (the fit is visible);
///  2. a piece is never under [kMinTouchTarget] on either side, and pieces
///     keep a [kMinTargetGap] visible gap (CLAUDE.md);
///  3. the picture is as big as possible.
/// Tries the tray beside the frame (1–3 columns) and in a row below it, at
/// the scene art's landscape shape and at a square crop (phones), and keeps
/// whichever gives the largest picture.
class PuzzleLayout {
  const PuzzleLayout._(this.frameW, this.frameH, this.trayW, this.below);

  /// The picture (inside the frame border).
  final double frameW, frameH;
  final double trayW;

  /// Tray in a row under the frame (else beside it, on the right).
  final bool below;

  double get pieceW => frameW / 2;
  double get pieceH => frameH / 2;

  static const double border = 10;
  static const double gap = 28;

  /// Wrap spacing: with each piece's 12px slop either side this makes the
  /// visible gap exactly kMinTargetGap.
  static const double spacing = kMinTargetGap - kHitSlop;

  /// Chapter scenes are drawn at 1194×834; 1.0 is the phone fallback crop.
  static const _aspects = [1194 / 834, 1.0];
  static const _maxFrameW = 780.0;

  static PuzzleLayout solve(
    Size box, {
    required int pieces,
    double clearance = 0,
  }) {
    PuzzleLayout? best;
    double bestArea = -1;
    void consider(double fw, double aspect, bool below, int cols) {
      fw = math.min(fw, _maxFrameW);
      final fh = fw / aspect;
      if (fh / 2 < kMinTouchTarget || fw / 2 < kMinTouchTarget) return;
      final area = fw * fh;
      if (area <= bestArea) return;
      bestArea = area;
      final trayW = cols * (fw / 2 + kHitSlop) + (cols - 1) * spacing;
      best = PuzzleLayout._(fw, fh, trayW, below);
    }

    final h = box.height, frameMaxH = h - 2 * border;
    for (final a in _aspects) {
      // Tray beside the frame: pieces sit level with the corner buttons, so
      // leave the phone clearance on the right.
      final w = box.width - clearance;
      for (var cols = 1; cols <= math.min(pieces, 3); cols++) {
        final rows = (pieces / cols).ceil();
        final byWidth =
            (w - 2 * border - gap - kHitSlop * cols - spacing * (cols - 1)) /
            (1 + cols / 2);
        final byTray =
            2 * a * (h - kHitSlop * rows - spacing * (rows - 1)) / rows;
        consider(
          math.min(byWidth, math.min(byTray, a * frameMaxH)),
          a,
          false,
          cols,
        );
      }
      // One row under the frame, clear of the corner buttons.
      final byRow =
          2 * (box.width - kHitSlop * pieces - spacing * (pieces - 1)) / pieces;
      final byHeight = a * (h - 2 * border - gap - kHitSlop) / 1.5;
      consider(
        math.min(math.min(byRow, byHeight), box.width - 2 * border),
        a,
        true,
        pieces,
      );
    }
    // Always return something: the smallest compliant layout.
    return best ??
        PuzzleLayout._(
          2 * kMinTouchTarget,
          2 * kMinTouchTarget,
          math.min(pieces, 2) * (kMinTouchTarget + kHitSlop) + spacing,
          false,
        );
  }
}

/// On phones the scaffold's home/replay buttons sit in side rails whose inner
/// edge is only 24px from our content, level with our top row. Returns how
/// much to pull targets in so they keep a full kMinTargetGap (CLAUDE.md).
double cornerClearance(Size screen) {
  const buttonEdge =
      4 + kHitSlop / 2 + kMinTouchTarget; // ActivityScaffold's corner buttons
  final insets = ActivityScaffold.contentInsets(screen);
  if (insets.top >= buttonEdge) return 0; // buttons sit above the content
  return math.max(0.0, kMinTargetGap - (insets.left - buttonEdge));
}
