#!/usr/bin/env python3
"""Builds the static landing page into landing/ (English at /, 中文 at /zh/).

Rules (docs/EXPANSION.md §8): no third-party requests at all — fonts, images and video
are copied in and served from the same origin, exactly like the app. No analytics, no
cookies, no embeds. The page is one file per language plus assets/.

    python design/build_landing.py     # then serve landing/ or deploy it as the Pages root
"""
import json
import os
import shutil

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "landing")
A = os.path.join(OUT, "assets")

APP_URL = "/yuns-lantern/play/"          # the web app, once E5 moves it under /play/
REPO_URL = "https://github.com/steven0608/yuns-lantern"

cat = json.load(open(os.path.join(ROOT, "content", "catalog.json"), encoding="utf-8"))
lib = json.load(open(os.path.join(ROOT, "content", "library.json"), encoding="utf-8"))
N_GAMES, N_TALES = len(cat["games"]), len(lib["tales"])
N_LANDS = len(cat["engines"])

COPY = {
    "en": dict(
        lang="en", other="zh", other_label="中文", dir_prefix="",
        title="Yun's Lantern — Mandarin and English for ages 3–5",
        desc="A bilingual learning app for ages 3–5. 75 games, 75 stories, no ads, no tracking, nothing collected.",
        tagline="Mandarin and English, for ages 3–5",
        hero_h1="Yun's lantern went out.",
        hero_p="Help Yun find eight little lights. Count apples, sort shapes, hear every word in English and 中文 — and never read a thing.",
        cta_play="Play in your browser", cta_ios="Coming to iPhone and iPad",
        badge_free="Free while we test",
        what_h="What's inside",
        cards=[("%d games" % N_GAMES, "Counting, shapes, sorting, patterns, memory, music and more, across %d lands. Every game is tap and drag." % N_LANDS),
               ("%d stories" % N_TALES, "Short illustrated tales, 6–8 pages each. Read in English, in 中文, or both, one after the other."),
               ("8 story chapters", "Yun's journey to relight the great lantern, from the apple orchard to Lantern Hill.")],
        how_h="How it works",
        how=[("Listening, not reading", "Every instruction is spoken. A three-year-old who cannot read either language can play alone."),
             ("No wrong answers", "A miss returns the piece softly and the hint grows. There is no buzzer, no red X, no score."),
             ("Made for small hands", "Every target is at least 88 points across, about 2 cm, with generous spacing.")],
        parents_h="For parents",
        parents=[("Collects nothing", "No accounts, no email, no analytics, no ads, no tracking. The app makes no network calls except the App Store purchase."),
                 ("Works offline", "Everything is on the device. Airplane mode is a feature."),
                 ("Nothing to nag with", "No timers, no streaks, no daily rewards, no virtual currency. Nothing your child sees will ask you for money.")],
        story_h="The story",
        story_p="The big lantern at the top of the hill has gone dark. Yun the red panda sets out to find eight little lights to bring it back. Each chapter is a place, a skill and one coloured light.",
        price_h="Price",
        price_p="Everything is free right now while we test. At release, the app will have a generous free tier and a single one-time purchase for the rest — no subscription, and Family Sharing included.",
        faq_h="Questions",
        faq=[("Does my child need to read?", "No. Everything a child needs is spoken aloud, in whichever language you choose. Text on screen is for you."),
             ("Do I need to speak Chinese?", "No. Pick English, 中文, or both. In Both mode each story page is read in one language, then the other."),
             ("What ages is it for?", "Three to five. You set your child's age once, and games meant for older children stay hidden until then."),
             ("Is there any advertising?", "None, ever. The app has no ad SDK, no analytics SDK, and makes no third-party network calls.")],
        footer_made="Made for one small person, and shared with yours.",
        privacy="Privacy: this site and the app collect nothing.",
        source="Source on GitHub",
    ),
    "zh": dict(
        lang="zh-Hans", other="en", other_label="English", dir_prefix="../",
        title="小云的灯笼 — 3 到 5 岁的中英双语启蒙",
        desc="3 到 5 岁的双语学习应用。75 个游戏，75 个故事。没有广告，不做追踪，不收集任何信息。",
        tagline="中文和英文，3 到 5 岁",
        hero_h1="小云的灯笼灭了。",
        hero_p="帮小云找到八个小灯光。数苹果、分形状，每个词都能听到中文和英文——一个字也不用认。",
        cta_play="在浏览器里玩", cta_ios="iPhone 和 iPad 版即将推出",
        badge_free="测试期间全部免费",
        what_h="里面有什么",
        cards=[("%d 个游戏" % N_GAMES, "数数、形状、分类、规律、记忆、音乐……分成 %d 个乐园。每个游戏都只需要点一点、拖一拖。" % N_LANDS),
               ("%d 个故事" % N_TALES, "短短的绘本故事，每个 6 到 8 页。可以用英文读、用中文读，也可以两种语言一起读。"),
               ("8 个故事章节", "小云重新点亮大灯笼的旅程，从苹果园一直走到灯笼山。")],
        how_h="它是怎么用的",
        how=[("用听的，不用认字", "所有提示都是语音。三岁的孩子两种语言都还不认字，也能自己玩。"),
             ("没有“做错了”", "放错了，东西会轻轻回到原位，提示会更明显一点。没有刺耳的声音，没有红叉，也没有分数。"),
             ("为小手设计", "每个可以点的地方至少 88 点宽，大约 2 厘米，彼此之间留足空隙。")],
        parents_h="给家长",
        parents=[("不收集任何信息", "没有账号、没有邮箱、没有统计、没有广告、没有追踪。除了 App Store 购买本身，应用不联网。"),
                 ("离线也能用", "所有内容都在设备上。飞行模式照样玩。"),
                 ("不会缠着孩子", "没有倒计时、没有连续打卡、没有每日奖励、没有虚拟货币。孩子看到的界面里，不会有任何让您花钱的东西。")],
        story_h="故事",
        story_p="山顶上的大灯笼灭了。小熊猫小云出发去找八个小灯光，把它重新点亮。每一章都是一个地方、一项本领，和一盏彩色的灯。",
        price_h="价格",
        price_p="测试期间全部免费。正式发布时会有一个内容很足的免费部分，其余内容一次性购买即可，没有订阅，并且支持家人共享。",
        faq_h="常见问题",
        faq=[("孩子需要认字吗？", "不需要。孩子需要知道的一切都会用您选的语言念出来。屏幕上的文字是给大人看的。"),
             ("我不会中文可以吗？", "可以。选英文、中文，或者两种都要。双语模式下，故事的每一页会先用一种语言念，再用另一种念。"),
             ("适合多大的孩子？", "三到五岁。您只需设置一次孩子的年龄，适合更大孩子的游戏在那之前不会出现。"),
             ("有广告吗？", "永远没有。应用里没有任何广告 SDK、统计 SDK，也不会向第三方发送任何请求。")],
        footer_made="为一个小朋友做的，也分享给您家的小朋友。",
        privacy="隐私：这个网站和这个应用都不收集任何信息。",
        source="GitHub 源码",
    ),
}

