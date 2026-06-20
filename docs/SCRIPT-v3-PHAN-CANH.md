# Họa Hồn Đèn Lồng — Phân cảnh & yêu cầu giao diện (companion SCRIPT-v3)

> Bảng tra cho lúc **dựng/nâng giao diện (UI) & hình ảnh**. Mỗi beat ghép với: khung
> hình, phần tử UI cần có, **cơ chế "cảm" (CC#) mà cảnh PHẢI gánh** (xem
> `SCRIPT-v3-EXPERIENCE.md`), và **lưu ý nâng cấp cho chính xác**.
> Cột "File" trỏ tới chỗ code chạm tới, để lúc làm không bỏ sót.

**UI hiện có** *(README / game_ui.gd / dialogue_ui.gd)*: HUD · mục tiêu · bảng màu Ngũ
Hành (phím 1–5) · title card chương · credits · hộp thoại máy đánh chữ + lựa chọn.

---

## QUY ƯỚC TOÀN GAME (áp mọi cảnh — kiểm trước khi đóng từng chương)

| # | Quy ước | Cơ chế | File | Lưu ý nâng cấp |
|---|---|---|---|---|
| G1 | **Nhãn người nói = "NGƯỜI GIỮ ĐÈN"** suốt game; chỉ đổi "MINH" đúng beat chiêu hồn C5 | CC6 | `dialogue_ui.gd` | Để 1 biến `speaker_label`; đừng hardcode "Minh" rải rác. Beat C5 set cờ đổi nhãn |
| G2 | **Minh KHÔNG phản chiếu, KHÔNG đổ bóng** ở mọi mặt gương/nước/vũng | CC1 ⭐ | `player.gd`, world reflection | Loại Minh khỏi reflection probe + tắt cast shadow. Test ở MỌI mặt phản chiếu, kể cả vũng nhỏ |
| G3 | **Đèn của Minh = ngọn duy nhất không tắt**; các đèn khác phụt tắt 1 nhịp ở beat rợn | CC8 | `player.gd`, `world.gd` | Lửa đèn Minh *chao như sắp tắt rồi gượng* khi đứng gần "sự thật" (xem cột cảnh) |
| G4 | **Vùng tối = thế giới mất chi tiết** (tường phẳng, mặt NPC mờ, chữ không đọc được); đèn lại gần → hiện | CC2 | shader/decal, đèn động | Bản tối giản đủ dùng: chỉ reveal **mặt NPC + chữ (bài vị/hoành phi)**, không cần cả thế giới |
| G5 | **Bảng màu Sắc** ghi rõ Sắc nào của **Bà nào** (Năm Bà Ngũ Hành) | — | `game_ui.gd` | Xem Ghi chú #1 SCRIPT-v3 về xung đột màu (Thủy/Kim). Quyết trước khi vẽ icon bảng màu |
| G6 | Title card mỗi chương: tên chương + Hành + đổi tông bảng màu | — | `game_ui.gd` | C1 đỏ-tro · C2 xanh lạnh · C3 nâu gỗ-lục · C4 tím-bạc-kim · C5 đen-ngũ sắc |

---

## C1 — NGÕ KHÔNG TÊN (Hỏa)

| Phân cảnh | Khung hình / hình ảnh | UI | CC | Lưu ý nâng cấp | File |
|---|---|---|---|---|---|
| Mở chương | Ngõ xám tro, sương; **ngấn lũ ngang tường cao quá đầu** | Title card "C1 · Ngõ Không Tên · Hỏa" | NL3 | Ngấn lũ phải *đọc ra được* nhưng không chú thích — đặt ở tầm mắt, vài tường | `world.gd` `c1.gd` |
| Quán bà hàng nước | Bóng quay lưng, **vành nón che khoảng trống thay mặt**; than đỏ | Hộp thoại (nhãn "BÀ HÀNG NƯỚC") | NL1 | Mặt bà = vùng mờ; đèn Minh lại gần thì *một phần* mặt hiện (G4) | `c1.gd` |
| Thoại "không ai nhang khói" | — | Hộp thoại | CC4 | Beat irony: kết bằng câu hỏi bà "có ai nhang khói cho thầy?" → Minh gạt | `c1.gd` |
| Giải đố Chim Lạc | Xoay đèn, bóng khớp hình mờ trên tường | Mục tiêu + prompt xoay (A/D) | — | Prompt xoay rõ; bóng chiếu phải sắc nét để khớp dễ đọc | `shadow_puzzle.gd` |
| Nhận Sắc Hỏa + hú hồn | Đốm đỏ hiện trên than | **Bảng màu: mở khóa Sắc Hỏa (phím 1)** | CC3 | **Thao tác hú hồn:** prompt "xoay 3 hướng – giữ nút gọi"; làm 3 lần | `c1.gd` `game_ui.gd` |
| Đốt rào tơ nhện | **Tất cả đèn phụt tắt 1 nhịp** rồi sáng; vệt áo dài đen lướt sau lưng | — | CC8/G3 | Vệt áo đen = cái chết Minh lướt qua; thoáng thôi, đừng để rõ mặt | `c1.gd` |

