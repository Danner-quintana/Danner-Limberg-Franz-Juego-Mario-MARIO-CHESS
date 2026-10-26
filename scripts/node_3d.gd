extends Node3D

const TAM_CASILLA := 0.885
const CENTRO := Vector2(0.044, 0.163)
const ELEVACION_SELECCION := 0.20   # 0.0 = no se eleva; 0.3 era lo que teníamos antes
const ALTURA_TABLERO := 0.05

const MenuPausa = preload("res://menu_pausa.tscn")
var menu_pausa

# Victory / defeat screen
const EndScreen = preload("res://scripts/end_screen.gd")
const MAIN_MENU_SCENE := "res://menu_principal.tscn"
var end_screen


const CerebroIA = preload("res://scripts/cerebro_ia.gd")
const Animador = preload("res://scripts/animador.gd")
var ia_equipo: int = 2            # equipo que controla la IA (0 = IA apagada)
var cerebro = CerebroIA.new()
var animador = Animador.new()

# HUD del duelo (paneles con vida y controles)
const HudDuelo = preload("res://scripts/hud_duelo.gd")
var hud
const NOMBRE_TIPO := {
	"rey": "King", "reina": "Queen", "alfil": "Bishop",
	"caballo": "Knight", "torre": "Rook", "peon": "Pawn",
}
const COLOR_EQUIPO := {
	1: Color(0.35, 0.65, 1.0),   # azul = jugador 1
	2: Color(1.0, 0.35, 0.3),    # rojo = jugador 2 / IA
}
const TEXTO_CONTROLES := {
	1: "W A S D  move   ·   F  attack",
	2: "Arrows  move   ·   Enter  attack",
}

# ---------- AJEDREZ COMPLETO (32 piezas) ----------
const AJEDREZ_COMPLETO := true     # false = vuelve a las 9 piezas de prueba
# Nodos que ya existen en la escena y se copian para armar todas las piezas
const PLANTILLAS := {
	"rey": "piezaMario(rey)",
	"reina": "piezaPeach(reina)",
	"alfil": "piezaLuigi(alfil)",
	"caballo": "piezaYoshi(caballo)",
	"torre": "piezaBowser(rey)",   # Bowser hace de torre (el nombre del nodo da igual)
	"peon": "piezaGomba(peon)",
}
const ORDEN_FONDO := ["torre", "caballo", "alfil", "reina", "rey", "alfil", "caballo", "torre"]
# Tinte rojo suave para distinguir al equipo 2 (mientras usan los mismos modelos)
const TINTAR_EQUIPO2 := true
const TINTE_EQUIPO2 := Color(1.0, 0.2, 0.2, 0.5)

# Duelo: vida y daño por tipo de pieza (ajústalos a tu gusto)
const DATOS := {
	"peon": {"vida": 30, "dano": 5},
	"caballo": {"vida": 50, "dano": 6},
	"alfil": {"vida": 50, "dano": 6},
	"torre": {"vida": 65, "dano": 7},
	"reina": {"vida": 80, "dano": 9},
	"rey": {"vida": 70, "dano": 8},
}
const ESPERA_ATAQUE := 0.5   # segundos entre golpes

# Controles de cada equipo durante el duelo
const CONTROLES := {
	1: {"izq": KEY_A, "der": KEY_D, "arriba": KEY_W, "abajo": KEY_S, "atacar": KEY_F},
	2: {"izq": KEY_LEFT, "der": KEY_RIGHT, "arriba": KEY_UP, "abajo": KEY_DOWN, "atacar": KEY_ENTER},
}

@onready var camara: Camera3D = $Camera3D
@onready var resaltador: MeshInstance3D = $Resaltador

# Cada pieza: {"nodo": Node3D, "tipo": String, "casilla": Vector2i, "equipo": int}
var piezas: Array = []
var seleccionada: Variant = null      # la pieza elegida (o null)
var en_movimiento: bool = false
var turno: int = 1           # 1 o 2
var juego_terminado: bool = false
var ganador: int = 0         # equipo ganador (0 = nadie todavía)
var etiqueta: Label

