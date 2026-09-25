import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/iap/purchase_service.dart';
import '../../core/storage/prefs.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';

/// Behind the gate (SPEC §11). The only place purchase UI may ever appear.
/// Progress is shown as plain play counts: no scores, percentiles or
/// "behind schedule" language.
class ParentArea extends StatelessWidget {
  const ParentArea({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = AppLocalizations.of(context);
    final lang = context.lang;
    return ListenableBuilder(
      listenable: Listenable.merge([s.settings, s.progress, s.purchases]),
      builder: (context, _) {
        final st = s.settings;
        return Scaffold(
          backgroundColor: Palette.paper,
          appBar: AppBar(
            backgroundColor: Palette.paperDeep,
            title: Text(l.parentTitle),
            leading: IconButton(
              tooltip: l.parentBack,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _Section(l.sectionPurchase, [
                    if (Settings.allFree) _Note(l.allFreeNote),
                    if (s.purchases.owned || st.purchased)
                      ListTile(
                        leading: const Icon(
                          Icons.favorite_rounded,
                          color: Palette.rust,
                        ),
                        title: Text(l.purchaseOwned),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l.purchasePitch),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: FilledButton(
                          onPressed: s.purchases.product == null
                              ? null
                              : s.purchases.buy,
                          child: Text(
                            l.purchaseButton(s.purchases.product?.price ?? '—'),
                          ),
                        ),
                      ),
                    ],
                    TextButton(
                      onPressed: s.purchases.restore,
                      child: Text(l.purchaseRestore),
                    ),
                    if (s.purchases.state case PurchaseState.unavailable)
                      _Note(l.purchaseUnavailable),
                    if (s.purchases.state case PurchaseState.pending)
                      _Note(l.purchasePending),
                    if (s.purchases.state case PurchaseState.failed)
                      _Note(l.purchaseFailed),
                    if (kDebugMode)
                      SwitchListTile(
                        title: Text(l.devUnlock),
                        value: st.devUnlock,
                        onChanged: (v) => st.devUnlock = v,
                      ),
                  ]),
                  _Section(l.sectionLanguage, [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'auto',
                            label: Text(l.languageAuto),
                          ),
                          ButtonSegment(value: 'en', label: Text(l.languageEn)),
                          ButtonSegment(value: 'zh', label: Text(l.languageZh)),
                        ],
                        selected: {st.localeOverride},
                        onSelectionChanged: (v) => st.localeOverride = v.first,
                      ),
                    ),
                  ]),
                  _Section(l.bookLanguage, [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'app',
                            label: Text(l.bookLanguageApp),
                          ),
                          ButtonSegment(
                            value: 'both',
                            label: Text(l.bookLanguageBoth),
                          ),
                        ],
                        selected: {st.bookLanguage},
                        onSelectionChanged: (v) => st.bookLanguage = v.first,
                      ),
                    ),
                  ]),
                  _Section(l.sectionSound, [
                    ListTile(
                      title: Text(l.voiceVolume),
                      subtitle: Slider(
                        value: st.voVolume,
                        onChanged: (v) => st.voVolume = v,
                      ),
                    ),
                    ListTile(
                      title: Text(l.musicVolume),
                      subtitle: Slider(
                        value: st.musicVolume,
                        onChanged: (v) => st.musicVolume = v,
                      ),
                    ),
                    ListTile(
                      title: Text(l.effectsVolume),
                      subtitle: Slider(
                        value: st.sfxVolume,
                        onChanged: (v) => st.sfxVolume = v,
                      ),
                    ),
                  ]),
                  _Section(l.sectionChild, [
                    ListTile(
                      title: Text(l.childAge),
                      subtitle: Text(l.childAgeHelp),
                      trailing: DropdownButton<int>(
                        value: st.childAge,
                        items: [
                          for (final a in [3, 4, 5])
                            DropdownMenuItem(
                              value: a,
                              child: Text(l.childAgeValue(a)),
                            ),
                        ],
                        onChanged: (v) => st.childAge = v ?? st.childAge,
                      ),
                    ),
                  ]),
                  _Section(l.sectionActivities, [
                    _Note(l.activitiesHelp),
                    for (final a in s.content.activities.values)
                      if (a.free || st.fullAccess)
                        SwitchListTile(
                          title: Text('${a.name.of(lang)}  ·  ${a.minAge}+'),
                          value: !st.hiddenActivities.contains(a.id),
                          onChanged: (v) => st.setActivityHidden(a.id, !v),
                        ),
                  ]),
                  _Section(l.sectionBreak, [
                    _Note(l.breakHelp),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SegmentedButton<int>(
                        segments: [
                          ButtonSegment(value: 0, label: Text(l.breakOff)),
                          for (final m in [10, 15, 20])
                            ButtonSegment(
                              value: m,
                              label: Text(l.breakMinutes(m)),
                            ),
                        ],
                        selected: {st.breakMinutes},
                        onSelectionChanged: (v) => st.breakMinutes = v.first,
                      ),
                    ),
                  ]),
                  _Section(l.sectionProgress, [
                    ListTile(
                      title: Text(
                        l.chaptersDone(
                          s.progress.lightsCollected.length,
                          s.content.story.chapters.length,
                        ),
                      ),
                    ),
                    ...() {
                      final played = [
                        for (final a in s.content.activities.values)
                          if (s.progress.timesPlayed(a.id) > 0)
                            ListTile(
                              dense: true,
                              title: Text(
                                l.progressLine(
                                  a.name.of(lang),
                                  s.progress.timesPlayed(a.id),
                                ),
                              ),
                            ),
                      ];
                      return played.isEmpty ? [_Note(l.progressNone)] : played;
                    }(),
                  ]),
                  _Section(l.sectionAbout, [
                    ExpansionTile(
                      title: Text(l.privacyTitle),
                      children: [_Note(l.privacyBody)],
                    ),
                    ExpansionTile(
                      title: Text(l.creditsTitle),
                      children: [_Note(l.creditsBody)],
                    ),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Palette.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Palette.rustDeep,
                  ),
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Text(text, style: const TextStyle(color: Palette.inkSoft)),
  );
}
