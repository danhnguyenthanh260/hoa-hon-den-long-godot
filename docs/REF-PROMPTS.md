# Prompt sinh ảnh ref kiến trúc — đợt 2 (ref-12 → ref-18 + bản vẽ *bp)

Đưa từng prompt cho Codex/image-gen, lưu kết quả ĐÚNG TÊN FILE vào:

```
D:\Coding_learning\hoa-hon-den-long-godot\Screenshots\
```

PNG hoặc JPG đều được (đổi đuôi tên khớp), khổ ngang, ≥1280px cạnh dài.

Mỗi công trình cần 2 LOẠI ảnh, vai trò khác nhau:

1. **Ảnh photo (ref-NN)** — không khí, vật liệu, màu, độ phong hóa.
2. **Bản vẽ kiến trúc (ref-NNbp)** — BLUEPRINT để dựng hình: các hình chiếu
   trực giao (mặt đứng / mặt bên / mặt bằng mái / mặt cắt) trên một tờ, KHÔNG
   phối cảnh. Đây là thứ Claude đo tỷ lệ để ra tọa độ box/cyl. QUAN TRỌNG:
   không yêu cầu ghi số đo (model sinh ảnh bịa số) — thay bằng **bóng người
   cao 1.7m đứng cạnh mặt đứng làm thước tỷ lệ**, Claude tự quy đổi pixel→mét.

Ảnh photo chụp ban ngày dịu (đọc khối chuẩn); riêng ref-17 chụp đêm.
Phong cách photo thống nhất với ref-01..10: photoreal, không người, không chữ.

## Khối bản vẽ blueprint (ưu tiên sinh TRƯỚC — đây là cái thiếu)

### ref-12bp.png — Chùa Cầu: bộ hình chiếu trực giao

> Architectural reference sheet of the Japanese Covered Bridge (Chua Cau) in
> Hoi An Vietnam, game-asset model sheet style on a plain white background,
> four orthographic views arranged on one sheet: full side elevation (the most
> important — showing the gentle deck arch over stone piers, roof silhouette
> with sagging ridge, shrine pavilion bump on one side), front entrance
> elevation, roof plan from above, and one cross-section through the corridor
> showing timber columns and roof framing. Clean dark linework with flat
> muted color fills (grey stone piers, dark timber, brown-grey tile roof,
> pink plaster end pavilions), accurate real-world proportions, a 1.7m human
> silhouette standing beside the side elevation for scale. Strictly
> orthographic, no perspective, no text, no dimension numbers.

### ref-14bp.png — Hội quán Phúc Kiến: tam quan trực giao

> Architectural reference sheet of the triple-arched gate of Phuc Kien
> Assembly Hall in Hoi An Vietnam, game-asset model sheet style on plain
> white background, three orthographic views on one sheet: front elevation
> (dominant — three arched openings, three stacked glazed-tile roof tiers
> with upturned ridge ends, ceramic dragon ridge ornaments), side elevation
> showing roof tier depths, and roof plan. Clean linework, flat muted fills
> (rose-red walls, green-and-ochre glazed tiles), accurate proportions, a
> 1.7m human silhouette beside the front elevation for scale. Strictly
> orthographic, no perspective, no text, no numbers.

### ref-15bp.png — Hội quán Quảng Đông: cổng trực giao

> Architectural reference sheet of the Cantonese Assembly Hall entrance gate
> in Hoi An Vietnam, game-asset model sheet style on plain white background,
> three orthographic views: front elevation (ochre-yellow walls, green glazed
> tile roof with curved ridge and ceramic figurines, granite columns), side
> elevation, roof plan. Clean linework, flat muted fills, accurate
> proportions, 1.7m human silhouette for scale. Strictly orthographic, no
> perspective, no text, no numbers.

### ref-16bp.png — Chợ Hội An: nhà lồng trực giao

> Architectural reference sheet of the long central market hall of Hoi An
> Vietnam, game-asset model sheet style on plain white background, three
> orthographic views: long street-side elevation (mustard-yellow walls,
> repeating arched arcade bays, central clock gable, red-brown tile roof),
> short end elevation, roof plan. Clean linework, flat fills, accurate
> proportions, 1.7m human silhouette for scale. Strictly orthographic, no
> perspective, no text, no numbers.

