# Kế hoạch bản đồ Phố cổ Hội An — theo `Screenshots/ref-11.png`

Ref-11 là sơ đồ level-concept toàn khu: 3 trục Đông-Tây (Phan Châu Trinh,
Trần Phú, Nguyễn Thái Học) + Bạch Đằng ven sông, các phố dọc (Lê Lợi, Hoàng
Văn Thụ, Nguyễn Huệ, Nguyễn Thị Minh Khai), sông Hoài, khu An Hội bờ nam,
10 công trình đánh số (Chùa Cầu, Chợ Hội An, hội quán, bến thuyền, chợ đêm…).

Quy trình mỗi phase: build → compile check → render houseview/boundary →
user duyệt → commit riêng.

## Phase 0 — Mặt tiền "thở" (fix nợ hiện tại) — ✅ xong 2026-06-12

Chẩn đoán (đo code 2026-06-12): mặt tiền 6m bị NHỒI — các khung dính nhau:

| Nhà | Phần tử | Vị trí z hiện tại | Khe hở |
|---|---|---|---|
| h01/h03 | khung cửa buôn | tới 1.40 | — |
| h01/h03 | viền cửa sổ trắng | 1.41 → 2.43 | **0.01m** với cửa, **0.02m** với trụ |
| h05 | khung cửa sổ | 1.40 → 2.40 | 0.05m với trụ |
| h02 | viền ô bông gió | tới 2.41 | 0.04m với trụ |

Nhà thật (ref-01/02): giữa cửa ↔ cửa sổ ↔ trụ luôn có mảng vữa 0.2–0.5m.

Sửa: cửa buôn h01/h03 rộng 2.64 → 2.3 (jamb_z 1.32 → 1.15, 4 cánh 0.55);
cửa sổ ww 0.78 → 0.62 (viền 0.86) tâm ±1.84 → hai khe đều ~0.18m;
h05 khung 1.0 → 0.9 tâm ±1.85; h02 ô bông gió 1.15 → 1.05 tâm ±1.76;
ô gió lanh tô 2.2 → 2.0. Render boundary12/34 + door* đối chiếu.

## Phase 1 — Cây cối v3 (hết "fake") — ✅ xong 2026-06-12

- Tán cây/quất: bỏ quả cầu trơn → cụm 3–4 alpha-card chéo nhau (cross-plane,
  chuẩn game foliage); alpha mask sinh procedural (cellular noise threshold)
  đục lỗ viền tán cho rách tự nhiên.
- Lá chuối: mép răng cưa (taper sin dọc ribbon) + gân giữa sáng màu.
- Hue variation theo instance (±10% tint qua instance uniform).
- Bụi cỏ lá dài chân tường/chân trụ (LeafyGrass card).

## Phase 2 — Khung phố theo sơ đồ — ✅ xong 2026-06-12

Điều kiện đặt: tất cả geometry tại |x|>11 để tránh hành lang ngõ (|x|≤5) và tường C2 (x=±8).

| Trục | z/x | Chi tiết |
|---|---|---|
| Nguyễn Thái Học north row | z=-28.5 | mặt quay Nam, skip \|x\|≤11 |
| Nguyễn Thái Học south row | z=-35.0 | mặt quay Bắc, skip \|x\|≤11 |
| Lê Lợi west (mặt Đông) | x=-22 | z=-3,-9,-15,-21 |
| Lê Lợi east (mặt Tây) | x=-16 | z=-3,-9,-15,-21 |
| Hoàng Văn Thụ west (mặt Đông) | x=16 | z=-3,-9,-15,-21 |
| Hoàng Văn Thụ east (mặt Tây) | x=22 | z=-3,-9,-15,-21 |

Thêm: dây đèn NTH (4 vị trí sx) + dây đèn Lê Lợi/HVT (chạy ngang đường dọc), cây xanh tại x=±18 giữa đường NTH, chậu cảnh.
Bạch Đằng sẽ thêm trong Phase 3 (cùng sông Hoài).

