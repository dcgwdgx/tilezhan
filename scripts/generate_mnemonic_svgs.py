"""Generate 34 mnemonic illustration SVGs — simplified icon-card style for MVP."""

import os

OUTPUT_DIR = "d:/claude/tilezhan/frontend/assets/mnemonic"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Each mnemonic: (tile_id, emoji, name, visual_elements, color)
MNEMONICS = [
    # ── Manzu (Wand-Scooter) ──
    ("m1", "🪵", "Wand-Scooter", "Log", "#E74C3C",
     '<circle cx="100" cy="100" r="45" fill="none" stroke="#E74C3C" stroke-width="3" opacity="0.3"/><text x="100" y="110" text-anchor="middle" font-size="50">🪵</text><line x1="100" y1="140" x2="100" y2="210" stroke="#E74C3C" stroke-width="2" stroke-dasharray="4"/><rect x="70" y="210" width="60" height="30" rx="6" fill="#E74C3C" opacity="0.4"/>'),
    ("m2", "🛹", "Double Decks", "2 Planks", "#E74C3C",
     '<text x="100" y="110" text-anchor="middle" font-size="50">🛹</text><rect x="60" y="130" width="80" height="10" rx="3" fill="#E74C3C" opacity="0.5"/><rect x="60" y="145" width="80" height="10" rx="3" fill="#E74C3C" opacity="0.5"/>'),
    ("m3", "🍔", "Triple Burger", "3 Layers", "#E74C3C",
     '<text x="100" y="110" text-anchor="middle" font-size="50">🍔</text><circle cx="100" cy="145" r="20" fill="#E74C3C" opacity="0.2"/><circle cx="100" cy="145" r="10" fill="#E74C3C" opacity="0.3"/>'),
    ("m4", "🪟", "Square Canopy", "Window", "#E74C3C",
     '<text x="100" y="110" text-anchor="middle" font-size="50">🪟</text><rect x="60" y="135" width="80" height="60" rx="4" fill="none" stroke="#E74C3C" stroke-width="2" opacity="0.4"/><line x1="100" y1="135" x2="100" y2="195" stroke="#E74C3C" stroke-width="1" opacity="0.3"/>'),
    ("m5", "🏖️", "The Lawn Chair", "Beach", "#E74C3C",
     '<text x="100" y="110" text-anchor="middle" font-size="50">🏖️</text><path d="M60,160 L140,160 L130,190 L70,190 Z" fill="none" stroke="#E74C3C" stroke-width="2" opacity="0.4"/>'),
    ("m6", "🚀", "Rocket Booster", "Launch", "#E74C3C",
     '<text x="100" y="100" text-anchor="middle" font-size="50">🚀</text><circle cx="100" cy="170" r="8" fill="#FFD700" opacity="0.5"/><circle cx="90" cy="175" r="5" fill="#FFD700" opacity="0.3"/><circle cx="110" cy="175" r="5" fill="#FFD700" opacity="0.3"/>'),
    ("m7", "🪝", "The Crane Hook", "Hook", "#E74C3C",
     '<text x="100" y="110" text-anchor="middle" font-size="50">🪝</text><path d="M100,140 L100,200" stroke="#E74C3C" stroke-width="2" opacity="0.3"/><circle cx="100" cy="140" r="4" fill="#E74C3C" opacity="0.4"/>'),
    ("m8", "🌋", "The Volcano", "Eruption", "#E74C3C",
     '<text x="100" y="100" text-anchor="middle" font-size="50">🌋</text><polygon points="60,180 100,130 140,180" fill="#E74C3C" opacity="0.15" stroke="#E74C3C" stroke-width="1"/>'),
    ("m9", "🏊", "The Diving Board", "Splash", "#E74C3C",
     '<text x="100" y="110" text-anchor="middle" font-size="50">🏊</text><rect x="60" y="150" width="80" height="6" rx="2" fill="#E74C3C" opacity="0.4"/><path d="M60,156 Q80,180 100,170" stroke="#3498DB" stroke-width="2" fill="none" opacity="0.3"/>'),
    # ── Pinzu (Everyday Objects) ──
    ("p1", "🛡️", "Giant Shield", "Captain", "#3498DB",
     '<text x="100" y="100" text-anchor="middle" font-size="55">🛡️</text><circle cx="100" cy="155" r="35" fill="none" stroke="#3498DB" stroke-width="4"/><circle cx="100" cy="155" r="25" fill="none" stroke="#3498DB" stroke-width="2" opacity="0.5"/><circle cx="100" cy="155" r="15" fill="#3498DB" opacity="0.2"/>'),
    ("p2", "⛄", "The Snowman", "Frozen", "#3498DB",
     '<text x="100" y="100" text-anchor="middle" font-size="55">⛄</text><circle cx="100" cy="155" r="15" fill="#3498DB" opacity="0.1"/><circle cx="100" cy="185" r="12" fill="#3498DB" opacity="0.1"/>'),
    ("p3", "🫛", "Slanted Peapod", "Diagonal", "#3498DB",
     '<text x="100" y="110" text-anchor="middle" font-size="50">🫛</text><ellipse cx="80" cy="155" rx="25" ry="12" fill="#2ECC71" opacity="0.2" transform="rotate(-30,80,155)"/><ellipse cx="100" cy="165" rx="25" ry="12" fill="#2ECC71" opacity="0.2" transform="rotate(-30,100,165)"/>'),
    ("p4", "🛸", "The Drone", "4 Props", "#3498DB",
     '<text x="100" y="110" text-anchor="middle" font-size="50">🛸</text><circle cx="75" cy="150" r="8" fill="none" stroke="#3498DB" stroke-width="1.5"/><circle cx="125" cy="150" r="8" fill="none" stroke="#3498DB" stroke-width="1.5"/><circle cx="75" cy="180" r="8" fill="none" stroke="#3498DB" stroke-width="1.5"/><circle cx="125" cy="180" r="8" fill="none" stroke="#3498DB" stroke-width="1.5"/>'),
    ("p5", "🌸", "The Sakura", "Blossom", "#3498DB",
     '<text x="100" y="110" text-anchor="middle" font-size="50">🌸</text><circle cx="100" cy="160" r="12" fill="#FFC0CB" opacity="0.3"/><circle cx="80" cy="145" r="8" fill="#FFC0CB" opacity="0.2"/><circle cx="120" cy="145" r="8" fill="#FFC0CB" opacity="0.2"/><circle cx="80" cy="175" r="8" fill="#FFC0CB" opacity="0.2"/><circle cx="120" cy="175" r="8" fill="#FFC0CB" opacity="0.2"/>'),
    ("p6", "🍺", "The 6-Pack", "Cheers", "#3498DB",
     '<text x="100" y="100" text-anchor="middle" font-size="50">🍺</text><rect x="65" y="145" width="30" height="25" rx="4" fill="#F39C12" opacity="0.2"/><rect x="105" y="145" width="30" height="25" rx="4" fill="#F39C12" opacity="0.2"/><rect x="65" y="175" width="30" height="25" rx="4" fill="#F39C12" opacity="0.15"/><rect x="105" y="175" width="30" height="25" rx="4" fill="#F39C12" opacity="0.15"/>'),
    ("p7", "🥄", "The Big Dipper", "Ursa Major", "#3498DB",
     '<text x="100" y="110" text-anchor="middle" font-size="50">🥄</text>'
     '<circle cx="75" cy="145" r="4" fill="#FFD700"/><circle cx="90" cy="140" r="4" fill="#FFD700"/><circle cx="105" cy="135" r="4" fill="#FFD700"/>'
     '<circle cx="115" cy="165" r="4" fill="#FFD700"/><circle cx="125" cy="175" r="4" fill="#FFD700"/><circle cx="110" cy="185" r="4" fill="#FFD700"/><circle cx="95" cy="180" r="4" fill="#FFD700"/>'
     '<line x1="75" y1="145" x2="90" y2="140" stroke="#FFD700" stroke-width="1" opacity="0.5"/><line x1="90" y1="140" x2="105" y2="135" stroke="#FFD700" stroke-width="1" opacity="0.5"/><line x1="105" y1="135" x2="115" y2="165" stroke="#FFD700" stroke-width="1" opacity="0.5"/><line x1="115" y1="165" x2="125" y2="175" stroke="#FFD700" stroke-width="1" opacity="0.5"/><line x1="125" y1="175" x2="110" y2="185" stroke="#FFD700" stroke-width="1" opacity="0.5"/><line x1="110" y1="185" x2="95" y2="180" stroke="#FFD700" stroke-width="1" opacity="0.5"/><line x1="95" y1="180" x2="75" y2="145" stroke="#FFD700" stroke-width="1" opacity="0.5"/>'),
    ("p8", "🧱", "The Lego Brick", "2x4 Studs", "#3498DB",
     '<text x="100" y="100" text-anchor="middle" font-size="50">🧱</text><rect x="55" y="140" width="90" height="50" rx="6" fill="#E74C3C" opacity="0.2" stroke="#E74C3C" stroke-width="1"/>'),
    ("p9", "🧩", "Rubik's Face", "9 Grid", "#3498DB",
     '<text x="100" y="110" text-anchor="middle" font-size="50">🧩</text><rect x="70" y="140" width="60" height="60" fill="none" stroke="#3498DB" stroke-width="1"/><line x1="90" y1="140" x2="90" y2="200" stroke="#3498DB" stroke-width="0.5"/><line x1="110" y1="140" x2="110" y2="200" stroke="#3498DB" stroke-width="0.5"/><line x1="70" y1="160" x2="130" y2="160" stroke="#3498DB" stroke-width="0.5"/><line x1="70" y1="180" x2="130" y2="180" stroke="#3498DB" stroke-width="0.5"/>'),
    # ── Souzu (Pop Culture) ──
    ("s1", "🐦", "The Spy Bird", "Incognito", "#2ECC71",
     '<text x="100" y="110" text-anchor="middle" font-size="50">🐦</text><rect x="70" y="150" width="60" height="30" rx="12" fill="#2ECC71" opacity="0.1"/><circle cx="100" cy="180" r="3" fill="#2ECC71" opacity="0.3"/>'),
    ("s2", "⏸️", "The Tech Twins", "Pause", "#2ECC71",
     '<text x="100" y="110" text-anchor="middle" font-size="50">⏸️</text><rect x="70" y="145" width="15" height="45" rx="3" fill="#2ECC71" opacity="0.3"/><rect x="115" y="145" width="15" height="45" rx="3" fill="#2ECC71" opacity="0.3"/>'),
    ("s3", "🚦", "Traffic Light", "Upside-Down", "#2ECC71",
     '<text x="100" y="110" text-anchor="middle" font-size="50">🚦</text><circle cx="100" cy="145" r="8" fill="#E74C3C" opacity="0.4"/><circle cx="85" cy="170" r="8" fill="#2ECC71" opacity="0.3"/><circle cx="115" cy="170" r="8" fill="#2ECC71" opacity="0.3"/>'),
    ("s4", "🏡", "The Garden Fence", "4 Posts", "#2ECC71",
     '<text x="100" y="100" text-anchor="middle" font-size="50">🏡</text><rect x="70" y="150" width="6" height="40" fill="#8B4513" opacity="0.3"/><rect x="90" y="150" width="6" height="40" fill="#8B4513" opacity="0.3"/><rect x="110" y="150" width="6" height="40" fill="#8B4513" opacity="0.3"/><rect x="130" y="150" width="6" height="40" fill="#8B4513" opacity="0.3"/>'),
    ("s5", "🌟", "The Party VIP", "Star Center", "#2ECC71",
     '<text x="100" y="110" text-anchor="middle" font-size="50">🌟</text><circle cx="80" cy="150" r="6" fill="#2ECC71" opacity="0.2"/><circle cx="120" cy="150" r="6" fill="#2ECC71" opacity="0.2"/><circle cx="80" cy="180" r="6" fill="#2ECC71" opacity="0.2"/><circle cx="120" cy="180" r="6" fill="#2ECC71" opacity="0.2"/><circle cx="100" cy="165" r="10" fill="#E74C3C" opacity="0.3"/>'),
    ("s6", "💪", "The 6-Pack Abs", "Flex", "#2ECC71",
     '<text x="100" y="100" text-anchor="middle" font-size="50">💪</text><rect x="70" y="145" width="60" height="55" rx="8" fill="#2ECC71" opacity="0.08"/><line x1="80" y1="155" x2="120" y2="155" stroke="#2ECC71" stroke-width="0.5" opacity="0.3"/><line x1="80" y1="170" x2="120" y2="170" stroke="#2ECC71" stroke-width="0.5" opacity="0.3"/><line x1="80" y1="185" x2="120" y2="185" stroke="#2ECC71" stroke-width="0.5" opacity="0.3"/>'),
    ("s7", "👑", "The Crowned King", "Royal", "#2ECC71",
     '<text x="100" y="100" text-anchor="middle" font-size="50">👑</text><polygon points="60,170 80,140 100,170 120,140 140,170" fill="#FFD700" opacity="0.2" stroke="#FFD700" stroke-width="1"/>'),
    ("s8", "⚔️", "The Sword Matrix", "Crossed", "#2ECC71",
     '<text x="100" y="110" text-anchor="middle" font-size="50">⚔️</text><line x1="70" y1="150" x2="130" y2="190" stroke="#2ECC71" stroke-width="2" opacity="0.3"/><line x1="130" y1="150" x2="70" y2="190" stroke="#2ECC71" stroke-width="2" opacity="0.3"/><line x1="70" y1="190" x2="130" y2="150" stroke="#2ECC71" stroke-width="2" opacity="0.3"/><line x1="130" y1="190" x2="70" y2="150" stroke="#2ECC71" stroke-width="2" opacity="0.3"/>'),
    ("s9", "📱", "App Home Screen", "3x3 Grid", "#2ECC71",
     '<text x="100" y="100" text-anchor="middle" font-size="50">📱</text><rect x="65" y="140" width="70" height="50" rx="6" fill="none" stroke="#2ECC71" stroke-width="1"/><line x1="88" y1="140" x2="88" y2="190" stroke="#2ECC71" stroke-width="0.5"/><line x1="112" y1="140" x2="112" y2="190" stroke="#2ECC71" stroke-width="0.5"/><line x1="65" y1="157" x2="135" y2="157" stroke="#2ECC71" stroke-width="0.5"/><line x1="65" y1="173" x2="135" y2="173" stroke="#2ECC71" stroke-width="0.5"/>'),
    # ── Winds (Nautical Compass) ──
    ("z1", "🎈", "The Sunrise Balloon", "East", "#F39C12",
     '<text x="100" y="100" text-anchor="middle" font-size="50">🎈</text><ellipse cx="100" cy="155" rx="30" ry="35" fill="#F39C12" opacity="0.1"/><line x1="100" y1="190" x2="100" y2="210" stroke="#F39C12" stroke-width="1" opacity="0.3"/><rect x="85" y="208" width="30" height="15" rx="4" fill="#F39C12" opacity="0.2"/>'),
    ("z2", "⛱️", "The Tropical Parasol", "South", "#F39C12",
     '<text x="100" y="110" text-anchor="middle" font-size="50">⛱️</text><path d="M60,180 Q100,130 140,180" fill="#F39C12" opacity="0.15" stroke="#F39C12" stroke-width="1"/>'),
    ("z3", "🍺", "Wild West Beer Stein", "West", "#F39C12",
     '<text x="100" y="110" text-anchor="middle" font-size="50">🍺</text><rect x="75" y="145" width="50" height="50" rx="8" fill="none" stroke="#F39C12" stroke-width="1.5"/><path d="M125,160 Q145,160 145,170 Q145,180 125,180" fill="none" stroke="#F39C12" stroke-width="1.5"/>'),
    ("z4", "🧊", "The Freezing Twins", "North", "#F39C12",
     '<text x="100" y="110" text-anchor="middle" font-size="50">🧊</text><circle cx="80" cy="160" r="12" fill="#F39C12" opacity="0.1"/><circle cx="120" cy="160" r="12" fill="#F39C12" opacity="0.1"/><line x1="92" y1="160" x2="108" y2="160" stroke="#F39C12" stroke-width="3" opacity="0.2"/>'),
    # ── Dragons (Mystical Alchemy) ──
    ("z5", "🎯", "The Bullseye Arrow", "Red Dragon", "#9B59B6",
     '<text x="100" y="100" text-anchor="middle" font-size="50">🎯</text><circle cx="100" cy="160" r="25" fill="none" stroke="#9B59B6" stroke-width="3"/><circle cx="100" cy="160" r="15" fill="none" stroke="#9B59B6" stroke-width="2"/><circle cx="100" cy="160" r="5" fill="#9B59B6" opacity="0.4"/><line x1="100" y1="130" x2="100" y2="155" stroke="#9B59B6" stroke-width="1.5" opacity="0.5"/>'),
    ("z6", "💰", "The Wealth Generator", "Green Dragon", "#9B59B6",
     '<text x="100" y="100" text-anchor="middle" font-size="50">💰</text><circle cx="80" cy="155" r="6" fill="#FFD700" opacity="0.3"/><circle cx="95" cy="148" r="6" fill="#FFD700" opacity="0.3"/><circle cx="110" cy="148" r="6" fill="#FFD700" opacity="0.3"/><circle cx="125" cy="155" r="6" fill="#FFD700" opacity="0.3"/><circle cx="90" cy="165" r="6" fill="#FFD700" opacity="0.2"/><circle cx="105" cy="165" r="6" fill="#FFD700" opacity="0.2"/><circle cx="100" cy="175" r="6" fill="#FFD700" opacity="0.15"/>'),
    ("z7", "🪞", "The Blank Mirror", "White Dragon", "#9B59B6",
     '<text x="100" y="110" text-anchor="middle" font-size="50">🪞</text><rect x="60" y="140" width="80" height="60" rx="8" fill="none" stroke="#9B59B6" stroke-width="2" opacity="0.3"/><rect x="70" y="150" width="60" height="40" rx="4" fill="#F5F0E8" opacity="0.05"/>'),
]

