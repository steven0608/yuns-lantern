#!/usr/bin/env python3
"""Builds the v3 expansion content: 75 games on 15 engines, 75 Lantern Tales.

Writes:
  content/catalog.json   15 engines x 5 games = 75 games (EN + 中文)
  content/library.json   15 themes x 5 tales  = 75 learning stories (EN + 中文)
  docs/CATALOG.md        human-readable tables for review
  docs/LIBRARY.md

The 12 original activities keep their ids and stay authoritative in
content/activities.json; the catalog only adds metadata around them.
Tale page text lives in TALE_PAGES below and is filled in batches
(see design/ROADMAP.md). Run tools/validate_expansion.py afterwards.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# id, EN, 中文, what the child does, skill (EN / 中文), default rounds
ENGINES = [
    ("count_feed", "Count and Feed", "数一数", "Drag N items to a character, one per count", "Counting", "数数", 20),
    ("sort_bins", "Sort It", "分一分", "Drag items into 2–3 bins by one attribute", "Sorting", "分类", 16),
    ("find_same", "Find the Same", "找相同", "Tap the match among 2–5 choices", "Looking closely", "观察", 20),
    ("silhouette", "What Is It?", "猜一猜", "Tap the picture that fits a shadow or partial view", "Recognising", "辨认", 16),
    ("order_line", "Line Up", "排一排", "Drag 3–5 items into order", "Ordering", "排序", 12),
    ("pattern", "Pattern Parade", "排排队", "Tap or drag what comes next", "Patterns", "规律", 24),
    ("jigsaw", "Puzzle Pieces", "拼一拼", "Drag 1–6 pieces into their slots", "Parts and wholes", "部分与整体", 12),
    ("position", "Where Is It?", "在哪里", "Tap or drag to a spoken position", "Position words", "方位", 12),
    ("mirror", "Mirror Match", "照镜子", "Tap cells or drag parts so both sides match", "Symmetry", "对称", 12),
    ("try_see", "Try It and See", "试一试", "Choose a guess, then watch what really happens", "Science", "科学", 10),
    ("listen_find", "Listen and Find", "听一听", "Hear a word, tap its picture", "Listening, two languages", "听力与双语", 24),
    ("trace", "Trace It", "描一描", "Drag a finger along a dotted path", "Pre-writing", "描写", 12),
    ("color_fill", "Color Me", "涂一涂", "Tap a colour, tap a shape; open-ended", "Colours and art", "颜色与美术", 12),
    ("music_echo", "Echo Music", "跟我唱", "Listen, then tap sounds back; every answer is music", "Music", "音乐", 12),
    ("memory_pairs", "Memory Pairs", "翻翻乐", "Flip 4–6 cards to find pairs", "Memory", "记忆", 12),
]

FREE = {"count_feed", "match_it", "shape_sorter", "find_the_same", "float_or_sink", "what_is_it",
        "first_words", "color_me", "echo_drums", "memory_pairs", "lines_curves", "lantern_painter"}
AGE4 = set("""bus_stop day_and_night weather_wardrobe odd_one_out spot_the_lantern who_made_tracks zoom_out
shadow_puppets morning_routine growing_up pattern_parade bead_necklace lantern_string clap_stomp dragon_boat
hide_seek set_table mirror_match butterfly_wings face_builder melt_or_not magnet_magic color_words tone_hills
numbers_out_loud number_tracing rainbow_mixing fast_slow high_low word_pairs festival_pairs""".split())
AGE5 = set("""flower_path tangram fix_bridge park_map paper_cutting reflection_lake light_shadow first_characters
letter_friends color_by_number shape_pairs""".split())
# Rounds already generated in content/activities.json for the original 12.
ORIGINAL = {"count_feed": 30, "match_it": 23, "shape_sorter": 24, "find_the_same": 30, "float_or_sink": 12,
            "what_is_it": 24, "big_and_small": 15, "where_is_it": 18, "puzzle_pieces": 16, "day_and_night": 14,
            "pattern_parade": 80, "mirror_match": 16}
ROUNDS = {"letter_friends": 26, "first_characters": 10, "number_tracing": 10, "shape_tracing": 8}

# engine -> [(id, EN, 中文, learning goal)]
GAMES = {
    "count_feed": [
        ("count_feed", "Count and Feed", "数一数", "Count 1–10 by feeding Bear, one item per count."),
        ("birthday_candles", "Birthday Candles", "生日蜡烛", "Put the right number of candles on a cake (to 5, then 10)."),
        ("bus_stop", "Bus Stop", "小巴士", "Board riders onto seats; compare more, fewer and the same."),
        ("share_cookies", "Share the Cookies", "分饼干", "Give one cookie to each friend: one-to-one correspondence."),
        ("garden_seeds", "Garden Seeds", "种种子", "Plant a seed in each hole, then watch them sprout (to 10)."),
    ],
    "sort_bins": [
        ("match_it", "Match It", "配对", "Sort by colour, shape, size or category into 2–3 bins."),
        ("shape_sorter", "Shape Sorter", "形状", "Fit circles, squares, triangles, rectangles and semicircles."),
        ("day_and_night", "Day and Night", "白天黑夜", "Sort animals and activities into day and night."),
        ("tidy_up", "Tidy Up Time", "收拾玩具", "Put toys, books and clothes where they belong."),
        ("weather_wardrobe", "Weather Wardrobe", "天气衣橱", "Dress for sunny, rainy and snowy days."),
    ],
    "find_same": [
        ("find_the_same", "Find the Same", "找相同", "Tap the item that matches, from 2 up to 5 choices."),
        ("odd_one_out", "Odd One Out", "哪个不一样", "Tap the one that is different."),
        ("feelings_faces", "Feelings Faces", "表情找朋友", "Match faces: happy, sad, angry, scared, surprised, sleepy."),
        ("sock_pairs", "Sock Pairs", "找袜子", "Match socks by colour and pattern."),
        ("spot_the_lantern", "Spot the Lantern", "找灯笼", "Find the lantern with the same colour and pattern."),
    ],
    "silhouette": [
        ("what_is_it", "What Is It?", "猜一猜", "Recognise objects from their silhouettes."),
        ("peekaboo_animals", "Peek-a-Boo Animals", "躲猫猫", "Recognise an animal from the part that peeks out."),
        ("who_made_tracks", "Who Made the Tracks?", "谁的脚印", "Match footprints to the animal that made them."),
        ("zoom_out", "Zoom Out", "放大镜", "Guess from a close-up, then zoom out to see the whole."),
        ("shadow_puppets", "Shadow Puppets", "手影戏", "Match hand-shadow shapes to animals."),
    ],
    "order_line": [
        ("big_and_small", "Big and Small", "比大小", "Order 3–5 items by size, small to big."),
        ("ladder_up", "Ladder Up", "搭梯子", "Build a ladder from shortest to tallest."),
        ("morning_routine", "Morning Routine", "早上做什么", "Put 3 routine pictures in order: first, next, last."),
        ("growing_up", "Growing Up", "慢慢长大", "Order life cycles: seed to flower, egg to hen."),
        ("stacking_cups", "Stacking Cups", "叠叠杯", "Nest and stack cups by size."),
    ],
    "pattern": [
        ("pattern_parade", "Pattern Parade", "排排队", "Continue AB, AAB, ABB and ABC patterns."),
        ("bead_necklace", "Bead Necklace", "串珠子", "Thread beads to continue a colour pattern."),
        ("lantern_string", "Lantern String", "挂灯笼", "Hang lanterns to continue a pattern."),
        ("clap_stomp", "Clap and Stomp", "拍拍跺跺", "Continue a sound pattern: clap, stomp, clap, stomp."),
        ("flower_path", "Flower Path", "花花小路", "Complete a growing pattern of flower tiles."),
    ],
    "jigsaw": [
        ("puzzle_pieces", "Puzzle Pieces", "拼图", "Complete scenes with 1–6 pieces."),
        ("build_snowman", "Build a Snowman", "堆雪人", "Build a snowman from its parts."),
        ("tangram", "Tangram Friends", "七巧板", "Fill a picture outline with 3–7 tangram shapes."),
        ("fix_bridge", "Fix the Bridge", "修小桥", "Choose planks of the right length to fix a bridge."),
        ("dragon_boat", "Dragon Boat", "拼龙舟", "Assemble a dragon boat: head, body, tail, paddles."),
    ],
    "position": [
        ("where_is_it", "Where Is It?", "在哪里", "Place things up, down, in, out, in front, behind."),
        ("hide_seek", "Hide and Seek", "捉迷藏", "Hear where a friend is hiding, then tap there."),
        ("set_table", "Set the Table", "摆餐桌", "Place bowl, cup and spoon on, in and next to."),
        ("owl_tree_house", "Owl's Tree House", "猫头鹰的树屋", "Top, middle and bottom floors of a tree house."),
        ("park_map", "Park Path", "公园小路", "Tap arrows to follow a path: up, down, left, right."),
    ],
    "mirror": [
        ("mirror_match", "Mirror Match", "照镜子", "Complete the other half so both sides match."),
        ("butterfly_wings", "Butterfly Wings", "蝴蝶翅膀", "Colour the second wing to match the first."),
        ("paper_cutting", "Paper Cutting", "剪窗花", "Fold, snip and open paper to reveal a window flower."),
        ("face_builder", "Face Builder", "对称脸", "Place eyes, ears and cheeks so both sides match."),
        ("reflection_lake", "Reflection Lake", "湖中倒影", "Pick the reflection that matches."),
    ],
    "try_see": [
        ("float_or_sink", "Float or Sink", "沉与浮", "Guess, then watch: does it float or sink?"),
        ("melt_or_not", "Melt or Not?", "会化吗", "Guess, then watch what melts in the sun."),
        ("plant_grows", "Plant Grows", "小种子长大", "Give a seed sun and water and watch it grow."),
        ("magnet_magic", "Magnet Magic", "磁铁吸吸", "Guess, then test: does the magnet pick it up?"),
        ("light_shadow", "Light and Shadow", "影子游戏", "Move the lamp and watch the shadow grow and shrink."),
    ],
    "listen_find": [
        ("first_words", "First Words", "第一个词", "Hear a word, tap its picture (64 everyday words)."),
        ("color_words", "Color Words", "双语颜色", "Hear a colour in the other language and tap it."),
        ("tone_hills", "Tone Hills", "声调小山", "Hear a Mandarin tone and tap the hill with its shape."),
        ("body_parts", "Body Parts", "身体部位", "Hear a body part and tap it on Yun."),
        ("numbers_out_loud", "Numbers Out Loud", "听数字", "Hear a number and tap the group with that many."),
    ],
    "trace": [
        ("lines_curves", "Lines and Curves", "画线条", "Trace straight, zigzag and wavy lines."),
        ("shape_tracing", "Shape Tracing", "描形状", "Trace circles, squares and triangles."),
        ("number_tracing", "Number Tracing", "描数字", "Trace numerals 1–10."),
        ("first_characters", "First Characters", "描汉字", "Trace 一 二 三 十 人 大 口 山 日 月 in stroke order."),
        ("letter_friends", "Letter Friends", "描字母", "Trace uppercase letters A–Z."),
    ],
    "color_fill": [
        ("color_me", "Color Me", "涂一涂", "Colour scenes and objects freely; there is no right answer."),
        ("rainbow_mixing", "Rainbow Mixing", "调颜色", "Mix two paints to discover orange, green and purple."),
        ("color_by_number", "Color by Number", "按数字涂色", "Colour regions using a 1–5 colour key."),
        ("lantern_painter", "Lantern Painter", "画灯笼", "Decorate your own lantern; it hangs on the story map."),
        ("night_sky", "Night Sky", "点星星", "Place stars and join them into shapes."),
    ],
    "music_echo": [
        ("echo_drums", "Echo Drums", "跟我敲鼓", "Listen to a rhythm, then tap it back."),
        ("animal_choir", "Animal Choir", "动物合唱团", "Tap animals to sing, loud and soft."),
        ("fast_slow", "Fast and Slow", "快和慢", "Tap along with fast and slow music."),
        ("rhyme_time", "Rhyme Time", "儿歌时间", "Sing-along nursery rhymes; tap to add sounds."),
        ("high_low", "High and Low", "高音低音", "Hear high or low notes: tap Bird for high, Bear for low."),
    ],
    "memory_pairs": [
        ("memory_pairs", "Memory Pairs", "翻翻乐", "Flip cards to find pairs (4, then 6 cards)."),
        ("word_pairs", "Word Pairs", "中英配对", "Match a picture to the same word heard in each language."),
        ("festival_pairs", "Festival Pairs", "节日配对", "Match festival things: lanterns, mooncakes, dumplings."),
        ("animal_families", "Animal Families", "动物妈妈", "Match baby animals to their parents."),
        ("shape_pairs", "Shape Pairs", "形状配对", "Match shapes to real things with that shape."),
    ],
}

THEMES = [
    ("numbers", "Numbers", "数字"), ("shapes_colors", "Shapes and Colors", "形状和颜色"),
    ("sizes", "Big and Small", "大小比较"), ("patterns_order", "Patterns and Order", "规律和顺序"),
    ("position", "Where Things Are", "位置"), ("nature", "Nature and Seasons", "自然和季节"),
    ("animals", "Animals", "动物"), ("science", "Why Does It Happen?", "为什么"),
    ("feelings", "Feelings and Friends", "情绪和朋友"), ("routines", "Every Day", "日常生活"),
    ("festivals", "Festivals", "节日和文化"), ("words", "Words and Sounds", "语言和声音"),
    ("family", "Family and Home", "家和家人"), ("music", "Music and Moving", "音乐和运动"),
    ("kindness", "Kindness", "善良和帮助"),
]

# theme -> [(EN title, 中文 title, learning goal, linked game, EN synopsis, 中文 synopsis)]
TALES = {
    "numbers": [
        ("Bear's Five Apples", "熊的五个苹果", "Count to 5", "count_feed",
         "Bear picks apples one by one, one to five, and finds a friend to share with.",
         "小熊一个一个地摘苹果，从一数到五，还找到朋友一起分享。"),
        ("Ten Little Stars", "十颗小星星", "Count to 10", "numbers_out_loud",
         "As night falls, Yun counts the stars that come out, all the way to ten.",
         "天黑了，小云数着一颗颗出来的星星，一直数到十。"),
        ("One for You, One for Me", "你一个我一个", "One-to-one sharing", "share_cookies",
         "Yun has cookies for every friend: one each, until everyone has one.",
         "小云给每个朋友分饼干，一人一个，直到大家都有。"),
        ("More or Fewer?", "多还是少", "Compare amounts", "bus_stop",
         "At the bus stop, Yun lines up riders and seats to see which has more.",
         "在车站，小云把乘客和座位排成一排，看看哪个多。"),
        ("The Birthday Cake", "生日蛋糕", "Count to match an age", "birthday_candles",
         "It is Duck's birthday! How many candles go on the cake?",
         "今天是鸭子的生日！蛋糕上要插几根蜡烛呢？"),
    ],
    "shapes_colors": [
        ("The Round Roof", "圆圆的屋顶", "Circles", "shape_sorter",
         "In Shape Village, a round house is looking for its round roof.",
         "形状村里，一座圆房子在找它圆圆的屋顶。"),
        ("Triangle Mountain", "三角形的山", "Triangles around us", "shape_tracing",
         "Yun spots triangles everywhere: mountains, roofs and slices of watermelon.",
         "小云到处都看到三角形：大山、屋顶，还有西瓜片。"),
        ("Yun's Rainbow", "小云的彩虹", "Colour names in two languages", "color_words",
         "After the rain, Yun names each colour of the rainbow in two languages.",
         "雨停了，小云用两种语言说出彩虹的每一种颜色。"),
        ("Mixing Paints", "调颜料", "Mixing colours", "rainbow_mixing",
         "Yellow and blue swirl together, and something green appears!",
         "黄色和蓝色转呀转，变出了绿色！"),
        ("Tangram Cat", "七巧板小猫", "Shapes make pictures", "tangram",
         "Seven shapes slide together to make a cat, a boat and a house.",
         "七块图形拼一拼，变成小猫、小船和房子。"),
    ],
    "sizes": [
        ("Big Shoes, Small Shoes", "大鞋子小鞋子", "Big and small", "big_and_small",
         "Yun tries on Bear's big shoes and Mouse's tiny ones.",
         "小云试穿小熊的大鞋子，还有小老鼠的小鞋子。"),
        ("The Tallest Tower", "最高的塔", "Tall and short", "stacking_cups",
         "Block by block, the tower grows taller than Yun!",
         "一块一块往上搭，塔比小云还高了！"),
        ("Long Scarf, Short Scarf", "长围巾短围巾", "Long and short", "fix_bridge",
         "Grandma knits a long scarf and a short one. Who gets which?",
         "奶奶织了一条长围巾和一条短围巾。谁戴哪一条呢？"),
        ("Heavy and Light", "重和轻", "Heavy and light", "big_and_small",
         "A feather and a rock sit on the seesaw. Which side goes down?",
         "羽毛和石头坐上跷跷板。哪一边会往下沉？"),
        ("Just Right", "刚刚好", "Fitting sizes", "stacking_cups",
         "The big hat is too big, the small hat too small, and this one is just right.",
         "大帽子太大，小帽子太小，这顶刚刚好。"),
    ],
    "patterns_order": [
        ("Red, Blue, Red, Blue", "红蓝红蓝", "AB patterns", "pattern_parade",
         "The meadow flowers glow in a pattern. What colour comes next?",
         "草地上的花按规律亮起来。下一朵是什么颜色？"),
        ("The Lantern Street", "灯笼街", "Colour patterns", "lantern_string",
         "Friends hang lanterns, red, yellow, red, yellow, all along the street.",
         "朋友们在街上挂灯笼，红、黄、红、黄，挂满整条街。"),
        ("First, Next, Last", "先、再、最后", "Sequencing", "morning_routine",
         "First Yun wakes up, next Yun eats breakfast, last Yun goes out to play.",
         "小云先起床，再吃早饭，最后出去玩。"),
        ("Clap Clap Stomp", "拍拍跺跺", "Sound patterns", "clap_stomp",
         "Bear claps, Frog stomps: clap, stomp, clap, stomp. Can you join in?",
         "小熊拍手，青蛙跺脚：拍、跺、拍、跺。你也来一起吧！"),
        ("The Growing Flower", "小花长大了", "Life-cycle order", "growing_up",
         "A seed, a sprout, a bud, a flower, step by step.",
         "种子、小芽、花苞、花朵，一步一步长大。"),
    ],
    "position": [
        ("Where Is Duck?", "鸭子在哪里", "In, on, under", "where_is_it",
         "Is Duck in the box, on the box, or under the box?",
         "鸭子在盒子里、盒子上，还是盒子下面？"),
        ("Owl Is Up High", "猫头鹰在高处", "Up and down", "owl_tree_house",
         "Owl lives up high, Frog lives down low. Who lives in the middle?",
         "猫头鹰住在高高的上面，青蛙住在低低的下面。谁住在中间呢？"),
        ("Hide and Seek in the Fog", "雾里捉迷藏", "In front and behind", "hide_seek",
         "In the misty forest, friends hide behind trees and in front of rocks.",
         "迷雾林里，朋友们躲在树后面，还有石头前面。"),
        ("Setting the Table", "摆桌子", "On and next to", "set_table",
         "The bowl goes on the table, and the spoon goes next to the bowl.",
         "碗放在桌子上，勺子放在碗旁边。"),
        ("Follow the Path", "沿着小路走", "Directions", "park_map",
         "Up the hill, down the steps, around the pond: Yun follows the path home.",
         "上山坡，下台阶，绕过池塘，小云沿着小路回家。"),
    ],
    "nature": [
        ("Rainy Day Boots", "下雨天的雨靴", "Dressing for weather", "weather_wardrobe",
         "Rain! Yun needs boots and an umbrella. What about sunny days?",
         "下雨了！小云需要雨靴和雨伞。那晴天呢？"),
        ("The Four Seasons Tree", "四季树", "Seasons", "growing_up",
         "One tree through the year: flowers, green leaves, orange leaves, snow.",
         "一棵树的一年：开花、绿叶、黄叶、白雪。"),
        ("Where Does the Sun Go?", "太阳去哪儿了", "Day and night", "day_and_night",
         "The sun goes down, the moon comes up, and the night animals wake.",
         "太阳落山，月亮升起，夜里的动物醒来了。"),
        ("Snow Day", "下雪啦", "Big, middle, small", "build_snowman",
         "Big ball, middle ball, small ball: Yun and Bear build a snowman.",
         "大雪球、中雪球、小雪球，小云和小熊堆雪人。"),
        ("The Moon Changes Shape", "月亮变变变", "Moon shapes", "night_sky",
         "Night after night, the moon grows round, then thin again.",
         "一夜又一夜，月亮变圆了，又变弯了。"),
    ],
    "animals": [
        ("Whose Footprints?", "谁的脚印", "Animal tracks", "who_made_tracks",
         "Tracks in the snow! Were they made by Duck, Bear or Rabbit?",
         "雪地上有脚印！是鸭子、小熊，还是小兔留下的？"),
        ("Baby Animals", "动物宝宝", "Babies and parents", "animal_families",
         "A duckling, a kitten, a puppy: each one looks for its mum.",
         "小鸭子、小猫、小狗，每个宝宝都在找妈妈。"),
        ("Peek-a-Boo Forest", "森林躲猫猫", "Recognising animals", "peekaboo_animals",
         "Two long ears behind a bush. Who could it be?",
         "灌木后面露出两只长耳朵。会是谁呢？"),
        ("Night Animals", "夜里的动物", "Day and night animals", "day_and_night",
         "When Yun goes to sleep, Owl and Mouse wake up.",
         "小云睡觉的时候，猫头鹰和小老鼠醒来了。"),
        ("The Busy Bee", "忙碌的小蜜蜂", "How gardens grow", "plant_grows",
         "Bee visits flower after flower, helping the garden grow.",
         "小蜜蜂飞过一朵又一朵花，帮助花园长大。"),
    ],
    "science": [
        ("Will It Float?", "会浮起来吗", "Float and sink", "float_or_sink",
         "Apple, key, leaf and rock go in the water. Let's watch!",
         "苹果、钥匙、树叶和石头放进水里。我们看看吧！"),
        ("The Melting Snowman", "雪人融化了", "Melting", "melt_or_not",
         "The sun comes out, and the snowman slowly turns into a puddle.",
         "太阳出来了，雪人慢慢变成了一滩水。"),
        ("What Plants Need", "小种子要什么", "What plants need", "plant_grows",
         "A little seed needs sun, water and time.",
         "一颗小种子需要阳光、水和时间。"),
        ("Magnet Friends", "磁铁好朋友", "Magnets", "magnet_magic",
         "The magnet picks up the key and the spoon, but not the leaf.",
         "磁铁吸起了钥匙和勺子，可是吸不起树叶。"),
        ("My Shadow", "我的影子", "Light and shadow", "light_shadow",
         "When the lamp comes close, Yun's shadow grows big!",
         "灯靠近的时候，小云的影子变大了！"),
    ],
    "feelings": [
        ("Frog Feels Grumpy", "青蛙不高兴", "Naming anger, calming down", "feelings_faces",
         "Frog's tower fell down. Frog takes three slow breaths and feels calmer.",
         "青蛙的塔倒了。青蛙慢慢地深呼吸三次，心里好多了。"),
        ("Butterfly Is Scared", "蝴蝶害怕了", "Fear and comfort", "feelings_faces",
         "The thunder is loud. Friends sit close until Butterfly feels safe.",
         "雷声好大。朋友们靠在一起，直到蝴蝶不再害怕。"),
        ("Taking Turns", "轮流玩", "Taking turns", "memory_pairs",
         "One swing, two friends: first Duck, then Yun.",
         "一个秋千，两个朋友：先鸭子，再小云。"),
        ("Sorry, Duck", "对不起，鸭子", "Saying sorry", "feelings_faces",
         "Yun bumps Duck's drawing. \"Sorry, Duck. Can I help fix it?\"",
         "小云碰坏了鸭子的画。“对不起，鸭子。我帮你一起修好吧？”"),
        ("A New Friend", "新朋友", "Welcoming others", "animal_choir",
         "A shy rabbit arrives. Yun says hello and asks her to play.",
         "来了一只害羞的小兔子。小云说你好，请她一起玩。"),
    ],
    "routines": [
        ("Brush, Brush, Brush", "刷刷牙", "Brushing teeth", "morning_routine",
         "Up and down, round and round: Yun brushes every tooth.",
         "上上下下，转转圈圈，小云把每颗牙都刷干净。"),
        ("Getting Dressed", "穿衣服", "Getting dressed in order", "weather_wardrobe",
         "Socks before shoes, shirt before coat: Yun gets ready.",
         "先穿袜子再穿鞋，先穿衣服再穿外套，小云准备好了。"),
        ("Tidy Up Song", "收拾玩具歌", "Tidying up", "tidy_up",
         "Blocks in the box, books on the shelf: tidying is a game.",
         "积木放进盒子，书本放上书架，收拾也是游戏。"),
        ("Yum, Dinner!", "吃饭啦", "Mealtime", "set_table",
         "Rice in a bowl, soup with a spoon: everyone eats together.",
         "米饭装在碗里，汤用勺子喝，大家一起吃饭。"),
        ("Bedtime for Yun", "小云要睡觉", "Bedtime routine", "rhyme_time",
         "Bath, pyjamas, one story, and a sleepy lantern glow.",
         "洗澡、穿睡衣、听一个故事，灯笼的光暖暖的。"),
    ],
    "festivals": [
        ("Spring Festival Dumplings", "春节包饺子", "Spring Festival, counting", "festival_pairs",
         "The whole family folds dumplings. How many can Yun make?",
         "一家人一起包饺子。小云能包几个呢？"),
        ("The Lantern Festival", "元宵节看灯", "Lantern Festival", "spot_the_lantern",
         "On the first full moon of the year, the sky fills with lanterns.",
         "新年第一个月圆的晚上，到处都是灯笼。"),
        ("Mooncakes for Grandma", "给奶奶的月饼", "Mid-Autumn Festival, sharing", "share_cookies",
         "Under the round Mid-Autumn moon, Yun shares mooncakes with Grandma.",
         "中秋节的月亮圆圆的，小云和奶奶一起分月饼。"),
        ("Dragon Boat Race", "赛龙舟", "Dragon Boat Festival, teamwork", "dragon_boat",
         "Row together! The dragon boat moves when everyone paddles.",
         "一起划，一起划！大家一起用力，龙舟就前进了。"),
        ("Paper Flowers on the Window", "窗花", "Paper cutting, symmetry", "paper_cutting",
         "Fold the paper, cut a shape, open it: a flower with two matching sides!",
         "把纸折起来，剪一剪，打开，两边一模一样的花！"),
    ],
    "words": [
        ("Hello, Nǐ Hǎo", "你好，Hello", "Greetings in two languages", "first_words",
         "Yun says hello to friends in English and in Chinese.",
         "小云用中文和英文跟朋友们打招呼。"),
        ("Four Little Hills", "四座小山", "Mandarin tones", "tone_hills",
         "Four little hills, flat, up, down-and-up and down, make four different sounds.",
         "四座小山，平平的、往上的、先下后上的、往下的，发出四种不同的声音。"),
        ("Animal Sounds", "动物怎么叫", "Animal sounds in two languages", "animal_choir",
         "Woof or wāng wāng? A dog sounds a little different in each language.",
         "Woof 还是汪汪？每种语言里，小狗的叫声都有点不一样。"),
        ("Rhymes with Yun", "和小云一起押韵", "Rhyme", "rhyme_time",
         "Cat, hat, bat: words that sound alike make a silly song.",
         "花、家、爸：听起来像的字，唱成一首好玩的歌。"),
        ("One Word, Two Languages", "一个东西两个名字", "Bilingual naming", "word_pairs",
         "An apple is an apple, and also a píngguǒ!",
         "苹果是 píngguǒ，也是 apple！"),
    ],
    "family": [
        ("Grandma's Garden", "奶奶的菜园", "Vegetables, planting", "garden_seeds",
         "Grandma and Yun plant carrots, corn and beans in rows.",
         "奶奶和小云一行一行地种胡萝卜、玉米和豆子。"),
        ("Who's in My Family?", "我的家人", "Family words", "word_pairs",
         "Mum, Dad, Grandma, Grandpa: every family is a little different.",
         "妈妈、爸爸、奶奶、爷爷，每个家都有一点不一样。"),
        ("Helping at Home", "在家帮忙", "Helping with chores", "tidy_up",
         "Yun waters the plants, feeds the fish and folds the socks.",
         "小云给花浇水、喂小鱼，还叠袜子。"),
        ("My Room", "我的房间", "Things at home, position", "where_is_it",
         "The teddy is on the bed, and the ball is under the chair.",
         "小熊玩偶在床上，球在椅子下面。"),
        ("Bath Time Boats", "洗澡小船", "Float and sink at home", "float_or_sink",
         "In the bath, the boat floats and the key sinks.",
         "洗澡的时候，小船浮起来，钥匙沉下去。"),
    ],
    "music": [
        ("The Drum Parade", "敲鼓游行", "Rhythm", "echo_drums",
         "Boom, boom, tap: the drum parade marches through the village.",
         "咚、咚、嗒，敲鼓游行队走过村子。"),
        ("Fast Rabbit, Slow Turtle", "快兔子慢乌龟", "Fast and slow", "fast_slow",
         "Rabbit hops fast, Turtle walks slow, and both get there in the end.",
         "兔子跳得快，乌龟走得慢，最后都到了。"),
        ("Bird Sings High", "小鸟唱高音", "High and low", "high_low",
         "Bird sings high, Bear hums low. Together they make a song.",
         "小鸟唱得高，小熊哼得低，合在一起是一首歌。"),
        ("Dance Like Animals", "学动物跳舞", "Moving your body (screen break)", "animal_choir",
         "Stand up! Hop like a frog, waddle like a duck, stretch like a cat.",
         "站起来！像青蛙一样跳，像鸭子一样摇，像小猫一样伸懒腰。"),
        ("Yun's Lullaby", "小云的摇篮曲", "Calm listening", "rhyme_time",
         "The lanterns dim, the stars hum, and Yun drifts off to sleep.",
         "灯笼暗下来，星星轻轻唱，小云慢慢睡着了。"),
    ],
    "kindness": [
        ("Yun Helps Bear", "小云帮小熊", "Helping", "count_feed",
         "Bear's basket is heavy. Yun helps carry it up the hill.",
         "小熊的篮子好重。小云帮他一起搬上山坡。"),
        ("Duck's Lost Hat", "鸭子的帽子丢了", "Keep trying", "find_the_same",
         "Duck's hat blew away! Friends look high and low until they find it.",
         "鸭子的帽子被风吹走了！朋友们到处找，终于找到了。"),
        ("The Bridge for Everyone", "大家的桥", "Working together", "fix_bridge",
         "The river is too wide for one, but not for friends working together.",
         "一个人过不了宽宽的河，可是朋友们一起就能搭好桥。"),
        ("Owl Can't Sleep", "猫头鹰睡不着", "Thinking of others", "owl_tree_house",
         "It is daytime and Owl is sleepy. Friends play quietly so Owl can rest.",
         "白天猫头鹰想睡觉。朋友们轻轻地玩，让猫头鹰好好休息。"),
        ("The Brightest Lantern", "最亮的灯笼", "Kindness", "lantern_painter",
         "Every kind thing Yun did made a little light. Together: the brightest lantern.",
         "小云做的每一件好事都是一点光。合在一起，就是最亮的灯笼。"),
    ],
}

# Full page text, filled in batches. tale id -> [(EN line, 中文 line), ...] (6–8 pages)
TALE_PAGES = {
    "tale_01": [  # Bear's Five Apples
        ("Bear has a big, empty basket.", "小熊有一个空空的大篮子。"),
        ("One red apple. Plop! Into the basket.", "一个红苹果。扑通！放进篮子。"),
        ("Two apples, three apples. Bear counts each one.", "两个苹果，三个苹果。小熊一个一个地数。"),
        ("Four apples, five apples. The basket is full!", "四个苹果，五个苹果。篮子满啦！"),
        ("Yun comes by. \"What a lot of apples!\"", "小云走过来。“好多苹果呀！”"),
        ("Bear gives Yun one apple. Five apples, shared by two friends.", "小熊送给小云一个苹果。五个苹果，两个好朋友一起分享。"),
    ],
    "tale_02": [  # Ten Little Stars
        ("The sun goes down. The sky turns dark blue.", "太阳落山了。天空变成了深蓝色。"),
        ("One little star comes out. Hello, star!", "一颗小星星出来了。星星你好！"),
        ("Two, three, four. More stars are waking up.", "两颗、三颗、四颗。更多的星星醒来了。"),
        ("Five, six, seven. Yun points to each one.", "五颗、六颗、七颗。小云一颗一颗地指。"),
        ("Eight, nine... where is the last one?", "八颗、九颗……最后一颗在哪里？"),
        ("There, above the lantern! Ten little stars.", "在那里，灯笼的上面！十颗小星星。"),
        ("Good night, ten little stars.", "晚安，十颗小星星。"),
    ],
    "tale_03": [  # One for You, One for Me
        ("Yun baked four round cookies.", "小云烤了四块圆圆的饼干。"),
        ("Here come Bear, Duck and Frog.", "小熊、鸭子和青蛙来了。"),
        ("One for Bear. One for Duck.", "小熊一块，鸭子一块。"),
        ("One for Frog. And one for Yun!", "青蛙一块，还有小云一块！"),
        ("Four friends, four cookies. Everyone has one.", "四个朋友，四块饼干。每个人都有一块。"),
        ("Crunch, crunch! Sharing tastes good.", "咔嚓咔嚓！一起分享真好吃。"),
    ],
    "tale_04": [  # More or Fewer?
        ("The little bus stops at the station. Beep beep!", "小巴士停在车站。嘀嘀！"),
        ("The bus has four seats.", "巴士上有四个座位。"),
        ("Five friends are waiting to get on.", "有五个朋友在等着上车。"),
        ("One friend, one seat. Yun lines them up.", "一个朋友，一个座位。小云把他们排好。"),
        ("One friend has no seat. There are more friends than seats!", "有一个朋友没有座位。朋友比座位多！"),
        ("Bear waves. \"I'll take the next bus. See you soon!\"", "小熊挥挥手。“我坐下一班车。一会儿见！”"),
    ],
    "tale_05": [  # The Birthday Cake
        ("Today is Duck's birthday!", "今天是鸭子的生日！"),
        ("Yun and Bear bring a big round cake.", "小云和小熊送来一个大大的圆蛋糕。"),
        ("\"How old are you, Duck?\" \"I am four!\"", "“鸭子，你几岁了？”“我四岁了！”"),
        ("Four candles for four years. One, two, three, four.", "四岁插四根蜡烛。一、二、三、四。"),
        ("The candles glow like little lanterns.", "蜡烛亮亮的，像小灯笼一样。"),
        ("Take a big breath... and blow!", "深深吸一口气……吹！"),
        ("Happy birthday, Duck!", "鸭子，生日快乐！"),
    ],
}


def build():
    engines = [dict(id=e, name={"en": en, "zh": zh}, mechanic=m, skill={"en": se, "zh": sz}, defaultRounds=r)
               for e, en, zh, m, se, sz, r in ENGINES]
    games, n = [], 0
    for e, *_ in ENGINES:
        for gid, en, zh, goal in GAMES[e]:
            n += 1
            games.append(dict(
                number=n, id=gid, engine=e, name={"en": en, "zh": zh}, goal=goal,
                minAge=5 if gid in AGE5 else 4 if gid in AGE4 else 3, free=gid in FREE,
                rounds=ORIGINAL.get(gid, ROUNDS.get(gid, next(x[6] for x in ENGINES if x[0] == e))),
                status="built-content" if gid in ORIGINAL else "planned"))
    themes = [dict(id=t, name={"en": en, "zh": zh}) for t, en, zh in THEMES]
    tales, n = [], 0
    for t, *_ in THEMES:
        for en, zh, goal, game, sen, szh in TALES[t]:
            n += 1
            tid = f"tale_{n:02d}"
            pages = [{"en": a, "zh": b} for a, b in TALE_PAGES.get(tid, [])]
            tales.append(dict(number=n, id=tid, theme=t, title={"en": en, "zh": zh}, goal=goal, game=game,
                              synopsis={"en": sen, "zh": szh}, pages=pages,
                              status="written" if pages else "outline"))
    comment = "Generated by tools/build_expansion.py. Edit that file, not this one."
    (ROOT / "content" / "catalog.json").write_text(json.dumps(
        {"_comment": comment, "engines": engines, "games": games}, ensure_ascii=False, indent=1), encoding="utf-8")
    (ROOT / "content" / "library.json").write_text(json.dumps(
        {"_comment": comment, "themes": themes, "tales": tales}, ensure_ascii=False, indent=1), encoding="utf-8")

    # review tables
    ename = {e["id"]: e["name"]["en"] for e in engines}
    lines = ["# Game catalog: 75 games on 15 engines", "",
             "Generated from `tools/build_expansion.py`. Free = in the free tier. Status `built-content` = rounds already exist in `content/activities.json`.", ""]
    for e in engines:
        lines += [f"## {e['name']['en']} · {e['name']['zh']}", "", f"_{e['mechanic']}. Skill: {e['skill']['en']} / {e['skill']['zh']}._", "",
                  "| # | id | English | 中文 | Age | Free | Rounds | Goal |", "|---|---|---|---|---|---|---|---|"]
        for g in [g for g in games if g["engine"] == e["id"]]:
            lines.append(f"| {g['number']} | `{g['id']}` | {g['name']['en']} | {g['name']['zh']} | {g['minAge']}+ | "
                         f"{'✅' if g['free'] else ''} | {g['rounds']} | {g['goal']} |")
        lines.append("")
    (ROOT / "docs" / "CATALOG.md").write_text("\n".join(lines), encoding="utf-8")
    gname = {g["id"]: g["name"]["en"] for g in games}
    lines = ["# Lantern Tales: 75 learning stories", "",
             "Generated from `tools/build_expansion.py`. Each tale is 6–8 pages, one or two short sentences per page, narrated in either language or both (see EXPANSION.md §5).", ""]
    for t in themes:
        lines += [f"## {t['name']['en']} · {t['name']['zh']}", "", "| # | English | 中文 | Learns | Plays next | Status |", "|---|---|---|---|---|---|"]
        for s in [s for s in tales if s["theme"] == t["id"]]:
            lines.append(f"| {s['number']} | **{s['title']['en']}**<br>{s['synopsis']['en']} | **{s['title']['zh']}**<br>{s['synopsis']['zh']} | "
                         f"{s['goal']} | {gname[s['game']]} | {s['status']} |")
        lines.append("")
    (ROOT / "docs" / "LIBRARY.md").write_text("\n".join(lines), encoding="utf-8")
    print(f"{len(engines)} engines, {len(games)} games ({sum(g['free'] for g in games)} free), "
          f"{len(tales)} tales ({sum(1 for s in tales if s['pages'])} written)")


if __name__ == "__main__":
    build()
