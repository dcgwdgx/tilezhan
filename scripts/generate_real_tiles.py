"""Generate real mahjong tile SVGs — ivory base, traditional look."""

import os

OUT = "d:/claude/tilezhan/frontend/assets/tiles"
os.makedirs(OUT, exist_ok=True)

# Tile definitions: (id, top_char, icon_type, color_hint)
tiles = [
    # 万子 — red characters on ivory
    ("m1","一万","wan","#8B0000"), ("m2","二万","wan","#8B0000"), ("m3","三万","wan","#8B0000"),
    ("m4","四万","wan","#8B0000"), ("m5","五万","wan","#8B0000"), ("m6","六万","wan","#8B0000"),
    ("m7","七万","wan","#8B0000"), ("m8","八万","wan","#8B0000"), ("m9","九万","wan","#8B0000"),
    # 筒子 — colored dots
    ("p1","一筒","dot","#1A5276"), ("p2","二筒","dot","#1A5276"), ("p3","三筒","dot","#1A5276"),
    ("p4","四筒","dot","#1A5276"), ("p5","五筒","dot","#1A5276"), ("p6","六筒","dot","#1A5276"),
    ("p7","七筒","dot","#1A5276"), ("p8","八筒","dot","#1A5276"), ("p9","九筒","dot","#1A5276"),
    # 条子 — green bamboo
    ("s1","一条","bam","#1E8449"), ("s2","二条","bam","#1E8449"), ("s3","三条","bam","#1E8449"),
    ("s4","四条","bam","#1E8449"), ("s5","五条","bam","#1E8449"), ("s6","六条","bam","#1E8449"),
    ("s7","七条","bam","#1E8449"), ("s8","八条","bam","#1E8449"), ("s9","九条","bam","#1E8449"),
    # 风牌 — black
    ("z1","東","wind","#1A1A1A"), ("z2","南","wind","#1A1A1A"),
    ("z3","西","wind","#1A1A1A"), ("z4","北","wind","#1A1A1A"),
    # 三元牌
    ("z5","中","dragon","#B22222"), ("z6","發","dragon","#228B22"),
    ("z7","白","dragon","#1A1A1A"),
]

# Dot patterns for 筒子 (1-9)
DOT_PATTERNS = {
    1: [(100,135)],
    2: [(100,115),(100,165)],
    3: [(75,115),(125,135),(75,165)],
    4: [(75,115),(125,115),(75,165),(125,165)],
    5: [(75,115),(125,115),(100,135),(75,165),(125,165)],
    6: [(75,105),(75,140),(75,175),(125,105),(125,140),(125,175)],
    7: [(75,105),(100,125),(125,145),(75,145),(100,165),(125,185),(100,185)],
    8: [(75,98),(100,98),(75,130),(100,130),(75,162),(100,162),(75,194),(100,194)],
    9: [(70,100),(100,100),(130,100),(70,130),(100,130),(130,130),(70,160),(100,160),(130,160)],
}

# Bamboo patterns for 条子 (1-9) — vertical lines
BAM_PATTERNS = {
    1: [(100,90,100,195)],
    2: [(85,90,85,195),(115,90,115,195)],
    3: [(70,85,70,195),(100,85,100,195),(130,85,130,195)],
    4: [(70,90,70,170),(100,90,100,170),(130,90,130,170),(100,175,100,195)],
    5: [(70,90,70,170),(100,90,100,170),(130,90,130,170),(85,180,85,200),(115,180,115,200)],
    6: [(65,90,65,170),(85,90,85,170),(105,90,105,170),(65,175,65,200),(85,175,85,200),(105,175,105,200)],
    7: [(65,90,65,170),(85,90,85,170),(105,90,105,170),(65,175,65,200),(85,175,85,200),(105,175,105,200),(125,175,125,200)],
    8: [(65,90,65,170),(85,90,85,170),(105,90,105,170),(65,175,65,200),(85,175,85,200),(105,175,105,200),(125,175,125,200),(125,90,125,170)],
    9: [(65,90,65,170),(85,90,85,170),(105,90,105,170),(65,175,65,200),(85,175,85,200),(105,175,105,200),(125,175,125,200),(125,90,125,170),(145,175,145,200)],
}

