extends Control

const EstiloMenu = preload("res://scripts/estilo_menu.gd")
const FondoMenu = preload("res://scripts/fondo_menu.gd")

# Cambia esto por la ruta real de tu escena del juego
const ESCENA_JUEGO := "res://esenas/node_3d.tscn"
const SUBTITULO := "Chess Duel Adventure"

var titulo_ranuras: Label

func _ready() -> void:
	# Fondo animado (el nodo VideoStreamPlayer "Fondo" ya no se usa)
	$Fondo.hide()
	var fondo := FondoMenu.new()
	add_child(fondo)
	move_child(fondo, 0)

	construir_menu()
	construir_ranuras()

	$Botones/BtnNueva.pressed.connect(_on_nueva)
	$Botones/BtnContinuar.pressed.connect(_on_continuar)
	$Botones/BtnSalir.pressed.connect(get_tree().quit)
	$Ranuras/BtnVolver.pressed.connect(_on_volver)
	# Si no hay ninguna partida guardada, "Load Game" no tiene sentido
	$Botones/BtnContinuar.disabled = not GestorPartidas.hay_partidas()

	# Aparece suavemente
	$Botones.modulate.a = 0.0
	create_tween().tween_property($Botones, "modulate:a", 1.0, 0.7)

func construir_menu() -> void:
	var botones: VBoxContainer = $Botones
	botones.add_theme_constant_override("separation", 14)

	var titulo: Label = $Botones/Titulo
	EstiloMenu.titulo(titulo, 84, EstiloMenu.DORADO)

	var sub := Label.new()
	sub.text = SUBTITULO
	EstiloMenu.titulo(sub, 26, Color.WHITE)
	sub.add_theme_constant_override("outline_size", 8)
	botones.add_child(sub)
	botones.move_child(sub, 1)

	var espacio := Control.new()
	espacio.custom_minimum_size = Vector2(0, 24)
	botones.add_child(espacio)
	botones.move_child(espacio, 2)

	EstiloMenu.boton($Botones/BtnNueva, EstiloMenu.VERDE)
	EstiloMenu.boton($Botones/BtnContinuar, EstiloMenu.AZUL)
	EstiloMenu.boton($Botones/BtnSalir, EstiloMenu.ROJO)

func construir_ranuras() -> void:
	var ranuras: VBoxContainer = $Ranuras
	ranuras.add_theme_constant_override("separation", 12)
	$Ranuras/Lista.add_theme_constant_override("separation", 12)

	titulo_ranuras = Label.new()
	titulo_ranuras.text = "LOAD GAME"
	EstiloMenu.titulo(titulo_ranuras, 52, EstiloMenu.DORADO)
	ranuras.add_child(titulo_ranuras)
	ranuras.move_child(titulo_ranuras, 0)

	EstiloMenu.boton($Ranuras/BtnVolver, EstiloMenu.GRIS)

func _on_nueva() -> void:
	GestorPartidas.ranura_a_cargar = -1
	get_tree().change_scene_to_file(ESCENA_JUEGO)

func _on_continuar() -> void:
	$Botones.hide()
	$Ranuras.show()
	refrescar_ranuras()

func _on_volver() -> void:
	$Ranuras.hide()
	$Botones.show()

func refrescar_ranuras() -> void:
	for h in $Ranuras/Lista.get_children():
		h.queue_free()
	for i in range(1, GestorPartidas.MAX_RANURAS + 1):
		var b := Button.new()
		if GestorPartidas.existe(i):
			var d: Dictionary = GestorPartidas.cargar(i)
			b.text = "Slot %d  -  %s" % [i, d.get("fecha", "")]
			b.pressed.connect(_cargar_ranura.bind(i))
		else:
			b.text = "Slot %d  -  Empty" % i
			b.disabled = true
		EstiloMenu.boton(b, EstiloMenu.AZUL)
		$Ranuras/Lista.add_child(b)

func _cargar_ranura(n: int) -> void:
	GestorPartidas.ranura_a_cargar = n
	get_tree().change_scene_to_file(ESCENA_JUEGO)
