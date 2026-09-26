# Voice-Over Recording Script

**GENERATED — do not hand-edit. Edit `content/phrases.json`, `content/vocab.json`, or `content/story.json` and re-run `tools/build_vo_script.py`.**

Total lines to record per language: **195** (×2 languages = **390** files)


## Direction for both voice actors

- **Warm, unhurried, and real.** Speak the way you would to one child sitting
  next to you — not to an audience, not to a camera. No sing-song "kids TV" voice.
- **Slow, but not slowed down.** Natural pace with clear articulation. Leave the
  final consonant/tone intact rather than trimming it.
- **No rising "quiz" inflection** on prompts. A question should sound curious,
  not testing.
- **Feedback lines must sound genuinely pleased**, not performed. These play
  hundreds of times; anything theatrical becomes grating by the third day.
- **Never sound disappointed.** There are no failure lines in this app by design.
  The "retry" lines are encouraging redirections, not corrections.

### Mandarin specifics
- Standard Mandarin (普通话), Beijing-neutral, no regional colouring.
- **Tones must be fully realised**, including neutral tones (轻声) — a child is
  learning pronunciation from this audio and will copy exactly what they hear.
- Observe 儿化 only where written. Do not add it.
- Numbers 一 through 十 are recorded in isolation and must be usable in any
  counting position, so keep 一 as first tone (yī), not the sandhi variant.

### English specifics
- Neutral North American or neutral British — pick one and stay consistent
  across every file.
- Fully articulate final consonants ("eight", not "eigh").

### Technical
- 48 kHz, 24-bit WAV masters; deliver mono. App bundles 128 kbps mono MP3.
- Silence trimmed to 80–120 ms head, 150–250 ms tail.
- Peak −3 dBFS, loudness normalised to −16 LUFS integrated.
- One file per line, named exactly as the **Key** column with dots replaced by
  slashes: `counting.ask` → `assets/audio/vo/en/counting/ask.mp3`.
- **File trees for `en/` and `zh/` must be identical.** The build fails otherwise.


## Story mode narration

