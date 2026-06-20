from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Screenshots"
W, H = 1448, 1086

BG = (9, 36, 59)
GRID = (27, 76, 105)
GRID_MAJOR = (45, 105, 135)
LINE = (205, 236, 246)
ACCENT = (255, 190, 92)
RED = (239, 119, 93)
GREEN = (109, 196, 139)
BLUE = (116, 187, 255)
TEXT = (224, 245, 250)
MUTED = (139, 185, 199)
PAPER = (16, 48, 73)


def font(size, bold=False):
    candidates = [
        "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
    ]
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            pass
    return ImageFont.load_default()


F_TITLE = font(46, True)
F_SUB = font(25, True)
F_BODY = font(22)
F_SMALL = font(18)
F_TINY = font(15)


def draw_grid(d):
    for x in range(0, W, 36):
        d.line((x, 0, x, H), fill=GRID, width=1)
    for y in range(0, H, 36):
        d.line((0, y, W, y), fill=GRID, width=1)
    for x in range(0, W, 144):
        d.line((x, 0, x, H), fill=GRID_MAJOR, width=1)
    for y in range(0, H, 144):
        d.line((0, y, W, y), fill=GRID_MAJOR, width=1)


def label(d, xy, text, fill=TEXT, f=F_SMALL):
    d.text(xy, text, fill=fill, font=f)


def box(d, xy, outline=LINE, fill=None, width=3):
    d.rectangle(xy, outline=outline, fill=fill, width=width)


def panel(d, xy, title, lines):
    x1, y1, x2, y2 = xy
    d.rounded_rectangle(xy, radius=12, outline=GRID_MAJOR, fill=PAPER, width=2)
    label(d, (x1 + 18, y1 + 14), title, ACCENT, F_SUB)
    y = y1 + 54
    for line in lines:
        label(d, (x1 + 18, y), line, TEXT if not line.startswith("-") else MUTED, F_SMALL)
        y += 28


def title(d, name, subtitle):
    label(d, (48, 36), name, TEXT, F_TITLE)
    label(d, (52, 92), subtitle, MUTED, F_BODY)
    d.line((48, 128, W - 48, 128), fill=GRID_MAJOR, width=2)


def dimension(d, p1, p2, txt):
    d.line((p1[0], p1[1], p2[0], p2[1]), fill=ACCENT, width=2)
    for p in (p1, p2):
        d.line((p[0] - 7, p[1] - 7, p[0] + 7, p[1] + 7), fill=ACCENT, width=2)
        d.line((p[0] - 7, p[1] + 7, p[0] + 7, p[1] - 7), fill=ACCENT, width=2)
    mx, my = (p1[0] + p2[0]) // 2, (p1[1] + p2[1]) // 2
    label(d, (mx + 10, my - 22), txt, ACCENT, F_TINY)


def roof(d, pts, color=LINE, width=4):
    d.line(pts, fill=color, width=width, joint="curve")
    for x, y in pts:
        d.ellipse((x - 4, y - 4, x + 4, y + 4), fill=color)


def sheet(path, name, subtitle, draw_fn):
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    draw_grid(d)
    title(d, name, subtitle)
    draw_fn(d)
    label(d, (48, H - 46), "Blueprint reference for Hoi An remake - orthographic, modular, screenshot-verifiable", MUTED, F_TINY)
    img.save(OUT / path)


