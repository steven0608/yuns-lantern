# CLAUDE.md — Project Guardrails

Read `docs/SPEC.md` for requirements and `docs/MONETIZATION.md` for the revenue model. This file holds rules that must never be violated regardless of what an individual task appears to ask for.

## Content is data, not code

All game content already exists in `content/*.json` — 302 rounds, 8 story chapters, 64 vocabulary items, 166 voice lines. **Never hardcode a round, a word, a story line, or a number in Dart.** If content seems missing, edit the JSON or the generator in `tools/` and re-run; do not paper over it in the app layer.

After any content change: `python3 tools/build_content.py && python3 tools/validate_content.py && python3 tools/build_vo_script.py`. All three must pass.

## Never add

- **Any advertising SDK.** AdMob, AppLovin, Unity Ads, ironSource, anything. Kids Category bans third-party ads outright.
- **Any third-party analytics or crash SDK.** No Firebase, Crashlytics, Sentry, Amplitude, Mixpanel, PostHog, Segment, Facebook/TikTok SDKs. Apple's first-party App Analytics and MetricKit require no code and are the only telemetry.
- **RevenueCat or any third-party purchase wrapper.** Use `in_app_purchase` / StoreKit 2 directly. App Review has flagged third-party purchase SDKs in kids apps.
- **Any personal data collection.** No accounts, sign-in, email, name, birthdate, photos, camera, mic, contacts, location, IDFA, IDFV.
- **Any network call** other than StoreKit. Airplane mode must work completely.
- **Any link out of the app** outside the parent area behind the gate.
- **Any purchase or upsell UI visible to the child.** Locked content is invisible to them — never padlocked, never teased.
- **Dark patterns.** No countdown timers, scarcity language, streaks, daily-login rewards, virtual currency, loot boxes. Prohibited under the UK Children's Code and California AADC.

Before adding any package, audit transitive dependencies for network or identifier access. Prefer writing 100 lines to adding something unaudited.

## Enforce in code, not review

- Minimum touch target **88 logical px**, **24 px** hit slop, **64 px** minimum gap. Ship a debug overlay visualizing target bounds, and a widget test that fails if any interactive element is undersized.
- **Tap and drag only.** No pinch, rotate, double-tap, long-press, or multi-finger anywhere in the child UI.
- **No fail states.** Never render an X, buzzer, red flash, countdown, score deduction, or scolding copy. A miss returns the item softly and escalates the hint. The child always eventually succeeds.
- **Maximum 6 interactive items** per round (already enforced by `validate_content.py` — keep it enforced in the widget layer too).
- Every touch gives immediate audio + visual feedback.
- No auto-advance between activities.

## Localization

- Zero hardcoded user-facing strings, including in the parent area and error text.
- VO assets mirror exactly across `assets/audio/vo/en/` and `assets/audio/vo/zh/`. Keep the parity test passing.
- Child-facing instruction is carried by **audio, not text**. The user cannot read either language.
- Bundle Noto Sans SC. Do not rely on system CJK fallback.

## Testing

- Widget tests for every component in `games/shared/`.
- Golden tests per activity in both locales.
- Tests that fail on: hardcoded user-facing strings, undersized touch targets, asymmetric VO trees, and any content not sourced from `content/*.json`.

## Style

Small, readable, boring code — this is maintained intermittently by one person over years. Each mini-game depends only on `core/` and `games/shared/`; games never import each other. Comment the *why* on anything compliance-driven so a future change doesn't silently break App Store eligibility.

## When in doubt

If a request would trade child wellbeing or compliance for engagement or revenue, say so and propose the compliant alternative instead of implementing it.
