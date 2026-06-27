# Toàn bộ âm thanh sinh bằng code lúc khởi động — không file ngoài.
# Gió: brown noise lặp 8s. Đàn tranh: tổng hợp dây gảy Karplus-Strong, ngũ cung,
# gảy thưa ngẫu nhiên. Bước chân: xung nhiễu lọc thấp theo nhịp đi.
# Tim đập: gần Hồn Ma (c3). Nước vỗ: chương 4.
extends Node

const RATE := 22050

var _wind: AudioStreamPlayer
var _water: AudioStreamPlayer
var _pluck_notes: Array = []      # AudioStreamWAV các nốt đàn
var _steps: Array = []            # 4 biến thể bước chân
var _heart: AudioStreamWAV
var _pluck_timer := 3.0
var _heart_timer := 0.0
var _prev_step_phase := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 99
	# bus có vang nhẹ cho nhạc cụ
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, "Tranh")
	var reverb := AudioEffectReverb.new()
	reverb.wet = 0.35
	reverb.room_size = 0.8
	reverb.damping = 0.4
	AudioServer.add_bus_effect(idx, reverb)

	_wind = _looper(_gen_wind(), -16.0)
	_water = _looper(_gen_water(), -60.0)
	# ngũ cung Nam ai — trầm, buồn
	for f in [146.83, 174.61, 196.0, 220.0, 261.63, 293.66, 349.23]:
		_pluck_notes.append(_gen_pluck(f))
	for i in range(4):
		_steps.append(_gen_step(i))
	_heart = _gen_heart()


func _looper(stream: AudioStreamWAV, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = db
	p.autoplay = true
	add_child(p)
	p.play()
	return p


func _wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var v := int(clampf(samples[i], -1.0, 1.0) * 32000.0)
		bytes.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = samples.size()
	return w


# gió đêm: brown noise + phồng xẹp chậm (chu kỳ khớp vòng lặp để không khựng)
func _gen_wind() -> AudioStreamWAV:
	var n := RATE * 8
	var out := PackedFloat32Array()
	out.resize(n)
	var b := 0.0
	var lp := 0.0
	for i in range(n):
		b = clampf(b + (_rng.randf() - 0.5) * 0.08, -1.0, 1.0)
		lp += 0.04 * (b - lp)
		var sway := 0.55 + 0.45 * sin(TAU * i / float(n))
		out[i] = lp * 0.9 * sway
	return _wav(out, true)


# nước vỗ mạn: nhiễu lọc + nhịp sóng chậm
func _gen_water() -> AudioStreamWAV:
	var n := RATE * 6
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in range(n):
		lp += 0.1 * ((_rng.randf() - 0.5) * 0.9 - lp)
		var wave := maxf(0.0, sin(TAU * i / float(n) * 3.0))
		out[i] = lp * (0.25 + 0.75 * wave * wave)
	return _wav(out, true)


# dây gảy Karplus-Strong — tiếng gần đàn tranh
func _gen_pluck(freq: float) -> AudioStreamWAV:
	var period := int(RATE / freq)
	var buf := PackedFloat32Array()
	buf.resize(period)
	for i in range(period):
		buf[i] = _rng.randf() * 2.0 - 1.0
	var n := int(RATE * 2.2)
	var out := PackedFloat32Array()
	out.resize(n)
	var idx := 0
	for i in range(n):
		var nxt := (idx + 1) % period
		var v := (buf[idx] + buf[nxt]) * 0.5 * 0.9965
		buf[idx] = v
		out[i] = v * minf(1.0, i / 200.0)
		idx = nxt
	return _wav(out, false)


# bước chân trên gạch: hai xung nhiễu lọc thấp (gót + mũi)
func _gen_step(variant: int) -> AudioStreamWAV:
	var n := int(RATE * 0.16)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var cut := 0.12 + variant * 0.025
	for i in range(n):
		var t := i / float(n)
		var env := exp(-t * 22.0) + 0.35 * exp(-maxf(0.0, t - 0.4) * 30.0) * (1.0 if t > 0.4 else 0.0)
		lp += cut * ((_rng.randf() - 0.5) - lp)
		out[i] = lp * env * 2.2
	return _wav(out, false)


# tim đập: hai cú trống trầm
func _gen_heart() -> AudioStreamWAV:
	var n := int(RATE * 0.6)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t := i / float(RATE)
		var v := 0.0
		for t0 in [0.0, 0.22]:
			if t >= t0:
				v += sin(TAU * 52.0 * (t - t0)) * exp(-(t - t0) * 18.0)
		out[i] = v * 0.9
	return _wav(out, false)


func _play_once(stream: AudioStreamWAV, db: float, pitch: float = 1.0, bus: String = "Master") -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = db
	p.pitch_scale = pitch
	p.bus = bus
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


# sting trầm cho khoảnh khắc quyết định (C4): nốt thấp nhất hạ pitch + một cú tim đập
func sting() -> void:
	_play_once(_pluck_notes[0], -5.0, 0.5, "Tranh")
	_play_once(_heart, -7.0, 0.8)


# gọi mỗi frame từ main
func update(delta: float, m) -> void:
	# đàn tranh gảy thưa — im bặt trong nhà ký ức (c3) cho rợn
	_pluck_timer -= delta
	if _pluck_timer <= 0.0:
		_pluck_timer = _rng.randf_range(3.5, 9.0)
		if m.chapter_no != 3 and m.state != m.State.WON:
			var note: AudioStreamWAV = _pluck_notes[_rng.randi_range(0, _pluck_notes.size() - 1)]
			_play_once(note, -13.0, 1.0, "Tranh")
			if _rng.randf() < 0.3:
				await get_tree().create_timer(_rng.randf_range(0.18, 0.4)).timeout
				_play_once(_pluck_notes[_rng.randi_range(0, _pluck_notes.size() - 1)], -16.0, 1.0, "Tranh")

	# gió theo chương: ngõ vừa, sân giếng to, trong nhà nhỏ, bến sông vừa, hư không rít
	var wind_target := -16.0
	match m.chapter_no:
		2: wind_target = -12.0
		3: wind_target = -30.0
		4: wind_target = -15.0
		5: wind_target = -10.0
	_wind.volume_db = lerpf(_wind.volume_db, wind_target, 1.0 - pow(0.3, delta))
	_water.volume_db = lerpf(_water.volume_db, -14.0 if m.chapter_no == 4 else -60.0, 1.0 - pow(0.3, delta))

	# bước chân: bắt pha nhún của người chơi
	if m.is_play():
		var phase: float = sin(m.player._anim_t)
		if m.player._gait > 0.4 and _prev_step_phase <= 0.0 and phase > 0.0:
			_play_once(_steps[_rng.randi_range(0, 3)], -11.0, _rng.randf_range(0.92, 1.08))
		if m.player._gait > 0.4 and _prev_step_phase >= 0.0 and phase < 0.0:
			_play_once(_steps[_rng.randi_range(0, 3)], -12.5, _rng.randf_range(0.92, 1.08))
		_prev_step_phase = phase

	# tim đập khi thứ-gì-đó lại gần
	_heart_timer -= delta
	var threat := 99.0
	var ch = m.current_chapter()
	var g = ch.get("ghost")
	if g != null and g.visible:
		threat = m.player.position.distance_to(g.position)
	if threat < 6.0 and _heart_timer <= 0.0:
		var urgency := clampf(1.0 - threat / 6.0, 0.0, 1.0)
		_heart_timer = lerpf(1.1, 0.45, urgency)
		_play_once(_heart, lerpf(-18.0, -6.0, urgency), lerpf(0.9, 1.15, urgency))