*24 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `story.bigmountain.beat` | Short step, then taller, then tallest. That is how a ladder is built. | 先矮的，再高一点，最后最高的。梯子就是这样搭的。 |  |
| `story.bigmountain.close` | Up we go! At the top, a green light was waiting. | 我们爬上去啦！山顶上有一个绿色的灯光在等你。 |  |
| `story.bigmountain.open` | The mountain is very tall. Yun is very small. We will need a ladder. | 山很高。小云很小。我们需要一个梯子。 |  |
| `story.lighthouse.beat` | The last light is inside the lantern itself. It only needs a little help waking up. | 最后一个灯光就在大灯笼里面。它只是需要一点帮助醒过来。 |  |
| `story.lighthouse.close` | Look at that! The whole hill is bright. You brought the light back, and Yun will never forget it. | 快看！整座山都亮了。是你把光带回来的，小云永远不会忘记。 |  |
| `story.lighthouse.open` | Seven lights. One to go. The big lantern is just up this path. | 七个灯光了。还差一个。大灯笼就在这条路的尽头。 |  |
| `story.mirrorlake.beat` | Butterfly lost one wing in the water. Can you make both sides match? | 蝴蝶的一只翅膀掉进水里了。你能让两边一模一样吗？ |  |
| `story.mirrorlake.close` | Butterfly can fly again. She leaves you a pink light. | 蝴蝶又能飞了。她留给你一个粉色的灯光。 |  |
| `story.mirrorlake.open` | The lake shows everything twice. One on top, one underneath. | 湖面把每样东西都照出两个。上面一个，下面一个。 |  |
| `story.mistyforest.beat` | Owl says: I am up. Frog says: I am down. Can you find them? | 猫头鹰说：我在上面。青蛙说：我在下面。你能找到他们吗？ |  |
| `story.mistyforest.close` | Everyone found. The fog lifts, and a blue light shines through. | 大家都找到了。雾散开了，一个蓝色的灯光照进来。 |  |
| `story.mistyforest.open` | The fog is thick here. Yun can hear friends, but cannot see them. | 这里的雾很浓。小云能听见朋友，可是看不见他们。 |  |
| `story.orchard.beat` | The apples are too high. If we help Bear fill his basket, maybe he will lift us up. | 苹果太高了。我们帮熊装满篮子，他也许会把我们举高。 |  |
| `story.orchard.close` | You did it! One red light. Seven more to find. | 你做到了！一个红色的光。还要找七个。 |  |
| `story.orchard.open` | Yun's lantern went out. Look — a tiny red light, way up in the apple tree! | 小云的灯笼灭了。快看——苹果树上有一点红色的光！ |  |
| `story.rainbowriver.beat` | Let's put the things that go together, together. | 我们把一样的东西放在一起吧。 |  |
| `story.rainbowriver.close` | All tidy. Duck says thank you — and gives you a yellow light. | 都整理好了。鸭子谢谢你——送你一个黄色的灯光。 |  |
| `story.rainbowriver.open` | The river washed everything into one big pile. Duck cannot find anything! | 河水把所有东西冲成了一大堆。鸭子什么都找不到了！ |  |
| `story.shapevillage.beat` | A round roof for a round house. Can you help each one find its own? | 圆的屋顶配圆的房子。你能帮它们找到自己的吗？ |  |
| `story.shapevillage.close` | Every house has its roof back. Here is your orange light! | 每座房子都有屋顶了。这是你的橙色灯光！ |  |
| `story.shapevillage.open` | In Shape Village every house is a different shape. The wind blew the roofs away! | 形状村里，每座房子都是不一样的形状。大风把屋顶吹跑了！ |  |
| `story.starrymeadow.beat` | Red, blue, red, blue... what comes next? | 红色、蓝色、红色、蓝色……接下来是什么？ |  |
| `story.starrymeadow.close` | The whole meadow is glowing again. A purple light floats up to you. | 整片草原又亮起来了。一个紫色的灯光飘到你面前。 |  |
| `story.starrymeadow.open` | At night the flowers here light up in a pattern. But some have gone dark. | 晚上，这里的花会按规律亮起来。可是有几朵灭了。 |  |

## Interface lines

*4 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `ui.again` | Again? | 再来一次？ | zài lái yí cì? |
| `ui.allDone` | All done! | 全部完成！ | quán bù wán chéng! |
| `ui.break` | Let's take a break. See you soon! | 我们休息一下。待会儿见！ | wǒ men xiū xi yí xià. dāi huìr jiàn! |
| `ui.home` | Let's play! | 我们来玩吧！ | wǒ men lái wán ba! |

## Feedback lines (recorded with genuine warmth, never sing-song)

*8 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `feedback.hint1` | Here, I'll help. | 来，我帮你。 | lái, wǒ bāng nǐ. |
| `feedback.hint2` | Try this one. | 试试这个。 | shì shi zhè ge. |
| `feedback.retry1` | Try another one. | 试试别的。 | shì shi bié de. |
| `feedback.retry2` | Not that one. Keep looking! | 不是这个。再找找！ | bú shì zhè ge. zài zhǎo zhao! |
| `feedback.success1` | You did it! | 你做到了！ | nǐ zuò dào le! |
| `feedback.success2` | That's right! | 对了！ | duì le! |
| `feedback.success3` | Nice work! | 真棒！ | zhēn bàng! |
| `feedback.success4` | You found it! | 你找到了！ | nǐ zhǎo dào le! |

## Numbers — record each in isolation, clearly, with a short pause

*10 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `number.1` | one | 一 | yī |
| `number.10` | ten | 十 | shí |
| `number.2` | two | 二 | èr |
| `number.3` | three | 三 | sān |
| `number.4` | four | 四 | sì |
| `number.5` | five | 五 | wǔ |
| `number.6` | six | 六 | liù |
| `number.7` | seven | 七 | qī |
| `number.8` | eight | 八 | bā |
| `number.9` | nine | 九 | jiǔ |

## Colors

