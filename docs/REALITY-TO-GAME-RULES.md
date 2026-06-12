# Reality-to-game translation rules — Hội An landmarks

Tài liệu này là ref-36. Nó ghi rõ **cái gì phải giữ đúng** và **cái gì được
simplify** khi dịch kiến trúc thật ngoài đời sang game asset Godot 4.5.

Confidence notation: ★ = tài liệu hóa được / đo được; ◇ = ước lượng từ ảnh;
△ = suy luận từ typology; không ký hiệu = game design choice (không cần thật).

---

## Nguyên tắc tổng quát

### Phải giữ đúng (Must-hold)
- **Silhouette đặc trưng** đọc ra ngay từ 20-30m (test: không nhầm với công
  trình khác).
- **Tỷ lệ chiều dài/chiều cao** của khối chính (±20% của số liệu tài liệu hóa).
- **Màu nhận dạng** tường/mái: đây là cách player phân biệt Phúc Kiến vs
  Quảng Đông từ xa.
- **Số lượng vịnh/cổng chính**: 3 cổng Phúc Kiến, 3 vịnh arcade Chợ, vv.
- **Collision path đi qua được** ở những chỗ thật có thể đi qua.

### Được phép simplify
- **Số cột bên trong** (thực tế nhiều, game dùng ½ hoặc ⅓, miễn nhịp hợp lý).
- **Đồ án chạm khắc** chi tiết (texture/material thay cho hình học phức tạp).
- **Số lớp mái** xếp chồng (giữ 2-3 tầng mái đặc trưng, bỏ tầng 4-5 nếu có).
- **Kích thước tổng thể** có thể scale xuống ≤50% nếu cần vừa map game, miễn
  tỷ lệ tương đối giữa các phần không đổi.
- **Vật liệu nội thất** (tượng thờ, tranh, bức hoành) có thể bỏ hoặc simplify
  thành 1 object đại diện.

### Không được làm
- Đặt shrine sai vị trí so với thực tế (lỗi hiện tại: xem Chùa Cầu bên dưới).
- Dùng mái rồng Phúc Kiến cho Quảng Đông (hai công trình phải khác màu rõ ràng).
- Biến Chợ Hội An thành đền (không có tam quan, không có mái long phụng).
- Để geometry collision chặn đường đi mà thực tế người đi qua được.

---

## Chùa Cầu (Japanese Covered Bridge)

### Số liệu thật
| Thuộc tính | Giá trị | Confidence |
|---|---|---|
| Chiều dài cầu | 18 m | ★ |
| Chiều rộng hành lang | ~3 m | ★ |
| Kết cấu | Đá granite + gỗ lim | ★ |
| Số nhịp | 11 nhịp chức năng (3+5+3) | ★ |
| Mái | Ngói âm dương rust-orange, 3 đoạn mái | ★ |
| Shrine | Gắn dọc mặt BẮC tại điểm giữa nhịp | ★ |
| Tượng | Chó đá phía Nam, Khỉ đá phía Bắc | ★ |
| Màu trụ đá | Xám ấm limestone | ★ |
| Màu gỗ | Nâu chocolate (gỗ lim già) | ★ |
| Màu tường pavilion | Hồng/kem phong hóa | ★ |

### Lỗi hiện tại trong game (cần sửa khi rebuild)
1. **Shrine đặt sai**: hiện ở TRUNG TÂM nhịp như một phòng riêng. Thực tế là
   khối nhỏ GẮN VÀO MẶT BẮC (protrudes north), không ăn vào hành lang chính.
2. **Chiều dài quá ngắn**: Phase 4 code dùng span sx=±4.5 → tổng ~9m. Thật là
   18m. Cần scale lại hoặc tăng số nhịp (7 span → 11-13 span).
3. **Thiếu trụ đá**: Hiện không có stone piers dưới mực nước. Thực tế: trụ đá
   granite nhô lên khỏi lạch nước là đặc trưng silhouette quan trọng nhất.
4. **Hai pavilion hai đầu**: Hiện dùng chỉ có mái liên tục. Thực tế có 2 nhà
   bia hồng ở 2 đầu cầu (nơi đặt tượng thú), tách ra khỏi mái cầu chính.

### Game translation
- Scale game: dùng 14m thay 18m nếu cần vừa vị trí `x=-46` trên map.
- Trụ đá: `Build.box()` gray stone, nửa chìm xuống `y < 0` — visible từ bên.
- Shrine north protrusion: box ~1.4×1.0m gắn vào `z=+1.5` (cạnh Bắc), không
  chiếm chiều rộng hành lang.
- Tượng: chó `z<0` (phía Nam = Đường Trần Phú), khỉ `z>0` (phía Bắc = lạch).

---

## Hội quán Phúc Kiến (Fujian Assembly Hall)

### Số liệu thật
| Thuộc tính | Giá trị | Confidence |
|---|---|---|
| Diện tích tổng | 2,500 m² | ★ |
| Chiều sâu (Trần Phú → Phan Châu Trinh) | ~120 m | ★ |
| Chiều ngang | ~20-25 m | ◇ |
| Cổng tam quan | 3 vịnh vòm, tầng 2, 3 tầng mái | ★ |
| Màu tường | Đỏ son / hồng đậm | ★ |
| Màu ngói | Rust-orange, glazed ceramic | ★ |
| Sân trong | 4 sân, trục thẳng | ★ |
| Tượng | Sư tử đá đỏ 2 bên cổng | ★ |
| Cửa chính | Sơn đỏ lacquer + gỗ lim | ★ |