# Estado del duelo
var duelo_en_curso: bool = false
var id_duelo_ia: int = 0
var duelo_terminando: bool = false
var duelo_atacante: Dictionary = {}
var duelo_defensor: Dictionary = {}
var luchadores: Array = []

var mat_hover: StandardMaterial3D
var mat_seleccion: StandardMaterial3D
var mat_invalido: StandardMaterial3D
var mat_captura: StandardMaterial3D

func _ready() -> void:
	mat_hover = crear_material(Color(1.0, 1.0, 0.0, 0.4))      # amarillo
	mat_seleccion = crear_material(Color(0.0, 1.0, 0.3, 0.6))  # verde
	mat_invalido = crear_material(Color(1.0, 0.1, 0.1, 0.6))   # rojo
	mat_captura = crear_material(Color(1.0, 0.5, 0.0, 0.7))    # naranja

	resaltador.material_override = mat_hover
	resaltador.visible = false

	# Texto del turno (se crea por código, no hay que añadir nodos)
	var capa = CanvasLayer.new()
	add_child(capa)
	etiqueta = Label.new()
	etiqueta.position = Vector2(20, 20)
	etiqueta.add_theme_font_size_override("font_size", 28)
	capa.add_child(etiqueta)
	etiqueta.add_theme_color_override("font_outline_color", Color.BLACK)
	etiqueta.add_theme_constant_override("outline_size", 8)
	hud = HudDuelo.new()
	add_child(hud)

	menu_pausa = MenuPausa.instantiate()
	add_child(menu_pausa)
	menu_pausa.configurar(self)

	end_screen = EndScreen.new()
	add_child(end_screen)
	end_screen.play_again.connect(_on_play_again)
	end_screen.main_menu.connect(_on_end_main_menu)

	# Aquí se arman las piezas (ajedrez completo o las 9 de prueba)
	registrar_piezas()

	var ranura: int = GestorPartidas.ranura_a_cargar
	if ranura > 0:
		restaurar_partida(GestorPartidas.cargar(ranura))
		GestorPartidas.ranura_a_cargar = -1
	if GestorPartidas.modo_juego == "solitario":
		ia_equipo = 2
	else:
		ia_equipo = 0

	for p in piezas:
		p["nodo"].position = calcular_pos(p["casilla"])
		p["nodo"].rotation_degrees.y = giro_inicial(p["equipo"])
		animador.preparar(p)

	actualizar_etiqueta()
	if not juego_terminado:
		Music.play("board")
	if juego_terminado:
		announce_result(0.4)
	elif turno == ia_equipo:
		jugar_ia()