def chua_cau_overall(d):
    base_y = 610
    # elevation
    d.line((100, base_y, 835, base_y), fill=LINE, width=4)
    d.arc((150, 420, 785, 700), start=190, end=350, fill=LINE, width=5)
    for x in (190, 295, 400, 505, 610, 715):
        box(d, (x - 14, 448, x + 14, base_y), GREEN, width=3)
        d.line((x - 36, 520, x + 36, 520), fill=LINE, width=2)
    roof(d, [(112, 410), (245, 356), (472, 332), (700, 356), (834, 410)], RED, 6)
    roof(d, [(132, 444), (285, 392), (472, 374), (660, 392), (812, 444)], RED, 4)
    box(d, (390, 380, 555, 520), ACCENT, width=3)
    roof(d, [(372, 380), (472, 330), (575, 380)], ACCENT, 4)
    for x in (125, 820):
        box(d, (x - 42, 455, x + 42, 615), LINE, width=3)
        roof(d, [(x - 58, 455), (x, 414), (x + 58, 455)], RED, 4)
    box(d, (158, 610, 250, 684), MUTED, width=3)
    box(d, (690, 610, 782, 684), MUTED, width=3)
    d.line((92, 700, 842, 700), fill=BLUE, width=3)
    dimension(d, (100, 735), (835, 735), "span target 9-11m in game")
    dimension(d, (472, 332), (472, 610), "roof + deck vertical silhouette")
    label(d, (108, 748), "SIDE ELEVATION: low arched deck, stone piers, timber covered bridge, north shrine bulge", TEXT, F_SMALL)
    # plan
    box(d, (120, 820, 790, 945), LINE, width=3)
    for x in range(170, 790, 90):
        d.line((x, 820, x, 945), fill=GRID_MAJOR, width=1)
    box(d, (390, 790, 555, 975), ACCENT, width=3)
    box(d, (92, 805, 120, 960), MUTED, width=3)
    box(d, (790, 805, 818, 960), MUTED, width=3)
    label(d, (130, 970), "PLAN: walkable center spine, railings both sides, shrine pavilion protrudes north", TEXT, F_SMALL)
    panel(d, (900, 165, 1388, 460), "Build modules", [
        "- stone creek piers and water reflection",
        "- arched timber deck with plank seams",
        "- red timber post pairs at each bay",
        "- sagging yin-yang tiled roof rows",
        "- mid-span shrine attached on north side",
        "- dog + monkey guardians at entries",
    ])
    panel(d, (900, 500, 1388, 920), "Remake pass criteria", [
        "Critical pass:",
        "- 8-view 360 shows bridge readable from all sides",
        "- side silhouette has low arch + sagging roof",
        "- shrine is visible as side attachment, not centered box",
        "- walkable corridor remains clear end-to-end",
        "- statues are visible at both entries in close-up",
        "Evidence:",
        "- shots/remake/chua-cau-360-00..07.png",
        "- close: entry, shrine, deck, roof tile rows",
    ])


def chua_cau_entry(d):
    box(d, (120, 265, 485, 775), LINE, width=4)
    roof(d, [(85, 265), (300, 185), (520, 265)], RED, 6)
    box(d, (205, 375, 400, 775), ACCENT, width=4)
    for x in (168, 438):
        box(d, (x - 45, 690, x + 45, 785), MUTED, width=3)
        d.ellipse((x - 32, 625, x + 32, 690), outline=LINE, width=4)
        d.rectangle((x - 22, 670, x + 22, 715), outline=LINE, width=3)
    for y in range(405, 725, 36):
        d.line((220, y, 386, y + 22), fill=GRID_MAJOR, width=2)
    label(d, (132, 805), "ENTRY ELEVATION: pink plaster gate, two guardian plinths, dim timber tunnel behind", TEXT, F_SMALL)
    # corridor cutaway
    d.polygon([(670, 360), (1170, 270), (1170, 610), (670, 760)], outline=LINE, fill=None)
    for i in range(6):
        x = 700 + i * 80
        d.line((x, 370 + i * -12, x, 748 - i * 20), fill=GREEN, width=4)
        d.line((x, 430 + i * -10, 1160, 300 + i * 12), fill=GRID_MAJOR, width=2)
    roof(d, [(650, 345), (910, 245), (1185, 280)], RED, 5)
    d.line((690, 740, 1170, 610), fill=ACCENT, width=4)
    label(d, (675, 805), "INTERIOR CUTAWAY: exposed rafters, red columns, plank deck rising gently", TEXT, F_SMALL)
    panel(d, (106, 850, 675, 1016), "Detail shots required", [
        "- gate front, 3/4, and low angle",
        "- monkey/dog statue silhouettes on plinths",
        "- inside corridor with roof framing visible",
        "- deck slope and plank rhythm visible",
    ])
    panel(d, (720, 850, 1345, 1016), "Failure states", [
        "- generic temple gate with no bridge tunnel",
        "- guardians missing or swapped into random lions",
        "- flat roof instead of curved tiled roof",
        "- corridor blocked by decoration or collision",
    ])