*10 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `color.black` | black | 黑色 | hēi sè |
| `color.blue` | blue | 蓝色 | lán sè |
| `color.brown` | brown | 棕色 | zōng sè |
| `color.green` | green | 绿色 | lǜ sè |
| `color.orange` | orange | 橙色 | chéng sè |
| `color.pink` | pink | 粉色 | fěn sè |
| `color.purple` | purple | 紫色 | zǐ sè |
| `color.red` | red | 红色 | hóng sè |
| `color.white` | white | 白色 | bái sè |
| `color.yellow` | yellow | 黄色 | huáng sè |

## Shapes

*5 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `shape.circle` | circle | 圆形 | yuán xíng |
| `shape.rectangle` | rectangle | 长方形 | cháng fāng xíng |
| `shape.semicircle` | half circle | 半圆形 | bàn yuán xíng |
| `shape.square` | square | 正方形 | zhèng fāng xíng |
| `shape.triangle` | triangle | 三角形 | sān jiǎo xíng |

## Sizes

*5 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `size.huge` | huge | 很大 | hěn dà |
| `size.large` | big | 大 | dà |
| `size.medium` | medium | 中等 | zhōng děng |
| `size.small` | small | 小 | xiǎo |
| `size.tiny` | tiny | 很小 | hěn xiǎo |

## Category names

*7 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `category.animal` | animals | 动物 | dòng wù |
| `category.clothing` | things we wear | 穿的东西 | chuān de dōng xi |
| `category.food` | food | 食物 | shí wù |
| `category.household` | things at home | 家里的东西 | jiā lǐ de dōng xi |
| `category.nature` | outdoors | 大自然 | dà zì rán |
| `category.toy` | toys | 玩具 | wán jù |
| `category.vehicle` | things that go | 交通工具 | jiāo tōng gōng jù |

## Position words

*7 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `position.ask` | Where is it? | 它在哪里？ | tā zài nǎ lǐ? |
| `position.behind` | behind | 后面 | hòu mian |
| `position.down` | down low | 下面 | xià mian |
| `position.front` | in front | 前面 | qián mian |
| `position.inside` | inside | 里面 | lǐ mian |
| `position.outside` | outside | 外面 | wài mian |
| `position.up` | up high | 上面 | shàng mian |

## Prompts — Match It

*4 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `matching.category` | Put the ones that go together, together. | 把是一类的放在一起。 | bǎ shì yí lèi de fàng zài yì qǐ. |
| `matching.color` | Put the same colors together. | 把一样颜色的放在一起。 | bǎ yí yàng yán sè de fàng zài yì qǐ. |
| `matching.shape` | Put the same shapes together. | 把一样形状的放在一起。 | bǎ yí yàng xíng zhuàng de fàng zài yì qǐ. |
| `matching.size` | Put the same sizes together. | 把一样大小的放在一起。 | bǎ yí yàng dà xiǎo de fàng zài yì qǐ. |

## Prompts — Count and Feed

*3 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `counting.ask` | Can you give him this many? | 你能给他这么多吗？ | nǐ néng gěi tā zhè me duō ma? |
| `counting.enough` | That's just right! | 刚刚好！ | gāng gāng hǎo! |
| `counting.more` | One more. | 再来一个。 | zài lái yí gè. |

## Prompts — Big and Small

*3 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `comparing.biggest` | Which one is the biggest? | 哪一个最大？ | nǎ yí gè zuì dà? |
| `comparing.order_small_big` | Line them up, small to big. | 从小到大排好队。 | cóng xiǎo dào dà pái hǎo duì. |
| `comparing.smallest` | Which one is the smallest? | 哪一个最小？ | nǎ yí gè zuì xiǎo? |

## Prompts — Shape Sorter

*2 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `shapes.intro` | Every shape has its own home. | 每个形状都有自己的家。 | měi gè xíng zhuàng dōu yǒu zì jǐ de jiā. |
| `shapes.sort` | Put each shape in its own hole. | 把每个形状放进它自己的洞里。 | bǎ měi gè xíng zhuàng fàng jìn tā zì jǐ de dòng lǐ. |