## Khối ảnh photo (không khí + vật liệu)

## ref-12.png — Chùa Cầu toàn cảnh (thay mô hình hiện tại "không giống")

> Photorealistic architectural reference photo, the Japanese Covered Bridge
> (Chua Cau, Lai Vien Kieu) in Hoi An ancient town Vietnam, full side profile
> view from across the small creek, soft overcast daylight. A low arched
> wooden covered bridge resting on heavy grey stone piers, sagging curved
> yin-yang clay tile roof, a small shrine pavilion attached at mid-span on the
> north side, weathered pink-and-cream plaster entrance pavilions at both
> ends, dark timber columns and lattice railings, moss and water stains on the
> stone base, reflection in still water. No people, no readable text, 4:3,
> sharp detail.

## ref-13.png — Chùa Cầu cận cổng + lòng cầu

> Photorealistic close-up reference, entrance pavilion of the Japanese Covered
> Bridge in Hoi An Vietnam, three-quarter view, soft daylight. Weathered pink
> plaster gate pavilion with curved tile roof, stone guardian statues (one
> stone monkey, one stone dog) on pedestals flanking the entrance steps, view
> through the open doorway down the dim timber corridor of the bridge interior
> with exposed wooden roof framing and red columns, worn wooden plank deck
> rising in a gentle arch. No people, no readable text, 4:3.

## ref-14.png — Hội quán Phúc Kiến (cổng tam quan)

> Photorealistic architectural reference, the triple-arched entrance gate of
> Phuc Kien (Fujian) Assembly Hall in Hoi An Vietnam, frontal view, soft
> daylight. Rose-pink and deep red plaster gate with three arched doorways,
> three stacked glazed tile roof tiers with upturned eaves, ceramic dragon
> ornaments on the ridges, a round moon-gate opening, stone forecourt with
> large bonsai pots, lacquered wooden doors. No people, no readable text, 4:3.

## ref-15.png — Hội quán Quảng Đông (cổng + sân)

> Photorealistic architectural reference, Cantonese Assembly Hall (Hoi Quan
> Quang Trieu) in Hoi An Vietnam, entrance gate and first courtyard,
> three-quarter view, soft daylight. Ochre-yellow and orange plaster walls,
> green glazed tile roof with curved ridge and ceramic figurines, granite
> columns carved with dragons, stone-paved courtyard with a large circular
> incense coil hanging, potted plants along the walls. No people, no readable
> text, 4:3.

## ref-16.png — Chợ Hội An (nhà lồng)

> Photorealistic architectural reference, the central market hall (Cho Hoi An)
> in Hoi An ancient town Vietnam, long single-storey yellow building seen from
> the street corner, soft morning light. Mustard-yellow plaster walls with
> arched arcade openings along the full length, red-brown clay tile roof with
> small clock gable at the center, market stalls with canvas awnings spilling
> onto the pavement, bicycles leaning on columns. No people, no readable text,
> 4:3.

## ref-17.png — Nhà phố Hội An đổ nát (asset tàn tích — chụp ĐÊM)

> Photorealistic reference, a ruined collapsed Hoi An shophouse lot at night,
> seen from the street, faint cold blue moonlight with thin mist. Broken
> mustard-yellow plaster walls standing in jagged fragments, collapsed
> yin-yang clay tile roof spilled across the floor, charred black timber beams
> leaning diagonally, piles of old brick rubble, weeds and small banana shoots
> growing through the debris, moss on the wall bases, neighboring intact house
> walls on both sides. Melancholic horror mood, no people, no readable text,
> 4:3.

## ref-18.png — Bờ kè + bậc nước + cầu tàu sông Hoài (tùy chọn, polish bến sông)