func crear_material(color: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

# ---------------- ARMADO DE PIEZAS ----------------
func registrar_piezas() -> void:
	if not AJEDREZ_COMPLETO:
		registrar_piezas_prueba()
		return

	var plantillas: Dictionary = {}
	for tipo in PLANTILLAS:
		var nodo = get_node_or_null(PLANTILLAS[tipo])
		if nodo == null:
			push_warning("FALTA LA PLANTILLA: " + PLANTILLAS[tipo])
			continue
		plantillas[tipo] = nodo

	for equipo in [1, 2]:
		var fila_fondo: int = 7 if equipo == 1 else 0
		var fila_peones: int = 6 if equipo == 1 else 1
		for col in 8:
			crear_pieza(plantillas, ORDEN_FONDO[col], Vector2i(col, fila_fondo), equipo)
			crear_pieza(plantillas, "peon", Vector2i(col, fila_peones), equipo)

	# Esconder las piezas originales de la escena (ya fueron copiadas)
	for hijo in get_children():
		if String(hijo.name).begins_with("pieza"):
			hijo.visible = false

# Copia una plantilla, la coloca en el tablero y la registra
func crear_pieza(plantillas: Dictionary, tipo: String, casilla: Vector2i, equipo: int) -> void:
	if not plantillas.has(tipo):
		return
	var original: Node3D = plantillas[tipo]
	var copia: Node3D = original.duplicate() as Node3D
	copia.name = "E%d_%s_%d" % [equipo, tipo, casilla.x]    # nombre único (lo usa el guardado)
	add_child(copia)
	copia.visible = true
	if TINTAR_EQUIPO2 and equipo == 2:
		tenir(copia)
	piezas.append({
		"nodo": copia, "tipo": tipo, "casilla": casilla, "equipo": equipo,
		"plantilla": PLANTILLAS[tipo],
	})

# Tinte suave sobre todos los modelos de una pieza
func tenir(nodo: Node3D) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = TINTE_EQUIPO2
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for malla in nodo.find_children("*", "MeshInstance3D", true, false):
		malla.material_overlay = m

# Las 9 piezas de prueba de antes
func registrar_piezas_prueba() -> void:
	# Equipo 1 (tú)
	piezas.append({"nodo": $"piezaMario(rey)", "tipo": "rey", "casilla": Vector2i(4, 7), "equipo": 1})
	piezas.append({"nodo": $"piezaPeach(reina)", "tipo": "reina", "casilla": Vector2i(3, 7), "equipo": 1})
	piezas.append({"nodo": $"piezaGomba(peon)", "tipo": "peon", "casilla": Vector2i(3, 6), "equipo": 1})
	piezas.append({"nodo": $"piezaGomba2(peon)", "tipo": "peon", "casilla": Vector2i(4, 6), "equipo": 1})
	# Equipo 2 (IA)
	piezas.append({"nodo": $"piezaBowser(rey)", "tipo": "rey", "casilla": Vector2i(4, 0), "equipo": 2})
	piezas.append({"nodo": $"piezaYoshi(caballo)", "tipo": "caballo", "casilla": Vector2i(6, 0), "equipo": 2})
	piezas.append({"nodo": $"piezaLuigi(alfil)", "tipo": "alfil", "casilla": Vector2i(2, 0), "equipo": 2})
	piezas.append({"nodo": $"piezaGombaRival(peon)", "tipo": "peon", "casilla": Vector2i(3, 1), "equipo": 2})
	piezas.append({"nodo": $"piezaGombaRival2(peon)", "tipo": "peon", "casilla": Vector2i(4, 1), "equipo": 2})

# Nombre que se le pasa al HUD (el de la plantilla, como antes)
func nombre_hud(p: Dictionary) -> String:
	return String(p.get("plantilla", p["nodo"].name))

func actualizar_etiqueta() -> void:
	texto_turno("Turn: Player " + str(turno), turno)

# Muestra un texto arriba a la izquierda con el color del equipo
func texto_turno(texto: String, equipo: int) -> void:
	etiqueta.text = texto
	etiqueta.add_theme_color_override("font_color", COLOR_EQUIPO[equipo])

# Resalta la casilla donde pasa el ratón (solo en la fase de tablero)
func _process(_delta: float) -> void:
	if duelo_en_curso:
		return
	var casilla = casilla_bajo_cursor(get_viewport().get_mouse_position())
	if casilla != Vector2i(-1, -1):
		var pos = calcular_pos(casilla)
		resaltador.position = pos + Vector3(0, 0.01, 0)
		resaltador.visible = true
		if seleccionada != null:
			var jugada = tipo_de_jugada(seleccionada, casilla)
			if casilla == seleccionada["casilla"] or jugada == "mover":
				resaltador.material_override = mat_seleccion
			elif jugada == "capturar":
				resaltador.material_override = mat_captura
			else:
				resaltador.material_override = mat_invalido
		else:
			resaltador.material_override = mat_hover
	elif seleccionada == null:
		resaltador.visible = false

# Entrada: teclas durante el duelo, ratón durante el tablero
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):   # tecla Esc
		abrir_pausa()
		return
	if duelo_en_curso:
		if event is InputEventKey and event.pressed and not event.echo:
			tecla_en_duelo(event.keycode)
		return

	if en_movimiento or juego_terminado or turno == ia_equipo:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var casilla = casilla_bajo_cursor(event.position)
		if casilla == Vector2i(-1, -1):
			return

		# PRIMER CLIC: elegir una pieza de tu equipo
		if seleccionada == null:
			var p: Variant = pieza_en(casilla)
			if p != null and p["equipo"] == turno:
				seleccionada = p
				p["nodo"].position.y = ALTURA_TABLERO + ELEVACION_SELECCION
		# SEGUNDO CLIC: mover, capturar o cancelar
		else:
			if casilla == seleccionada["casilla"]:
				seleccionada["nodo"].position.y = ALTURA_TABLERO
				seleccionada = null
			else:
				var jugada = tipo_de_jugada(seleccionada, casilla)
				if jugada == "mover":
					var p = seleccionada
					seleccionada = null
					mover_pieza(p, casilla)
				elif jugada == "capturar":
					var atacante = seleccionada
					var defensor: Variant = pieza_en(casilla)
					seleccionada = null
					atacante["nodo"].position.y = ALTURA_TABLERO
					iniciar_duelo(atacante, defensor)
				# Si no es válido, no pasa nada y sigue seleccionada

