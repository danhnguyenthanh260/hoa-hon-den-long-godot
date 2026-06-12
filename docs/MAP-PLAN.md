# Kế hoạch bản đồ Phố cổ Hội An — theo `Screenshots/ref-11.png`

Ref-11 là sơ đồ level-concept toàn khu: 3 trục Đông-Tây (Phan Châu Trinh,
Trần Phú, Nguyễn Thái Học) + Bạch Đằng ven sông, các phố dọc (Lê Lợi, Hoàng
Văn Thụ, Nguyễn Huệ, Nguyễn Thị Minh Khai), sông Hoài, khu An Hội bờ nam,
10 công trình đánh số (Chùa Cầu, Chợ Hội An, hội quán, bến thuyền, chợ đêm…).

Quy trình mỗi phase: build → compile check → render houseview/boundary →
user duyệt → commit riêng.

## Phase 0 — Mặt tiền "thở" (fix nợ hiện tại)

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

## Phase 1 — Cây cối v3 (hết "fake")

- Tán cây/quất: bỏ quả cầu trơn → cụm 3–4 alpha-card chéo nhau (cross-plane,
  chuẩn game foliage); alpha mask sinh procedural (cellular noise threshold)
  đục lỗ viền tán cho rách tự nhiên.
- Lá chuối: mép răng cưa (taper sin dọc ribbon) + gân giữa sáng màu.
- Hue variation theo instance (±10% tint qua instance uniform).
- Bụi cỏ lá dài chân tường/chân trụ (LeafyGrass card).

## Phase 2 — Khung phố theo sơ đồ

- Thêm trục Nguyễn Thái Học (song song Trần Phú, phía nam) + Bạch Đằng ven sông.
- 2–3 phố dọc nối trục (Lê Lợi, Hoàng Văn Thụ) — dùng lại 5 mẫu nhà, ngõ hẹp hơn.
- Zone hóa theo chú giải ref-11: thương mại / ven sông / chợ-quảng trường.

## Phase 3 — Sông Hoài (8)

Mặt nước + bờ kè đá + bậc xuống nước + bến thuyền + thuyền gỗ mui cong +
đèn lồng phản chiếu mặt nước (ven sông hoạt động đêm theo ghi chú ref-11).

## Phase 4 — Chùa Cầu thật (1)

Thay silhouette hiện tại bằng mô hình đi xuyên được: cầu gỗ có mái, miếu giữa,
tượng chó/khỉ hai đầu. Giữ vai trò phong ấn chương 1.

## Phase 5 — Landmark quest (2)(4)(5)

Chợ Hội An (nhà lồng — hub đông người theo ghi chú), hội quán Phúc Kiến +
Quảng Đông (cổng tam quan màu nổi) — điểm neo quest lịch sử/tín ngưỡng.

## Phase 6 — An Hội bờ nam (10)

Cầu An Hội + dải nhà thấp bờ nam + chợ đêm đèn lồng — sân khấu lễ hội,
ánh sáng phản chiếu mặt nước (climax thị giác về đêm).

## Phase 7 — Địa hình + hoàn thiện

Độ dốc phố (ref-10), ngõ hẹp khu cầu, map lại 5 chương vào các zone mới.
