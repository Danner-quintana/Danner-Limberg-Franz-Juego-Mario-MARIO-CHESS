extends Control
# Fondo animado del menú: cielo con sol y nubes, y un tablero de ajedrez en
# perspectiva que se desliza. Todo se dibuja por código: no necesita imágenes.

const CIELO_ARRIBA := Color(0.18, 0.42, 0.95)
const CIELO_ABAJO := Color(0.68, 0.87, 1.0)
const CASILLA_CLARA := Color(0.95, 0.95, 0.98)
const CASILLA_OSCURA := Color(0.12, 0.12, 0.2)
const FILAS := 16

var t: float = 0.0
var nubes: Array = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 9:
		nubes.append({
			"x": rng.randf(), "y": rng.randf_range(0.05, 0.38),
			"e": rng.randf_range(0.6, 1.5), "v": rng.randf_range(0.01, 0.035),
		})

func _process(delta: float) -> void:
	t += delta
	for n in nubes:
		n["x"] = fmod(n["x"] + n["v"] * delta, 1.0)
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var horizonte: float = h * 0.55

	# Cielo degradado
	draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, horizonte), Vector2(0, horizonte)]),
		PackedColorArray([CIELO_ARRIBA, CIELO_ARRIBA, CIELO_ABAJO, CIELO_ABAJO]))
	# Sol
	draw_circle(Vector2(w * 0.8, h * 0.18), 56.0, Color(1.0, 0.95, 0.55, 0.35))
	draw_circle(Vector2(w * 0.8, h * 0.18), 38.0, Color(1.0, 0.96, 0.6))
	# Nubes
	for n in nubes:
		nube(Vector2(n["x"] * (w + 400.0) - 200.0, n["y"] * h), n["e"])
	# Base del suelo (el tablero se difumina con el cielo hacia el horizonte)
	draw_rect(Rect2(0, horizonte, w, h - horizonte), CIELO_ABAJO)
	tablero(w, h, horizonte)

func nube(c: Vector2, e: float) -> void:
	var blanco := Color(1, 1, 1, 0.93)
	draw_circle(c + Vector2(-30, 8) * e, 22.0 * e, blanco)
	draw_circle(c + Vector2(0, 0) * e, 30.0 * e, blanco)
	draw_circle(c + Vector2(32, 5) * e, 24.0 * e, blanco)
	draw_circle(c + Vector2(58, 12) * e, 16.0 * e, blanco)
	draw_rect(Rect2(c + Vector2(-48, 10) * e, Vector2(120, 20) * e), blanco)

func tablero(w: float, h: float, horizonte: float) -> void:
	var alto: float = h - horizonte
	var desplaz: float = t * 0.5
	var base: int = int(floor(desplaz))
	var frac: float = desplaz - float(base)
	for r in FILAS:
		var t0: float = float(r) / FILAS
		var t1: float = float(r + 1) / FILAS
		var y0: float = horizonte + alto * pow(t0, 1.8)
		var y1: float = horizonte + alto * pow(t1, 1.8)
		var ws0: float = 0.5 * (y0 - horizonte) + 16.0
		var ws1: float = 0.5 * (y1 - horizonte) + 16.0
		var n: int = int(w * 0.5 / ws0) + 2
		var fade: float = clampf(pow(t0, 0.6) * 1.3, 0.0, 1.0)
		for c in range(-n, n):
			var cc: float = float(c) - frac
			var col: Color = CASILLA_OSCURA if (c + r + base) % 2 == 0 else CASILLA_CLARA
			col = CIELO_ABAJO.lerp(col, fade)
			draw_colored_polygon(PackedVector2Array([
				Vector2(w * 0.5 + cc * ws0, y0), Vector2(w * 0.5 + (cc + 1.0) * ws0, y0),
				Vector2(w * 0.5 + (cc + 1.0) * ws1, y1), Vector2(w * 0.5 + cc * ws1, y1),
			]), col)