TEMPLATE = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 768" width="512" height="768">
  <defs>
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:{bg_top}"/>
      <stop offset="100%" style="stop-color:{bg_bottom}"/>
    </linearGradient>
    <filter id="glow">
      <feGaussianBlur stdDeviation="3" result="blur"/>
      <feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>

  <!-- Background -->
  <rect width="512" height="768" fill="url(#bgGrad)"/>

  <!-- Visual scene (scaled to 512x768 from 200x280) -->
  <g transform="translate(56, 80) scale(2.0)">
    {visual}
  </g>

  <!-- Tile ID badge -->
  <rect x="220" y="30" width="72" height="28" rx="14" fill="{color}" opacity="0.3"/>
  <text x="256" y="50" text-anchor="middle" font-family="Poppins,sans-serif" font-size="13" font-weight="700" fill="{color}">{tile_id}</text>

  <!-- Name -->
  <text x="256" y="580" text-anchor="middle" font-family="Poppins,sans-serif" font-size="26" font-weight="800" fill="#F5F0E8" filter="url(#glow)">{name}</text>

  <!-- Slogan -->
  <text x="256" y="620" text-anchor="middle" font-family="Poppins,sans-serif" font-size="14" font-weight="600" fill="{color}" opacity="0.8">{slogan}</text>

  <!-- Chinese hint -->
  <text x="256" y="720" text-anchor="middle" font-family="Noto Serif SC,SimSun,serif" font-size="13" fill="#8A847C">{chinese}</text>
