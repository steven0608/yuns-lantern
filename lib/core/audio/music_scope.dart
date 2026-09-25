import 'package:flutter/widgets.dart';

import '../app_scope.dart';

/// Plays [track] (a `Music` name) while this screen is in the tree; the
/// screen underneath gets its own track back when this one closes.
class MusicScope extends StatefulWidget {
  const MusicScope({super.key, required this.track, required this.child});
  final String track;
  final Widget child;

  @override
  State<MusicScope> createState() => _MusicScopeState();
}

class _MusicScopeState extends State<MusicScope> {
  int? _token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _token ??= context.services.audio.pushMusic(widget.track);
  }

  @override
  void deactivate() {
    // Pop while the inherited services are still reachable.
    final t = _token;
    if (t != null) {
      context.services.audio.popMusic(t);
      _token = null;
    }
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _token ??= context.services.audio.pushMusic(widget.track);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
