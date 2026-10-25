extends RefCounted

const TIPO_SALTADOR := "caballo"   # el tipo de pieza que salta al moverse (si su modelo trae salto)

# Palabras para reconocer cada modelo por su nombre (en minúsculas)
const CLAVES_RECIBIR := ["resiv", "recib", "herid", "dano"]
const CLAVES_GOLPE := ["golpe", "ataq", "punch"]
const CLAVES_CORRER := ["run", "corr", "walk", "camin"]
const CLAVES_BAILE := ["bail", "dance", "fest", "victor"]
const CLAVES_SALTAR := ["jump", "salt"]
const CLAVES_IDLE := ["idle", "quiet", "pose", "static", "estatic", "stand"]

func contiene(texto: String, claves: Array) -> bool:
	for c in claves:
		if texto.contains(c):
			return true
	return false

# Según el nombre del modelo, ¿qué animación representa?
func clasificar(nombre: String) -> String:
	var n: String = nombre.to_lower()
	if contiene(n, CLAVES_RECIBIR):
		return "recibir"
	if contiene(n, CLAVES_GOLPE):
		return "golpe"
	if contiene(n, CLAVES_CORRER):
		return "correr"
	if contiene(n, CLAVES_BAILE):
		return "baile"
	return "idle"

func buscar(player: AnimationPlayer, claves: Array) -> String:
	for nombre in player.get_animation_list():
		if contiene(String(nombre).to_lower(), claves):
			return String(nombre)
	return ""

# Elige qué animación del AnimationPlayer usar para cada modelo
func elegir_animacion(player: AnimationPlayer, clave: String) -> String:
	var claves: Array = []
	match clave:
		"idle":
			claves = CLAVES_IDLE
		"correr":
			claves = CLAVES_CORRER
		"golpe":
			claves = CLAVES_GOLPE
		"recibir":
			claves = CLAVES_RECIBIR
		"baile":
			claves = CLAVES_BAILE
	var n: String = buscar(player, claves)
	if n != "":
		return n
	# Si ninguna coincide por nombre, usa la primera
	for nombre in player.get_animation_list():
		var s: String = String(nombre)
		if s == "RESET":
			continue
		if clave == "idle" and contiene(s.to_lower(), CLAVES_SALTAR):
			continue
		return s
	return ""

# Prepara una pieza: reconoce sus modelos y sus animaciones
func preparar(p: Dictionary) -> void:
	p["modelos"] = {}
	p["players"] = {}
	p["anims"] = {}
	p["anim_saltar"] = ""

	for hijo in p["nodo"].get_children():
		if not (hijo is Node3D):
			continue
		var clave: String = clasificar(String(hijo.name))
		if not p["modelos"].has(clave):
			p["modelos"][clave] = hijo

	if p["modelos"].is_empty():
		push_warning("La pieza no tiene modelos: " + String(p["nodo"].name))
		return

	for clave in p["modelos"]:
		var modelo: Node3D = p["modelos"][clave]
		var lista = modelo.find_children("*", "AnimationPlayer", true, false)
		if lista.is_empty():
			continue
		var player: AnimationPlayer = lista[0]
		p["players"][clave] = player
		var nombre: String = elegir_animacion(player, clave)
		p["anims"][clave] = nombre
		if nombre != "":
			var en_bucle: bool = clave == "idle" or clave == "correr" or clave == "baile"
			player.get_animation(nombre).loop_mode = Animation.LOOP_LINEAR if en_bucle else Animation.LOOP_NONE

	# El salto del caballo, si viene dentro del modelo principal
	var player_idle = p["players"].get("idle", null)
	if player_idle != null:
		p["anim_saltar"] = buscar(player_idle, CLAVES_SALTAR)
	quieto(p)

# Muestra solo el modelo de esa animación y la reproduce. Devuelve false si la pieza no la tiene.
func mostrar(p: Dictionary, clave: String) -> bool:
	if not p["modelos"].has(clave):
		return false
	for k in p["modelos"]:
		p["modelos"][k].visible = (k == clave)
	var player = p["players"].get(clave, null)
	var nombre: String = p["anims"].get(clave, "")
	if player != null and nombre != "":
		player.stop()
		player.play(nombre)
	return true

func duracion(p: Dictionary, clave: String) -> float:
	var player = p["players"].get(clave, null)
	var nombre: String = p["anims"].get(clave, "")
	if player == null or nombre == "":
		return 0.6
	return player.get_animation(nombre).length

func quieto(p: Dictionary) -> void:
	mostrar(p, "idle")

func saltar(p: Dictionary) -> void:
	var nombre: String = p.get("anim_saltar", "")
	var player = p["players"].get("idle", null)
	if nombre == "" or player == null:
		return
	mostrar(p, "idle")
	player.stop()
	player.play(nombre)

# Animación mientras se desplaza (si no hay modelo de correr, se queda en su pose)
func moviendo(p: Dictionary) -> void:
	if p["tipo"] == TIPO_SALTADOR and p.get("anim_saltar", "") != "":
		saltar(p)
	elif not mostrar(p, "correr"):
		mostrar(p, "idle")

# Estas tres devuelven cuánto dura la animación (0.0 si la pieza no la tiene)
func golpe(p: Dictionary) -> float:
	if mostrar(p, "golpe"):
		return duracion(p, "golpe")
	return 0.0

func recibir(p: Dictionary) -> float:
	if mostrar(p, "recibir"):
		return duracion(p, "recibir")
	return 0.0

func festejar(p: Dictionary) -> float:
	if mostrar(p, "baile"):
		return duracion(p, "baile")
	return 0.0

# Al empezar a moverse: gira hacia el destino y empieza la animación
func empezar_movimiento(p: Dictionary, destino_pos: Vector3) -> void:
	var dir: Vector3 = destino_pos - p["nodo"].position
	dir.y = 0.0
	if dir.length() > 0.01:
		p["nodo"].rotation.y = atan2(dir.x, dir.z)
	moviendo(p)

# Al llegar: vuelve a mirar al frente de su equipo y se queda quieto
func terminar_movimiento(p: Dictionary, giro_grados: float) -> void:
	p["nodo"].rotation_degrees.y = giro_grados
	quieto(p)
