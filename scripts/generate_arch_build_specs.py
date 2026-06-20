from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Screenshots"
W, H = 2048, 1448

BG = (7, 31, 51)
PANEL = (13, 50, 75)
GRID = (27, 75, 103)
GRID2 = (44, 104, 133)
LINE = (216, 241, 247)
DIM = (255, 196, 92)
RED = (240, 105, 92)
GREEN = (105, 198, 145)
BLUE = (95, 177, 242)
STONE = (154, 178, 188)
WOOD = (190, 139, 91)
TEXT = (230, 246, 250)
MUTED = (151, 191, 203)


def font(size, bold=False):
    names = [
        "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
    ]
    for name in names:
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default()


F1 = font(58, True)
F2 = font(30, True)
F3 = font(23, True)
F4 = font(20)
F5 = font(16)


def label(d, xy, text, fill=TEXT, f=F4):
    d.text(xy, text, fill=fill, font=f)


def grid(d):
    for x in range(0, W, 32):
        d.line((x, 0, x, H), fill=GRID, width=1)
    for y in range(0, H, 32):
        d.line((0, y, W, y), fill=GRID, width=1)
    for x in range(0, W, 160):
        d.line((x, 0, x, H), fill=GRID2, width=1)
    for y in range(0, H, 160):
        d.line((0, y, W, y), fill=GRID2, width=1)


def rect(d, xy, outline=LINE, fill=None, width=3):
    d.rectangle(xy, outline=outline, fill=fill, width=width)


def panel(d, xy, title, lines, f=F5):
    x1, y1, x2, y2 = xy
    d.rounded_rectangle(xy, radius=10, outline=GRID2, fill=PANEL, width=2)
    label(d, (x1 + 18, y1 + 14), title, DIM, F2)
    y = y1 + 58
    for line in lines:
        color = TEXT if not line.startswith("-") else MUTED
        label(d, (x1 + 18, y), line, color, f)
        y += 25


def title(d, code, subtitle):
    label(d, (52, 34), code, TEXT, F1)
    label(d, (56, 104), subtitle, MUTED, F4)
    d.line((52, 144, W - 52, 144), fill=GRID2, width=2)