## Prompts — Find the Same

*1 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `spotsame.intro` | Which one looks exactly the same? | 哪一个和它一模一样？ | nǎ yí gè hé tā yì mú yí yàng? |

## Prompts — Puzzle Pieces

*1 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `puzzle.intro` | A piece is missing. Which one fits? | 少了一块。哪一块合适？ | shǎo le yí kuài. nǎ yí kuài hé shì? |

## Prompts — Day and Night

*3 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `daynight.either` | This one can be either! You choose. | 这个都可以！你来选。 | zhè ge dōu kě yǐ! nǐ lái xuǎn. |
| `daynight.intro` | Some things happen in the day, some at night. | 有些事在白天，有些事在晚上。 | yǒu xiē shì zài bái tiān, yǒu xiē shì zài wǎn shang. |
| `daynight.sort` | Put each one where it belongs. | 把每个放到它该去的地方。 | bǎ měi gè fàng dào tā gāi qù de dì fang. |

## Prompts — Float or Sink

*3 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `floatsink.floats` | It floats! | 它浮起来了！ | tā fú qǐ lái le! |
| `floatsink.intro` | Drop something in and see what happens. | 放一个进去，看看会怎么样。 | fàng yí gè jìn qù, kàn kan huì zěn me yàng. |
| `floatsink.sinks` | It sinks! | 它沉下去了！ | tā chén xià qù le! |

## Prompts — What Is It?

*1 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `whatisit.intro` | What do you think it is? | 你猜这是什么？ | nǐ cāi zhè shì shén me? |

## Prompts — Pattern Parade

*2 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `pattern.intro` | Look at the order they go in. | 看看它们排的规律。 | kàn kan tā men pái de guī lǜ. |
| `pattern.whatnext` | What comes next? | 接下来是什么？ | jiē xià lái shì shén me? |

## Prompts — Mirror Match

*1 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `mirror.intro` | Make both sides match. | 让两边一模一样。 | ràng liǎng biān yì mú yí yàng. |

## Object names (spoken whenever an object is named or celebrated)

*91 lines*

