# Họa Hồn Đèn Lồng (Soul Painter) — Godot 4.5

Game phiêu lưu kể chuyện, tương tác nhẹ (~15-25 phút) bối cảnh phố cổ Hội An trong
đêm bị bóng tối nuốt ký ức. Kinh dị tâm linh nhẹ, logic giấc mơ. Chủ yếu đi khám phá
và cảm nhận không khí. Toàn bộ scene dựng bằng GDScript thuần — texture sinh
procedural, không asset ngoài.

**Cách chơi cốt lõi:** đi khám phá → tìm vật → đổi đúng màu đèn Ngũ Hành (phím 1-5)
→ bấm E.

**Mô tả gameplay:** [docs/GAME-PLAY.md](docs/GAME-PLAY.md) — lối chơi, điều khiển,
5 chương, Ngũ Hành, các kết.

## Chạy game

```powershell
.\tools\Godot_v4.5-stable_win64_console.exe --path .
```

(Godot 4.5 nằm sẵn trong `tools/`, không commit vào git. Hoặc mở `project.godot` bằng editor → F5.)

## Điều khiển

| Phím | Hành động |
|------|-----------|
| W A S D · chuột | Di chuyển · nhìn quanh |
| E / Space | Tương tác · tua thoại |
| 1-5 | Đổi màu đèn Ngũ Hành (Hỏa·Thủy·Mộc·Kim·Thổ — mở khóa dần) |
| V | Đổi góc nhìn camera |
| M | Bản đồ |
| R | Chơi lại (sau khi kết thúc) |

## 5 chương — mỗi Sắc một công dụng rõ

Lối chơi mọi chương giống nhau: **đi khám phá → tìm vật → đổi đúng màu đèn → bấm E.**

1. **Ngõ Không Tên** (Hỏa) — rót trà mời bà hàng nước để nhận chìa · ghép bức Chim Lạc bị xé · **Sắc Hỏa (1)** đốt rào tơ nhện, xuống hầm
2. **Giếng Đôi** (Thủy) — đứa trẻ không bóng · soi giếng bắt radio nói dối · nhận **Sắc Thủy (2)** + đóa sen · thả sen trả lễ để mở cổng
3. **Nhà Ký Ức** (Mộc) — nhà trong to hơn ngoài · **Sắc Mộc (3)** mọc thang dây leo lên gác · đứng đúng chỗ cho bóng ghép thành hình → ảnh thờ lật
4. **Bến Sông Ngược** (Kim · Thổ) — thắp 2 chuông, nghe người chèo đò giải oan · đắp mộ gió: **Sắc Thổ (5)** đắp đất, **Sắc Kim (4)** khắc tên · trả một ký ức để qua sông (lựa chọn)
5. **Chùa Cầu Treo Giữa Không** — soi 3 chứng cứ bằng đúng Sắc (mặt nước = Thủy, bài vị = Hỏa, vết nứt = Thổ) · hé lộ Minh là ai · ending

**Ngũ Hành — dùng ở đâu:** Hỏa = đốt · Thủy = nước/soi · Mộc = mọc/sống · Kim = khắc/kim loại · Thổ = đắp/neo đất.

## Kiến trúc & đồ họa

- Nhà ống Hội An: vữa vàng nghệ loang ố (texture sinh code), chân tường rêu, cột gỗ
  treo câu đối sơn ta, cửa **thượng song hạ bản**, **mắt cửa**, cửa sổ chấn song,
  ban công gỗ nhà hai tầng, mái **ngói âm dương** (MultiMesh từng hàng ống ngói),
  đòn dông + đầu đao
- Giếng cổ **vuông kiểu Bá Lễ** với khung gỗ kéo nước (C2), hoành phi - câu đối -
  bát nhang (C3), **Chùa Cầu** vòm cong, miếu giữa cầu, tượng linh thú hai đầu (C5)
- **PBR texture thật** (ambientCG, CC0): đá lát, vữa tường, gỗ ván, ngói, đất —
  đủ Color + Normal + Roughness, normal map bắt ánh đèn lồng nổi khối
- Render: Forward+, volumetric fog, glow/bloom, ACES, **SDFGI**, **SSAO**, SSR,
  tàn lửa lơ lửng (particle texture), mỗi chương một bảng màu riêng

## Ghi công

- Texture PBR: [ambientCG.com](https://ambientcg.com) — giấy phép CC0
  (Plaster001, PavingStones138, WoodFloor043, RoofingTiles013A, Ground068)
- Tượng "người giữ đèn" (cảnh kết): mesh tái tạo bằng
  [Hunyuan3D-2](https://huggingface.co/spaces/tencent/Hunyuan3D-2) (Tencent, open source)
  từ render một asset CC BY 4.0 sinh bởi Meshy — xem `scripts/gen3d.py`

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
| `scripts/bird_stencil_puzzle.gd` | Khung đèn Chim Lạc (C1) |
| `scripts/ghost.gd` | Hồn Ma Phai Nhạt — hiệu ứng không khí trong Nhà Ký Ức |
| `scripts/build.gd` | Thư viện dựng hình: ngói âm dương, mắt cửa, đèn lồng, NPC không mặt |
| `scripts/textures.gd` | Texture procedural: gạch, vữa, gỗ |
| `scripts/gen3d.py` | Ảnh → mesh 3D qua HF Space Hunyuan3D-2 (miễn phí) |
| `scripts/rig_glb.py` | Auto-rig mesh người đứng: đặt xương heuristic + trọng số da → glb skinned |
| `scripts/ghost_walker.gd` | Hồn dân phố: điều khiển xương walk cycle, đi theo waypoint |
| `scripts/game_ui.gd` | HUD, mục tiêu, bảng màu, title card, credits |

## Trần đồ họa hiện tại & đường lên tiếp

Mức "Sekiro" là asset AAA làm tay (model scan/sculpt, PBR 4K, mocap). Hình học
procedural chạm trần ở mức stylized hiện tại. Bước nhảy tiếp theo theo thứ tự hiệu quả:

1. Model nhà/nhân vật làm trong Blender (miễn phí) import `.glb` — thay primitives
2. PBR texture thật (ambientCG/PolyHaven, CC0) thay texture sinh code
3. Rig + animation cho Minh (Mixamo miễn phí cũng đủ tốt hơn code-anim)
4. Bụi/lửa bằng GPUParticles có texture, decal rêu/ố tường
