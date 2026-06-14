"""助记词 JSON 生成脚本"""
import os, json
with open("d:/claude/tilezhan/frontend/assets/data/tiles.json",encoding="utf-8") as f:
    tiles = json.load(f)
out = "d:/claude/tilezhan/frontend/assets/mnemonic"
os.makedirs(out,exist_ok=True)
colors = {"man":"#E74C3C","pin":"#3498DB","sou":"#2ECC71","wind":"#F39C12","dragon":"#9B59B6"}
for t in tiles:
    c = colors.get(t["suit"],"#fff")
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 768"><rect width="512" height="768" fill="#0A0F14"/><text x="256" y="200" text-anchor="middle" font-size="100">{t["mnemonic"]["emoji"]}</text><text x="256" y="320" text-anchor="middle" font-size="28" font-weight="800" fill="#F5F0E8" font-family="Poppins,sans-serif">{t["mnemonic"]["name"]}</text><text x="256" y="360" text-anchor="middle" font-size="15" font-weight="600" fill="{c}" font-family="Poppins,sans-serif">{t["mnemonic"]["slogan"]}</text><text x="256" y="700" text-anchor="middle" font-size="13" fill="#8A847C" font-family="Noto Serif SC,serif">{t["mnemonic"]["chinese"]}</text><rect x="230" y="40" width="52" height="24" rx="12" fill="{c}" opacity="0.2"/><text x="256" y="57" text-anchor="middle" font-size="11" font-weight="700" fill="{c}" font-family="Poppins,sans-serif">{t["id"].upper()}</text></svg>'
    with open(f"{out}/{t['id']}.svg","w",encoding="utf-8") as f2:
        f2.write(svg)
print(f"Generated {len(tiles)} SVGs")
