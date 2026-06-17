"""
麻将牌常量定义 — 34 张牌及其完整助记数据。

本模块是 TileZhan 项目的牌数据库唯一权威来源（Single Source of Truth）。
包含三类核心数据：
  1. 牌的 ID 列表（ALL_TILE_IDS / VALID_TILE_IDS）
  2. 牌的枚举与数据结构定义（TileSuit / TileDefinition）
  3. 34 张牌的完整助记数据库（TILES_DATA → ALL_TILES）

花色体系：
  - 万子 (Manzu, m1–m9): 九张数字牌，花色 man
  - 筒子 (Pinzu, p1–p9): 九张数字牌，花色 pin
  - 条子 (Souzu, s1–s9): 九张数字牌，花色 sou
  - 风牌 (Winds, z1–z4):  东南西北，花色 wind
  - 三元牌 (Dragons, z5–z7): 中發白，花色 dragon

共计 9+9+9+4+3 = 34 张牌，与标准麻将一致。
"""

from enum import Enum
from dataclasses import dataclass, field

# ── 牌 ID 列表 ──────────────────────────────────────────────
# 按麻将花色顺序排列：万子→筒子→条子→字牌
# 用于遍历、验证、生成牌墙等场景
ALL_TILE_IDS = [
    *(f"m{i}" for i in range(1, 10)),  # 万子 1–9
    *(f"p{i}" for i in range(1, 10)),  # 筒子 1–9
    *(f"s{i}" for i in range(1, 10)),  # 条子 1–9
    "z1", "z2", "z3", "z4",            # 风牌：东南西北
    "z5", "z6", "z7",                  # 三元牌：中發白
]


class TileSuit(str, Enum):
    """
    麻将牌花色枚举。

    继承 str 以便直接序列化为 JSON 字符串值。
    共五种花色：万子、筒子、条子、风牌、三元牌。
    """
    MAN = "man"        # 万子 (Characters / 10,000s)
    PIN = "pin"        # 筒子 (Dots / Coins)
    SOU = "sou"        # 条子 (Bamboos / Sticks)
    WIND = "wind"      # 风牌 (Winds): 东南西北
    DRAGON = "dragon"  # 三元牌 (Dragons): 中發白


@dataclass(frozen=True)
class TileDefinition:
    """
    单张麻将牌的完整定义（不可变数据类）。

    frozen=True 确保牌数据创建后不可修改，保证全局唯一实例的安全性。
    每张牌包含：标识信息、花色、汉字/印章、面值、标签、助记数据、易混淆牌列表。

    Attributes:
        id:             牌的唯一标识符，如 "m1", "p5", "z7"
        suit:           花色，见 TileSuit 枚举
        character:      牌面的核心汉字，如 "一"、"東"、"中"
        seal:           牌角印章文字，如 "萬"、"筒"、"条"、"風"、"龍"
        value:          牌的面值。数字牌为 int (1-9)，字牌为 str ("E"/"S"/"W"/"N"/"D-R"/"D-G"/"D-W")
        label:          人类可读的英文标签，如 "5-Pin", "East"
        mnemonic:       助记数据字典，包含 emoji/name/slogan/desc/chinese/anchor 六个字段
        confused_with:  外观相似、容易混淆的其他牌 ID 列表，用于训练和提示
    """
    id: str
    suit: TileSuit
    character: str
    seal: str
    value: int
    label: str
    mnemonic: dict = field(default_factory=dict)
    confused_with: list[str] = field(default_factory=list)


