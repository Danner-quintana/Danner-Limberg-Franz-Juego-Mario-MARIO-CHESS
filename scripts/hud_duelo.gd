extends CanvasLayer
# HUD del duelo: por jugador, retrato + barra de vida inclinada, nombre y controles.
# Los retratos se buscan en res://iconos/<Nombre>.png (ver buscar_icono).
# Se crea todo por código: no hay que añadir nodos a la escena.

const BarraVida = preload("res://scripts/barra_vida.gd")

var paneles: Array = []   # por jugador: {"caja", "nombre", "barra", "vida", "ctl"}

func _ready() -> void:
	layer = 10
	visible = false

	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["left", "right", "top"]:
		margen.add_theme_constant_override("margin_" + lado, 20)
	add_child(margen)

	var fila := HBoxContainer.new()
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(fila)

	paneles.append(crear_panel(fila, Color(0.3, 0.65, 1.0), false))   # jugador 1 (izquierda)

	var titulo := Label.new()
	titulo.text = "¡DUELO!"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	estilo_texto(titulo, 40, Color(1.0, 0.85, 0.2))
	fila.add_child(titulo)

	paneles.append(crear_panel(fila, Color(1.0, 0.4, 0.35), true))    # jugador 2 (derecha)

func estilo_texto(l: Label, tam: int, color: Color) -> void:
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)

func crear_panel(padre: Node, color: Color, espejo: bool) -> Dictionary:
	var caja := VBoxContainer.new()
	caja.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	caja.custom_minimum_size = Vector2(420, 0)
	caja.add_theme_constant_override("separation", 4)
	padre.add_child(caja)

	var alineacion := HORIZONTAL_ALIGNMENT_RIGHT if espejo else HORIZONTAL_ALIGNMENT_LEFT

	var nombre := Label.new()
	nombre.horizontal_alignment = alineacion
	estilo_texto(nombre, 26, color)
	caja.add_child(nombre)

	var barra = BarraVida.new()
	barra.color_equipo = color
	barra.espejo = espejo
	caja.add_child(barra)

	var vida := Label.new()
	vida.horizontal_alignment = alineacion
	estilo_texto(vida, 22, Color.WHITE)
	caja.add_child(vida)

	var ctl := Label.new()
	ctl.horizontal_alignment = alineacion
	estilo_texto(ctl, 17, Color(0.9, 0.9, 0.9))
	caja.add_child(ctl)

	return {"caja": caja, "nombre": nombre, "barra": barra, "vida": vida, "ctl": ctl}

# "piezaGombaRival2(peon)" -> "Gomba"; "piezaMario(rey)" -> "Mario"
func nombre_base(nombre_nodo: String) -> String:
	var base: String = nombre_nodo.trim_prefix("pieza")
	var corte: int = base.find("(")
	if corte >= 0:
		base = base.substr(0, corte)
	base = base.rstrip("0123456789").trim_suffix("Rival")
	return base

# Busca res://iconos/<Nombre>.png (también .webp, .jpg). Devuelve null si no hay.
func buscar_icono(base: String) -> Texture2D:
	for ext in ["png", "webp", "jpg"]:
		var ruta: String = "res://iconos/" + base + "." + ext
		if ResourceLoader.exists(ruta):
			return load(ruta) as Texture2D
	return null

# Prepara el panel del jugador i (0 = izquierda, 1 = derecha)
func configurar(i: int, nombre: String, vida_max: int, controles: String, nombre_nodo: String) -> void:
	var p: Dictionary = paneles[i]
	var base: String = nombre_base(nombre_nodo)
	p["nombre"].text = nombre
	p["ctl"].text = controles
	var barra = p["barra"]
	barra.maximo = float(vida_max)
	barra.valor = float(vida_max)
	barra.icono = buscar_icono(base)
	barra.inicial = base.left(1).to_upper()
	p["caja"].modulate = Color.WHITE
	actualizar(i, vida_max, vida_max)

func actualizar(i: int, vida: int, vida_max: int) -> void:
	var p: Dictionary = paneles[i]
	var barra = p["barra"]
	if float(vida) < barra.valor:
		# Destello rojo al recibir un golpe
		p["caja"].modulate = Color(1.0, 0.5, 0.5)
		create_tween().tween_property(p["caja"], "modulate", Color.WHITE, 0.3)
	create_tween().tween_property(barra, "valor", float(vida), 0.25)
	p["vida"].text = "Vida: " + str(vida) + " / " + str(vida_max)

func mostrar() -> void:
	visible = true

func ocultar() -> void:
	visible = false