func abrir_pausa() -> void:
	if duelo_en_curso or en_movimiento:
		return
	if not juego_terminado and turno == ia_equipo:
		return
	if seleccionada != null:
		seleccionada["nodo"].position.y = ALTURA_TABLERO
		seleccionada = null
	menu_pausa.abrir()

# Lo que se escribe en la ranura
func datos_de_partida() -> Dictionary:
	var lista: Array = []
	for p in piezas:
		lista.append({
			"nodo": String(p["nodo"].name),
			"tipo": p["tipo"],
			"casilla": [p["casilla"].x, p["casilla"].y],
			"equipo": p["equipo"],
		})
	return {"turno": turno, "piezas": lista, "terminado": juego_terminado, "ganador": ganador}

# Coloca cada pieza donde estaba y elimina las que ya habían sido capturadas
func restaurar_partida(datos: Dictionary) -> void:
	var guardadas: Dictionary = {}
	for g in datos.get("piezas", []):
		guardadas[g["nodo"]] = g
	for p in piezas.duplicate():
		var nombre: String = String(p["nodo"].name)
		if guardadas.has(nombre):
			var g: Dictionary = guardadas[nombre]
			p["casilla"] = Vector2i(int(g["casilla"][0]), int(g["casilla"][1]))
		else:
			piezas.erase(p)
			p["nodo"].queue_free()
	turno = int(datos.get("turno", 1))
	juego_terminado = bool(datos.get("terminado", false))
	ganador = int(datos.get("ganador", 0))

# Mueve una pieza a una casilla (con animación) y pasa el turno
func mover_pieza(p: Dictionary, casilla: Vector2i) -> void:
	p["casilla"] = casilla
	en_movimiento = true
	var destino: Vector3 = calcular_pos(casilla)
	animador.empezar_movimiento(p, destino)
	var tween = create_tween()
	tween.tween_property(p["nodo"], "position", destino, 0.5)
	tween.finished.connect(func():
		animador.terminar_movimiento(p, giro_inicial(p["equipo"]))
		en_movimiento = false
		cambiar_turno()
	)

func cambiar_turno() -> void:
	if juego_terminado:
		return
		
	turno = 3 - turno   # alterna entre 1 y 2
	
	actualizar_camara_turno()  # Cambiar la cámara según el turno
	actualizar_etiqueta()

	if turno == ia_equipo:
		jugar_ia()

# ---------------- IA ----------------
func jugar_ia() -> void:
	texto_turno("AI thinking...", ia_equipo)
	await get_tree().create_timer(1.0).timeout    # pausa para que se note que "piensa"
	if juego_terminado or duelo_en_curso:
		return
	var jugada: Dictionary = cerebro.elegir_jugada(self, ia_equipo)
	if jugada.is_empty():
		cambiar_turno()    # no tiene jugadas posibles: pasa el turno
		return
	texto_turno("AI decided: " + jugada["motivo"], ia_equipo)
	await get_tree().create_timer(0.8).timeout
	var p: Dictionary = jugada["pieza"]
	if jugada["jugada"] == "mover":
		mover_pieza(p, jugada["destino"])
	else:
		iniciar_duelo(p, pieza_en(jugada["destino"]))