for tid, top_char, itype, color in tiles:
    svg_parts = []
    svg_parts.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 280" width="200" height="280">')
    # Ivory background
    svg_parts.append(f'<rect x="3" y="3" width="194" height="274" rx="12" fill="#F8F0E0"/>')
    svg_parts.append(f'<rect x="6" y="6" width="188" height="268" rx="10" fill="#FDF8F0" stroke="#D4C8B0" stroke-width="1.5"/>')
    # Inner border
    svg_parts.append(f'<rect x="16" y="16" width="168" height="248" rx="6" fill="none" stroke="#E8DCC8" stroke-width="0.8"/>')

    if itype == "wan":
        # Large Chinese numeral + small red 萬 mark
        n = int(tid[1:])
        big_char = ['一','二','三','四','五','六','七','八','九'][n-1]
        svg_parts.append(f'<text x="100" y="165" text-anchor="middle" font-family="serif" font-size="76" font-weight="900" fill="{color}">{big_char}</text>')
        svg_parts.append(f'<text x="100" y="240" text-anchor="middle" font-family="serif" font-size="24" font-weight="700" fill="{color}">萬</text>')

    elif itype == "dot":
        # Colored circles
        n = int(tid[1:])
        for cx, cy in DOT_PATTERNS[n]:
            svg_parts.append(f'<circle cx="{cx}" cy="{cy}" r="14" fill="{color}"/>')
        # Small 筒 at bottom
        svg_parts.append(f'<text x="100" y="250" text-anchor="middle" font-family="serif" font-size="14" fill="#999">筒</text>')

    elif itype == "bam":
        # Green bamboo sticks
        n = int(tid[1:])
        if n == 1:
            # Bird for 1-bam
            svg_parts.append(f'<text x="100" y="180" text-anchor="middle" font-size="60" fill="{color}">🀐</text>')
        else:
            for x1,y1,x2,y2 in BAM_PATTERNS[n]:
                svg_parts.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" stroke-width="8" stroke-linecap="round"/>')
        svg_parts.append(f'<text x="100" y="255" text-anchor="middle" font-family="serif" font-size="14" fill="#999">条</text>')

    elif itype == "wind":
        svg_parts.append(f'<text x="100" y="180" text-anchor="middle" font-family="serif" font-size="72" font-weight="900" fill="{color}">{top_char}</text>')

    elif itype == "dragon":
        if tid == "z7":
            # White dragon — empty frame
            svg_parts.append(f'<rect x="55" y="95" width="90" height="100" rx="4" fill="none" stroke="#999" stroke-width="2"/>')
        else:
            svg_parts.append(f'<text x="100" y="180" text-anchor="middle" font-family="serif" font-size="76" font-weight="900" fill="{color}">{top_char}</text>')

    # Corner label
    label = {"m1":"1m","m2":"2m","m3":"3m","m4":"4m","m5":"5m","m6":"6m","m7":"7m","m8":"8m","m9":"9m",
             "p1":"1p","p2":"2p","p3":"3p","p4":"4p","p5":"5p","p6":"6p","p7":"7p","p8":"8p","p9":"9p",
             "s1":"1s","s2":"2s","s3":"3s","s4":"4s","s5":"5s","s6":"6s","s7":"7s","s8":"8s","s9":"9s",
             "z1":"E","z2":"S","z3":"W","z4":"N","z5":"D-R","z6":"D-G","z7":"D-W"}[tid]
    svg_parts.append(f'<text x="190" y="22" text-anchor="end" font-family="sans-serif" font-size="10" font-weight="600" fill="#999">{label}</text>')
    svg_parts.append(f'<text x="14" y="268" text-anchor="start" font-family="sans-serif" font-size="9" fill="#CCC">{label}</text>')
    svg_parts.append('</svg>')

    with open(f"{OUT}/{tid}.svg", "w", encoding="utf-8") as f:
        f.write("\n".join(svg_parts))
    print(f"  {tid}.svg")

print(f"\nGenerated {len(tiles)} real mahjong tile SVGs")