</svg>'''

CHINESE_HINTS = {
    "m1":"一根木头 + 滑板车 = 一万","m2":"双层夹板改造成越野车 = 二万","m3":"三层汉堡正在配送 = 三万",
    "m4":"四四方方的防晒遮阳棚 = 四万","m5":"五字形折叠沙滩椅 = 五万","m6":"六字形火箭推进器 = 六万",
    "m7":"七字形倒挂大吊钩 = 七万","m8":"八字形开口超级火山 = 八万","m9":"九字形高空跳水台 = 九万",
    "p1":"独一无二的巨型盾牌 = 一筒","p2":"上下两个圆球 = 雪人 = 二筒","p3":"对角线倾斜排列 = 豌豆荚 = 三筒",
    "p4":"2x2排列 = 四轴无人机 = 四筒","p5":"四角+中心 = 樱花 = 五筒","p6":"2x3矩形 = 六瓶装啤酒 = 六筒",
    "p7":"3+4 = 北斗七星 = 七筒","p8":"2x4长条 = 乐高积木 = 八筒","p9":"3x3正方形 = 魔方切面 = 九筒",
    "s1":"竹林里的1号间谍伪装者","s2":"两个平行长条 = 暂停键","s3":"倒三角形 = 倒立红绿灯",
    "s4":"2x2排列 = 花园围栏4根柱子","s5":"4绿+1红 = 骰子5点VIP","s6":"上3下3 = 型男六块腹肌",
    "s7":"6底座+1尖顶 = 戴王冠的国王","s8":"M+W对称 = 8把利剑合璧","s9":"3x3完美方阵 = App桌面",
    "z1":"热气球往东飞","z2":"热带遮阳伞撑在南方","z3":"狂野西部啤酒杯干杯","z4":"背靠背的极地冰人",
    "z5":"一箭穿心正中红心","z6":"双手一挥 暴发致富","z7":"纯白无瑕的魔法空镜",
}

SLOGANS = {
    "m1":"Delivery time!","m2":"Double the speed!","m3":"Hungry?","m4":"Keep cool!","m5":"Max relaxation!",
    "m6":"To the moon!","m7":"Busted!","m8":"Jackpot!","m9":"Ultimate leap!",
    "p1":"The One and Only.","p2":"Do you want to build a…","p3":"3 peas in a pod.","p4":"4 propellers ready.",
    "p5":"4 petals + 1 heart.","p6":"Grab a cold one!","p7":"Follow the stars.","p8":"Don't step on it!",
    "p9":"Perfect 3x3.",
    "s1":"I'm a bird, but I identify as a bamboo.","s2":"Hit PAUSE for 2 seconds.","s3":"Red on top = count to 3!",
    "s4":"A fence with 4 posts.","s5":"4 bodyguards + 1 VIP = 5!","s6":"Flexing my 6-pack!",
    "s7":"6 guards bow to 1 King.","s8":"8 swords unbreakable.","s9":"Perfect 3x3 grid!",
    "z1":"Rise with the East!","z2":"South = Vacation!","z3":"Welcome to the Wild West!",
    "z4":"Back-to-back against the cold.",
    "z5":"Arrow through the center!","z6":"Jackpot! Get Rich!","z7":"Pure white. Infinite magic.",
}

for tile_id, emoji, name, _, color, svg_content in MNEMONICS:
    if color == "#E74C3C":
        bg_top, bg_bottom = "#1A0806", "#0A0303"
    elif color == "#3498DB":
        bg_top, bg_bottom = "#060E1A", "#03070A"
    elif color == "#2ECC71":
        bg_top, bg_bottom = "#061A0C", "#030A05"
    elif color == "#F39C12":
        bg_top, bg_bottom = "#1A1004", "#0A0802"
    else:
        bg_top, bg_bottom = "#0E061A", "#06030A"

    svg = TEMPLATE.format(
        bg_top=bg_top, bg_bottom=bg_bottom,
        color=color, tile_id=tile_id.upper(),
        name=name, visual=svg_content,
        slogan=SLOGANS[tile_id],
        chinese=CHINESE_HINTS[tile_id],
    )
    path = os.path.join(OUTPUT_DIR, f"{tile_id}.svg")
    with open(path, "w", encoding="utf-8") as f:
        f.write(svg)

print(f"Generated {len(MNEMONICS)} mnemonic SVGs in {OUTPUT_DIR}")
