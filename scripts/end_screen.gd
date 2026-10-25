extends CanvasLayer
# End-of-game screen.
#   VICTORY: golden pixel-art trophy, twinkling stars and falling confetti.
#   DEFEAT:  pixel-art skull, red tint and rising embers.
# Everything is drawn by code, so no image files are needed.

signal play_again
signal main_menu

const EstiloMenu = preload("res://scripts/estilo_menu.gd")

# Pixel art: each letter is a color from the palette, "." is transparent
const TROPHY := [
	"................",
	".KKKKKKKKKKKKKK.",
	".KLLYYYYYYYYYDK.",
	"KKLLYYYYYYYYYDKK",
	"KYKLLYYYYYYYDKYK",
	"KYKLYYYYYYYYDKYK",
	".KKLYYYYYYYYDKK.",
	"..KKLYYYYYYDKK..",
	"...KKLYYYYDKK...",
	".....KKLYDKK....",
	"......KLDK......",
	"......KLDK......",
	".....KKLDKK.....",
	"...KKKLYYDKKK...",
	"..KLLYYYYYYDDK..",
	"..KKKKKKKKKKKK..",
]
const TROPHY_COLORS := {
	"K": Color(0.10, 0.06, 0.02), "Y": Color(1.0, 0.78, 0.15),
	"L": Color(1.0, 0.95, 0.55), "D": Color(0.85, 0.50, 0.10),
}
const SKULL := [
	"................",
	"....KKKKKKKK....",
	"..KKWWWWWWWWKK..",
	".KWWWWWWWWWWWWK.",
	".KWWWWWWWWWWWWK.",
	".KWWWWWWWWWWWWK.",
	".KWKKKWWWWKKKWK.",
	".KWKEKWWWWKEKWK.",
	".KWKKKWKKWKKKWK.",
	".KWWWWWWWWWWWWK.",
	"..KKWWWWWWWWKK..",
	"....KWWWWWWK....",
	"....KWKWWKWK....",
	"....KWKWWKWK....",
	"....KKKKKKKK....",
	"................",
]
const SKULL_COLORS := {
	"K": Color(0.08, 0.02, 0.02), "W": Color(0.92, 0.92, 0.94),
	"E": Color(1.0, 0.15, 0.10),
}
const CONFETTI_COLORS := [
	Color(0.9, 0.15, 0.15), Color(0.2, 0.5, 0.95), Color(1.0, 0.82, 0.2),
	Color(0.2, 0.75, 0.3), Color(1.0, 1.0, 1.0),
]

var victory: bool = true
var title_text: String = "VICTORY"
var accent: Color = Color(1.0, 0.78, 0.15)
var accent_dark: Color = Color(0.85, 0.5, 0.1)
var t: float = 0.0
var appear: float = 0.0
var particles: Array = []
var rng := RandomNumberGenerator.new()

var dim: ColorRect
var canvas: Control
var box: VBoxContainer
var subtitle: Label
var btn_again: Button
var btn_menu: Button

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	set_process(false)
	rng.randomize()
	build_ui()

func build_ui() -> void:
	dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP   # blocks clicks on the board
	dim.color = Color(0, 0, 0, 0)
	add_child(dim)

	canvas = Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_canvas)
	add_child(canvas)

	# Subtitle and buttons, anchored to the bottom center
	box = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.offset_top = -36.0
	box.offset_bottom = -36.0
	box.add_theme_constant_override("separation", 16)
	add_child(box)

	subtitle = Label.new()
	EstiloMenu.titulo(subtitle, 28, Color.WHITE)
	subtitle.add_theme_constant_override("outline_size", 8)
	box.add_child(subtitle)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	box.add_child(row)

	btn_again = Button.new()
	btn_again.text = "Play Again"
	EstiloMenu.boton(btn_again, EstiloMenu.VERDE)
	btn_again.pressed.connect(func(): play_again.emit())
	row.add_child(btn_again)

	btn_menu = Button.new()
	btn_menu.text = "Main Menu"
	EstiloMenu.boton(btn_menu, EstiloMenu.ROJO)
	btn_menu.pressed.connect(func(): main_menu.emit())
	row.add_child(btn_menu)

