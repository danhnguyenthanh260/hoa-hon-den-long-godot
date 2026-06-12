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

## Phase 6 — An Hội bờ nam (10) — ✅ xong 2026-06-12

Cầu An Hội + dải nhà thấp bờ nam + chợ đêm đèn lồng — sân khấu lễ hội,
ánh sáng phản chiếu mặt nước (climax thị giác về đêm).

| Phần tử | Vị trí | Chi tiết |
|---|---|---|
| Cầu An Hội | x=22, z=-52.5↔-82 | 6 nhịp gỗ vòm hump, lan can, 7 đèn lồng, 3 đôi cọc |
| Bờ kè bờ nam | z=-82, 48m ngang | PavingStones138 + thành kè 0.45m |
| 6 nhà thấp | z=-90, x=-15..+15 | Mặt quay Bắc (nhìn ra sông) |
| Chợ đêm | z=-87.5, 6 gian | 6 màu sắc xen kẽ, awning, glow nội |
| 3 dây đèn | z=-87,-90,-93.5 | 9 đèn/dây E-W, vào _string_lanterns |
| Glow phản chiếu | z=-82.4 | 6 emis disc cạnh bờ nam hắt lên mặt sông |

## Phase 7 — Địa hình + hoàn thiện — ✅ xong 2026-06-12

Độ dốc phố (ref-10), ngõ hẹp khu cầu, map lại 5 chương vào các zone mới.

| Phần tử | Vị trí | Chi tiết |
|---|---|---|
| Thềm đá nâng (ref-10) | Trần Phú 2 dãy | Dãy Bắc z=13.7→14.25 (x=-37.5..14.5), dãy Nam z=7.95→8.45 hai bên miệng ngõ — cao 0.14m, đăng ký floor, chậu cảnh dời lên thềm |
| Ngõ hẹp khu cầu | x=-38.45→-40.75, z=9.4/12.6 | 2 vách vữa 3.4m + mũ gỗ + rêu chân, cổng trụ + lanh tô + mái ngói + đèn lồng (_hanging) tại x=-38.6, bậc đá ngưỡng cổng |
| Clamp mở rộng | x tới -40.55, z∈[9.95,12.05] | Lách qua sương tới chân cầu; ván cầu vẫn phong ấn (interact "Chân Chùa Cầu" trong c1) |
| Zone địa lý | pho_dem / ngo_cau | `update_zone_geo()` chạy mỗi frame khi chapter 1 + sau light_up: ngõ=c1_lit, phố=pho_dem (ấm), khu cầu=ngo_cau (sương đặc lạnh) |
| Map 5 chương | — | C1 ngõ+phố (geo zones), C2 giếng z=-28..-43 (zone c2), C3 nhà ký ức x=60 (c3), C4 bến sông Phase-3 (c4), C5 cầu treo y=40 (c5) — C2-C5 giữ zone riêng, geo chỉ chạy ở C1 |
| Fix biên | clamp_alley | \|x\|>5.5 luôn xử lý theo phố — hết giật ngang khi lọt biên z=8 trên thềm Nam |

## Phase 8 — Mở phố đi được + tàn tích — ✅ xong 2026-06-12

Phản hồi user: map mở rộng phải ĐI ĐƯỢC; vùng không đi được phải đọc ra là đổ
nát/phong ấn chứ không phải khoảng trống. Mạng phố mở khóa sau `light_up()`
(phố thức dậy) — trước đó vẫn bị chặn tại z=8.4 như cũ.

| Phần tử | Vị trí | Chi tiết |
|---|---|---|
| Giao lộ TP→Lê Lợi/HVT | lot ±21 dãy Nam Trần Phú | Bỏ 2 nhà, thềm Nam tách 4 đoạn hở miệng, guard z=8.4 miễn trừ miệng giao lộ |
| 3 nhà tàn tích | NTH Bắc ±21, NTH Nam -21 | `_ruin_house()`: 2 mảng mặt tiền đứng (cửa sập = lối xuyên), tường hồi gãy bậc, xà cháy, gạch vụn, ngói sập, cỏ dại |
| Hẻm Bạch Đằng | lot -21, z -42..-47 | 2 vách hồi + rêu + đèn lồng giăng (_hanging) — xuống bến sông |
| Mạng ROAM_RECTS | 16 rect | TP↔LL↔NTH-tây↔band↔hẻm↔bờ sông tây; TP↔HVT↔NTH-đông; `_roam_clamp()` kẹp về điểm gần nhất trong union |
| Bờ sông đi được | x -35.5..-9.3, z -42..-52.1 | Nền đá Phase 3 đăng ký floor y=0.075 (nc — không tính sát thềm nhà) |
| Sương biên mới | NTH ±37, sông -36.8 | `_mist()` helper (refactor từ mist Trần Phú) |
| Zone bo_song | z<-39.5 | Trăng xanh mặt nước đen; update_zone_geo thêm nhánh roam |
| 3 interact C1 | tàn tích/tường C2/bờ sông | Độc thoại: bóng tối "nhai" nhà, tường C2 vữa còn ấm, hoa đăng trôi ngược |
| Fix trigger C2 | c1.update | Thêm điều kiện \|x\|<5.5 — đi dạo Lê Lợi/NTH z<-23 không còn nhảy chương |

Còn chờ ảnh ref đợt 2 (docs/REF-PROMPTS.md → Screenshots/ref-12..18): rebuild
Chùa Cầu + 2 hội quán + chợ theo kiến trúc thật, asset tàn tích theo ref-17.
