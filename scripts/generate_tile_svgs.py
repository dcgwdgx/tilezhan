"""Generate 34 mahjong tile SVGs for TileZhan — Cyber-Chinatown style."""

import os

OUTPUT_DIR = "d:/claude/tilezhan/frontend/assets/tiles"

TILES = [
    # Manzu (万子)
    ("m1","一","萬","#E74C3C"), ("m2","二","萬","#E74C3C"), ("m3","三","萬","#E74C3C"),
    ("m4","四","萬","#E74C3C"), ("m5","五","萬","#E74C3C"), ("m6","六","萬","#E74C3C"),
    ("m7","七","萬","#E74C3C"), ("m8","八","萬","#E74C3C"), ("m9","九","萬","#E74C3C"),
    # Pinzu (筒子)
    ("p1","一","筒","#3498DB"), ("p2","二","筒","#3498DB"), ("p3","三","筒","#3498DB"),
    ("p4","四","筒","#3498DB"), ("p5","五","筒","#3498DB"), ("p6","六","筒","#3498DB"),
    ("p7","七","筒","#3498DB"), ("p8","八","筒","#3498DB"), ("p9","九","筒","#3498DB"),
    # Souzu (条子)
    ("s1","一","条","#2ECC71"), ("s2","二","条","#2ECC71"), ("s3","三","条","#2ECC71"),
    ("s4","四","条","#2ECC71"), ("s5","五","条","#2ECC71"), ("s6","六","条","#2ECC71"),
    ("s7","七","条","#2ECC71"), ("s8","八","条","#2ECC71"), ("s9","九","条","#2ECC71"),
    # Winds (风牌)
    ("z1","東","風","#F39C12"), ("z2","南","風","#F39C12"),
    ("z3","西","風","#F39C12"), ("z4","北","風","#F39C12"),
    # Dragons (三元牌)
    ("z5","中","龍","#9B59B6"), ("z6","發","龍","#9B59B6"),
    ("z7","白","龍","#9B59B6"),
]

SVG_TEMPLATE = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 280" width="200" height="280">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:{bg_top}"/>
      <stop offset="100%" style="stop-color:{bg_bottom}"/>
    </linearGradient>
  </defs>
  <!-- Card body -->
  <rect x="6" y="6" width="188" height="268" rx="14" fill="url(#bg)" stroke="{color}" stroke-width="2.5"/>
  <!-- Inner border -->
  <rect x="18" y="18" width="164" height="244" rx="8" fill="none" stroke="{color}" stroke-opacity="0.2" stroke-width="1"/>
  <!-- Main character -->
  <text x="100" y="175" text-anchor="middle" font-family="Noto Serif SC, SimSun, serif" font-size="72" font-weight="700" fill="#F5F0E8">{char}</text>
  <!-- Seal -->
  <text x="100" y="230" text-anchor="middle" font-family="Noto Serif SC, SimSun, serif" font-size="22" font-weight="700" fill="{seal_color}">{seal}</text>
  <!-- Corner label (top-right) -->
  <text x="172" y="42" text-anchor="end" font-family="Poppins, sans-serif" font-size="10" font-weight="600" fill="{label_color}">{label}</text>
  <!-- Corner label (bottom-left) -->
  <text x="28" y="252" text-anchor="start" font-family="Poppins, sans-serif" font-size="10" font-weight="600" fill="{label_color}" opacity="0.5">{label}</text>
</svg>'''

LABELS = {
    "m1":"1m","m2":"2m","m3":"3m","m4":"4m","m5":"5m","m6":"6m","m7":"7m","m8":"8m","m9":"9m",
    "p1":"1p","p2":"2p","p3":"3p","p4":"4p","p5":"5p","p6":"6p","p7":"7p","p8":"8p","p9":"9p",
    "s1":"1s","s2":"2s","s3":"3s","s4":"4s","s5":"5s","s6":"6s","s7":"7s","s8":"8s","s9":"9s",
    "z1":"E","z2":"S","z3":"W","z4":"N",
    "z5":"D-R","z6":"D-G","z7":"D-W",
}

os.makedirs(OUTPUT_DIR, exist_ok=True)

for tile_id, char, seal, color in TILES:
    # Darker bg gradient based on suit
    r, g, b = int(color[1:3], 16), int(color[3:5], 16), int(color[5:7], 16)
    bg_top = f"#{min(255, r//2 + 20):02x}{min(255, g//2 + 20):02x}{min(255, b//2 + 20):02x}"
    bg_bottom = f"#{r//3:02x}{g//3:02x}{b//3:02x}"

    seal_hex = "#FF3B30" if seal in ("萬","筒","条") else color

    svg = SVG_TEMPLATE.format(
        bg_top=bg_top, bg_bottom=bg_bottom,
        color=color, char=char, seal=seal,
        seal_color=seal_hex, label=LABELS[tile_id],
        label_color=color,
    )

    path = os.path.join(OUTPUT_DIR, f"{tile_id}.svg")
    with open(path, "w", encoding="utf-8") as f:
        f.write(svg)

print(f"Generated {len(TILES)} tile SVGs in {OUTPUT_DIR}")