---

## C2 — GIẾNG ĐÔI (Thủy)

| Phân cảnh | Khung hình / hình ảnh | UI | CC | Lưu ý nâng cấp | File |
|---|---|---|---|---|---|
| Mở chương | Hai giếng vuông Chăm, ánh xanh lạnh; **hình nhân đất vỡ bên thành giếng** | Title card C2 | NL3 | Hình nhân vỡ = manh mối nghề Minh; đặt thấy được khi đi ngang | `world.gd` `c2.gd` |
| Cổng gập (loop) | Qua cổng → ra lại từ cổng cũ | Mục tiêu mơ hồ | NL3 | Phải *cảm* được vòng lặp: cùng góc camera khi quay về | `c2.gd` |
| Đứa trẻ soi giếng | **Áo ướt rỏ nước dù không mưa**; chỗ mặt = vùng mờ; **không có bóng** | Hộp thoại | NL1 | Nước rỏ = đã chết đuối; chi tiết nhỏ, không nói ra | `c2.gd` |
| ⭐ Minh tự soi giếng | Dưới nước: phố cũ sáng đèn lộn ngược; **mặt Minh KHÔNG hiện** | — | **CC1 (đỉnh)** | Đây là beat then chốt CC1 — đảm bảo reflection của Minh trống *rõ ràng*, người chơi soi kỹ vẫn không thấy | `c2.gd` G2 |
| Giải đố đường nước + đi lùi | Giữ đèn Thủy hiện phiến đá; đi giật lùi qua cổng | Bảng màu: Sắc Thủy (phím 2); prompt đi lùi (Shift) | CC2 | Đèn tắt thì phiến đá biến → người chơi *cảm* "đèn = thấy được sự thật" | `c2.gd` |
| Nặn mộ gió + chiêu hồn | Minh nắn hình nhân lành, đặt bên giếng, gọi 3 hướng | Thao tác nặn/đặt + gọi 3 hướng | CC3 | Lần đầu đứa trẻ soi thấy mặt mình → trả công cho việc người chơi vừa làm | `c2.gd` |
| Đứa trẻ hỏi "xác thầy đâu?" | — | Hộp thoại | CC4 | Câu irony nặng nhất C2; Minh không đáp, đi tiếp | `c2.gd` |

---

## C3 — NHÀ KÝ ỨC (Mộc)

| Phân cảnh | Khung hình / hình ảnh | UI | CC | Lưu ý nâng cấp | File |
|---|---|---|---|---|---|
| Vào nhà | Trong rộng hơn ngoài; **dãy HÌNH NHÂN THẾ MẠNG xếp kệ** (xưởng của Minh) | Title card C3 | NL1 | Nhiều hình nhân = "đây là nhà Minh"; người chơi ghép ra trước Minh | `world.gd`/`house03.gd` `c3.gd` |
| Hồn Ma Phai Nhạt | Khoảng người bị xóa, nuốt sáng quanh nó | — | NL4 | Chiếu Hỏa = *vỗ về/trả nhận diện*, không phải "bắn". Hiệu ứng nên dịu | `ghost.gd` `c3.gd` |
| Giải đố Hoa Sen (gác) | Xoay đèn khớp bóng sen trên vách | Prompt xoay; bảng màu Sắc Mộc (phím 3) | — | — | `shadow_puzzle.gd` `c3.gd` |
| ⭐ Ảnh thờ lật + bài vị trống | Camera nhìn từ gác xuống: **ảnh người gánh đèn (dáng Minh)** + **bài vị KHẮC TÊN TRỐNG**; nến phụt tắt 1 nhịp | — | NL1/CC8 | Đừng để mặt trong ảnh quá rõ — "chưa rõ hẳn" giữ nghi vấn | `c3.gd` |
| ⭐⭐ Khắc tên bài vị | Game mở **giao diện khắc tên** — nhưng **ô trống, gõ KHÔNG vào** (con trỏ nhấp nháy, không nhận ký tự) | **UI khắc-tên (đặc biệt, chỉ ở đây)** | **CC3 (cao trào)** | Cần UI riêng: cho người chơi *thử gõ* rồi *không được* — nỗi bất lực nằm ở tương tác. Sau vài giây tự đóng, Minh thoại "để mai" | `c3.gd` + UI mới |