| Key | English | 中文 | Pinyin |
|---|---|---|---|
| `item.angry` | angry | 生气 | shēng qì |
| `item.apple` | apple | 苹果 | píng guǒ |
| `item.baby` | baby | 宝宝 | bǎo bao |
| `item.ball` | ball | 球 | qiú |
| `item.balloon` | balloon | 气球 | qì qiú |
| `item.banana` | banana | 香蕉 | xiāng jiāo |
| `item.bear` | bear | 熊 | xióng |
| `item.bee` | bee | 蜜蜂 | mì fēng |
| `item.bike` | bicycle | 自行车 | zì xíng chē |
| `item.bird` | bird | 小鸟 | xiǎo niǎo |
| `item.block` | block | 积木 | jī mù |
| `item.boat` | boat | 小船 | xiǎo chuán |
| `item.book` | book | 书 | shū |
| `item.bowl` | bowl | 碗 | wǎn |
| `item.bread` | bread | 面包 | miàn bāo |
| `item.brother` | big brother | 哥哥 | gē ge |
| `item.bus` | bus | 公共汽车 | gōng gòng qì chē |
| `item.butterfly` | butterfly | 蝴蝶 | hú dié |
| `item.cake` | cake | 蛋糕 | dàn gāo |
| `item.candle` | candle | 蜡烛 | là zhú |
| `item.car` | car | 汽车 | qì chē |
| `item.carrot` | carrot | 胡萝卜 | hú luó bo |
| `item.cat` | cat | 猫 | māo |
| `item.clock` | clock | 钟 | zhōng |
| `item.cloud` | cloud | 云 | yún |
| `item.cookie` | cookie | 饼干 | bǐng gān |
| `item.corn` | corn | 玉米 | yù mǐ |
| `item.cup` | cup | 杯子 | bēi zi |
| `item.dad` | dad | 爸爸 | bà ba |
| `item.dog` | dog | 狗 | gǒu |
| `item.dragon_boat` | dragon boat | 龙舟 | lóng zhōu |
| `item.drum` | drum | 鼓 | gǔ |
| `item.duck` | duck | 鸭子 | yā zi |
| `item.dumpling` | dumpling | 饺子 | jiǎo zi |
| `item.ear` | ear | 耳朵 | ěr duo |
| `item.egg` | egg | 鸡蛋 | jī dàn |
| `item.elephant` | elephant | 大象 | dà xiàng |
| `item.eye` | eye | 眼睛 | yǎn jing |
| `item.fish` | fish | 鱼 | yú |
| `item.flower` | flower | 花 | huā |
| `item.foot` | foot | 脚 | jiǎo |
| `item.frog` | frog | 青蛙 | qīng wā |
| `item.gift` | gift | 礼物 | lǐ wù |
| `item.grandma` | grandma | 奶奶 | nǎi nai |
| `item.grandpa` | grandpa | 爷爷 | yé ye |
| `item.grape` | grape | 葡萄 | pú tao |
| `item.hand` | hand | 手 | shǒu |
| `item.happy` | happy | 开心 | kāi xīn |
| `item.hat` | hat | 帽子 | mào zi |
| `item.key` | key | 钥匙 | yào shi |
| `item.key_lantern` | lantern | 灯笼 | dēng long |
| `item.kite` | kite | 风筝 | fēng zheng |
| `item.lamp` | lamp | 台灯 | tái dēng |
| `item.leaf` | leaf | 叶子 | yè zi |
| `item.mom` | mom | 妈妈 | mā ma |
| `item.moon` | moon | 月亮 | yuè liang |
| `item.mooncake` | mooncake | 月饼 | yuè bǐng |
| `item.mouse` | mouse | 老鼠 | lǎo shǔ |
| `item.mouth` | mouth | 嘴巴 | zuǐ ba |
| `item.mushroom` | mushroom | 蘑菇 | mó gu |
| `item.nose` | nose | 鼻子 | bí zi |
| `item.orange` | orange | 橙子 | chéng zi |
| `item.owl` | owl | 猫头鹰 | māo tóu yīng |
| `item.panda` | panda | 熊猫 | xióng māo |
| `item.pillow` | pillow | 枕头 | zhěn tou |
| `item.plane` | airplane | 飞机 | fēi jī |
| `item.rabbit` | rabbit | 兔子 | tù zi |
| `item.rainbow` | rainbow | 彩虹 | cǎi hóng |
| `item.red_envelope` | red envelope | 红包 | hóng bāo |
| `item.rock` | rock | 石头 | shí tou |
| `item.sad` | sad | 难过 | nán guò |
| `item.scared` | scared | 害怕 | hài pà |
| `item.scarf` | scarf | 围巾 | wéi jīn |
| `item.shell` | shell | 贝壳 | bèi ké |
| `item.shoe` | shoe | 鞋子 | xié zi |
| `item.sister` | big sister | 姐姐 | jiě jie |
| `item.sleepy` | sleepy | 困了 | kùn le |
| `item.sock` | sock | 袜子 | wà zi |
| `item.spoon` | spoon | 勺子 | sháo zi |
| `item.star` | star | 星星 | xīng xing |
| `item.strawberry` | strawberry | 草莓 | cǎo méi |
| `item.sun` | sun | 太阳 | tài yáng |
| `item.surprised` | surprised | 惊讶 | jīng yà |
| `item.teddy` | teddy bear | 玩具熊 | wán jù xióng |
| `item.toothbrush` | toothbrush | 牙刷 | yá shuā |
| `item.train` | train | 火车 | huǒ chē |
| `item.tree` | tree | 树 | shù |
| `item.turtle` | turtle | 乌龟 | wū guī |
| `item.umbrella` | umbrella | 雨伞 | yǔ sǎn |
| `item.watermelon` | watermelon | 西瓜 | xī guā |
| `item.window` | window | 窗户 | chuāng hu |
