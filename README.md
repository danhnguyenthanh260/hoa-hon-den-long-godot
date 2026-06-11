# Họa Hồn Đèn Lồng — bản Godot (Demo "Ngõ Nhỏ")

Game phiêu lưu giải đố bối cảnh phố cổ Hội An, làm bằng **Godot 4.5** (Forward+).
Toàn bộ scene dựng bằng GDScript thuần — không asset ngoài, ánh sáng là nhân vật chính:
volumetric fog, bloom/glow, ACES tonemapping.

## Chạy game

Godot 4.5 đã nằm sẵn trong `tools/` (không commit vào git):

```powershell
.\tools\Godot_v4.5-stable_win64_console.exe --path .
```

Hoặc mở project bằng Godot editor (`project.godot`) rồi nhấn F5.

## Cách chơi

| Phím | Hành động |
|------|-----------|
| W A S D | Di chuyển Minh |
| E | Tương tác với đèn lồng hỏng / thoát chế độ giải đố |
| A / D (khi giải đố) | Xoay đèn cho bóng Chim Lạc khớp hình mờ trên tường |
| R (sau khi thắng) | Chơi lại |

Vòng chơi: ngõ tối → tới đèn lồng phong ấn cuối ngõ → xoay bóng Chim Lạc →
cổng mở, cả phố lên đèn → bước ra bến sông hoa đăng → thắng.

## Bot tự chơi + chụp màn hình

```powershell
.\tools\Godot_v4.5-stable_win64_console.exe --path . --resolution 1280x720 -- --autoplay
```

Bot chơi qua toàn bộ game và lưu screenshot từng giai đoạn vào `shots/` —
dùng để kiểm tra hình ảnh/regression sau mỗi lần sửa code.

## Cấu trúc code

| File | Vai trò |
|------|---------|
| `scripts/main.gd` | Máy trạng thái (intro → play → puzzle → won), camera, bot autoplay |
| `scripts/world.gd` | Môi trường: nhà phố Hội An, dây đèn lồng, cổng, bến sông hoa đăng, fog/glow |
| `scripts/player.gd` | Minh: áo dài + nón lá + sào tre gánh đèn, animation nhún/đong đưa |
| `scripts/puzzle.gd` | Cơ chế "Thắp Sáng Ký Ức" — stencil quay quanh nến, bóng đổ thật |
| `scripts/bird.gd` | Silhouette Chim Lạc (đa giác 2D → mesh) |
| `scripts/game_ui.gd` | UI: intro, HUD, lời nhắc, màn thắng, tiếng chuông ngũ cung (WebAudio-style) |

## Cơ chế bóng đổ

Ngọn nến là `OmniLight3D` có shadow. Stencil Chim Lạc là mesh phẳng quay quanh nến
ở bán kính 0.5m; tường cách nến 3m nên bóng phóng đại 6 lần. Hình mờ trên tường
chính là hình chiếu tính sẵn tại góc đúng — xoay stencil về góc 0 thì bóng trùng khít.

## Hướng phát triển tiếp (theo design doc)

- [ ] Hệ màu Ngũ Hành — bắt đầu với Hỏa (đèn đỏ đốt rào tơ nhện)
- [ ] Thanh năng lượng đèn + Vùng Tối
- [ ] Câu đố bóng 2 stencil (xoay 2 trục)
- [ ] Model nhân vật rig + animation thật (Blender)
- [ ] Texture giấy dó / gỗ lim, asset nhà chi tiết
- [ ] Nhạc nền đàn tranh + ambience phố đêm
- [ ] Màn 2: Bến Sông (đèn thả trôi kích hoạt cơ quan)
