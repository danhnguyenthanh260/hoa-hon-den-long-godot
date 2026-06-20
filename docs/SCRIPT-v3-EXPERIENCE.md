# Họa Hồn Đèn Lồng — Lớp "người chơi CẢM được" (companion của SCRIPT-v3)

> Kịch bản chứa *nghĩa*. Doc này trả lời: **làm sao nghĩa đó tới được người chơi —
> qua tay họ làm, mắt họ thấy, tai họ nghe, và cái họ *không* được cho thấy.** Nền
> tảng: 5 game tham chiếu trong `SCRIPT-RESEARCH.md` (phần B). Quy tắc vàng rút ra:
> **đừng diễn nghĩa — dựng cơ chế để người chơi tự đi tới nghĩa.**

---

## 4 NGUYÊN LÝ (vì sao "cảm" khác "biết")

**NL1 — Người chơi phải hiểu TRƯỚC Minh. Khoảng cách đó = nơi chứa toàn bộ rợn & buồn.**
*[Edith Finch + Detention + Devotion]* Không bao giờ NÓI "Minh đã chết". Để người chơi
tự ghép ra (qua gương không bóng, bài vị trống, ngấn lũ...), rồi bắt họ *nhìn Minh KHÔNG
biết điều họ đã biết*. Dramatic irony — không phải twist. Khi C5 xác nhận, người chơi đã
ôm sự thật cả tiếng đồng hồ; cú đấm là *sự nhẹ nhõm cay đắng "cuối cùng anh ấy cũng biết"*,
không phải "à hóa ra".

**NL2 — Đừng diễn cảm xúc; bắt tay người chơi LÀM nghi thức.**
*[Gris: cơ chế = cảm xúc, người chơi *enact* chứ không *quan sát*]* Mỗi lễ phải là một
*động từ người chơi bấm nút làm*, không phải cutscene. Nghĩa nằm trong cơ-bắp-ký-ức của
người chơi, không trong lời thoại.

**NL3 — Thế giới phản ứng SAI khi Minh tin vào điều sai.**
*[Detention: lore điều khiển nhận thức]* Cái sai cảm qua *ma sát tương tác*, không qua kể.
Người chơi cảm "có gì đó không ổn" trước khi đọc được nó thành chữ.

**NL4 — Chỉ cảm mất mát khi đã GÂY DỰNG quan hệ cụ thể trước.**
*[Spiritfarer]* Phải tốn thời gian khiến người chơi *quan tâm từng hồn một* (việc riêng,
giọng riêng, đồ vật riêng) thì lúc tiễn mới nặng. Tiễn biệt phải *được gây dựng*, không *trích xuất*.

---

## 8 CƠ CHẾ CỤ THỂ (nghĩa → kênh người chơi nhận)

### CC1 — ⭐ Tấm gương không bao giờ có Minh *(device mạnh nhất)*
**Người chơi thấy:** mọi mặt phản chiếu trong game (giếng C2, gương đồng C4, mặt sông
C4, vũng nước, mảnh gương vỡ rải khắp phố) — NPC có bóng, đồ vật có bóng, **riêng Minh
không có phản chiếu, không có bóng đổ.**
**Cảm:** người chơi tự nhận ra sau 20–30 phút, *không ai chỉ*. Tới khi đứa trẻ nói "soi
không thấy mặt" thì người chơi đã lạnh sống lưng vì *chính họ cũng chưa từng thấy mặt Minh*.
**Neo:** NL1 (hiểu trước). **Chương:** cài từ C1 (vũng nước), trả ở C2/C4. **Code:** Minh
không render vào reflection probe / không cast shadow. Rẻ, hiệu quả cực cao.