---

## C4 — BẾN SÔNG NGƯỢC (Kim · Thổ)

| Phân cảnh | Khung hình / hình ảnh | UI | CC | Lưu ý nâng cấp | File |
|---|---|---|---|---|---|
| Mở chương | Nước chảy ngược, hoa đăng trôi ngược; **trăng dưới đáy sông**, lỗ đen trên trời; **ma trơi lập lòe trên sông**; **mộ gió đắp dở bên bến** | Title card C4 | NL3/CC7 | Mộ gió dở = "việc Minh làm thì nước cuốn"; ma trơi = hồn lang thang. Cả hai im lặng | `world.gd` `c4.gd` |
| Minh khẽ "đi đi, về đi" | — | Hộp thoại (nghĩ) | — | Câu nói với ma trơi *[nguồn thật]* — phản xạ nghề, hé Minh quá rành việc người chết | `c4.gd` |
| Người chèo đò | Nón che khoảng trống thay mặt; **không bóng** | Hộp thoại | NL4 | Kể nỗi oan (chết oan, lật đò) — giai oan; Minh nghe hết, không ngắt | `c4.gd` |
| Giải đố gương đồng (Kim) | Dẫn tia từ trăng-dưới-nước qua 3 gương tới chuông | Prompt xoay gương; bảng màu Sắc Kim (phím 4) | CC1 | **Gương đồng cũng là mặt phản chiếu** → Minh không hiện trong gương khi đi ngang (G2) | `c4.gd` |
| Giải đố đầm bùn (Thổ) | Bùn cứng vài giây khi chiếu vàng | Bảng màu Sắc Thổ (phím 5) | — | — | `c4.gd` |
| ⭐ Lựa chọn "mặt mẹ / tên mình" | Hai lựa chọn | **Menu lựa chọn (2 nhánh)**; lưu cờ `minh_giu_ten` | — | Đây là lựa chọn DUY NHẤT có hậu quả → UI lựa chọn nên *nặng* hơn thoại thường (nhịp chậm, có thể tối nền). Lưu cờ vào state `main.gd` | `c4.gd` `main.gd` |

---

## C5 — CHÙA CẦU TREO GIỮA KHÔNG (kết)

