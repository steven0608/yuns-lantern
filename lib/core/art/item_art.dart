import 'package:flutter/material.dart';

import '../app_scope.dart';

/// Draws a vocab item. Placeholder emoji today (assets/images/placeholder_art.json);
/// Phase 4 swaps this body for Image.asset('assets/images/items/$id.png').
class ItemArt extends StatelessWidget {
  const ItemArt(this.id, {super.key, this.size = 72, this.silhouette = false});
  final String id;
  final double size;

  /// Solid dark shape of the item, for What Is It?
  final bool silhouette;

  @override
  Widget build(BuildContext context) {
    final glyph = context.services.content.art.items[id] ?? '❔';
    return Emoji(glyph, size: size, silhouette: silhouette);
  }
}

class Emoji extends StatelessWidget {
  const Emoji(this.glyph, {super.key, this.size = 72, this.silhouette = false});
  final String glyph;
  final double size;
  final bool silhouette;

  @override
  Widget build(BuildContext context) {
    Widget t = SizedBox(
      width: size * 1.15,
      height: size * 1.15,
      child: Center(
        child: Text(
          glyph,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: size, height: 1.0),
        ),
      ),
    );
    if (silhouette) {
      t = ColorFiltered(
        colorFilter: const ColorFilter.mode(Color(0xFF3E3150), BlendMode.srcIn),
        child: t,
      );
    }
    return ExcludeSemantics(child: t);
  }
}
