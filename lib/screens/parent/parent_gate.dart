import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'parent_area.dart';

void openParentArea(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const ParentGate()));
}

/// Apple's parental gate (SPEC §10): a multiplication written out in WORDS —
/// the words are the barrier, since a pre-reader can't parse them. New problem
/// every time. A wrong answer returns silently to the child's home: no
/// lockout, no retry counter, nothing that reads as failure to the child.
/// This is not COPPA verifiable parental consent; the app collects nothing.
class ParentGate extends StatefulWidget {
  const ParentGate({super.key, this.random});
  final math.Random? random;

  @override
  State<ParentGate> createState() => _ParentGateState();
}

class _ParentGateState extends State<ParentGate> {
  late final math.Random _rng = widget.random ?? math.Random.secure();
  late int _a, _b;
  String _entry = '';

  @override
  void initState() {
    super.initState();
    do {
      _a = 2 + _rng.nextInt(8);
      _b = 2 + _rng.nextInt(8);
    } while (_a * _b < 10); // always a two-digit answer
  }

  String _word(AppLocalizations l, int n) => switch (n) {
    2 => l.numberWord2,
    3 => l.numberWord3,
    4 => l.numberWord4,
    5 => l.numberWord5,
    6 => l.numberWord6,
    7 => l.numberWord7,
    8 => l.numberWord8,
    _ => l.numberWord9,
  };

  void _press(String d) {
    if (_entry.length < 2) setState(() => _entry += d);
  }

  void _submit() {
    final nav = Navigator.of(context);
    if (int.tryParse(_entry) == _a * _b) {
      nav.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ParentArea()),
      );
    } else {
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget key(String label, VoidCallback onTap, {Color? color}) => Padding(
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        width: 76,
        height: 60,
        child: FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: color ?? Palette.card,
            foregroundColor: Palette.ink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: onTap,
          child: Text(label),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Palette.paperDeep,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                iconSize: 40,
                padding: const EdgeInsets.all(20),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Palette.inkSoft),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.center,
                  spacing: 40,
                  runSpacing: 16,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l.gateTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              color: Palette.inkSoft,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l.gateQuestion(_word(l, _a), _word(l, _b)),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              color: Palette.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: 140,
                            height: 64,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Palette.card,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _entry,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Palette.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final row in const [
                          ['1', '2', '3'],
                          ['4', '5', '6'],
                          ['7', '8', '9'],
                        ])
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final d in row) key(d, () => _press(d)),
                            ],
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            key(l.gateClear, () => setState(() => _entry = '')),
                            key('0', () => _press('0')),
                            key(l.gateOk, _submit, color: Palette.lantern),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