> Photorealistic reference, the Hoai river stone embankment in Hoi An Vietnam
> at dusk, view along the promenade. Low stone quay wall with short pillars,
> wide stone steps leading down to the dark water, a simple wooden boat jetty
> on timber piles, moored wooden sampan boats with curved bamboo canopies,
> strings of silk lanterns reflected in the river, yellow houses glowing on
> the far bank. No people, no readable text, 4:3.

---

Quy trình dùng: Claude đọc **bp trước** (đo tỷ lệ từ bóng người 1.7m → khung
khối chính xác), rồi áp **photo** lên để tô vật liệu/màu/độ phong hóa, dựng
xong render houseview cùng góc với ảnh để đối chiếu — như quy trình các phase
trước. Có ảnh rồi thì kêu Claude: "có ref-12..18 + bp rồi, rebuild Chùa Cầu /
hội quán / chợ theo ref".

---

# Prompt sinh ảnh ref tái dựng thực tế — đợt 3 (ref-31 → ref-36)

Đây là lớp **"measured reconstruction / reality-to-game"** — mục đích khác hẳn
ref-12..18 (không khí) và ref-19..30 (game build-spec). Lớp này phải ghi lại
**những gì công trình thật thực sự trông ra sao**, tách rõ:

- Phần đo được / tài liệu hóa được (HIGH/MEDIUM confidence)
- Phần ước lượng từ ảnh hoặc tỷ lệ tương tự (ESTIMATED)
- Phần suy luận từ typology kiến trúc (APPROXIMATED)

Mỗi sheet là **orthographic reconstruction drawing**, không phải photorealistic,
không phải concept art. Phong cách: nét vẽ kỹ thuật sạch, fills màu phẳng muted,
bóng người 1.7m cạnh mặt đứng chính làm thước tỷ lệ. Ghi chú confidence level
bằng ký hiệu ★ (HIGH) / ◇ (ESTIMATED) trên từng module.

## ref-31.png — Chùa Cầu: tái dựng mặt bằng + mặt đứng

> Architectural reality-reconstruction sheet of the Japanese Covered Bridge
> (Chua Cau / Lai Vien Kieu) in Hoi An Vietnam, measured survey drawing style on
> plain white background. Four orthographic views on one sheet: (1) full side
> elevation showing the TRUE proportions — bridge is 18 meters long and only 3
> meters wide, resting on stone piers, low sagging covered roof spanning the full
> 18m, pink-plaster pavilion at each entry end; (2) top plan showing the narrow
> 3m walkway corridor, the small shrine chamber protruding from the NORTH SIDE
> at mid-span (not at the end), stone piers beneath at both entries and under
> the canal crossing; (3) front entrance elevation showing the arched brick entry
> gate with curved tile roof above; (4) cross-section through mid-span showing
> the 3-meter interior width, timber column pairs, low covered roof framing. All
> views use clean dark linework with flat grey stone piers, dark brown timber,
> rust-orange roof tiles, pink/cream plaster. Annotate stone piers with ★,
> 18m length with ★, shrine north-side protrusion with ★, roof sag profile
> with ◇. A 1.7m human silhouette stands inside the side elevation for scale.
> Strictly orthographic, no perspective, no readable text, no dimension numbers.

## ref-32.png — Chùa Cầu: module chi tiết

> Architectural detail reconstruction sheet, Japanese Covered Bridge in Hoi An,
> drawing style on plain white background. Five detail panels on one sheet:
> (1) railing module — wave-pattern carved wooden balusters, horizontal top rail,
> show 1m section in elevation; (2) roof tile module — yin-yang convex/concave
> clay tile overlap pattern in cross-section, rust-orange color; (3) shrine
> chamber — small pavilion box protruding from north side, separate curved tile
> roof, wooden lattice door; (4) guardian statue module — stone monkey pedestal +
> body + head at south entry, stone dog at north entry, 0.9m scale; (5) stone
> pier detail — grey stone pier emerging from water with brick arch above.
> Flat muted fills, annotate each module with material identity labels
> (grey stone ★, rust-orange clay tile ★, dark ironwood ★, pink plaster ★,
> stone statue ◇). No perspective, no text, no numbers.

## ref-33.png — Hội quán Phúc Kiến: tái dựng mặt đứng cổng

