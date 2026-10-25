extends CanvasLayer

const EstiloMenu = preload("res://scripts/estilo_menu.gd")
const ESCENA_MENU := "res://menu_principal.tscn"

var juego: Node = null
var modo := "guardar"   # "guardar" o "cargar" (valores internos, no se muestran)

# Referencias a los nodos (se guardan antes de moverlos al panel)
@onready var oscurecer: ColorRect = $Oscurecer
@onready var botones: VBoxContainer = $Botones
@onready var ranuras: VBoxContainer = $Ranuras
@onready var lista: VBoxContainer = $Ranuras/Lista
@onready var aviso: Label = $Aviso
@onready var btn_continuar: Button = $Botones/BtnContinuar
@onready var btn_guardar: Button = $Botones/BtnGuardar
@onready var btn_cargar: Button = $Botones/BtnCargar
@onready var btn_menu: Button = $Botones/BtnMenu
@onready var btn_volver: Button = $Ranuras/BtnVolver

var panel: PanelContainer
var titulo_ranuras: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	construir_ui()
	hide()
	btn_continuar.pressed.connect(cerrar)
	btn_guardar.pressed.connect(_abrir_ranuras.bind("guardar"))
	btn_cargar.pressed.connect(_abrir_ranuras.bind("cargar"))
	btn_menu.pressed.connect(_on_menu)
	btn_volver.pressed.connect(_on_volver)

func construir_ui() -> void:
	oscurecer.color = Color(0.02, 0.04, 0.12, 0.7)

	# Panel centrado que contiene los botones, las ranuras y el aviso
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	move_child(centro, 1)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", EstiloMenu.panel_caja())
	centro.add_child(panel)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 14)
	panel.add_child(caja)
	botones.reparent(caja, false)
	ranuras.reparent(caja, false)
	aviso.reparent(caja, false)

	botones.add_theme_constant_override("separation", 12)
	ranuras.add_theme_constant_override("separation", 12)
	lista.add_theme_constant_override("separation", 10)

	var titulo: Label = botones.get_node("Titulo")
	EstiloMenu.titulo(titulo, 56, EstiloMenu.DORADO)

	titulo_ranuras = Label.new()
	EstiloMenu.titulo(titulo_ranuras, 44, EstiloMenu.DORADO)
	ranuras.add_child(titulo_ranuras)
	ranuras.move_child(titulo_ranuras, 0)

	EstiloMenu.boton(btn_continuar, EstiloMenu.VERDE)
	EstiloMenu.boton(btn_guardar, EstiloMenu.AZUL)
	EstiloMenu.boton(btn_cargar, EstiloMenu.AZUL)
	EstiloMenu.boton(btn_menu, EstiloMenu.ROJO)
	EstiloMenu.boton(btn_volver, EstiloMenu.GRIS)

	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.add_theme_font_size_override("font_size", 20)
	aviso.add_theme_color_override("font_color", EstiloMenu.DORADO)
	aviso.add_theme_color_override("font_outline_color", Color.BLACK)
	aviso.add_theme_constant_override("outline_size", 6)
	mostrar_aviso("")

func mostrar_aviso(texto: String) -> void:
	aviso.text = texto
	aviso.visible = texto != ""

func configurar(j: Node) -> void:
	juego = j

func abrir(puede_guardar: bool = true) -> void:
	get_tree().paused = true
	ranuras.hide()
	botones.show()
	btn_guardar.disabled = not puede_guardar
	btn_cargar.disabled = not GestorPartidas.hay_partidas()
	mostrar_aviso("" if puede_guardar else "Game over: saving is disabled")
	show()
	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.2)

func cerrar() -> void:
	hide()
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if ranuras.visible:
			_on_volver()
		else:
			cerrar()
		get_viewport().set_input_as_handled()

func _abrir_ranuras(m: String) -> void:
	modo = m
	botones.hide()
	ranuras.show()
	titulo_ranuras.text = "SAVE GAME" if m == "guardar" else "LOAD GAME"
	refrescar_ranuras()

func _on_volver() -> void:
	ranuras.hide()
	botones.show()

func refrescar_ranuras() -> void:
	for h in lista.get_children():
		h.queue_free()
	for i in range(1, GestorPartidas.MAX_RANURAS + 1):
		var b := Button.new()
		var hay: bool = GestorPartidas.existe(i)
		if hay:
			var d: Dictionary = GestorPartidas.cargar(i)
			b.text = "Slot %d  -  %s" % [i, d.get("fecha", "")]
		else:
			b.text = "Slot %d  -  Empty" % i
		if modo == "cargar":
			b.disabled = not hay
			b.pressed.connect(_cargar_de.bind(i))
		else:
			if hay:
				b.text += "  (overwrite)"
			b.pressed.connect(_guardar_en.bind(i))
		EstiloMenu.boton(b, EstiloMenu.AZUL)
		lista.add_child(b)

func _guardar_en(n: int) -> void:
	if GestorPartidas.guardar(n, juego.datos_de_partida()):
		mostrar_aviso("Game saved in slot %d" % n)
	else:
		mostrar_aviso("Could not save the game")
	refrescar_ranuras()

func _cargar_de(n: int) -> void:
	GestorPartidas.ranura_a_cargar = n
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(ESCENA_MENU)
