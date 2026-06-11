# Sinh texture procedural: gạch lát, vữa tường vàng nghệ loang ố, gỗ ván.
# Toàn bộ deterministic (seed cố định) để screenshot kiểm tra ổn định.
extends RefCounted


static func _rng(seed_v: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	return r


# gạch lát kiểu chữ công — nền phố Hội An
static func brick(size: int = 256) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	var r := _rng(7)
	var rows := 10
	var bh := size / rows
	var bw := bh * 2
	var shades := {}
	for y in range(size):
		var row := y / bh
		var offset := (row % 2) * (bw / 2)
		for x in range(size):
			var xx := (x + offset) % size
			var col := xx / bw
			var key := row * 100 + col
			if not shades.has(key):
				shades[key] = 0.82 + r.randf() * 0.36
			var c: Color
			if (y % bh) < 2 or (xx % bw) < 2:
				c = Color(0.21, 0.185, 0.165)
			else:
				var s: float = shades[key]
				c = Color(0.34 * s, 0.215 * s, 0.165 * s)
			var n := (r.randf() - 0.5) * 0.05
			img.set_pixel(x, y, Color(c.r + n, c.g + n, c.b + n))
	return ImageTexture.create_from_image(img)


# vữa vôi vàng nghệ loang ố thời gian
static func plaster(size: int = 256, base := Color(0.52, 0.36, 0.16)) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	var r := _rng(13)
	for y in range(size):
		for x in range(size):
			var n := (r.randf() - 0.5) * 0.06
			img.set_pixel(x, y, Color(base.r + n, base.g + n, base.b + n))
	# vết loang: ố nước, rêu mờ, vôi bạc màu
	for k in range(70):
		var cx := r.randi_range(0, size - 1)
		var cy := r.randi_range(0, size - 1)
		var rad := r.randi_range(8, 42)
		var dark := r.randf_range(-0.16, 0.10)
		var tint_g := r.randf_range(-0.02, 0.04)
		for dy in range(-rad, rad):
			for dx in range(-rad, rad):
				var d := sqrt(dx * dx + dy * dy) / rad
				if d > 1.0:
					continue
				var px := (cx + dx + size) % size
				var py := (cy + dy + size) % size
				var f := (1.0 - d) * (1.0 - d) * dark
				var c := img.get_pixel(px, py)
				img.set_pixel(px, py, Color(c.r + f, c.g + f + tint_g * (1.0 - d), c.b + f))
	return ImageTexture.create_from_image(img)


# gỗ ván nâu sậm — cửa và vách
static func wood(size: int = 256, base := Color(0.21, 0.135, 0.08)) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	var r := _rng(29)
	var plank := size / 6
	var shades := []
	for i in range(7):
		shades.append(0.8 + r.randf() * 0.4)
	for x in range(size):
		var p := x / plank
		var grain := sin(x * 0.7) * 0.03
		for y in range(size):
			var s: float = shades[p % shades.size()]
			var streak := sin(y * 0.12 + p * 3.0) * 0.025 + (r.randf() - 0.5) * 0.03
			var c := Color(base.r * s + grain + streak, base.g * s + grain * 0.7 + streak, base.b * s + streak * 0.6)
			if (x % plank) < 2:
				c = c.darkened(0.45)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)