> Architectural reality-reconstruction sheet of the triple-arched entrance gate
> of Phuc Kien (Fujian) Assembly Hall in Hoi An Vietnam, measured survey drawing
> style on plain white background. Three orthographic views: (1) front elevation
> — the gate is 2 storeys tall with THREE arched archways side by side, center
> bay distinctly wider and taller than flanking bays, three separate stacked
> tile roof tiers rising above, each tier narrower than the one below, upturned
> curved eave ends, ceramic dragon and phoenix ornaments on ridges; (2) side
> elevation showing roof tier depths (stacked but receding toward rear);
> (3) plan showing the three-bay plan with deep archway recesses and a forecourt
> stone floor with decorative pots. Rose-pink to deep red plaster walls ★,
> glazed rust-orange tile roofs ★, dark timber lacquered doors ★. Annotate
> triple-arch bay structure ★, stacked 3-tier roof ★, red-pink wall mass ★.
> A 1.7m human silhouette beside center arch for scale. Orthographic, no
> perspective, no text, no numbers.

## ref-34.png — Hội quán Quảng Đông: trục sân + mái

> Architectural reality-reconstruction sheet of the Cantonese Assembly Hall
> (Quang Dong / Quang Trieu) in Hoi An Vietnam, measured survey drawing style on
> plain white background. Three orthographic views: (1) longitudinal section
> through the central axis — gate → open courtyard → main hall, showing the
> spatial sequence of enclosed compound; (2) front elevation of the entrance gate
> — three-way arched gate, ochre-orange/yellow plaster walls (distinctly NOT red
> like Phuc Kien), green glazed ceramic tile roof with curved ridge and ceramic
> figurines, stone-carved arch reliefs with dragon/phoenix/unicorn ornaments;
> (3) roof plan of main hall showing the "Two Dragons Competing for a Pearl"
> ridge sculpture at apex. Flat muted fills: ochre/orange walls ★, green glazed
> tile ★, grey marble stone courtyard ◇, dark lim wood structural pillars ★.
> Annotate the color separation from Phuc Kien (ochre vs red, green vs rust tile).
> A 1.7m human silhouette beside front gate for scale. Orthographic, no
> perspective, no text, no numbers.

## ref-35.png — Chợ Hội An: module arcade + mặt tiền dài

> Architectural reality-reconstruction sheet of the Central Market Hall (Cho
> Hoi An) in Hoi An Vietnam, measured survey drawing style on plain white
> background. Three orthographic views: (1) long street-side elevation — a
> single-storey hall with 9 to 11 repeated arched arcade bays along the full
> facade, small clock gable or roof dormer at the center of the long roof,
> mustard-yellow plaster walls ★ with each arcade bay forming an arched opening,
> red-brown clay tile roof above; (2) single arcade bay module in detail —
> showing the arch proportions, column width, opening width, bay depth, with
> canvas awning hanging outside the arch; (3) plan of one market section showing
> the walkable arcade corridor inside with stall counters behind. The building
> must read as a market hall, NOT as a temple or assembly hall — no tam quan,
> no dragon ridges, no courtyard axis. Flat fills: mustard yellow walls ★, red-
> brown tile ★, canvas blue-grey awning ◇, yellow iron/concrete pillars ◇.
> A 1.7m human silhouette inside one arcade bay for scale. Orthographic, no
> perspective, no text, no numbers.

## ref-36.md — Quy tắc dịch reality → game (tạo file text, không phải ảnh)

Tạo file `docs/REALITY-TO-GAME-RULES.md` theo nội dung sau — xem tài liệu đó.

---

Quy trình đợt 3: sinh ref-31..35 trước (đo tỷ lệ từ bóng người → khung khối
chính xác hơn ref-26..30), so sánh với ref-12..18 (màu/vật liệu), sau đó rebuild
từng landmark theo thứ tự: Chùa Cầu → Phúc Kiến → Quảng Đông → Chợ.
Kêu Claude: "có ref-31..35 rồi, rebuild Chùa Cầu theo reality-to-game dossier".
