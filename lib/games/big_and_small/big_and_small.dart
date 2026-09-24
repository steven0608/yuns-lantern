import 'package:flutter/material.dart';

import '../shared/activity_scaffold.dart';
import '../shared/cards.dart';

/// STUB — replaced by the real engine. See docs/GAME_DESIGN.md#big_and_small.
final bigAndSmallGame = GameDef(
  id: 'big_and_small',
  build: (rc) => Center(
    child: ChoiceCard(id: 'star', correct: true, hints: rc.hints, onCorrect: rc.complete),
  ),
  prompt: (r) => r.vo.take(2).toList(),
);