# ── 34 牌助记原始数据库 — 项目唯一权威数据源 ─────────────────
# 每条记录是一张牌的完整原始数据。
# 通过下方的 ALL_TILES 字典转换为不可变的 TileDefinition 对象。
# 数据字段说明：
#   id:           牌的唯一标识符 (m1–m9, p1–p9, s1–s9, z1–z7)
#   suit:         花色字符串，对应 TileSuit 枚举值
#   char:         牌面核心汉字
#   seal:         牌角印章文字（萬/筒/条/風/龍）
#   value:        面值 — 数字牌为 int，字牌为 str (方向/三元缩写)
#   label:        英文标签
#   mnemonic:     助记六元组 {emoji, name, slogan, desc, chinese, anchor}
#   confused_with:容易与此牌混淆的其他牌 ID 列表
TILES_DATA: list[dict] = [
    # ── MANZU (万子) — Wand-Scooter (魔法滑板车) 主题 ────────
    {"id":"m1","suit":"man","char":"一","seal":"萬","value":1,"label":"1-Man",
     "mnemonic":{"emoji":"🪵","name":"The Lone Log","slogan":"Delivery time!",
     "desc":"One lonely log on the Wand-Scooter. Magic multiplies it into 10,000 paper rolls!",
     "chinese":"滑板车置物篮里横放着一根粗壮的原始木头","anchor":"🧹 Wand-Scooter"},
     "confused_with":["m2","m3","s1"]},
    {"id":"m2","suit":"man","char":"二","seal":"萬","value":2,"label":"2-Man",
     "mnemonic":{"emoji":"🛹","name":"Double Decks","slogan":"Double the speed!",
     "desc":"Two wooden planks upgrade the Wand-Scooter into a 20,000 watt supercharged monster!",
     "chinese":"车把手上加装了两层滑板夹板→双层越野车","anchor":"🧹 Wand-Scooter"},
     "confused_with":["m1","m3","s2"]},
    {"id":"m3","suit":"man","char":"三","seal":"萬","value":3,"label":"3-Man",
     "mnemonic":{"emoji":"🍔","name":"Triple Burger","slogan":"Hungry?",
     "desc":"A Three-layer burger balanced on the Wand-Scooter — feeds a stadium of 30,000 fans!",
     "chinese":"外卖小哥车头叠三层巨大汉堡→全速配送","anchor":"🧹 Wand-Scooter"},
     "confused_with":["m2","m4","s3"]},
    {"id":"m4","suit":"man","char":"四","seal":"萬","value":4,"label":"4-Man",
     "mnemonic":{"emoji":"🪟","name":"Square Canopy","slogan":"Keep cool!",
     "desc":"A four-cornered sun canopy mounted on the Scooter, protecting 40,000 gold coins from the rain!",
     "chinese":"四四方方遮阳棚→正面像带窗帘的方窗","anchor":"🧹 Wand-Scooter"},
     "confused_with":["m3","m5","p4"]},
    {"id":"m5","suit":"man","char":"五","seal":"萬","value":5,"label":"5-Man",
     "mnemonic":{"emoji":"🏖️","name":"The Lawn Chair","slogan":"Max relaxation!",
     "desc":"Lounging on a 5-shaped folding beach chair while the Wand-Scooter cruises at 50,000 mph!",
     "chinese":"\"五\"字形折叠沙滩椅→外卖小哥躺着喝可乐","anchor":"🧹 Wand-Scooter"},
     "confused_with":["m4","m6","p5"]},
    {"id":"m6","suit":"man","char":"六","seal":"萬","value":6,"label":"6-Man",
     "mnemonic":{"emoji":"🚀","name":"Rocket Booster","slogan":"To the moon!",
     "desc":"Flip the Six-directional rocket switch — the Wand-Scooter blasts into 60,000 feet of air!",
     "chinese":"\"六\"字形火箭推进器→尾部喷射火花","anchor":"🧹 Wand-Scooter"},
     "confused_with":["m5","m8","p6"]},
    {"id":"m7","suit":"man","char":"七","seal":"萬","value":7,"label":"7-Man",
     "mnemonic":{"emoji":"🪝","name":"The Crane Hook","slogan":"Busted!",
     "desc":"A Seven-shaped giant crane hook lifts the illegally-parked Wand-Scooter with a 70,000 dollar fine!",
     "chinese":"\"七\"字形倒挂大吊钩→勾住违章滑板车","anchor":"🧹 Wand-Scooter"},
     "confused_with":["m8","m9","s7"]},
    {"id":"m8","suit":"man","char":"八","seal":"萬","value":8,"label":"8-Man",
     "mnemonic":{"emoji":"🌋","name":"The Volcano","slogan":"Jackpot!",
     "desc":"The Wand-Scooter drives into an Eight-shaped volcano erupting with 80,000 diamond gems!",
     "chinese":"\"八\"字形开口超级火山→喷发钻石钞票","anchor":"🧹 Wand-Scooter"},
     "confused_with":["m6","m7","p8"]},
    {"id":"m9","suit":"man","char":"九","seal":"萬","value":9,"label":"9-Man",
     "mnemonic":{"emoji":"🏊","name":"The Diving Board","slogan":"Ultimate leap!",
     "desc":"Flying off a Nine-meter high diving board, the Wand-Scooter makes a splash worth 90,000 points!",
     "chinese":"\"九\"字形高空跳水台→凌空飞跃","anchor":"🧹 Wand-Scooter"},
     "confused_with":["m7","m8","p9"]},
    # ── PINZU (筒子) — Everyday Objects (日常物品) 主题 ──────
    {"id":"p1","suit":"pin","char":"一","seal":"筒","value":1,"label":"1-Pin",
     "mnemonic":{"emoji":"🛡️","name":"The Giant Shield","slogan":"The One and Only.",
     "desc":"A single massive circle — the Giant Shield. \"The Big Boss\" of all Pinzu tiles.",
     "chinese":"独一无二的巨型盾牌→The Big Boss","anchor":"🟡 Everyday Objects"},
     "confused_with":["p2","z5","z7"]},
    {"id":"p2","suit":"pin","char":"二","seal":"筒","value":2,"label":"2-Pin",
     "mnemonic":{"emoji":"⛄","name":"The Snowman","slogan":"Do you want to build a…",
     "desc":"Two circles stacked = a Snowman! Carrot nose on top, two coal buttons below.",
     "chinese":"两个圆点上下排列=雪人⛄→致敬《冰雪奇缘》","anchor":"🟡 Everyday Objects"},
     "confused_with":["p1","p3","p8"]},
    {"id":"p3","suit":"pin","char":"三","seal":"筒","value":3,"label":"3-Pin",
     "mnemonic":{"emoji":"🫛","name":"The Slanted Peapod","slogan":"3 peas in a pod.",
     "desc":"Three dots in a diagonal line — the defining feature! Like three peas nestled in a tilted peapod.",
     "chinese":"对角线倾斜排列→豌豆荚里3颗豌豆","anchor":"🟡 Everyday Objects"},
     "confused_with":["p2","p5","s3"]},
    {"id":"p4","suit":"pin","char":"四","seal":"筒","value":4,"label":"4-Pin",
     "mnemonic":{"emoji":"🛸","name":"The Drone","slogan":"4 propellers ready.",
     "desc":"A perfect 2×2 square — like a Quad-Drone with four spinning propellers, ready for takeoff!",
     "chinese":"2×2排列=四轴无人机螺旋桨","anchor":"🟡 Everyday Objects"},
     "confused_with":["p5","m4","s4"]},
    {"id":"p5","suit":"pin","char":"五","seal":"筒","value":5,"label":"5-Pin",
     "mnemonic":{"emoji":"🌸","name":"The Sakura","slogan":"4 petals + 1 heart.",
     "desc":"Four dots around one center = a Sakura blossom! Four petals surrounding the golden heart — a perfect 5.",
     "chinese":"四角+中心=樱花(4花瓣+1花蕊)","anchor":"🟡 Everyday Objects"},
     "confused_with":["p4","p6","m5"]},
    {"id":"p6","suit":"pin","char":"六","seal":"筒","value":6,"label":"6-Pin",
     "mnemonic":{"emoji":"🍺","name":"The 6-Pack","slogan":"Grab a cold one!",
     "desc":"A 2×3 rectangle — every Westerner instantly recognizes this as a 6-Pack of beer/soda. Weekend ready!",
     "chinese":"2×3矩形=六瓶装啤酒(6-Pack)","anchor":"🟡 Everyday Objects"},
     "confused_with":["p5","p8","m6"]},
    {"id":"p7","suit":"pin","char":"七","seal":"筒","value":7,"label":"7-Pin",
     "mnemonic":{"emoji":"🥄","name":"The Big Dipper","slogan":"Follow the stars.",
     "desc":"3 dots (handle) + 4 dots (bowl) = the Big Dipper constellation! The most famous 7-star pattern in the sky.",
     "chinese":"3(勺柄)+4(勺碗)=北斗七星!","anchor":"🟡 Everyday Objects"},
     "confused_with":["p6","p8","m7"]},
    {"id":"p8","suit":"pin","char":"八","seal":"筒","value":8,"label":"8-Pin",
     "mnemonic":{"emoji":"🧱","name":"The Lego Brick","slogan":"Don't step on it!",
     "desc":"A 2×4 rectangle — the classic 8-stud Lego brick. Everyone on Earth knows this shape.",
     "chinese":"2×4长条矩阵=8凸起乐高积木","anchor":"🟡 Everyday Objects"},
     "confused_with":["p6","p9","m8"]},
    {"id":"p9","suit":"pin","char":"九","seal":"筒","value":9,"label":"9-Pin",
     "mnemonic":{"emoji":"🧩","name":"The Rubik's Face","slogan":"Perfect 3×3.",
     "desc":"A 3×3 perfect square — like one face of a Rubik's Cube, or a full Tic-Tac-Toe board. 9 dots aligned!",
     "chinese":"3×3完美正方形=魔方切面=井字棋","anchor":"🟡 Everyday Objects"},
     "confused_with":["p8","m9","s9"]},
    # ── SOUZU (条子) — Pop Culture Icons (流行文化) 主题 ─────
    {"id":"s1","suit":"sou","char":"一","seal":"条","value":1,"label":"1-Bam",
     "mnemonic":{"emoji":"🐦","name":"The Spy Bird","slogan":"I'm a bird, but I identify as a bamboo.",
     "desc":"Why is a bird in the bamboo suit? It's the #1 Spy of the bamboo forest — the only non-plant infiltrator!",
     "chinese":"伪装者小鸟→竹林里的1号间谍","anchor":"🎋 Pop Culture Icons"},
     "confused_with":["s2","z1","m1"]},
    {"id":"s2","suit":"sou","char":"二","seal":"条","value":2,"label":"2-Bam",
     "mnemonic":{"emoji":"⏸️","name":"The Tech Twins","slogan":"Hit PAUSE for 2 seconds.",
     "desc":"Two parallel vertical bars = the universal Pause Button. Double bars, double power.",
     "chinese":"电脑双子星=暂停键⏸️=双口USB","anchor":"🎋 Pop Culture Icons"},
     "confused_with":["s1","s3","m2"]},
    {"id":"s3","suit":"sou","char":"三","seal":"条","value":3,"label":"3-Bam",
     "mnemonic":{"emoji":"🚦","name":"The Upside-Down Traffic Light","slogan":"Red on top = count to 3!",
     "desc":"An inverted triangle — like an upside-down traffic light. The red light sits on top with two green lights below.",
     "chinese":"倒三角形=倒立红绿灯→红灯在最上","anchor":"🎋 Pop Culture Icons"},
     "confused_with":["s2","s4","p3"]},
    {"id":"s4","suit":"sou","char":"四","seal":"条","value":4,"label":"4-Bam",
     "mnemonic":{"emoji":"🏡","name":"The Garden Fence","slogan":"A fence with 4 posts.",
     "desc":"Four vertical bars in a 2×2 square = a cute garden fence with 4 posts. A tiny cat is climbing over it!",
     "chinese":"2×2方正排列=花园围栏4根柱子","anchor":"🎋 Pop Culture Icons"},
     "confused_with":["s3","s5","p4"]},
    {"id":"s5","suit":"sou","char":"五","seal":"条","value":5,"label":"5-Bam",
     "mnemonic":{"emoji":"🌟","name":"The Party VIP","slogan":"4 bodyguards + 1 VIP = 5!",
     "desc":"Four outer bars guard the one red center bar — the VIP. Like a dice showing 5, or an X marking treasure!",
     "chinese":"4绿+1红=骰子5点→中心VIP明星","anchor":"🎋 Pop Culture Icons"},
     "confused_with":["s4","s6","p5"]},
    {"id":"s6","suit":"sou","char":"六","seal":"条","value":6,"label":"6-Bam",
     "mnemonic":{"emoji":"💪","name":"The 6-Pack Abs","slogan":"Flexing my 6-pack!",
     "desc":"A 2×3 grid — like a muscular torso showing off 6-pack abs. Or three London double-decker buses!",
     "chinese":"上3下3=型男六块腹肌💪","anchor":"🎋 Pop Culture Icons"},
     "confused_with":["s5","s7","p6"]},
    {"id":"s7","suit":"sou","char":"七","seal":"条","value":7,"label":"7-Bam",
     "mnemonic":{"emoji":"👑","name":"The Crowned King","slogan":"6 guards bow to 1 King.",
     "desc":"A 6-bar base with 1 bar on top — like a King wearing a crown, or a 6-inch cake with 1 lucky candle!",
     "chinese":"6底座+1尖顶=腹肌戴王冠👑","anchor":"🎋 Pop Culture Icons"},
     "confused_with":["s6","s8","m7"]},
    {"id":"s8","suit":"sou","char":"八","seal":"条","value":8,"label":"8-Bam",
     "mnemonic":{"emoji":"⚔️","name":"The Sword Matrix","slogan":"8 swords unbreakable.",
     "desc":"An M+W crisscross pattern — like 8 swords locked into an unbreakable shield formation. A mystical sword matrix!",
     "chinese":"M+W对称=8把利剑合璧→剑阵⚔️","anchor":"🎋 Pop Culture Icons"},
     "confused_with":["s7","s9","p8"]},
    {"id":"s9","suit":"sou","char":"九","seal":"条","value":9,"label":"9-Bam",
     "mnemonic":{"emoji":"📱","name":"The Ultimate 3×3 Matrix","slogan":"Perfect 3×3 grid!",
     "desc":"A flawless 3×3 grid — like your phone's App Home Screen, a Sudoku board, or Tic-Tac-Toe. Mission accomplished!",
     "chinese":"完美3×3=App桌面=数独=井字棋","anchor":"🎋 Pop Culture Icons"},
     "confused_with":["s8","p9","m9"]},
    # ── WINDS (风牌) — Nautical Compass (航海罗盘) 主题 ────
    {"id":"z1","suit":"wind","char":"東","seal":"風","value":"E","label":"East",
     "mnemonic":{"emoji":"🎈","name":"The Sunrise Balloon","slogan":"Rise with the East!",
     "desc":"The sun rises in the East! The character looks like a hot air balloon — basket below, balloon above.",
     "chinese":"東=冉冉升起的热气球🎈→捕捉晨风","anchor":"🧭 Nautical Compass"},
     "confused_with":["z2","z3","z4","m6"]},
    {"id":"z2","suit":"wind","char":"南","seal":"風","value":"S","label":"South",
     "mnemonic":{"emoji":"⛱️","name":"The Tropical Parasol","slogan":"South = Vacation!",
     "desc":"Heading South for vacation! The character is a giant tropical beach umbrella with a lounge chair underneath.",
     "chinese":"南=热带海滩豪华遮阳伞⛱️→度假!","anchor":"🧭 Nautical Compass"},
     "confused_with":["z1","z3","z4","m8"]},
    {"id":"z3","suit":"wind","char":"西","seal":"風","value":"W","label":"West",
     "mnemonic":{"emoji":"🍺","name":"The Wild West Beer Stein","slogan":"Welcome to the Wild West!",
     "desc":"The West — where the sun sets and cowboys drink! The character looks exactly like a beer stein with a handle.",
     "chinese":"西=狂野西部大号啤酒杯🍺→牛仔干杯!","anchor":"🧭 Nautical Compass"},
     "confused_with":["z1","z2","z4","m4"]},
    {"id":"z4","suit":"wind","char":"北","seal":"風","value":"N","label":"North",
     "mnemonic":{"emoji":"🧊","name":"The Freezing Twins","slogan":"Back-to-back against the cold.",
     "desc":"The freezing North! Two polar explorers sit back-to-back to survive the arctic blizzard.",
     "chinese":"北=两个背靠背的人→极地冰人🧊","anchor":"🧭 Nautical Compass"},
     "confused_with":["z1","z2","z3","m2"]},
    # ── DRAGONS (三元牌) — Mystical Alchemy (神秘炼金) 主题 ─
    {"id":"z5","suit":"dragon","char":"中","seal":"龍","value":"D-R","label":"Red Dragon",
     "mnemonic":{"emoji":"🎯","name":"The Bullseye Arrow","slogan":"Arrow through the center!",
     "desc":"The Red Dragon never misses! A rectangle pierced straight through its center by an arrow — the universal bullseye symbol!",
     "chinese":"中=一箭穿心正中红心🎯→靶心!","anchor":"🐉 Mystical Alchemy"},
     "confused_with":["z6","z7","p1"]},
    {"id":"z6","suit":"dragon","char":"發","seal":"龍","value":"D-G","label":"Green Dragon",
     "mnemonic":{"emoji":"💰","name":"The Wealth Generator","slogan":"Jackpot! Get Rich!",
     "desc":"The Green Dragon brings Fortune! A wizard waves both hands over a massive pile of gold coins. Instant wealth!",
     "chinese":"發=巫师双手狂揽金币堆💰→暴富!","anchor":"🐉 Mystical Alchemy"},
     "confused_with":["z5","z7","m9"]},
    {"id":"z7","suit":"dragon","char":"白","seal":"龍","value":"D-W","label":"White Dragon",
     "mnemonic":{"emoji":"🪞","name":"The Blank Mirror","slogan":"Pure white. Infinite magic.",
     "desc":"The White Dragon is invisible! A completely blank mirror reflecting pure white light. Zero markings, infinite magic.",
     "chinese":"白=纯白魔法空镜🪞→无限魔力","anchor":"🐉 Mystical Alchemy"},
     "confused_with":["z5","z6","p1"]},
]

# ── 牌对象查询字典 ───────────────────────────────────────────
# 将 TILES_DATA 原始字典列表转换为不可变的 TileDefinition 对象字典。
# key = 牌 ID (如 "m1")，value = TileDefinition 实例。
# 这是项目中查询牌信息的唯一入口，外部模块不应直接访问 TILES_DATA。
ALL_TILES: dict[str, TileDefinition] = {
    d["id"]: TileDefinition(
        id=d["id"],
        suit=TileSuit(d["suit"]),
        character=d["char"],
        seal=d["seal"],
        value=d["value"],
        label=d["label"],
        mnemonic=d["mnemonic"],
        confused_with=d.get("confused_with", []),
    )
    for d in TILES_DATA
}

# 合法牌 ID 的冻结集合 — 用于 O(1) 成员资格验证
# 例如：判断用户输入是否为合法牌 ID、过滤非法牌等场景
VALID_TILE_IDS: frozenset[str] = frozenset(ALL_TILES.keys())