## Phase 3 — Sông Hoài (8) — ✅ xong 2026-06-12

Tất cả ở |x|>9 (tránh C4 corridor |x|≤7.4, z∈[-57.4,-44.5]).

| Phần tử | Vị trí | Chi tiết |
|---|---|---|
| Bạch Đằng houses | z=-47, \|x\|>9 | 8 nhà/mặt quay Nam, body kéo bắc z=-42 |
| Nền đá lát bờ sông | |x|=9→35, z=-42→-54 | PavingStones138 |
| Bờ kè đá + lan can | z=-52.5, |x|=9→35 | tường 0.55m + 11 trụ + dải ngang |
| Bậc xuống nước | x=±18, ±26 | 4 bậc × 0.2m cao, 0.55m sâu |
| Cầu tàu gỗ | x=±20, z=-53→-65 | ván sàn 12m + 6 cọc + đèn bến |
| Mặt sông rộng | |x|=9→35, z=-58→-78 | metallic 0.93, roughness 0.04 |
| 2 thuyền mui cong | x=±25, z=-64 | 5 tấm cung + đèn + glow phản chiếu |
| 3 dây đèn qua sông | z=-60,-64.5,-69 | 9 đèn/dây, vắt full width |
| 8 hoa đăng tĩnh | flanks |x|>9 | atmospheric, C4 xử lý chuyển động giữa dòng |

## Phase 4 — Chùa Cầu thật (1) — ✅ xong 2026-06-12

Thay silhouette hiện tại bằng mô hình đi xuyên được: cầu gỗ có mái, miếu giữa,
tượng chó/khỉ hai đầu. Giữ vai trò phong ấn chương 1.

| Phần tử | Chi tiết |
|---|---|
| Mặt cầu vòm | 7 nhịp ván WoodFloor043 PBR, arch sy=0.6..1.15, span 9m |
| Lan can | tay vịn + chấn song đỏ mỗi nhịp |
| Cột đỏ | 4 cặp redcol 0.22×2.6m tại sx=±4.2, ±1.4 |
| Mái ngói | slab 11.5×4.4m + 2 dốc tile_rows + đòn nóc cyl + đầu đao |
| Miếu giữa | box gỗ 1.6×1.4×1.0 + altar_glow vàng ấm |
| Tượng | linh khuyển/linh hầu: bệ + thân + đầu + tai tại x=±5.6 |
| Đèn lồng | 5 đèn x=-4..+4, kích hoạt qua light_up() |

## Phase 5 — Landmark quest (2)(4)(5) — ✅ xong 2026-06-12

Chợ Hội An (nhà lồng — hub đông người theo ghi chú), hội quán Phúc Kiến +
Quảng Đông (cổng tam quan màu nổi) — điểm neo quest lịch sử/tín ngưỡng.

| Công trình | Vị trí | Chi tiết |
|---|---|---|
| Chợ Hội An | (-20, 0, 26) | Nhà lồng 8 cột arcade gỗ, mái ngói 2 dốc, 6 quầy, 4 đèn lồng |
| Hội quán Quảng Đông | (18, 0, 14.2) | Tam quan 3 nhịp tường cam + ngói lục, sân + chính điện 5.8m sâu |
| Hội quán Phúc Kiến | (30, 0, 14.2) | Tam quan tường đỏ son + ngói xanh, to hơn Quảng Đông |
| Dãy Bắc x≥15 | — | Bỏ trống nhường chỗ hội quán (4 căn x=15,21,27,33) |

## Phase 6 — An Hội bờ nam (10)

Cầu An Hội + dải nhà thấp bờ nam + chợ đêm đèn lồng — sân khấu lễ hội,
ánh sáng phản chiếu mặt nước (climax thị giác về đêm).

## Phase 7 — Địa hình + hoàn thiện

Độ dốc phố (ref-10), ngõ hẹp khu cầu, map lại 5 chương vào các zone mới.
