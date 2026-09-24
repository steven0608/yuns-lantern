import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/audio/audio_service.dart';
import '../../core/tokens.dart';
import 'drop_target.dart';

/// Drag + snap + hit slop + soft return (SPEC §7.1–7.2).
///
/// While dragged, the item is lifted into the Overlay so it floats above
/// everything regardless of the layout it came from. On release:
///  * inside a target's snap radius and accepted → glides into the target;
///  * rejected by the target → floats home, target's onReject escalates help;
///  * dropped in empty space → floats home silently. Never a penalty sound.
class DraggableItem extends StatefulWidget {
  const DraggableItem({
    super.key,
    required this.data,
    required this.child,
    this.size = const Size.square(kMinTouchTarget + 8),
    this.enabled = true,
    this.onTouched,
  });

  final String data;
  final Widget child;
  final Size size;
  final bool enabled;

  /// Any touch, used to reset idle hints.
  final VoidCallback? onTouched;

  @override
  State<DraggableItem> createState() => _DraggableItemState();
}

class _DraggableItemState extends State<DraggableItem> with SingleTickerProviderStateMixin {
  late final AnimationController _fly = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  OverlayEntry? _entry;
  final ValueNotifier<Offset> _pos = ValueNotifier(Offset.zero);
  Offset _home = Offset.zero;
  DropTargetState? _hover;
  bool _lifted = false;

  Size get _size => Size(
        widget.size.width < kMinTouchTarget ? kMinTouchTarget : widget.size.width,
        widget.size.height < kMinTouchTarget ? kMinTouchTarget : widget.size.height,
      );

  @override
  void dispose() {
    _entry?.remove();
    _fly.dispose();
    _pos.dispose();
    super.dispose();
  }

  RenderBox get _overlayBox => Overlay.of(context).context.findRenderObject()! as RenderBox;

  void _start(DragStartDetails d) {
    final scope = DropZoneScope.of(context);
    if (!widget.enabled || _lifted || (scope?.dragging.value ?? false)) return;
    scope?.dragging.value = true;
    final box = context.findRenderObject()! as RenderBox;
    // The visible item sits inside the hit-slop padding.
    _home = _overlayBox.globalToLocal(box.localToGlobal(const Offset(kHitSlop / 2, kHitSlop / 2)));
    _pos.value = _home;
    _entry = OverlayEntry(builder: _buildFloating);
    Overlay.of(context).insert(_entry!);
    context.services.audio.sfx(Sfx.pickup);
    setState(() => _lifted = true);
  }

  void _update(DragUpdateDetails d) {
    if (!_lifted || _fly.isAnimating) return;
    _pos.value += d.delta;
    final t = DropZoneScope.of(context)?.targetAt(_globalCenter);
    if (t != _hover) {
      _hover?.hovered.value = false;
      t?.hovered.value = true;
      _hover = t;
    }
  }

  Offset get _globalCenter => _overlayBox.localToGlobal(_pos.value + _size.center(Offset.zero));

  Future<void> _end([DragEndDetails? _]) async {
    if (!_lifted || _fly.isAnimating) return;
    _hover?.hovered.value = false;
    _hover = null;
    final audio = context.services.audio;
    final target = DropZoneScope.of(context)?.targetAt(_globalCenter);

    if (target != null && target.widget.willAccept(widget.data)) {
      final r = target.globalRect!;
      final dest = _overlayBox.globalToLocal(r.center) - _size.center(Offset.zero);
      audio.sfx(Sfx.snap);
      await _flyTo(dest, shrink: true);
      _finish();
      target.widget.onAccept(widget.data);
      return;
    }
    if (target != null) {
      target.widget.onReject?.call(widget.data);
      audio.sfx(Sfx.softReturn);
    } else {
      audio.sfx(Sfx.whoosh);
    }
    await _flyTo(_home);
    _finish();
  }

  void _finish() {
    _entry?.remove();
    _entry = null;
    DropZoneScope.of(context)?.dragging.value = false;
    if (mounted) setState(() => _lifted = false);
  }

  Future<void> _flyTo(Offset dest, {bool shrink = false}) async {
    final from = _pos.value;
    void tick() => _pos.value = Offset.lerp(from, dest, kStandardCurve.transform(_fly.value))!;
    _fly.addListener(tick);
    _shrink = shrink;
    await _fly.forward(from: 0);
    _fly.removeListener(tick);
    _shrink = false;
  }

  bool _shrink = false;

  Widget _buildFloating(BuildContext _) {
    return ValueListenableBuilder<Offset>(
      valueListenable: _pos,
      builder: (_, p, child) {
        final scale = _shrink ? 1.12 - 0.12 * _fly.value : 1.12;
        return Positioned(
          left: p.dx,
          top: p.dy,
          child: IgnorePointer(
            child: Transform.scale(
              scale: scale,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  boxShadow: [BoxShadow(color: Palette.shadow, blurRadius: 18, offset: Offset(0, 10))],
                  shape: BoxShape.circle,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      child: SizedBox.fromSize(size: _size, child: widget.child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (_) {
        widget.onTouched?.call();
        if (!_lifted) context.services.audio.sfx(Sfx.tap);
      },
      onPanStart: _start,
      onPanUpdate: _update,
      onPanEnd: _end,
      onPanCancel: () {
        if (_lifted) _end();
      },
      child: Padding(
        padding: const EdgeInsets.all(kHitSlop / 2),
        child: Opacity(
          opacity: _lifted ? 0.25 : 1,
          child: SizedBox.fromSize(size: _size, child: widget.child),
        ),
      ),
    );
  }
}