CSS = """*{box-sizing:border-box}
html{scroll-behavior:smooth}
body{margin:0;background:#FBF1E1;color:#4A3426;font-family:'Noto Sans SC',system-ui,-apple-system,sans-serif;font-size:18px;line-height:1.65}
h1,h2,h3,.f{font-family:Fredoka,'Noto Sans SC',system-ui,sans-serif;font-weight:600}
h1{font-size:clamp(34px,5.2vw,60px);line-height:1.12;margin:0 0 18px}
h2{font-size:clamp(26px,3.4vw,38px);margin:0 0 28px}
h3{font-size:21px;margin:0 0 8px}
p{margin:0 0 16px}
a{color:#9E4726}
.wrap{max-width:1120px;margin:0 auto;padding:0 24px}
header{padding:20px 0}
.bar{display:flex;align-items:center;justify-content:space-between;gap:16px;flex-wrap:wrap}
.logo{display:flex;align-items:center;gap:12px;text-decoration:none;color:inherit}
.logo img{width:52px;height:52px}
.logo b{font-family:Fredoka,sans-serif;font-size:22px;font-weight:600}
.logo span{display:block;font-size:15px;color:#75594A;font-weight:400}
.lang{border:1.5px solid #E0CDB0;background:#FFF8EC;border-radius:22px;padding:9px 18px;text-decoration:none;color:#4A3426;font-weight:500;font-size:16px}
.hero{display:grid;grid-template-columns:1.05fr .95fr;gap:48px;align-items:center;padding:36px 0 64px}
.hero img.shot{width:100%;height:auto;border-radius:26px;box-shadow:0 22px 50px rgba(74,52,38,.18)}
.badge{display:inline-block;background:#DDEBD2;color:#2F5520;border-radius:20px;padding:6px 14px;font-size:15px;font-weight:600;margin-bottom:18px}
.lead{font-size:20px;color:#5C4535;max-width:34em}
.cta{display:flex;gap:14px;flex-wrap:wrap;margin-top:26px;align-items:center}
.btn{display:inline-block;background:#9E4726;color:#FFF8EC;border-radius:16px;padding:15px 28px;text-decoration:none;font-weight:600;font-size:18px}
.btn:hover{background:#7A3419}
.btn.ghost{background:transparent;color:#75594A;border:1.5px solid #E0CDB0}
section{padding:60px 0}
section.tint{background:#F4E0C2}
section.night{background:#3A3D6B;color:#FFE9C9}
section.night h2,section.night h3{color:#FFE9C9}
section.night p{color:#DED8CF}
.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:24px}
.card{background:#FFF8EC;border-radius:22px;padding:28px;box-shadow:inset 0 0 0 1px #EAD9BF}
.card .n{font-family:Fredoka,sans-serif;font-size:clamp(30px,2.6vw,40px);font-weight:600;color:#9E4726;line-height:1;margin-bottom:10px}
.card p{margin:0;color:#5C4535;font-size:17px}
.rowimgs{display:flex;gap:18px;flex-wrap:wrap;justify-content:center;margin-top:34px}
.rowimgs img{width:clamp(72px,8vw,104px);height:auto}
.list{display:grid;grid-template-columns:repeat(3,1fr);gap:28px}
.list p{color:#5C4535;font-size:17px;margin:0}
.storyrow{display:grid;grid-template-columns:1fr 1fr;gap:40px;align-items:center}
.storyrow img{width:100%;height:auto;border-radius:22px}
.lanterns{display:flex;gap:10px;flex-wrap:wrap;margin-top:22px}
.lanterns img{width:clamp(36px,4.2vw,52px);height:auto}
.faq dt{font-weight:600;font-family:Fredoka,'Noto Sans SC',sans-serif;font-size:19px;margin-top:22px}
.faq dd{margin:6px 0 0;color:#5C4535}
footer{padding:44px 0 64px;color:#75594A;font-size:16px}
footer .fl{display:flex;gap:22px;flex-wrap:wrap;justify-content:space-between;align-items:center}
@media (max-width:900px){
 .hero{grid-template-columns:1fr;gap:28px;padding-bottom:40px}
 .grid,.list{grid-template-columns:1fr}
 .storyrow{grid-template-columns:1fr}
 body{font-size:17px}
 section{padding:44px 0}
}
@media (prefers-reduced-motion:reduce){html{scroll-behavior:auto}}
"""


