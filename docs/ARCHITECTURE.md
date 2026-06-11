# Kiến trúc nhà ống Hội An — số liệu thật → áp vào builder

## Số liệu nghiên cứu (nguồn cuối trang)

- **Lô nhà**: ngang 4–8m, sâu 10–40m, **liền kề chung tường** — phố là một dải mặt tiền
  liên tục, không có khe giữa các nhà
- **Mặt bằng** (trước → sau): vỉa hè → **hiên có mái che** → nhà chính → nhà phụ →
  hiên → **nhà cầu + sân trời** (giếng trời thoát nước, lấy sáng) → nhà sau 3 gian → vườn
- **Mái**: ngói âm dương (ngói máng), **độ dốc cao** để thoát mưa nhanh; hai lớp mái,
  đầu hồi có đầu đao
- **Vì kèo**: chồng rường - giả thủ, cột trốn - kẻ chuyền, kèo cầu - cánh ác;
  hiên dùng **vì vỏ cua** đặc trưng
- **Mặt tiền nhà buôn**: cửa ván rộng gần hết gian (tháo lắp được khi mở hàng),
  thượng song hạ bản, **mắt cửa** trên đố, vỉa hè được mái hiên che chống cột gỗ

## Đã áp vào builder (world.gd `_house`)

| Thật | Trong game |
|---|---|
| Nhà liền kề chung tường | Bước nhà = đúng bề ngang nhà → mặt tiền liên tục |
| Hiên che vỉa hè + cột hiên | Mái hiên ngói thấp (y≈2.4) vươn 1.1m + cột gỗ (nhà 1 tầng) |
| Mái dốc cao | Độ nghiêng 0.42 → 0.55 rad (~31°) |
| Thân nhà sâu | 3m → 5m (đọc đúng khối nhà ống từ góc nghiêng) |
| Cửa buôn rộng gần hết gian | Hạ bản + thượng song mở rộng 2.2m |
| Vữa mỗi nhà một sắc | Tint per-house |

## Chưa làm (cần khi mở rộng)

- Sân trời + nhà cầu (chỉ thấy khi vào trong nhà — C3 có thể dựng đúng mặt bằng này)
- Vì vỏ cua ở hiên, con tiện lan can tiện tròn
- Hai lớp mái chồng diềm

## Nguồn

- [Di tích kiến trúc nghệ thuật Đô thị cổ Hội An — Cục Di sản văn hóa](http://dsvh.gov.vn/di-tich-kien-truc-nghe-thuat-do-thi-co-hoi-an-2942)
- [Kiến trúc phố cổ Hội An — VinWonders](https://vinwonders.com/vi/wonderpedia/news/kien-truc-pho-co-hoi-an/)
- [Nhà cổ Đức An — Tạp chí Kiến Trúc](https://www.tapchikientruc.com.vn/tac-gia-tac-pham/nha-co-duc-an-hoi-an.html)
- [Kiến trúc độc đáo phố cổ Hội An — Thư viện Xây dựng](https://thuvienxaydung.net/kien-truc/kien-truc-doc-dao-o-pho-co-hoi-an.html)