### Lỗi hiện tại trong game (cần sửa khi rebuild)
1. **Cổng chưa đủ 3 vòm rõ ràng**: Hiện code `_build_hoi_quan()` dùng 3 cổng
   vòm nhưng nhìn từ xa chưa đọc ra tam quan kinh điển (center wider + 3 tầng
   mái chồng lên).
2. **Thiếu chiều sâu sân**: Hiện chỉ có facade, không có sân trước thấy được.

### Game translation
- Chiều rộng game: giữ ~12m facade (⅗ thực), sâu 6-8m thấy được.
- Bắt buộc: center bay rộng hơn 2 cánh ≥1.5×. Tầng mái 1 rộng nhất, tầng 3
  hẹp nhất — cần thấy 3 nếp mái từ góc camera thông thường.
- Màu tường: `Color(0.70, 0.12, 0.09)` giữ đúng.

---

## Hội quán Quảng Đông (Cantonese Assembly Hall)

### Số liệu thật
| Thuộc tính | Giá trị | Confidence |
|---|---|---|
| Diện tích tổng | ~1,500-2,000 m² | ◇ |
| Cổng | 3 vòm, 1 tầng mái (ít tầng hơn Phúc Kiến) | ◇ |
| Màu tường | Ochre / vàng cam | ★ |
| Màu ngói | Xanh lục / green glazed | ★ |
| Vật liệu cột | Gỗ lim + đá hoa cương (marble) | ★ |
| Đỉnh nóc | Rồng tranh châu ("Two Dragons Competing") | ★ |
| Sân | Có sân trước + đài phun rồng phía sau | ★ |

### Lỗi hiện tại trong game (cần sửa khi rebuild)
1. **Màu ngói sai**: Hiện dùng tile màu tối. Thực tế: **green glazed** — đây là
   điểm nhận dạng quan trọng nhất phân biệt với Phúc Kiến.
2. **Không có đỉnh rồng**: Ridge sculpture "Lưỡng Long Tranh Châu" chưa có.

### Game translation
- Màu tường `Color(0.72, 0.42, 0.12)` — giữ.
- Màu ngói: đổi sang `Color(0.18, 0.50, 0.22)` (green glazed). QUAN TRỌNG.
- Ridge cyl đỉnh nóc: thêm 2 cyl nhỏ uốn cong vào tâm (đại diện rồng đối mặt).

---

## Chợ Hội An (Central Market Hall)

### Số liệu thật
| Thuộc tính | Giá trị | Confidence |
|---|---|---|
| Biên giới | 4 đường (Trần Phú/Bạch Đằng/Trần Quý Cáp/Tiểu La) | ★ |
| Màu tường ngoài | Vàng mù tạt (mustard yellow) | ★ |
| Kết cấu | Khung sắt thực dân Pháp, trần vòm | ★ |
| Arcade | 9-11 vịnh vòm lặp đều dọc mặt tiền | ◇ |
| Gable trung tâm | Clock/dormer nhỏ ở giữa mái dài | ◇ |
| Cột | Sắt/bê tông, màu vàng | ★ |
| Mái | Ngói đỏ nâu, 1 lớp (không phải mái chồng kiểu đền) | ★ |

### Lỗi hiện tại trong game (cần sửa khi rebuild)
1. **Arcade chưa đủ**: Hiện chỉ có 8 cột arcade. Cần 9-11 vịnh vòm **lặp đều**
   và **đọc ra nhịp điệu arcade từ xa** — đây là silhouette chính của chợ.
2. **Mái chưa đúng typology**: Hiện gần giống mái đền. Cần mái dài liên tục
   (barrel/gable), không có long phụng/đầu đao như đền.
3. **Thiếu awning**: Canvas awnings treo ngoài arcade là visual identity quan
   trọng (phân biệt chợ vs đền).
4. **Màu chưa đủ vàng**: Phải đọc ra **vàng mù tạt** (mustard), không phải cam.

### Game translation
- Arcade: `for i in range(10): Build.box() vòm` — đặt đều, vòm bán nguyệt.
- Mustard yellow: `Color(0.82, 0.72, 0.22)` cho tường. Không pha cam.
- Awning: box phẳng xiên nhẹ ra phía trước arcade, màu canvas (`Color(0.6,
  0.55, 0.45, 0.85)`).
- Mái: gable liên tục, không có đầu đao cong, không có tầng mái chồng.

---

## Thứ tự rebuild được đề nghị

1. **Chùa Cầu** — sửa trụ đá + chiều dài + vị trí shrine + 2 pavilion đầu cầu
2. **Chợ Hội An** — rebuild arcade + awning + mustard yellow
3. **Quảng Đông** — sửa màu ngói xanh + đỉnh rồng
4. **Phúc Kiến** — làm rõ 3 tầng mái + center bay dominant

Mỗi bước: build → compile check → houseview render → so với ref-31..35 + ref-12..18
→ commit.