### CC2 — Thắp đèn = phục hồi CHI TIẾT & KÝ ỨC của thế giới
**Người chơi làm:** vùng tối thì thế giới *trống ký ức* — tường phẳng lì, mặt NPC mờ, chữ
trên bài vị/hoành phi không đọc được. Đưa đèn lại gần → texture hiện ra, mặt NPC *một phần*
thành hình, chữ trở nên đọc được.
**Cảm:** "thắp đèn = nhớ lại" thành thứ *sờ được*, không phải ẩn dụ nói suông. Đúng nguồn
*[ánh sáng = trí tuệ phá vô minh]*. Bóng tối nuốt phố = vô minh, người chơi *chống lại nó bằng tay*.
**Neo:** NL2 (cơ chế = nghĩa). **Code:** shader/decal reveal theo khoảng cách đèn — dùng được engine sẵn (SDFGI/đèn động đã có).

### CC3 — Người chơi TỰ TAY làm lễ (không cutscene)
**Người chơi làm:**
- **Gọi 3 hướng (hú hồn):** đứng cạnh hồn, *xoay người về 3 hướng, mỗi hướng giữ nút gọi* —
  người chơi tự thực hiện nghi thức 3 lần. *[nguồn: hú hồn gọi 3 lần 3 hướng]*
- **Nặn hình nhân / đắp mộ gió:** một thao tác đặt/nắn nhỏ cho mỗi hồn.
- **Khắc tên lên bài vị:** ở C3, game đưa người chơi *giao diện khắc tên* — nhưng với bài
  vị của Minh, **ô tên trống và không gõ được** (con trỏ nhấp nháy, không ký tự nào nhận).
**Cảm:** tới C5, người chơi đã *bấm nút làm lễ tiễn* cho 3–4 người bằng chính tay mình. Lúc
nhận ra người chưa được tiễn là Minh — và *họ không thể tự khắc tên cho Minh* — nỗi bất lực
nằm trong ngón tay họ. **Neo:** NL2. **Chương:** xuyên suốt; cao trào C3 (bài vị không gõ được).

### CC4 — NPC hỏi câu người chơi HIỂU, Minh gạt đi *(động cơ dramatic irony)*
**Người chơi nghe:** "Có ai nhang khói cho thầy không?" (C1) · "Xác thầy nằm đâu? Sao thầy
không nặn cho thầy một cái?" (C2) · ảnh thờ gánh đèn + bài vị trống (C3) · "lần trước thầy
cũng chọn vậy" (C4). **Mỗi câu Minh đều GẠT** ("bà hỏi lạ", "nước động thôi", "để mai").
**Cảm:** người chơi muốn hét "đừng gạt nữa!" — họ thấy sự thật, Minh né. Đó *chính là* nỗi
buồn, không cần nhạc bi. **Neo:** NL1. **Lưu ý:** sức mạnh nằm ở chỗ Minh LUÔN né — đừng để
Minh "gần hiểu ra" quá sớm, giữ anh mù tới C5.

### CC5 — Cắt ở ngưỡng chết (không flashback cái chết)
**Người chơi thấy:** không có cảnh hồi tưởng "Minh chết thế nào". Nhiều nhất: ở C5, một
khung giữ lại — nước dâng, cây đèn còn cháy lập lờ *trên* mặt nước đang ngập, rồi **cắt đen**.
Không animation chết, không xác.
**Cảm:** người chơi tự lấp khoảng trống → nặng hơn mọi cảnh tả. *[Edith Finch]* **Neo:** NL1.

### CC6 — Cái tên VẮNG MẶT suốt game, thành một sự kiện âm thanh ở cuối
**Người chơi nghe:** cả game, NPC chỉ gọi "thầy / thầy pháp"; nhãn thoại là "NGƯỜI GIỮ ĐÈN";
nền âm có tiếng rao, tiếng "ai gọi về" nhưng *không bao giờ có tên Minh*. Ở chiêu hồn cuối
C5: nhạc tụt xuống, *một giọng rõ cất tên Minh — lần đầu trong cả game*.
**Cảm:** vì đã thiếu cả tiếng đồng hồ, tiếng gọi tên đầu tiên *vang như chuông*. Người chơi
cảm cái "được gọi về" bằng tai. **Neo:** NL1+NL4. **Code:** kỷ luật audio + nhãn `dialogue_ui.gd`.

