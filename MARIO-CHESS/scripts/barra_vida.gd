extends Control
# Barra de vida estilo juego de peleas: retrato circular + barra inclinada.
# Se dibuja por código. Si "icono" es null, muestra la inicial del personaje.

const RADIO := 46.0            # radio del retrato
const ALTO_BARRA := 32.0
const INCLINACION := 20.0      # cuánto se inclina la barra

var maximo: float = 1.0
var valor: float = 1.0:
	set(v):
		valor = v
		queue_redraw()
var color_equipo := Color(0.3, 0.65, 1.0)
var espejo := false            # true = retrato a la derecha (jugador 2)
var icono: Texture2D = null
var inicial := "?"

func _init() -> void:
	custom_minimum_size = Vector2(420, RADIO * 2.0 + 12.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

# Refleja la coordenada X cuando el panel va a la derecha
func _x(x: float) -> float:
	return size.x - x if espejo else x

# Franja inclinada entre dos X y dos Y (y0/y1 = altura de referencia de la barra)
func _franja(xa: float, xb: float, ya: float, yb: float, y0: float, y1: float) -> PackedVector2Array:
	var oa: float = INCLINACION * (y1 - ya) / (y1 - y0)
	var ob: float = INCLINACION * (y1 - yb) / (y1 - y0)
	return PackedVector2Array([
		Vector2(_x(xa + oa), ya), Vector2(_x(xb + oa), ya),
		Vector2(_x(xb + ob), yb), Vector2(_x(xa + ob), yb),
	])

func _draw() -> void:
	var cy: float = size.y / 2.0
	var cx: float = RADIO + 6.0
	var y0: float = cy - ALTO_BARRA / 2.0
	var y1: float = cy + ALTO_BARRA / 2.0
	var xa: float = cx + RADIO * 0.5
	var xb: float = size.x - 6.0 - INCLINACION

	# Marco negro y fondo oscuro
	draw_colored_polygon(_franja(xa - 4.0, xb + 4.0, y0 - 4.0, y1 + 4.0, y0, y1), Color.BLACK)
	draw_colored_polygon(_franja(xa, xb, y0, y1, y0, y1), Color(0.12, 0.12, 0.12))

	# Relleno según la vida
	var r: float = 0.0
	if maximo > 0.0:
		r = clampf(valor / maximo, 0.0, 1.0)
	if r > 0.0:
		var color := Color(0.1, 0.85, 0.3)
		if r <= 0.25:
			color = Color(0.9, 0.15, 0.15)
		elif r <= 0.5:
			color = Color(0.95, 0.75, 0.1)
		var xr: float = xa + (xb - xa) * r
		draw_colored_polygon(_franja(xa, xr, y0, y1, y0, y1), color)
		draw_colored_polygon(_franja(xa, xr, y0, cy, y0, y1), Color(1, 1, 1, 0.25))   # brillo

	# Retrato circular
	var c := Vector2(_x(cx), cy)
	draw_circle(c, RADIO + 5.0, Color.BLACK)
	draw_circle(c, RADIO + 2.0, color_equipo)
	draw_circle(c, RADIO - 1.0, Color(0.1, 0.1, 0.14))
	if icono != null:
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		var rr: float = RADIO - 3.0
		for k in 40:
			var d := Vector2(cos(TAU * k / 40.0), sin(TAU * k / 40.0))
			pts.append(c + d * rr)
			uvs.append(Vector2(0.5, 0.5) + d * 0.5)
		draw_colored_polygon(pts, Color.WHITE, uvs, icono)
	else:
		draw_string(ThemeDB.fallback_font, Vector2(c.x - RADIO, c.y + 17.0), inicial,
			HORIZONTAL_ALIGNMENT_CENTER, RADIO * 2.0, 48, Color.WHITE)