# ---------------- DUELO (en el mismo tablero) ----------------
func iniciar_duelo(atacante: Dictionary, defensor: Dictionary) -> void:
	duelo_en_curso = true
	duelo_terminando = false
	duelo_atacante = atacante
	duelo_defensor = defensor
	resaltador.visible = false
	etiqueta.text = ""   # el HUD del duelo muestra la información
	Music.play("duel")

	# Esconder las demás piezas
	for p in piezas:
		if p != atacante and p != defensor:
			p["nodo"].visible = false

	# El luchador de la izquierda es del equipo 1 y el de la derecha del equipo 2
	var pieza1: Dictionary = atacante if atacante["equipo"] == 1 else defensor
	var pieza2: Dictionary = defensor if atacante["equipo"] == 1 else atacante
	luchadores = [crear_luchador(pieza1, Vector2i(4, 7), 0), crear_luchador(pieza2, Vector2i(4, 0), 1)]
	orientar_luchadores()

	for f in luchadores:
		var eq: int = f["pieza"]["equipo"]
		var nombre: String = NOMBRE_TIPO.get(f["pieza"]["tipo"], "Piece")
		var controles: String = TEXTO_CONTROLES[eq]
		var nombre_jugador: String = "Player " + str(eq)

		if GestorPartidas.modo_juego == "solitario" and eq == ia_equipo:
			nombre_jugador = "AI - " + nombre
			controles = "AI controlled"

		hud.configurar(
			f["indice"],
			nombre_jugador + " - " + nombre,
			f["vida_max"],
			controles,
			nombre_hud(f["pieza"])
		)
	
	hud.mostrar()
	if GestorPartidas.modo_juego == "solitario":
		iniciar_ia_duelo()



func crear_luchador(p: Dictionary, casilla: Vector2i, indice: int) -> Dictionary:
	var datos: Dictionary = DATOS[p["tipo"]]
	p["nodo"].position = calcular_pos(casilla)
	animador.quieto(p)
	return {
		"pieza": p, "casilla": casilla, "indice": indice,
		"vida": datos["vida"], "vida_max": datos["vida"], "dano": datos["dano"],
		"listo_atacar": 0.0, "tween": null, "anim_id": 0,
	}

# Cada luchador mira hacia su rival
func orientar_luchadores() -> void:
	if luchadores.size() < 2:
		return
	for i in 2:
		var f: Dictionary = luchadores[i]
		var otro: Dictionary = luchadores[1 - i]
		var dx: float = float(otro["casilla"].x - f["casilla"].x)
		var dz: float = float(otro["casilla"].y - f["casilla"].y)
		f["pieza"]["nodo"].rotation.y = atan2(dx, dz)

# Después de una animación (golpe, recibir, correr) vuelve a la pose quieta
func animar_y_volver(f: Dictionary, espera: float) -> void:
	f["anim_id"] += 1
	var id: int = f["anim_id"]
	await get_tree().create_timer(espera).timeout
	var nodo = f["pieza"]["nodo"]
	if f["anim_id"] == id and is_instance_valid(nodo) and f["vida"] > 0:
		animador.quieto(f["pieza"])

func actualizar_vida(f: Dictionary) -> void:
	hud.actualizar(f["indice"], f["vida"], f["vida_max"])

# Una pulsación de tecla = una acción
func tecla_en_duelo(k: int) -> void:
	if duelo_terminando:
		return
	for i in 2:
		var f: Dictionary = luchadores[i]
		var otro: Dictionary = luchadores[1 - i]
		if GestorPartidas.modo_juego == "solitario" and f["pieza"]["equipo"] == ia_equipo:
			continue
		var ctl: Dictionary = CONTROLES[f["pieza"]["equipo"]]
		var paso := Vector2i.ZERO
		if k == ctl["izq"]:
			paso = Vector2i(-1, 0)
		elif k == ctl["der"]:
			paso = Vector2i(1, 0)
		elif k == ctl["arriba"]:
			paso = Vector2i(0, -1)
		elif k == ctl["abajo"]:
			paso = Vector2i(0, 1)
		if paso != Vector2i.ZERO:
			mover_luchador(f, otro, paso)
		elif k == ctl["atacar"]:
			atacar(f, otro)