| Phân cảnh | Khung hình / hình ảnh | UI | CC | Lưu ý nâng cấp | File |
|---|---|---|---|---|---|
| Mở chương | Chùa Cầu lơ lửng; mảnh phố trôi; **sống lưng con Cù mờ dưới sàn**; **shrine Trấn Vũ mặt Bắc tối, nhang tắt** | Title card C5 | — | Cù để mơ hồ (không chốt địa lý — nguồn). Shrine tối = nhang tắt nên Cù cựa | `world.gd` `c5.gd` |
| Boss Bóng Tối Thủ Cựu | Khối người khổng lồ kết bằng hồn bị quên; **nói bằng nhiều giọng (bà/trẻ/đò)** | Hộp thoại (nhiều giọng) | NL1 | Audio: chồng giọng các NPC đã gặp → người chơi nhận ra giọng quen | `c5.gd` |
| Trận 3 pha tương khắc | 3 pha: Thủy↔Hỏa, Hỏa↔Kim, Thổ↔Thủy | HUD chiến đấu; bảng màu | CC3 | **Mỗi pha hé 1 mảnh sự thật bằng THOẠI NGẮN** (sửa craft: đừng giải thích hết). Hình ảnh gánh phần còn lại | `c5.gd` |
| ⭐ Cắt ở ngưỡng chết | Nước dâng, **đèn còn cháy lập lờ trên mặt nước ngập, rồi CẮT ĐEN**; không xác, không animation chết | — (giữ khung + cắt đen) | **CC5** | Tuyệt đối không làm flashback cái chết. Giữ khung ~vài giây, **âm thanh nền-only** (nước, không nhạc) | `c5.gd` `main.gd` |
| Boss nhỏ lại = Minh | Bóng Tối thu thành bóng người gánh đèn; sau lưng hiện bài vị trống | — | NL1 | Khoảnh khắc xác nhận — vẫn chưa nói tên | `c5.gd` |
| ⭐⭐ Chiêu hồn (nhánh giữ tên) | Một hồn khắc nốt **tên lên bài vị**; cất tiếng gọi 3 lần 3 hướng | **Nhãn đổi "NGƯỜI GIỮ ĐÈN"→"MINH"**; bài vị hiện tên | **CC6 (đỉnh)** | Audio: **nhạc tụt, một giọng rõ cất tên Minh — lần đầu cả game**. Đây là payoff của G1+CC6 | `c5.gd` `dialogue_ui.gd` |
| Kết siêu thoát | Minh vào lòng Đèn Họa Hồn; lửa đỏ→vàng→ngũ sắc; **nhang Trấn Vũ tự bén**; phố ráp lại, hoa đăng xuôi dòng | — | — | Không reset khi sáng (khác loop) → cho người chơi *thấy* phố sáng bền | `c5.gd` |
| Kết vòng-lặp (nhánh bỏ tên) | Hồn định gọi nhưng tên không còn; **đốm sáng (cái tên) trong tay người chèo đò**; phố sáng 1 nhịp rồi xám | Nhãn vẫn "NGƯỜI GIỮ ĐÈN" | CC6 | Tương phản chủ đích: cái tên *thiếu* → im lặng chỗ lẽ ra có tiếng gọi | `c5.gd` |
| Cảnh sau cùng | Phố hội hiện tại; du khách cầm đèn cũ tự sáng; **đáy đèn có một cái tên** (rõ/mờ tùy nhánh) | Credits | CC6 | Nhánh siêu thoát: tên đọc rõ. Nhánh vòng lặp: tên mờ chưa điền | `c5.gd` `game_ui.gd` |
| Chữ cuối | "Họa hồn — vẽ hồn mình vào đèn. ...người làm những việc ấy, ai làm cho người ấy?" | Text cuối | — | — | `game_ui.gd` |

---

## CHECKLIST UI MỚI CẦN DỰNG (ngoài UI sẵn có)

1. **UI khắc-tên (C3)** — cho gõ nhưng không nhận ký tự; tự đóng sau vài giây. *(CC3, cao trào)*
2. **Prompt hú hồn "xoay 3 hướng – giữ nút gọi"** — dùng lại mọi chương Minh làm lễ. *(CC3)*
3. **Đổi nhãn người nói động** ("NGƯỜI GIỮ ĐÈN" ↔ "MINH") — cờ kích ở C5. *(CC6)*
4. **Khung giữ + cắt đen** ở beat chết, âm thanh nền-only. *(CC5)*
5. **Bảng màu gắn Năm Bà** — sau khi quyết Ghi chú #1 (màu Thủy/Kim).

## ĐÃ CÓ — CHỈ NÂNG, KHÔNG DỰNG MỚI

- Hộp thoại máy đánh chữ + lựa chọn → thêm biến `speaker_label`; menu lựa chọn C4 làm "nặng" hơn.
- Title card chương + bảng màu + credits → đổi tông màu theo chương (G6).
- HUD/mục tiêu → giữ.

> **Nguyên tắc khi nâng giao diện:** mỗi cảnh có dấu ⭐ là chỗ một cơ chế "cảm" SỐNG hoặc
> CHẾT. Làm các cảnh thường cho đúng chức năng; nhưng các cảnh ⭐ phải làm tới — vì đó là nơi
> người chơi *cảm* được, không chỉ *biết*.