# winner = winning team (1 or 2). ai_team = team played by the AI (0 = two human players)
func show_result(winner: int, ai_team: int) -> void:
	var sub: String
	if ai_team == 0:
		victory = true
		title_text = "PLAYER %d WINS!" % winner
		sub = "Congratulations!"
	elif winner != ai_team:
		victory = true
		title_text = "VICTORY"
		sub = "You captured the enemy king!"
	else:
		victory = false
		title_text = "DEFEAT"
		sub = "Your king has fallen..."

	if victory:
		accent = Color(1.0, 0.78, 0.15)
		accent_dark = Color(0.85, 0.5, 0.1)
	else:
		accent = Color(0.92, 0.18, 0.15)
		accent_dark = Color(0.45, 0.05, 0.05)
	subtitle.text = sub

	# Initial particles
	particles.clear()
	var w: float = canvas.size.x
	var h: float = canvas.size.y
	if victory:
		for i in 90:
			spawn_confetti(Vector2(rng.randf() * w, rng.randf_range(-h, h * 0.5)))

	# Fade-in animations
	var target: Color = Color(0.02, 0.03, 0.12, 0.72) if victory else Color(0.18, 0.0, 0.0, 0.78)
	dim.color = Color(target.r, target.g, target.b, 0.0)
	create_tween().tween_property(dim, "color", target, 0.6)
	appear = 0.0
	t = 0.0
	create_tween().tween_property(self, "appear", 1.0, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	box.modulate.a = 0.0
	create_tween().tween_property(box, "modulate:a", 1.0, 0.5).set_delay(0.9)

	visible = true
	set_process(true)

func spawn_confetti(pos: Vector2) -> void:
	particles.append({
		"pos": pos,
		"vel": Vector2(rng.randf_range(-30.0, 30.0), rng.randf_range(90.0, 200.0)),
		"col": CONFETTI_COLORS[rng.randi() % CONFETTI_COLORS.size()],
		"size": rng.randf_range(6.0, 12.0),
		"ph": rng.randf() * TAU,
	})

func spawn_ember(pos: Vector2) -> void:
	particles.append({
		"pos": pos,
		"vel": Vector2(rng.randf_range(-15.0, 15.0), -rng.randf_range(40.0, 110.0)),
		"col": Color(1.0, rng.randf_range(0.15, 0.5), 0.1, rng.randf_range(0.5, 0.9)),
		"size": rng.randf_range(4.0, 9.0),
		"ph": rng.randf() * TAU,
	})

func _process(delta: float) -> void:
	t += delta
	var w: float = canvas.size.x
	var h: float = canvas.size.y
	if victory:
		if rng.randf() < delta * 40.0:
			spawn_confetti(Vector2(rng.randf() * w, -10.0))
	else:
		if rng.randf() < delta * 18.0:
			spawn_ember(Vector2(rng.randf() * w, h + 10.0))
	for p in particles:
		var np: Vector2 = p["pos"] + p["vel"] * delta
		np.x += sin(t * 2.0 + p["ph"]) * 20.0 * delta
		p["pos"] = np
	particles = particles.filter(func(p): return p["pos"].y > -60.0 and p["pos"].y < h + 60.0)
	canvas.modulate = Color(1, 1, 1, clampf(appear * 3.0, 0.0, 1.0))
	canvas.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	# While this screen is open, Esc does nothing (so the pause menu doesn't open on top)
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()

func _draw_canvas() -> void:
	var w: float = canvas.size.x
	var h: float = canvas.size.y
	var u: float = h / 648.0
	var font: Font = ThemeDB.fallback_font

	# Particles
	for p in particles:
		var s: float = p["size"] * u
		canvas.draw_rect(Rect2(p["pos"], Vector2(s, s)), p["col"])

	# Pixel-art sprite (trophy or skull)
	var rows: Array = TROPHY if victory else SKULL
	var palette: Dictionary = TROPHY_COLORS if victory else SKULL_COLORS
	var px: float = 12.0 * u
	var sprite_size: float = px * 16.0
	var x0: float = (w - sprite_size) / 2.0
	var y_target: float = 36.0 * u
	var y0: float = lerpf(-sprite_size, y_target, appear)
	if victory:
		y0 += sin(t * 2.5) * 4.0 * u                      # gentle floating
	else:
		x0 += sin(t * 35.0) * 3.0 * u * maxf(0.0, 1.0 - t)   # short shake at the start

	# Twinkling stars around the trophy
	if victory:
		for k in 10:
			var ang: float = k * TAU / 10.0 + 0.3
			var c := Vector2(w * 0.5 + cos(ang) * sprite_size * 0.95,
				y_target + sprite_size * 0.5 + sin(ang) * sprite_size * 0.7)
			var tw: float = maxf(0.0, sin(t * 3.0 + k * 1.7))
			if tw > 0.05:
				var s: float = (6.0 + 8.0 * tw) * u
				var col := Color(1.0, 0.95, 0.6, tw)
				canvas.draw_rect(Rect2(c.x - s, c.y - s * 0.25, s * 2.0, s * 0.5), col)
				canvas.draw_rect(Rect2(c.x - s * 0.25, c.y - s, s * 0.5, s * 2.0), col)

	for ry in rows.size():
		var row: String = rows[ry]
		for rx in row.length():
			var ch: String = row[rx]
			if palette.has(ch):
				canvas.draw_rect(Rect2(x0 + rx * px, y0 + ry * px, px + 0.5, px + 0.5), palette[ch])

	# Title with 3D extrusion (pops in with a bounce)
	var fs: int = int(112.0 * u)
	var text_w: float = font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	if text_w > w * 0.9:
		fs = int(fs * (w * 0.9) / text_w)
	var base_y: float = y_target + sprite_size + fs * 0.95 + 14.0 * u
	var sc: float = maxf(0.001, appear)
	canvas.draw_set_transform(Vector2(w * 0.5, base_y - fs * 0.35), 0.0, Vector2(sc, sc))
	var pos := Vector2(-w * 0.5, fs * 0.35)
	var depth: int = int(12.0 * u)
	canvas.draw_string_outline(font, pos + Vector2(0, depth), title_text, HORIZONTAL_ALIGNMENT_CENTER, w, fs, int(14.0 * u), Color.BLACK)
	for i in range(depth, 0, -1):
		canvas.draw_string(font, pos + Vector2(0, i), title_text, HORIZONTAL_ALIGNMENT_CENTER, w, fs, accent_dark)
	canvas.draw_string(font, pos, title_text, HORIZONTAL_ALIGNMENT_CENTER, w, fs, accent)
	canvas.draw_string(font, pos + Vector2(0, -3.0 * u), title_text, HORIZONTAL_ALIGNMENT_CENTER, w, fs, Color(1, 1, 1, 0.22))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