### CC7 — Sự LẶP LẠI nhìn thấy được (để "lần nào cũng vậy" có sức nặng)
**Người chơi thấy:** vài chi tiết *y hệt, đứng yên mãi*: mộ gió đắp dở ở bến chưa bao giờ
xong, bài vị luôn trống, ngấn lũ trên tường, hình nhân vỡ. Nếu có màn chơi-lại/hết-đêm-reset,
cho người chơi *thấy* phố xám lại y cũ.
**Cảm:** khi boss nói "lần nào cũng vậy", người chơi đã *tận mắt thấy sự bất biến* — câu đó
không phải lời khoe của boss mà là điều họ đã ngờ. **Neo:** NL3. *[Devotion/Detention]*

### CC8 — Cây đèn của Minh phản ứng theo sự thật *(gắn cơ thể vào twist)*
**Người chơi thấy:** đèn của Minh là ngọn duy nhất *không bao giờ tắt* (mọi đèn khác phụt
tắt một nhịp ở các beat rợn). Càng về cuối, khi Minh đứng gần một sự thật (bài vị, gương,
mộ gió dở), **lửa trong đèn khẽ chao như sắp tắt rồi gượng lại.**
**Cảm:** trước khi C5 nói "cây đèn là chính mạng anh", người chơi đã *cảm thấy* mối dây giữa
đèn và Minh qua hành vi của ngọn lửa. **Neo:** NL2 *[đèn = sinh mệnh vô thường — nguồn]*.

---

## CUNG CẢM XÚC — người chơi nên cảm gì ở mỗi chặng

| Chặng | Người chơi BIẾT | Người chơi CẢM | Kênh chính |
|---|---|---|---|
| C1 Ngõ | "có gì đó sai-chỗ" (than đỏ 20 năm, ngấn lũ) | tò mò + chớm bất an | môi trường, CC4 |
| C2 Giếng | "Minh cũng không soi thấy mặt" → ngờ vực | rợn lạnh, *nghi Minh* | CC1 (đỉnh), CC3 |
| C3 Nhà | "đây là nhà/xưởng của Minh; ảnh thờ là anh" | gần như chắc; sợ thay cho Minh | CC3 (bài vị không gõ), CC2 |
| C4 Bến | "Minh sắp phải chọn liên quan đường-về của mình" | thắt ruột, dồn nén | lựa chọn, CC1, CC7 |
| C5 Cầu | xác nhận + Minh cuối cùng cũng biết | vỡ òa: thương + nhẹ nhõm cay đắng | CC5, CC6, CC8 |
| Kết | "vẽ hồn mình vào đèn" | bình an (siêu thoát) / hy vọng (vòng lặp) | CC6, ánh sáng |

> Mục tiêu: tới C5, người chơi **không học được thông tin mới** — họ chỉ *thấy Minh cuối
> cùng cũng tới chỗ mình đã đứng từ lâu*. Đó là khác biệt giữa "biết" và "cảm".

---

## ƯU TIÊN TRIỂN KHAI (rẻ → đắt)

1. **Rẻ, hiệu quả cao — làm trước:** CC1 (gương/bóng), CC4 (thoại gạt — chỉ là viết), CC6
   (nhãn "NGƯỜI GIỮ ĐÈN" + kỷ luật tên), CC7 (chi tiết bất biến). Phần lớn là *viết & cấu hình*.
2. **Vừa:** CC3 (thao tác làm lễ + bài vị không gõ được), CC8 (lửa đèn chao), CC5 (khung giữ + cắt đen).
3. **Đắt hơn:** CC2 (shader reveal theo đèn) — nhưng engine đã có đèn động + SDFGI, có thể làm tối giản (reveal mặt NPC + chữ là đủ, không cần cả thế giới).

**Nguyên tắc bao trùm:** ở đâu phân vân giữa *nói ra* và *để người chơi tự thấy* — luôn chọn
để họ tự thấy. Niềm tin vào người chơi chính là thứ tạo ra "cảm".