def dim(d, p1, p2, text, offset=(8, -24)):
    d.line((p1[0], p1[1], p2[0], p2[1]), fill=DIM, width=2)
    for x, y in (p1, p2):
        d.line((x - 8, y - 8, x + 8, y + 8), fill=DIM, width=2)
        d.line((x - 8, y + 8, x + 8, y - 8), fill=DIM, width=2)
    label(d, ((p1[0] + p2[0]) // 2 + offset[0], (p1[1] + p2[1]) // 2 + offset[1]), text, DIM, F5)


def roof(d, pts, color=RED, width=5):
    d.line(pts, fill=color, width=width, joint="curve")
    for x, y in pts:
        d.ellipse((x - 4, y - 4, x + 4, y + 4), fill=color)


def hatch(d, xy, color=GRID2, step=18):
    x1, y1, x2, y2 = xy
    for x in range(x1 - (y2 - y1), x2, step):
        d.line((x, y2, x + (y2 - y1), y1), fill=color, width=1)


def swatch(d, x, y, color, name):
    d.rectangle((x, y, x + 54, y + 34), fill=color, outline=LINE, width=2)
    label(d, (x + 66, y + 5), name, TEXT, F5)


def save(name, draw):
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    grid(d)
    draw(d)
    label(d, (52, H - 44), "BUILD SPEC V2: use as construction checklist, not just mood art", MUTED, F5)
    img.save(OUT / name)
    print(f"wrote {name}")


def chua_cau_build(d):
    title(d, "BUILD SPEC V2-01: CHUA CAU", "orthographic build sheet: footprint, elevation, section, modules, evidence")

    # Plan
    px, py = 88, 230
    label(d, (px, py - 42), "A. TOP PLAN / COLLISION", DIM, F2)
    rect(d, (px, py, px + 850, py + 240), LINE, width=4)
    hatch(d, (px, py, px + 850, py + 240))
    rect(d, (px + 70, py + 45, px + 780, py + 195), BLUE, width=3)
    rect(d, (px + 375, py - 65, px + 530, py + 305), DIM, width=4)
    rect(d, (px - 36, py + 25, px + 34, py + 215), STONE, width=4)
    rect(d, (px + 816, py + 25, px + 886, py + 215), STONE, width=4)
    for x in range(px + 120, px + 780, 110):
        d.line((x, py + 45, x, py + 195), fill=GRID2, width=2)
    dim(d, (px + 70, py + 270), (px + 780, py + 270), "walkable timber corridor 9-11m")
    dim(d, (px + 375, py - 90), (px + 530, py - 90), "north shrine protrusion")
    label(d, (px + 12, py + 315), "Keep center spine clear; railings stay outside player route; shrine attaches north side only.", TEXT, F5)

    # Elevation
    ex, ey = 80, 620
    label(d, (ex, ey - 42), "B. SIDE ELEVATION / SILHOUETTE", DIM, F2)
    d.arc((ex + 120, ey + 105, ex + 830, ey + 380), 190, 350, fill=LINE, width=6)
    d.line((ex + 70, ey + 340, ex + 930, ey + 340), fill=LINE, width=5)
    for x in (ex + 190, ex + 300, ex + 410, ex + 520, ex + 630, ex + 740):
        rect(d, (x - 13, ey + 115, x + 13, ey + 340), GREEN, width=4)
        d.line((x - 38, ey + 225, x + 38, ey + 225), fill=LINE, width=2)
    roof(d, [(ex + 55, ey + 95), (ex + 230, ey + 35), (ex + 500, ey + 10), (ex + 770, ey + 35), (ex + 950, ey + 95)], RED, 7)
    roof(d, [(ex + 105, ey + 145), (ex + 260, ey + 90), (ex + 500, ey + 70), (ex + 740, ey + 90), (ex + 900, ey + 145)], RED, 4)
    rect(d, (ex + 405, ey + 85, ex + 595, ey + 245), DIM, width=4)
    roof(d, [(ex + 380, ey + 85), (ex + 500, ey + 25), (ex + 620, ey + 85)], DIM, 4)
    for x in (ex + 90, ex + 910):
        rect(d, (x - 44, ey + 170, x + 44, ey + 340), LINE, width=4)
        roof(d, [(x - 62, ey + 170), (x, ey + 120), (x + 62, ey + 170)], RED, 4)
    rect(d, (ex + 150, ey + 340, ex + 260, ey + 420), STONE, width=4)
    rect(d, (ex + 735, ey + 340, ex + 845, ey + 420), STONE, width=4)
    dim(d, (ex + 500, ey + 10), (ex + 500, ey + 340), "roof peak / deck ratio")
    label(d, (ex + 40, ey + 455), "Required read: stone base + arched timber deck + sagging covered roof + shrine bulge.", TEXT, F5)

    # Section
    sx, sy = 1085, 230
    label(d, (sx, sy - 42), "C. CROSS SECTION", DIM, F2)
    rect(d, (sx + 80, sy + 175, sx + 430, sy + 245), WOOD, width=4)
    rect(d, (sx + 100, sy + 110, sx + 410, sy + 175), BLUE, width=3)
    roof(d, [(sx + 45, sy + 110), (sx + 255, sy + 5), (sx + 470, sy + 110)], RED, 6)
    roof(d, [(sx + 90, sy + 150), (sx + 255, sy + 78), (sx + 425, sy + 150)], RED, 4)
    for x in (sx + 135, sx + 375):
        rect(d, (x - 12, sy + 105, x + 12, sy + 245), GREEN, width=4)
    dim(d, (sx + 100, sy + 275), (sx + 410, sy + 275), "interior width: player + rail clearance")
    dim(d, (sx + 255, sy + 5), (sx + 255, sy + 245), "roof overhang protects corridor")
    label(d, (sx + 70, sy + 318), "Section proves roof volume is a covered bridge, not a flat walkway.", TEXT, F5)

    panel(d, (1080, 620, 1960, 900), "D. Build order", [
        "1. Place stone piers and water line first.",
        "2. Add arched walkable deck and collision.",
        "3. Add red column pairs + railings per bay.",
        "4. Add two-layer tiled roof with sagging ridge.",
        "5. Attach north shrine pavilion at mid-span.",
        "6. Add dog/monkey guardian plinths at entries.",
        "7. Apply weathering: moss, water stain, dark timber.",
    ])
    panel(d, (1080, 930, 1960, 1240), "E. Evidence gate", [
        "Need: 8 compass shots + top-down + player-scale.",
        "Need bridge extras: entry, shrine, roof-tile detail,",
        "walkthrough-start, walkthrough-mid, walkthrough-exit.",
        "Critical fail: bridge cannot be walked end-to-end,",
        "or side view lacks arch/shrine/stone-pier silhouette.",
    ])
    for i, (c, name) in enumerate([(STONE, "grey stone piers"), (WOOD, "dark timber"), (RED, "aged clay tiles"), (DIM, "shrine glow")]):
        swatch(d, 1120 + (i // 2) * 360, 1280 + (i % 2) * 48, c, name)


def assembly_build(d):
    title(d, "BUILD SPEC V2-02: ASSEMBLY HALLS", "separate Phuc Kien and Quang Dong by massing, color, roof, courtyard")

    # Fujian facade
    label(d, (88, 188), "A. PHUC KIEN / FRONT FACADE", DIM, F2)
    fx, fy = 92, 265
    for x1, x2, h in [(fx + 20, fx + 220, fy + 430), (fx + 260, fx + 560, fy + 510), (fx + 600, fx + 800, fy + 430)]:
        rect(d, (x1, fy + 135, x2, h), RED, width=5)
        d.arc((x1 + 32, fy + 235, x2 - 32, h + 100), 180, 360, fill=LINE, width=5)
    roof(d, [(fx - 20, fy + 135), (fx + 410, fy + 45), (fx + 840, fy + 135)], RED, 7)
    roof(d, [(fx + 50, fy + 65), (fx + 410, fy - 15), (fx + 770, fy + 65)], DIM, 5)
    roof(d, [(fx + 170, fy - 5), (fx + 410, fy - 75), (fx + 650, fy - 5)], RED, 5)
    d.ellipse((fx + 352, fy - 45, fx + 468, fy + 72), outline=LINE, width=4)
    dim(d, (fx + 260, fy + 550), (fx + 560, fy + 550), "center bay wider/taller")
    label(d, (fx + 10, fy + 600), "Must read as red/pink triple tam quan with stacked upturned roofs.", TEXT, F5)

    # Quang Dong plan+section
    label(d, (1080, 188), "B. QUANG DONG / COURTYARD AXIS", DIM, F2)
    qx, qy = 1090, 270
    rect(d, (qx, qy, qx + 760, qy + 410), LINE, width=4)
    rect(d, (qx, qy, qx + 760, qy + 92), GREEN, width=4)
    rect(d, (qx + 80, qy + 150, qx + 680, qy + 330), WOOD, width=3)
    d.ellipse((qx + 340, qy + 190, qx + 420, qy + 270), outline=DIM, width=4)
    rect(d, (qx, qy + 318, qx + 760, qy + 410), GREEN, width=4)
    for x in (qx + 120, qx + 640):
        rect(d, (x - 28, qy + 100, x + 28, qy + 382), STONE, width=3)
    dim(d, (qx + 20, qy + 450), (qx + 740, qy + 450), "gate -> courtyard -> main hall axis")
    label(d, (qx + 15, qy + 495), "Use orange/ochre wall mass + green roof. Keep courtyard open and legible.", TEXT, F5)

    panel(d, (92, 925, 950, 1230), "C. Phuc Kien remake criteria", [
        "- 3 arched entries, center bay dominant.",
        "- 3 roof tiers visible from gameplay camera.",
        "- red/pink plaster is main color; trim can be green/yellow.",
        "- ridge ornaments read as dragon/ceramic silhouettes.",
        "- forecourt pots frame the gate, never block arches.",
        "Fail: looks like generic shrine or flat wall with one door.",
    ])
    panel(d, (1090, 925, 1950, 1230), "D. Quang Dong remake criteria", [
        "- Green roof and orange/ochre plaster separate it from Phuc Kien.",
        "- Gate, courtyard, and main hall share one center axis.",
        "- Hanging incense coil or round courtyard marker visible.",
        "- Side walls/potted plants guide player eye inward.",
        "- 360 shots must prove courtyard depth, not facade-only set.",
        "Fail: same red gate language as Phuc Kien.",
    ])
    for i, (c, name) in enumerate([(RED, "Phuc Kien red/pink"), (GREEN, "Quang Dong green roof"), (DIM, "glazed trim"), (STONE, "stone courtyard")]):
        swatch(d, 110 + i * 410, 1290, c, name)


def market_build(d):
    title(d, "BUILD SPEC V2-03: HOI AN MARKET", "long low arcade hall; not a temple; player-readable street edge")
    x, y = 95, 235
    label(d, (x, y - 48), "A. LONG ELEVATION", DIM, F2)
    rect(d, (x, y + 180, x + 1250, y + 430), DIM, width=5)
    roof(d, [(x - 40, y + 180), (x + 625, y + 30), (x + 1290, y + 180)], RED, 8)
    rect(d, (x + 560, y + 60, x + 690, y + 180), DIM, width=4)
    d.ellipse((x + 600, y + 90, x + 650, y + 140), outline=LINE, width=3)
    for i in range(11):
        ax = x + 60 + i * 105
        d.arc((ax, y + 230, ax + 68, y + 425), 180, 360, fill=LINE, width=5)
        d.line((ax, y + 330, ax + 68, y + 330), fill=GRID2, width=2)
    dim(d, (x + 60, y + 465), (x + 1180, y + 465), "repeat arcade bay rhythm: 9-11 bays")
    dim(d, (x + 625, y + 30), (x + 625, y + 430), "low 1-storey hall; roof gable centered")

    label(d, (x, 820), "B. STREET EDGE PLAN", DIM, F2)
    rect(d, (x, 880, x + 1250, 1030), LINE, width=4)
    for i in range(11):
        ax = x + 60 + i * 105
        rect(d, (ax, 880, ax + 60, 1030), GRID2, width=2)
    for i in range(6):
        ax = x + 95 + i * 190
        d.polygon([(ax, 1030), (ax + 120, 1030), (ax + 150, 1110), (ax - 20, 1110)], outline=BLUE, width=4)
    dim(d, (x, 1148), (x + 1250, 1148), "street corner view must show building length")
    label(d, (x + 10, 1182), "Awnings/stalls sit outside arcade; collision keeps walkable strip clear.", TEXT, F5)

    panel(d, (1430, 230, 1955, 610), "C. Module checklist", [
        "- long mustard-yellow plaster body",
        "- red-brown clay tile roof",
        "- centered clock/gable marker",
        "- repeated arched arcade openings",
        "- canvas stall awnings on pavement",
        "- bicycles/carts only as scale props",
        "- no temple-style tam quan or dragon roof",
    ])
    panel(d, (1430, 665, 1955, 1115), "D. Success criteria", [
        "- From 30m: reads as market hall, not assembly hall.",
        "- 8+ arcade bays countable in side/corner shot.",
        "- roof gable sits near center of long mass.",
        "- stalls add life but do not block arcade silhouette.",
        "- player path remains clear along street edge.",
        "Evidence: corner, side sweep, arcade detail, top-down.",
    ])
    for i, (c, name) in enumerate([(DIM, "mustard plaster"), (RED, "red-brown tile"), (BLUE, "canvas awning"), (WOOD, "stall wood")]):
        swatch(d, 1435, 1210 + i * 48, c, name)


def ruin_river_build(d):
    title(d, "BUILD SPEC V2-04: RUIN + RIVER", "set dressing that still communicates former architecture and navigable boundary")

    rx, ry = 90, 245
    label(d, (rx, ry - 48), "A. RUINED SHOPHOUSE KIT", DIM, F2)
    rect(d, (rx, ry, rx + 760, ry + 520), STONE, width=4)
    d.line((rx, ry, rx + 180, ry + 180), fill=RED, width=6)
    d.line((rx + 760, ry, rx + 610, ry + 175), fill=RED, width=6)
    d.line((rx + 150, ry + 120, rx + 620, ry + 440), fill=LINE, width=7)
    d.line((rx + 560, ry + 120, rx + 240, ry + 500), fill=LINE, width=7)
    for i, (bx, by) in enumerate([(rx + 160, ry + 350), (rx + 330, ry + 420), (rx + 560, ry + 370)]):
        rect(d, (bx, by, bx + 92, by + 34), DIM, width=3)
    for i in range(9):
        d.arc((rx + 80 + i * 72, ry + 490, rx + 135 + i * 72, ry + 570), 200, 340, fill=GREEN, width=4)
    rect(d, (rx + 310, ry + 230, rx + 450, ry + 520), BLUE, width=4)
    dim(d, (rx + 310, ry + 555), (rx + 450, ry + 555), "open pass-through")
    label(d, (rx + 20, ry + 610), "Do not make random rubble. It must read as a broken Hoi An tube-house frontage.", TEXT, F5)

    wx, wy = 1010, 245
    label(d, (wx, wy - 48), "B. RIVER EMBANKMENT KIT", DIM, F2)
    rect(d, (wx, wy + 250, wx + 835, wy + 520), BLUE, width=4)
    rect(d, (wx, wy + 100, wx + 835, wy + 250), LINE, width=4)
    for i in range(8):
        px = wx + 35 + i * 105
        rect(d, (px, wy + 55, px + 34, wy + 250), STONE, width=4)
    for i in range(4):
        rect(d, (wx + 270 + i * 42, wy + 250 + i * 34, wx + 585 - i * 42, wy + 280 + i * 34), DIM, width=3)
    rect(d, (wx + 395, wy + 150, wx + 560, wy + 500), WOOD, width=4)
    for x in (wx + 410, wx + 545):
        d.line((x, wy + 160, x, wy + 535), fill=LINE, width=5)
    d.arc((wx + 610, wy + 355, wx + 805, wy + 455), 180, 360, fill=RED, width=6)
    d.arc((wx + 630, wy + 312, wx + 785, wy + 390), 180, 360, fill=DIM, width=5)
    dim(d, (wx + 270, wy + 585), (wx + 585, wy + 585), "steps down to water")
    label(d, (wx + 20, wy + 625), "Separate quay wall, safe walkway, steps, jetty, water plane, and boat silhouette.", TEXT, F5)

    panel(d, (90, 1010, 850, 1260), "C. Ruin criteria", [
        "- Former doorway remains as navigable cut-through.",
        "- Standing walls are jagged but vertical enough to imply house.",
        "- Fallen tiles collect inward; beams lean diagonally.",
        "- Weeds/moss sit at wall base and cracks.",
        "- Night lighting preserves edge readability.",
    ])
    panel(d, (1010, 1010, 1845, 1260), "D. River criteria", [
        "- Player can distinguish walkway, quay edge, and unsafe water.",
        "- Steps and jetty create actual approach targets.",
        "- Boat canopy reads in silhouette from side view.",
        "- Lantern reflections align along river direction.",
        "- 360 set includes both bank and far-house context.",
    ])


def qa_build(d):
    title(d, "BUILD SPEC V2-05: REMAKE ACCEPTANCE", "what proves a landmark remake is successful")
    label(d, (95, 205), "A. REQUIRED SCREENSHOT RING", DIM, F2)
    cx, cy, r = 520, 600, 350
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=LINE, width=5)
    import math
    names = ["00 N", "01 NE", "02 E", "03 SE", "04 S", "05 SW", "06 W", "07 NW"]
    for i, name in enumerate(names):
        a = math.radians(-90 + i * 45)
        x = cx + int(math.cos(a) * r)
        y = cy + int(math.sin(a) * r)
        d.line((cx, cy, x, y), fill=GRID2, width=2)
        d.ellipse((x - 45, y - 45, x + 45, y + 45), outline=DIM, width=4)
        label(d, (x - 25, y - 12), name, TEXT, F5)
    rect(d, (cx - 115, cy - 70, cx + 115, cy + 70), RED, width=5)
    roof(d, [(cx - 145, cy - 70), (cx, cy - 145), (cx + 145, cy - 70)], RED, 4)
    label(d, (190, 1010), "Same camera height/lens for 8 compass shots. Add top-down, detail, and player-scale shots.", TEXT, F5)

    panel(d, (1080, 205, 1905, 455), "B. File set per asset", [
        "shots/remake/<asset-slug>/",
        "- 360-00-north.png ... 360-07-northwest.png",
        "- top-down.png",
        "- player-scale.png",
        "- detail-roof.png / detail-entry.png / detail-materials.png",
        "- bridge only: walkthrough-start/mid/exit.png",
    ])
    panel(d, (1080, 500, 1905, 820), "C. Critical fail conditions", [
        "- landmark silhouette can be mistaken for another asset",
        "- required module exists in code but is hidden in screenshots",
        "- path/collision blocks intended route",
        "- material identity disappears under night lighting",
        "- props look decorative but reduce gameplay readability",
        "- no 360 evidence pack stored beside the work",
    ])
    panel(d, (1080, 865, 1905, 1190), "D. Scorecard", [
        "Silhouette match: 30 pts, pass >=24",
        "Landmark modules: 25 pts, pass >=20",
        "Material/color identity: 15 pts, pass >=12",
        "Gameplay readability/collision: 15 pts, pass >=12",
        "Evidence completeness: 15 pts, pass =15",
        "Overall pass: >=83/100 and no critical fail",
    ])


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    sheets = [
        ("ref-26.png", chua_cau_build),
        ("ref-27.png", assembly_build),
        ("ref-28.png", market_build),
        ("ref-29.png", ruin_river_build),
        ("ref-30.png", qa_build),
    ]
    existing = [name for name, _ in sheets if (OUT / name).exists()]
    if existing:
        raise SystemExit(f"Refusing to overwrite existing files: {', '.join(existing)}")
    for name, draw in sheets:
        save(name, draw)


if __name__ == "__main__":
    main()
