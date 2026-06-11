# Họa Hồn Đèn Lồng (Soul Painter) — Godot 4.5

Game phiêu lưu giải đố cốt truyện (~60 phút) bối cảnh phố cổ Hội An trong đêm bị
bóng tối nuốt ký ức. Kinh dị tâm linh nhẹ, logic giấc mơ. Toàn bộ scene dựng bằng
GDScript thuần — texture sinh procedural, không asset ngoài.

**Kịch bản đầy đủ:** [docs/SCRIPT.md](docs/SCRIPT.md) — 5 chương, thoại + độc thoại + twist.

## Chạy game

```powershell
.\tools\Godot_v4.5-stable_win64_console.exe --path .
```

(Godot 4.5 nằm sẵn trong `tools/`, không commit vào git. Hoặc mở `project.godot` bằng editor → F5.)

## Điều khiển

| Phím | Hành động |
|------|-----------|
| W A S D | Di chuyển |
| Shift | Đi giật lùi (có lúc phải đi như người-ở-đây đi...) |
| E / Space | Tương tác · tua thoại |
| 1-5 | Đổi màu đèn Ngũ Hành (Hỏa·Thủy·Mộc·Kim·Thổ — mở khóa dần) |
| A / D | Xoay đèn lồng / gương khi đứng gần |
| R | Chơi lại (sau khi kết thúc) |

## 5 chương — 6 loại câu đố

1. **Ngõ Không Tên** — bà hàng nước không mặt · đố bóng Chim Lạc · Sắc Hỏa đốt rào tơ nhện
2. **Giếng Đôi** — sân lặp như giấc mơ · đứa trẻ không bóng · Sắc Thủy hiện đường đá ẩn · thoát bằng đi lùi
3. **Nhà Ký Ức** — nhà trong to hơn ngoài · Hồn Ma Phai Nhạt (khắc bằng Hỏa) · Sắc Mộc mọc thang dây leo · đố bóng Hoa Sen · ảnh thờ
4. **Bến Sông Ngược** — trăng dưới đáy sông · gương đồng dẫn tia trăng (Kim) · đầm bùn cứng hóa (Thổ) · người chèo đò đòi một ký ức (lựa chọn)
5. **Chùa Cầu Treo Giữa Không** — boss Bóng Tối Thủ Cựu, 3 pha theo vòng tương khắc · reveal · ending + credits

## Kiến trúc & đồ họa

- Nhà ống Hội An: vữa vàng nghệ loang ố (texture sinh code), chân tường rêu, cột gỗ
  treo câu đối sơn ta, cửa **thượng song hạ bản**, **mắt cửa**, cửa sổ chấn song,
  ban công gỗ nhà hai tầng, mái **ngói âm dương** (MultiMesh từng hàng ống ngói),
  đòn dông + đầu đao
- Giếng cổ **vuông kiểu Bá Lễ** với khung gỗ kéo nước (C2), hoành phi - câu đối -
  bát nhang (C3), **Chùa Cầu** vòm cong, miếu giữa cầu, tượng linh thú hai đầu (C5)
- Render: Forward+, volumetric fog, glow/bloom, ACES, **SDFGI**, **SSAO**, SSR,
  hạt tàn tro lơ lửng, mỗi chương một bảng màu riêng

## Kiểm tra tự động

```powershell
# bot chụp screenshot từng chương vào shots/
.\tools\Godot_v4.5-stable_win64_console.exe --path . --resolution 1280x720 -- --autoplay

# chơi HẾT 5 chương bằng handler thật (headless, thoại tự tua) — in "FLOW OK" nếu trọn vẹn
.\tools\Godot_v4.5-stable_win64_console.exe --headless --path . -- --flow
```

## Cấu trúc code

| File | Vai trò |
|------|---------|
| `scripts/main.gd` | State machine, chương, camera, fade/title card, autoplay + flow test |
| `scripts/world.gd` | Môi trường theo zone, ngõ phố C1, nhà ống Hội An |
| `scripts/c1..c5.gd` | Nội dung + beat + câu đố từng chương |
| `scripts/player.gd` | Minh + hệ màu Ngũ Hành + animation |
| `scripts/dialogue_ui.gd` | Hộp thoại máy đánh chữ + lựa chọn + chế độ auto (test) |
| `scripts/shadow_puzzle.gd` | Đố bóng tổng quát (Chim Lạc, Hoa Sen) |
| `scripts/ghost.gd` | Hồn Ma Phai Nhạt (đèn âm nuốt sáng) |
| `scripts/build.gd` | Thư viện dựng hình: ngói âm dương, mắt cửa, đèn lồng, NPC không mặt |
| `scripts/textures.gd` | Texture procedural: gạch, vữa, gỗ |
| `scripts/game_ui.gd` | HUD, mục tiêu, bảng màu, title card, credits |

## Trần đồ họa hiện tại & đường lên tiếp

Mức "Sekiro" là asset AAA làm tay (model scan/sculpt, PBR 4K, mocap). Hình học
procedural chạm trần ở mức stylized hiện tại. Bước nhảy tiếp theo theo thứ tự hiệu quả:

1. Model nhà/nhân vật làm trong Blender (miễn phí) import `.glb` — thay primitives
2. PBR texture thật (ambientCG/PolyHaven, CC0) thay texture sinh code
3. Rig + animation cho Minh (Mixamo miễn phí cũng đủ tốt hơn code-anim)
4. Bụi/lửa bằng GPUParticles có texture, decal rêu/ố tường