def fonts_css():
    return """@font-face{font-family:Fredoka;src:url(assets/Fredoka.ttf) format('truetype');font-weight:400 600;font-display:swap}
@font-face{font-family:'Noto Sans SC';src:url(assets/NotoSansSC-subset.ttf) format('truetype');font-weight:400 700;font-display:swap}
"""


def page(key):
    c = COPY[key]
    p = "../" if key != "en" else ""
    cards = "".join(f'<div class="card"><div class="n">{t}</div><p>{d}</p></div>' for t, d in c["cards"])
    how = "".join(f'<div><h3>{t}</h3><p>{d}</p></div>' for t, d in c["how"])
    parents = "".join(f'<div><h3>{t}</h3><p>{d}</p></div>' for t, d in c["parents"])
    faq = "".join(f'<dt>{q}</dt><dd>{a}</dd>' for q, a in c["faq"])
    icons = "".join(f'<img src="{p}assets/land_{e}.png" alt="">' for e in
                    ("count_feed", "sort_bins", "find_same", "pattern", "trace", "music_echo", "memory_pairs", "color_fill"))
    lanterns = "".join(f'<img src="{p}assets/light_{col}.png" alt="">' for col in
                       ("red", "orange", "yellow", "green", "blue", "purple", "pink", "white"))
    other_href = "zh/" if key == "en" else "../"
    return f"""<!doctype html>
<html lang="{c['lang']}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{c['title']}</title>
<meta name="description" content="{c['desc']}">
<meta property="og:title" content="{c['title']}">
<meta property="og:description" content="{c['desc']}">
<meta property="og:image" content="{p}assets/og.png">
<meta property="og:type" content="website">
<link rel="icon" type="image/png" href="{p}assets/favicon.png">
<link rel="alternate" hreflang="{'zh-Hans' if key == 'en' else 'en'}" href="{other_href}">
<style>
{fonts_css().replace('assets/', p + 'assets/')}
{CSS}
</style>
</head>
<body>
<header>
  <div class="wrap bar">
    <a class="logo" href="#top"><img src="{p}assets/mark.png" alt=""><span><b>{'Yun&#39;s Lantern' if key == 'en' else '小云的灯笼'}</b><span>{c['tagline']}</span></span></a>
    <a class="lang" href="{other_href}" lang="{'zh-Hans' if key == 'en' else 'en'}">{c['other_label']}</a>
  </div>
</header>

<main id="top">
  <div class="wrap hero">
    <div>
      <span class="badge">{c['badge_free']}</span>
      <h1>{c['hero_h1']}</h1>
      <p class="lead">{c['hero_p']}</p>
      <div class="cta">
        <a class="btn" href="{APP_URL}">{c['cta_play']}</a>
        <span class="btn ghost">{c['cta_ios']}</span>
      </div>
    </div>
    <img class="shot" src="{p}assets/shot_home.png" alt="" width="1194" height="834">
  </div>

  <section class="tint">
    <div class="wrap">
      <h2>{c['what_h']}</h2>
      <div class="grid">{cards}</div>
      <div class="rowimgs">{icons}</div>
    </div>
  </section>

  <section>
    <div class="wrap">
      <h2>{c['how_h']}</h2>
      <div class="list">{how}</div>
    </div>
  </section>

  <section class="night">
    <div class="wrap storyrow">
      <div>
        <h2>{c['story_h']}</h2>
        <p>{c['story_p']}</p>
        <div class="lanterns">{lanterns}</div>
      </div>
      <img src="{p}assets/shot_map.png" alt="" width="1194" height="834">
    </div>
  </section>

  <section class="tint">
    <div class="wrap">
      <h2>{c['parents_h']}</h2>
      <div class="list">{parents}</div>
    </div>
  </section>

  <section>
    <div class="wrap">
      <h2>{c['price_h']}</h2>
      <p style="max-width:44em">{c['price_p']}</p>
    </div>
  </section>

  <section class="tint">
    <div class="wrap">
      <h2>{c['faq_h']}</h2>
      <dl class="faq">{faq}</dl>
    </div>
  </section>
</main>

<footer>
  <div class="wrap fl">
    <span>{c['footer_made']}</span>
    <span>{c['privacy']} · <a href="{REPO_URL}">{c['source']}</a></span>
  </div>
</footer>
</body>
</html>
"""


