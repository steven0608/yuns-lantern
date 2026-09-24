# How This App Makes Money Without Ads

Run `python3 tools/revenue_model.py` to reproduce or change any number here.

---

## The strategic point most people miss

This app has **two** paying audiences, not one:

1. **Chinese-speaking families who want their child to learn English.** Large, price-sensitive, already served by 洪恩, 宝宝巴士, 悟空识字, 叽里呱啦. You would be a late entrant competing on price against companies with studio budgets.

2. **English-speaking families who want their child to learn Mandarin.** Far smaller, far less served, and **dramatically higher willingness to pay.** These parents already spend $30–80/hour on Mandarin tutors, $500+/year on immersion programmes, and buy every Mandarin-for-kids product that exists. Almost none of it is good.

Audience 2 is the business. Audience 1 is the bonus.

This reframes everything: your App Store listing, your screenshots, and your keywords should lead with **"Mandarin for young children"**, not "preschool math." The math curriculum is the *vehicle* — it's what makes the Mandarin exposure meaningful rather than flashcard drilling. That's a genuinely differentiated pitch, and it's why a parent pays $12.99 instead of downloading a free counting app.

---

## The four revenue streams

### 1. One-time full unlock — $12.99 (primary)

All 12 activities, all 8 story chapters, forever, one purchase, Family Sharing enabled.

- Non-consumable IAP, purchased **only** from inside the parent area behind the parental gate.
- Family Sharing on. It costs you a little revenue and buys a lot of goodwill in reviews, which is worth more.
- $12.99 sits deliberately above the $4.99 impulse tier. It signals "this is a real product," and research on Education pricing shows one-time purchases have grown to ~17% of category revenue precisely because parents prefer a clean purchase over another subscription.

**Why one-time and not subscription-only:** you are one person. A subscription is a promise of continuous new content. Breaking that promise generates refunds and 1-star reviews. Sell the thing you've actually built.

### 2. Annual subscription — $39.99/year (secondary, optional)

Offered alongside the unlock, not instead of it. Includes everything plus a new story chapter monthly.

**Only enable this once you have shipped three monthly chapters on schedule.** Until then it is a liability. If you never get there, ship unlock-only — that's a perfectly good business.

### 3. Classroom licensing — $180/classroom/year (the real opportunity)

The model shows this plainly: going from 8 to 40 classrooms adds more revenue than raising your price by $7, and it is far more achievable than tripling organic downloads.

**Why it works for you specifically:**
- No App Store commission. $180 invoiced is $180 received, versus $12.99 becoming $11.04.
- No COPPA verifiable-parental-consent burden — the school contracts as an institution, and since the app collects no personal data anyway, the compliance story is a one-page document.
- Mandarin immersion and dual-language programmes are your *exact* audience, they have budget lines for curriculum software, and they are desperate for age-appropriate bilingual material.

**How to actually do it:** there are several hundred Mandarin immersion programmes in the US alone, plus Chinese community weekend schools in every major city. They are individually findable. Email the programme director, offer a free semester for the first ten, ask for a testimonial and a referral. This is roughly forty emails, not a sales team.

### 4. Curated bundles — Apple Arcade / Google Play Pass (upside, not a plan)

Apply once the app is polished and reviewed well. Both are invitation-curated; Arcade has historically paid an upfront fixed fee, Play Pass pays on engagement. Neither is predictable enough to plan around, both are worth an application. You cannot run IAP while in Play Pass, so treat it as an alternative, not an addition.

---

## What the model says

| Scenario | Downloads/mo | Classrooms | Year 1 | Year 2 |
|---|---|---|---|---|
| Pessimistic — organic only | 300 | 0 | **$1,208** | $1,422 |
| Base — good ASO + word of mouth | 1,500 | 8 | **$11,533** | $13,675 |
| Good — featured once, or schools land | 6,000 | 40 | **$63,786** | $76,634 |

**Lever sensitivity from the base case:**

| Change | Year 1 | Delta |
|---|---|---|
| Double downloads | $21,627 | +$10,093 |
| Raise price $12.99 → $19.99 | $13,675 | +$2,142 |
| Lift conversion 3.0% → 4.5% | $16,580 | +$5,047 |
| 8 → 40 classrooms | $17,293 | +$5,760 |
| All four | $43,906 | +$32,373 |

Downloads dominate; classrooms are the cheapest large gain; price is the weakest lever. Stop optimizing the paywall and go talk to schools.

---

## Free tier design (validated in `tools/validate_content.py`)

**Free:** 6 of 12 activities (143 rounds) + story chapters 1–2.
**Paid:** 6 more activities (159 rounds) + story chapters 3–8.

The free tier is deliberately generous and genuinely complete — a child can play it for weeks without hitting a wall. The build **fails** if a free story chapter requires a paid activity, which is exactly the bug that shipped in the first draft and got caught.

**What converts:** the story. A child who has relit two of eight lights and wants to know what happens at Mirror Lake is the reason a parent pays. Not a locked padlock icon — the child never sees those. The parent sees, in the parent area: *"Yun has 6 more places to visit."*

---

## Rules that protect the product

- **No purchase UI is ever visible to the child.** Locked content is not shown to them at all — no padlocks, no teasers, no "ask a grown-up!" popups.
- **No countdown timers, no limited-time offers, no scarcity language.** The UK Children's Code prohibits nudge techniques toward children, and California's AADC mirrors it.
- **Restore Purchases must work.** Apple rejects apps without it.
- **Price honestly in every region.** Set explicit CNY/TWD/HKD/SGD tiers rather than letting Apple auto-convert.

---

## Sequence

1. **Ship free tier + $12.99 unlock.** Kids Category, 4+, no ads, no analytics, no data collection.
2. **Month 1–3: reviews and ASO.** Bilingual listing with separate zh-Hans metadata. Lead with Mandarin learning.
3. **Month 2: start the school outreach.** Forty emails. Free semester for the first ten in exchange for a testimonial.
4. **Month 6: decide on subscription** — only if you've shipped three chapters on time.
5. **Month 9: apply to Apple Arcade and Google Play Pass.**

Expect year one to be four figures unless something breaks your way. Year two is where the school channel compounds.