func mover_luchador(f: Dictionary, otro: Dictionary, paso: Vector2i) -> void:
	var destino: Vector2i = f["casilla"] + paso
	if destino.x < 0 or destino.x > 7 or destino.y < 0 or destino.y > 7:
		return
	if destino == otro["casilla"]:
		return   # no se puede entrar en la casilla del rival
	f["casilla"] = destino
	orientar_luchadores()
	f["anim_id"] += 1
	animador.moviendo(f["pieza"])
	if f["tween"] != null:
		f["tween"].kill()
	f["tween"] = create_tween()
	f["tween"].tween_property(f["pieza"]["nodo"], "position", calcular_pos(destino), 0.12)
	f["tween"].finished.connect(func(): animar_y_volver(f, 0.15))

func atacar(f: Dictionary, otro: Dictionary) -> void:
	var ahora: float = Time.get_ticks_msec() / 1000.0
	if ahora < f["listo_atacar"]:
		return
	f["listo_atacar"] = ahora + ESPERA_ATAQUE
	# Animación del golpe (si la pieza no tiene, se agranda un momento)
	var dur: float = animador.golpe(f["pieza"])
	if dur > 0.0:
		animar_y_volver(f, minf(dur, 0.8))
	else:
		var nodo: Node3D = f["pieza"]["nodo"]
		var s: Vector3 = nodo.scale
		var t = create_tween()
		t.tween_property(nodo, "scale", s * 1.25, 0.08)
		t.tween_property(nodo, "scale", s, 0.08)
	# Solo golpea si el rival está en una casilla pegada a la tuya
	var d: Vector2i = f["casilla"] - otro["casilla"]
	if maxi(absi(d.x), absi(d.y)) == 1:
		recibir_dano(otro, f["dano"])

func recibir_dano(f: Dictionary, cantidad: int) -> void:
	f["vida"] = maxi(f["vida"] - cantidad, 0)
	actualizar_vida(f)
	var dur: float = animador.recibir(f["pieza"])
	if f["vida"] > 0:
		if dur > 0.0:
			animar_y_volver(f, minf(dur, 0.7))
	elif not duelo_terminando:
		duelo_terminando = true
		f["anim_id"] += 1   # el derrotado se queda en su pose de golpe
		for g in luchadores:
			if g["indice"] != f["indice"]:
				g["anim_id"] += 1
				animador.festejar(g["pieza"])   # solo Yoshi tiene baile
		var gana_equipo: int = 3 - f["pieza"]["equipo"]
		await get_tree().create_timer(1.6).timeout
		terminar_duelo(gana_equipo)

func terminar_duelo(gana_equipo: int) -> void:
	id_duelo_ia += 1
	luchadores.clear()
	hud.ocultar()

	# Todas las piezas vuelven a su casilla del ajedrez y se muestran de nuevo
	for p in piezas:
		p["nodo"].visible = true
		p["nodo"].position = calcular_pos(p["casilla"])
		p["nodo"].rotation_degrees.y = giro_inicial(p["equipo"])
		animador.quieto(p)

	duelo_en_curso = false
	actualizar_etiqueta()

	resolver_duelo(
		duelo_atacante,
		duelo_defensor,
		duelo_atacante["equipo"] == gana_equipo
	)

	if not juego_terminado:
		Music.play("board")

	actualizar_camara_turno()

func resolver_duelo(atacante: Dictionary, defensor: Dictionary, gana_atacante: bool) -> void:
	if gana_atacante:
		var casilla_defensor: Vector2i = defensor["casilla"]
		eliminar_pieza(defensor)
		mover_pieza(atacante, casilla_defensor)   # ocupa la casilla y pasa el turno
	else:
		eliminar_pieza(atacante)
		cambiar_turno()

