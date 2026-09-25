import 'package:flutter/material.dart';

import '../app_scope.dart';

/// Draws a vocab item: the design session's drawing (`assets/images/items/{id}.png`,
/// in the item's vocab.json colour and shape) when it exists, else the
/// placeholder emoji from assets/images/placeholder_art.json.
class ItemArt extends StatelessWidget {
  const ItemArt(this.id, {super.key, this.size = 72, this.silhouette = false});
  final String id;
  final double size;

  /// Solid dark shape of the item, for What Is It?
  final bool silhouette;

  @override
  Widget build(BuildContext context) {
    final art = context.services.content.art;
    final image = art.itemImage(id);
    if (image == null) return Emoji(art.items[id] ?? '❔', size: size, silhouette: silhouette);
    Widget pic = Image.asset(image, width: size * 1.15, height: size * 1.15, fit: BoxFit.contain, filterQuality: FilterQuality.medium);
    if (silhouette) {
      pic = ColorFiltered(colorFilter: const ColorFilter.mode(Color(0xFF3E3150), BlendMode.srcIn), child: pic);
    }
    return ExcludeSemantics(child: pic);
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