def main():
    os.makedirs(A, exist_ok=True)
    os.makedirs(os.path.join(OUT, "zh"), exist_ok=True)
    png = os.path.join(HERE, "png")
    copies = {
        "mark.png": ("brand", "logo_mark.png"), "favicon.png": ("brand", "favicon_mark.png"),
        "og.png": ("brand", "logo_horizontal.png"), "shot_home.png": ("shots", "home.png"),
        "shot_map.png": ("shots", "map.png"), "shot_reader.png": ("shots", "reader.png"),
    }
    for e in ("count_feed", "sort_bins", "find_same", "pattern", "trace", "music_echo", "memory_pairs", "color_fill"):
        copies[f"land_{e}.png"] = ("lands", f"{e}.png")
    for col in ("red", "orange", "yellow", "green", "blue", "purple", "pink", "white"):
        copies[f"light_{col}.png"] = (None, f"light_{col}.png")
    for dest, (sub, src) in copies.items():
        shutil.copyfile(os.path.join(png, sub, src) if sub else os.path.join(png, src), os.path.join(A, dest))
    for f in ("Fredoka.ttf", "NotoSansSC-subset.ttf", "OFL.txt"):
        s = os.path.join(ROOT, "assets", "fonts", f)
        if os.path.exists(s):
            shutil.copyfile(s, os.path.join(A, f))
    open(os.path.join(OUT, "index.html"), "w", encoding="utf-8", newline="\n").write(page("en"))
    open(os.path.join(OUT, "zh", "index.html"), "w", encoding="utf-8", newline="\n").write(page("zh"))
    open(os.path.join(OUT, ".nojekyll"), "w").write("")
    print("landing/: index.html, zh/index.html,", len(os.listdir(A)), "assets")


if __name__ == "__main__":
    main()