func eliminar_pieza(p: Dictionary) -> void:
	piezas.erase(p)
	p["nodo"].queue_free()
	if p["tipo"] == "rey":
		juego_terminado = true
		ganador = 3 - p["equipo"]
		announce_result()

# Devuelve la pieza que está en una casilla (o null si está vacía)
func pieza_en(casilla: Vector2i) -> Variant:
	for p in piezas:
		if p["casilla"] == casilla:
			return p
	return null

# ---------------- REGLAS ----------------
func direccion_adelante(equipo: int) -> int:
	return -1 if equipo == 1 else 1      # el equipo 1 avanza hacia arriba de la pantalla

func fila_inicial_peon(equipo: int) -> int:
	return 6 if equipo == 1 else 1

# Hacia dónde mira cada equipo (en grados). Si ves que miran al revés, intercambia los valores.
func giro_inicial(equipo: int) -> float:
	return 180.0 if equipo == 1 else 0.0

# Devuelve "mover", "capturar" o "" (jugada no permitida)
func tipo_de_jugada(p: Dictionary, hasta: Vector2i) -> String:
	var otra: Variant = pieza_en(hasta)
	var desde: Vector2i = p["casilla"]
	var dx: int = hasta.x - desde.x
	var dy: int = hasta.y - desde.y
	var adelante: int = direccion_adelante(p["equipo"])
	match p["tipo"]:
		"rey":
			if maxi(absi(dx), absi(dy)) != 1:
				return ""
			return resultado_destino(p, otra)
		"torre":
			if (dx == 0) != (dy == 0) and camino_libre(desde, hasta):
				return resultado_destino(p, otra)
			return ""
		"alfil":
			if dx != 0 and absi(dx) == absi(dy) and camino_libre(desde, hasta):
				return resultado_destino(p, otra)
			return ""
		"reina":
			var recto: bool = (dx == 0) != (dy == 0)
			var diagonal: bool = dx != 0 and absi(dx) == absi(dy)
			if (recto or diagonal) and camino_libre(desde, hasta):
				return resultado_destino(p, otra)
			return ""
		"caballo":
			# Salta en L: no importa lo que haya en medio
			if (absi(dx) == 1 and absi(dy) == 2) or (absi(dx) == 2 and absi(dy) == 1):
				return resultado_destino(p, otra)
			return ""
		"peon":
			# Captura: diagonal hacia adelante, sobre una pieza enemiga
			if absi(dx) == 1 and dy == adelante:
				if otra != null and otra["equipo"] != p["equipo"]:
					return "capturar"
				return ""
			# Avance: recto hacia adelante, solo a una casilla vacía
			if dx == 0 and otra == null:
				if dy == adelante:
					return "mover"
				# Primer movimiento: 2 casillas si la del medio está libre
				if dy == 2 * adelante and desde.y == fila_inicial_peon(p["equipo"]):
					if pieza_en(Vector2i(desde.x, desde.y + adelante)) == null:
						return "mover"
			return ""
	return ""

# Qué pasa al llegar a una casilla: vacía = mover, enemiga = capturar, propia = no se puede
func resultado_destino(p: Dictionary, otra: Variant) -> String:
	if otra == null:
		return "mover"
	if otra["equipo"] != p["equipo"]:
		return "capturar"
	return ""

# ¿Están libres las casillas que hay entre dos casillas en línea (recta o diagonal)?
func camino_libre(desde: Vector2i, hasta: Vector2i) -> bool:
	var paso := Vector2i(signi(hasta.x - desde.x), signi(hasta.y - desde.y))
	var c: Vector2i = desde + paso
	while c != hasta:
		if pieza_en(c) != null:
			return false
		c += paso
	return true

