extends RefCounted

# Elige la mejor jugada para un equipo. "tablero" es el script del main.
func elegir_jugada(tablero, equipo: int) -> Dictionary:
	var mejor: Dictionary = {}
	var mejor_puntaje: float = -INF
	for p in tablero.piezas:
		if p["equipo"] != equipo:
			continue
		for x in 8:
			for y in 8:
				var destino := Vector2i(x, y)
				var jugada: String = tablero.tipo_de_jugada(p, destino)
				if jugada == "":
					continue
				var v: Dictionary = valorar(tablero, p, destino, jugada)
				var puntaje: float = v["puntaje"] + randf() * 0.3
				if puntaje > mejor_puntaje:
					mejor_puntaje = puntaje
					mejor = {"pieza": p, "destino": destino, "jugada": jugada, "motivo": v["motivo"]}
	return mejor

# Da puntos a una jugada y explica el motivo
func valorar(tablero, p: Dictionary, destino: Vector2i, jugada: String) -> Dictionary:
	var puntaje := 0.0
	var motivo := "avanzar"

	if jugada == "capturar":
		var victima = tablero.pieza_en(destino)
		puntaje += 10.0
		motivo = "capturar"
		if victima["tipo"] == "rey":
			puntaje += 20.0
			motivo = "capturar al rey"

	# Acercarse al enemigo más cercano
	var antes: float = distancia_enemigo(tablero, p["casilla"], p["equipo"])
	var despues: float = distancia_enemigo(tablero, destino, p["equipo"])
	puntaje += (antes - despues) * 1.0

	# Evitar el peligro
	if jugada != "capturar":
		var peligro_aqui: bool = casilla_amenazada(tablero, p["casilla"], p)
		var peligro_alla: bool = casilla_amenazada(tablero, destino, p)
		if peligro_alla:
			puntaje -= 4.0
		elif peligro_aqui:
			puntaje += 3.0
			motivo = "huir del peligro"

	return {"puntaje": puntaje, "motivo": motivo}

func distancia_enemigo(tablero, casilla: Vector2i, equipo: int) -> float:
	var d := 99.0
	for q in tablero.piezas:
		if q["equipo"] != equipo:
			var dif: Vector2i = q["casilla"] - casilla
			d = minf(d, float(maxi(absi(dif.x), absi(dif.y))))
	return d

# ¿Algún enemigo podría capturar a una pieza que estuviera en esa casilla?
func casilla_amenazada(tablero, casilla: Vector2i, p: Dictionary) -> bool:
	for q in tablero.piezas:
		if q["equipo"] == p["equipo"]:
			continue
		if q["tipo"] == "peon":
			var dif: Vector2i = casilla - q["casilla"]
			if absi(dif.x) == 1 and dif.y == tablero.direccion_adelante(q["equipo"]):
				return true
		elif tablero.tipo_de_jugada(q, casilla) != "":
			return true
	return false
