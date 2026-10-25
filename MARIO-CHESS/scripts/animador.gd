extends RefCounted


# Configuración de cada pieza.
# Los nombres deben coincidir con los nodos de Godot.

const MODELOS := {
	"piezaMario(rey)": {
		"quieto": "Mario Bros",
		"correr": "Mario_run"
	},

	"piezaBowser(rey)": {
		"quieto": "Browser_quieto",
		"correr": "Bowser_run"
	},

	"piezaLuigi(alfil)": {
		"quieto": "luigi_quieto",
		"correr": "luigi_run"
	},

	"piezaPeach(reina)": {
		"quieto": "peach_quieta",
		"correr": ""
	},

	"piezaYoshi(caballo)": {
		"quieto": "yoshi_quieto",
		"correr": "yoshi_run"
	},

	"piezaGomba(peon)": {
		"quieto": "goomba",
		"correr": ""
	},

	"piezaGomba2(peon)": {
		"quieto": "goomba",
		"correr": ""
	},

	"piezaGombaRival(peon)": {
		"quieto": "goomba",
		"correr": ""
	},

	"piezaGombaRival2(peon)": {
		"quieto": "goomba",
		"correr": ""
	}
}


# Busca un modelo por su nombre dentro de la pieza.
func buscar_modelo(padre: Node, nombre: String) -> Node3D:
	if nombre == "":
		return null

	var encontrado := padre.find_child(nombre, true, false)

	if encontrado is Node3D:
		return encontrado as Node3D

	return null


# Prepara los modelos de cada pieza.
func preparar(p: Dictionary) -> void:
	var nodo: Node3D = p["nodo"]
	var configuracion: Dictionary = MODELOS.get(nodo.name, {})

	p["modelo_quieto"] = buscar_modelo(
		nodo,
		configuracion.get("quieto", "")
	)

	p["modelo_correr"] = buscar_modelo(
		nodo,
		configuracion.get("correr", "")
	)

	# Si no encuentra el modelo estático, avisa en la consola.
	if p["modelo_quieto"] == null:
		push_warning(
			"No se encontró el modelo estático de: " + nodo.name
		)

	# Si no encuentra el modelo de correr, la pieza
	# seguirá mostrando su modelo estático.
	if configuracion.get("correr", "") != "":
		if p["modelo_correr"] == null:
			push_warning(
				"No se encontró el modelo de correr de: " + nodo.name
			)

	quieto(p)


# Muestra el modelo correspondiente al estado actual.
func mostrar_modelo(p: Dictionary, _moviendo: bool) -> void:
	var quieto_modelo: Node3D = p.get("modelo_quieto")
	var correr_modelo: Node3D = p.get("modelo_correr")

	# Solo se cambia al modelo de correr si existe.
	if _moviendo and correr_modelo != null:
		if quieto_modelo != null:
			quieto_modelo.visible = false

		correr_modelo.visible = true

	else:
		# Si no hay modelo de correr, permanece visible el estático.
		if quieto_modelo != null:
			quieto_modelo.visible = true

		if correr_modelo != null:
			correr_modelo.visible = false


# La pieza está quieta.
func quieto(p: Dictionary) -> void:
	mostrar_modelo(p, false)


# La pieza se está desplazando.
func _moviendo(p: Dictionary) -> void:
	mostrar_modelo(p, true)


# Gira la pieza y muestra el modelo animado al empezar.
func empezar_movimiento(
	p: Dictionary,
	destino_pos: Vector3
) -> void:
	var dir: Vector3 = destino_pos - p["nodo"].position
	dir.y = 0.0

	if dir.length() > 0.01:
		p["nodo"].rotation.y = atan2(dir.x, dir.z)

	_moviendo(p)


# Al terminar, vuelve a la pose estática.
func terminar_movimiento(
	p: Dictionary,
	giro_grados: float
) -> void:
	p["nodo"].rotation_degrees.y = giro_grados

	quieto(p)