# ---------------- CUADRÍCULA ----------------
func casilla_bajo_cursor(pos_mouse: Vector2) -> Vector2i:
	var camara_actual: Camera3D = get_viewport().get_camera_3d()

	if camara_actual == null:
		return Vector2i(-1, -1)

	var origen = camara_actual.project_ray_origin(pos_mouse)
	var direccion = camara_actual.project_ray_normal(pos_mouse)

	var plano = Plane(Vector3.UP, ALTURA_TABLERO)
	var punto = plano.intersects_ray(origen, direccion)

	if punto == null:
		return Vector2i(-1, -1)

	var col = floori((punto.x - CENTRO.x) / TAM_CASILLA + 4)
	var fila = floori((punto.z - CENTRO.y) / TAM_CASILLA + 4)

	if col < 0 or col > 7 or fila < 0 or fila > 7:
		return Vector2i(-1, -1)

	return Vector2i(col, fila)

func calcular_pos(c: Vector2i) -> Vector3:
	return Vector3(CENTRO.x + (c.x - 3.5) * TAM_CASILLA, ALTURA_TABLERO, CENTRO.y + (c.y - 3.5) * TAM_CASILLA)

# ---------------- VICTORY / DEFEAT ----------------
# Waits a moment (so you can see the final capture) and then shows VICTORY or DEFEAT
func announce_result(delay: float = 1.6) -> void:
	etiqueta.text = ""
	await get_tree().create_timer(delay).timeout
	var player_won: bool = ia_equipo == 0 or ganador != ia_equipo
	Music.play("victory" if player_won else "defeat", 0.3)
	end_screen.show_result(ganador, ia_equipo)

func _on_play_again() -> void:
	GestorPartidas.ranura_a_cargar = -1
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_end_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	
	
func iniciar_ia_duelo() -> void:
	id_duelo_ia += 1
	var mi_id: int = id_duelo_ia

	# Esperar un poco antes del primer movimiento
	await get_tree().create_timer(0.7).timeout

	while duelo_en_curso and not duelo_terminando and mi_id == id_duelo_ia:
		var ia_f: Dictionary = {}
		var jugador_f: Dictionary = {}

		# Identificar al luchador de la IA y al jugador
		for f in luchadores:
			if f["pieza"]["equipo"] == ia_equipo:
				ia_f = f
			else:
				jugador_f = f

		if ia_f.is_empty() or jugador_f.is_empty():
			return

		if ia_f["vida"] <= 0 or jugador_f["vida"] <= 0:
			return

		var diferencia: Vector2i = jugador_f["casilla"] - ia_f["casilla"]
		var distancia: int = maxi(absi(diferencia.x), absi(diferencia.y))

		# Si el jugador está cerca, la IA ataca
		if distancia == 1:
			atacar(ia_f, jugador_f)

		# Si está lejos, la IA busca acercarse
		else:
			var mejor_paso := Vector2i.ZERO
			var mejor_distancia: int = distancia

			# Probar las ocho direcciones posibles
			for x in range(-1, 2):
				for y in range(-1, 2):
					if x == 0 and y == 0:
						continue

					var paso := Vector2i(x, y)
					var destino: Vector2i = ia_f["casilla"] + paso

					# No salir del tablero
					if destino.x < 0 or destino.x > 7:
						continue
					if destino.y < 0 or destino.y > 7:
						continue

					# No intentar ocupar la casilla del jugador
					if destino == jugador_f["casilla"]:
						continue

					var nueva_distancia: int = maxi(
						absi(jugador_f["casilla"].x - destino.x),
						absi(jugador_f["casilla"].y - destino.y)
					)

					# Elegir el movimiento que más acerque a la IA
					if nueva_distancia < mejor_distancia:
						mejor_distancia = nueva_distancia
						mejor_paso = paso

			if mejor_paso != Vector2i.ZERO:
				mover_luchador(ia_f, jugador_f, mejor_paso)

		# Pausa breve entre acciones
		await get_tree().create_timer(0.6).timeout
		
func actualizar_camara_turno() -> void:
	if duelo_en_curso or GestorPartidas.modo_juego != "multijugador":
		return

	if turno == 1:
		$Camera3D.make_current()
	elif turno == 2:
		$CamaraJugador2.make_current()
