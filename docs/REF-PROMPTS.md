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
