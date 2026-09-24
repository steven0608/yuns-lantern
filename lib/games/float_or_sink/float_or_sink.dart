import 'package:flutter/material.dart';

import '../shared/activity_scaffold.dart';
import '../shared/cards.dart';

/// STUB — replaced by the real engine. See docs/GAME_DESIGN.md#float_or_sink.
final floatOrSinkGame = GameDef(
  id: 'float_or_sink',
  build: (rc) => Center(
    child: ChoiceCard(id: 'star', correct: true, hints: rc.hints, onCorrect: rc.complete),
  ),
  prompt: (r) => r.vo.take(2).toList(),
);
