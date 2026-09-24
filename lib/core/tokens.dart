import 'package:flutter/widgets.dart';

// Design tokens (SPEC §6). Touch sizes are compliance-driven: 88 logical px is
// ~2cm on iPad, the NN/g minimum for 3-5 year olds. Do not lower them to fit
// a layout — change the layout.
const double kMinTouchTarget = 88.0;
const double kHitSlop = 24.0;
const double kMinTargetGap = 64.0;
const int kMaxInteractiveItems = 6;

const Duration kIdleHintDelay = Duration(seconds: 8);
const Duration kIdleHintRepeat = Duration(seconds: 12);
const Duration kCelebrationLength = Duration(milliseconds: 1800);
const Duration kStandardEase = Duration(milliseconds: 260);
const Curve kStandardCurve = Curves.easeOutCubic;

/// Extra radius around a drop target inside which a release still snaps (§7.2).
const double kSnapRadius = 72.0;

/// Warm, medium-saturation palette. No pure white anywhere (§6).
abstract final class Palette {
  static const Color paper = Color(0xFFFBF1E1);
  static const Color paperDeep = Color(0xFFF4E0C2);
  static const Color card = Color(0xFFFFF8EC);
  static const Color ink = Color(0xFF4A3426);
  static const Color inkSoft = Color(0xFF8A6D58);
  static const Color rust = Color(0xFFC8643B);
  static const Color rustDeep = Color(0xFF9E4726);
  static const Color cream = Color(0xFFFFE9C9);
  static const Color lantern = Color(0xFFE8A93C);
  static const Color leaf = Color(0xFF8DB86B);
  static const Color water = Color(0xFF7FB7D1);
  static const Color waterDeep = Color(0xFF4F8FB0);
  static const Color night = Color(0xFF3A3D6B);
  static const Color mist = Color(0xFFD9D4CC);
  static const Color shadow = Color(0x334A3426);

  /// Content colour names (vocab, story lights) → display colour. Colour never
  /// carries meaning alone: bins and lights always pair it with an object/shape.
  static const Map<String, Color> named = {
    'red': Color(0xFFD9534A),
    'orange': Color(0xFFEE9A3E),
    'yellow': Color(0xFFF2CC4A),
    'green': Color(0xFF79B45A),
    'blue': Color(0xFF5B9BD5),
    'purple': Color(0xFF9B76C4),
    'pink': Color(0xFFEFA0B8),
    'brown': Color(0xFF9C6B45),
    'white': Color(0xFFF7F1E6),
    'black': Color(0xFF3B3533),
  };
}
