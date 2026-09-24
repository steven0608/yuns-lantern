#!/usr/bin/env python3
"""
Revenue model for the no-ads Kids Category plan.

Every assumption is named and editable. The point is not to predict your
revenue -- nobody can -- but to show which levers actually matter, so effort
goes where it pays. Run it, then change the assumptions you disagree with.

Apple's commission: 15% under the Small Business Program (<$1M/yr), which
you will qualify for. Net to you = 85%.
"""

APPLE_NET = 0.85
SMALL_BIZ_NOTE = "15% commission (Small Business Program, under $1M/yr)"


def money(x):
    return f"${x:,.0f}"


def consumer(downloads_per_month, conv_unlock, price_unlock,
             conv_sub, price_sub_year, sub_renewal_y2, months=12):
    """One-time unlock and annual subscription running side by side.
    A parent picks one; they are not additive per user."""
    m_unlock = downloads_per_month * conv_unlock * price_unlock * APPLE_NET
    m_sub_new = downloads_per_month * conv_sub * price_sub_year * APPLE_NET
    y1 = (m_unlock + m_sub_new) * months
    # year two: new cohort plus renewals from year one's subscribers
    subs_y1 = downloads_per_month * conv_sub * months
    y2 = y1 + subs_y1 * sub_renewal_y2 * price_sub_year * APPLE_NET
    return y1, y2


def b2b(classrooms, price_per_classroom):
    return classrooms * price_per_classroom  # direct invoice, no store cut


def scenario(name, downloads_per_month, conv_unlock, conv_sub,
             classrooms, price_unlock=12.99, price_sub_year=39.99,
             renewal=0.35, price_classroom=180):
    y1, y2 = consumer(downloads_per_month, conv_unlock, price_unlock,
                      conv_sub, price_sub_year, renewal)
    b = b2b(classrooms, price_classroom)
    print(f"\n{name}")
    print(f"  {downloads_per_month:,}/mo downloads · "
          f"{conv_unlock*100:.1f}% unlock · {conv_sub*100:.1f}% subscribe · "
          f"{classrooms} classrooms")
    print(f"  consumer year 1 : {money(y1)}")
    print(f"  consumer year 2 : {money(y2)}   (incl. {renewal*100:.0f}% renewals)")
    print(f"  B2B licensing   : {money(b)}/yr")
    print(f"  TOTAL year 1    : {money(y1 + b)}")
    print(f"  TOTAL year 2    : {money(y2 + b)}")
    return y1 + b, y2 + b


print("=" * 68)
print("REVENUE MODEL — Kids Category, no advertising")
print(f"Apple takes {SMALL_BIZ_NOTE}")
print("=" * 68)

print("""
PRICING
  One-time full unlock      $12.99   (all 12 activities + all 8 story chapters)
  Annual subscription       $39.99   (everything + new chapter each month)
  Classroom licence         $180/yr  (direct invoice, no store commission)

CONVERSION ASSUMPTIONS
  Research baseline: freemium apps convert ~2.2% of downloads to paid;
  hard paywalls ~12%. This app uses a generous free tier (6 of 12 activities,
  2 of 8 story chapters), which sits at the freemium end. Modelled at 2-4%
  combined, split between the two options.""")

pess = scenario("PESSIMISTIC — no marketing, organic discovery only",
                downloads_per_month=300, conv_unlock=0.015, conv_sub=0.005,
                classrooms=0)

base = scenario("BASE — decent ASO, bilingual listing, some parent word-of-mouth",
                downloads_per_month=1500, conv_unlock=0.020, conv_sub=0.010,
                classrooms=8)

good = scenario("GOOD — featured once, or a school channel takes hold",
                downloads_per_month=6000, conv_unlock=0.025, conv_sub=0.015,
                classrooms=40)

print("\n" + "=" * 68)
print("WHAT THE LEVERS ARE WORTH (from the BASE case)")
print("=" * 68)

b_y1, _ = consumer(1500, 0.020, 12.99, 0.010, 39.99, 0.35)
b_y1 += b2b(8, 180)

levers = [
    ("Double downloads (1500 -> 3000)",
     consumer(3000, 0.020, 12.99, 0.010, 39.99, 0.35)[0] + b2b(8, 180)),
    ("Raise unlock price $12.99 -> $19.99",
     consumer(1500, 0.020, 19.99, 0.010, 39.99, 0.35)[0] + b2b(8, 180)),
    ("Lift conversion 3.0% -> 4.5% (better free tier)",
     consumer(1500, 0.030, 12.99, 0.015, 39.99, 0.35)[0] + b2b(8, 180)),
    ("Go from 8 to 40 classrooms",
     consumer(1500, 0.020, 12.99, 0.010, 39.99, 0.35)[0] + b2b(40, 180)),
    ("All four together",
     consumer(3000, 0.030, 19.99, 0.015, 39.99, 0.35)[0] + b2b(40, 180)),
]

for label, val in levers:
    delta = val - b_y1
    print(f"  {label:48s} {money(val):>10s}  ({delta:+,.0f})")

print("""
=" * 68
READ THIS PART

Consumer app revenue at realistic solo-developer scale is a few thousand
dollars a year, not a salary. The two levers that actually move the number
are DOWNLOADS and B2B CLASSROOMS -- not price, and not squeezing conversion.

40 classrooms at $180 is $7,200/yr from roughly 40 emails and 8 phone calls.
Reaching 6,000 organic downloads a month is far harder than that. For a solo
developer, the school channel is the highest return on effort by a wide
margin, and it is the one nobody bothers with.

Note also: B2B revenue has no store commission and no COPPA parental-consent
complexity (schools contract as the institution), and immersion programmes
are exactly the audience for a bilingual Mandarin-English maths app. That is
the moat. Build the consumer app well, then sell it to schools.
""".replace('=" * 68', "=" * 68))