def fujian_gate(d):
    # frontal triple gate
    for x1, x2, hgt in [(145, 315, 650), (350, 590, 710), (625, 795, 650)]:
        box(d, (x1, 410, x2, hgt), RED, width=4)
        d.arc((x1 + 25, 500, x2 - 25, hgt + 80), 180, 360, fill=LINE, width=4)
    for i, (x1, x2, y) in enumerate([(105, 835, 410), (150, 790, 340), (210, 730, 278)]):
        roof(d, [(x1, y), ((x1 + x2) // 2, y - 58), (x2, y)], ACCENT if i == 1 else RED, 5)
    d.ellipse((420, 258, 520, 358), outline=LINE, width=4)
    for x in (190, 750):
        d.line((x, 260, x + 60, 290), fill=ACCENT, width=4)
        d.line((x + 60, 290, x + 100, 260), fill=ACCENT, width=4)
    for x in (95, 840):
        box(d, (x, 655, x + 70, 735), MUTED, width=3)
        d.ellipse((x + 10, 610, x + 60, 665), outline=LINE, width=3)
    label(d, (120, 758), "FRONT: tam quan, red/pink plaster, stacked roofs, moon motif, dragon ridge ornaments", TEXT, F_SMALL)
    # top plan
    box(d, (130, 850, 810, 970), LINE, width=3)
    for x in (320, 620):
        d.line((x, 850, x, 970), fill=GRID_MAJOR, width=2)
    box(d, (365, 805, 575, 850), ACCENT, width=3)
    label(d, (140, 982), "PLAN: three entry bays with forecourt pots and inner threshold", TEXT, F_SMALL)
    panel(d, (900, 170, 1385, 430), "Build modules", [
        "- 3 arched gate bays, center taller",
        "- 3 stacked upturned roof tiers",
        "- rose-pink/deep-red plaster surfaces",
        "- ceramic dragon ridge ornaments",
        "- moon opening and bonsai forecourt",
    ])
    panel(d, (900, 470, 1385, 935), "Remake pass criteria", [
        "- frontal 360 view reads as Phuc Kien, not generic pagoda",
        "- roof has layered tier rhythm and upturned eaves",
        "- red/pink color family dominates, with accent tile trim",
        "- center bay proportion is taller/wider than side bays",
        "- courtyard props do not block the three arches",
        "Evidence: front, 45L, 45R, side, top-down, detail roof",
    ])


def cantonese_hall(d):
    # angled gate and courtyard
    d.polygon([(120, 445), (520, 360), (850, 470), (450, 575)], outline=LINE, fill=None)
    for x in (220, 460, 700):
        d.line((x, 425, x, 690), fill=GREEN, width=5)
    roof(d, [(120, 440), (360, 300), (855, 465)], GREEN, 7)
    roof(d, [(180, 515), (460, 410), (850, 520)], ACCENT, 4)
    box(d, (230, 575, 760, 770), LINE, width=3)
    d.ellipse((460, 600, 555, 695), outline=ACCENT, width=4)
    for i in range(5):
        d.arc((455 + i * 7, 603 + i * 4, 555 - i * 4, 695 - i * 5), 20, 300, fill=ACCENT, width=2)
    for x in (255, 720):
        box(d, (x - 35, 685, x + 35, 765), MUTED, width=3)
    label(d, (140, 800), "3/4 VIEW: ochre-orange walls, green glazed tile roof, dragon columns, incense coil courtyard", TEXT, F_SMALL)
    # courtyard plan
    box(d, (155, 865, 805, 990), LINE, width=3)
    box(d, (155, 865, 310, 990), GREEN, width=3)
    d.ellipse((450, 900, 525, 975), outline=ACCENT, width=3)
    box(d, (655, 865, 805, 990), GREEN, width=3)
    label(d, (170, 1000), "PLAN: gate -> open courtyard -> main hall, center incense/fountain feature", TEXT, F_SMALL)
    panel(d, (900, 170, 1385, 455), "Build modules", [
        "- ochre/orange plaster wall mass",
        "- green yin-yang glazed roof",
        "- dragon-carved granite column hints",
        "- stone courtyard and central incense coil",
        "- potted plants along side walls",
    ])
    panel(d, (900, 495, 1385, 930), "Remake pass criteria", [
        "- 360 view preserves orange wall + green roof contrast",
        "- courtyard remains readable as open space",
        "- gate and main hall align on one central axis",
        "- roof ridge has dragon/ceramic silhouette, not flat bar",
        "- props are symmetrical enough for player orientation",
        "Evidence: 8 compass shots + roof detail + courtyard top",
    ])


def market_hall(d):
    # perspective long arcade
    d.polygon([(115, 420), (1030, 335), (1190, 525), (215, 650)], outline=LINE, fill=None)
    roof(d, [(95, 420), (610, 255), (1205, 520)], RED, 7)
    for i in range(9):
        x = 185 + i * 95
        d.line((x, 410 - i * 9, x + 55, 627 - i * 13), fill=ACCENT, width=4)
        d.arc((x - 8, 500 - i * 10, x + 84, 670 - i * 12), 180, 360, fill=LINE, width=3)
    box(d, (545, 270, 665, 365), ACCENT, width=3)
    d.ellipse((585, 295, 625, 335), outline=LINE, width=3)
    for i in range(5):
        x = 225 + i * 165
        d.polygon([(x, 650), (x + 90, 638), (x + 120, 705), (x + 15, 718)], outline=BLUE, fill=None)
    label(d, (125, 760), "STREET CORNER: long yellow market hall, arched arcade rhythm, roof clock gable, awnings", TEXT, F_SMALL)
    # elevation strip
    box(d, (125, 850, 1080, 945), ACCENT, width=3)
    for i in range(10):
        x = 165 + i * 85
        d.arc((x, 872, x + 50, 945), 180, 360, fill=LINE, width=3)
    roof(d, [(110, 850), (595, 785), (1095, 850)], RED, 4)
    label(d, (130, 965), "ELEVATION: repeated arches should be countable from distance", TEXT, F_SMALL)
    panel(d, (1120, 170, 1390, 465), "Build modules", [
        "- 1-storey long hall",
        "- mustard plaster walls",
        "- repeated arcade bays",
        "- red-brown tile roof",
        "- small clock gable",
        "- canvas awnings + stalls",
    ])
    panel(d, (1120, 500, 1390, 930), "Remake pass criteria", [
        "- long low silhouette, not a temple",
        "- at least 8 arcade bays visible",
        "- clock gable centered on roof",
        "- stalls/awnings sit outside, not inside wall",
        "- collision leaves clear street edge",
        "Evidence: corner, side sweep, roof, arcade close",
    ])


def ruin_and_river(d):
    # ruin
    box(d, (105, 245, 620, 700), MUTED, width=3)
    d.line((105, 245, 230, 365), fill=RED, width=5)
    d.line((620, 245, 505, 385), fill=RED, width=5)
    for x, y in [(190, 520), (290, 610), (430, 560), (530, 630)]:
        d.rectangle((x, y, x + 62, y + 28), outline=ACCENT, width=2)
    for x1, y1, x2, y2 in [(180, 350, 470, 690), (500, 330, 300, 690), (250, 310, 575, 520)]:
        d.line((x1, y1, x2, y2), fill=LINE, width=5)
    for x in range(150, 575, 70):
        d.arc((x, 680, x + 55, 760), 200, 340, fill=GREEN, width=3)
    label(d, (120, 725), "RUIN KIT: jagged yellow wall fragments, collapsed roof tiles, charred beams, rubble, weeds", TEXT, F_SMALL)
    # river
    d.rectangle((760, 550, 1320, 760), outline=BLUE, width=3)
    for i in range(6):
        y = 555 + i * 34
        d.line((760, y, 1320, y + 18), fill=GRID_MAJOR, width=2)
    box(d, (775, 430, 1320, 550), LINE, width=3)
    for x in range(800, 1300, 95):
        box(d, (x, 390, x + 32, 550), MUTED, width=3)
    for i in range(5):
        d.rectangle((915 + i * 30, 550 + i * 22, 1175 - i * 28, 573 + i * 22), outline=ACCENT, width=2)
    box(d, (1010, 475, 1130, 735), ACCENT, width=3)
    for x in (1025, 1115):
        d.line((x, 500, x, 750), fill=LINE, width=4)
    d.arc((1150, 630, 1300, 710), 180, 360, fill=RED, width=4)
    d.arc((1165, 600, 1285, 660), 180, 360, fill=ACCENT, width=4)
    label(d, (770, 790), "RIVER KIT: quay wall, pillars, steps, timber jetty, sampan canopy, lantern reflection lanes", TEXT, F_SMALL)
    panel(d, (105, 820, 620, 1010), "Ruin criteria", [
        "- broken silhouette must imply a former tube house",
        "- doorway path is open and readable",
        "- roof tiles fall inward, not random debris cloud",
        "- night lighting keeps wall edges visible",
    ])
    panel(d, (760, 820, 1320, 1010), "River criteria", [
        "- quay edge, steps, jetty, and water plane are distinct",
        "- player can read safe walkway vs water boundary",
        "- lantern reflections follow river direction",
        "- 360 shots include both bank and far houses",
    ])


def qa_matrix(d):
    # 360 compass
    cx, cy, r = 405, 515, 265
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=LINE, width=4)
    for i, name in enumerate(["N", "NE", "E", "SE", "S", "SW", "W", "NW"]):
        import math
        a = math.radians(-90 + i * 45)
        x = cx + int(math.cos(a) * r)
        y = cy + int(math.sin(a) * r)
        d.line((cx, cy, x, y), fill=GRID_MAJOR, width=2)
        d.ellipse((x - 28, y - 28, x + 28, y + 28), outline=ACCENT, width=3)
        label(d, (x - 13, y - 12), name, TEXT, F_TINY)
    box(d, (cx - 92, cy - 58, cx + 92, cy + 58), RED, width=4)
    roof(d, [(cx - 118, cy - 58), (cx, cy - 118), (cx + 118, cy - 58)], RED, 3)
    label(d, (150, 820), "360 CAPTURE: 8 compass shots + top-down + detail macros", TEXT, F_SMALL)
    panel(d, (780, 175, 1375, 515), "Shot set naming", [
        "shots/remake/<asset>/",
        "- 360-00-north.png ... 360-07-northwest.png",
        "- top-down.png",
        "- detail-roof.png",
        "- detail-entry.png",
        "- detail-materials.png",
        "- player-scale.png",
        "- bridge: walkthrough-start/mid/exit.png",
    ])
    panel(d, (780, 555, 1375, 930), "Definition of done", [
        "Pass only when:",
        "- silhouette matches blueprint from all compass views",
        "- landmark-specific modules are visible and countable",
        "- scale fits player path and collision is clean",
        "- material colors match ref photos under night lighting",
        "- no decorative prop blocks gameplay readability",
        "- before/after screenshots are stored beside the task",
    ])


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    sheets = [
        ("ref-19.png", "BP-01 CHUA CAU OVERALL", "Side elevation, plan, remake criteria", chua_cau_overall),
        ("ref-20.png", "BP-02 CHUA CAU ENTRY + INTERIOR", "Entrance pavilion, guardians, timber corridor", chua_cau_entry),
        ("ref-21.png", "BP-03 PHUC KIEN GATE", "Triple-arched red tam quan and roof tiers", fujian_gate),
        ("ref-22.png", "BP-04 QUANG DONG HALL", "Ochre court, green roof, incense axis", cantonese_hall),
        ("ref-23.png", "BP-05 HOI AN MARKET HALL", "Long arcade building and street corner silhouette", market_hall),
        ("ref-24.png", "BP-06 RUIN + RIVER KIT QA", "Ruin kit, embankment kit, and 360 evidence matrix", ruin_and_river),
        ("ref-25.png", "BP-07 REMAKE QA SHOT MATRIX", "360 capture and definition of done", qa_matrix),
    ]
    existing = [name for name, *_ in sheets if (OUT / name).exists()]
    if existing:
        raise SystemExit(f"Refusing to overwrite existing files: {', '.join(existing)}")
    for args in sheets:
        sheet(*args)
        print(f"wrote {args[0]}")


if __name__ == "__main__":
    main()
