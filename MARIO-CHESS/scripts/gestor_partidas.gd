extends Node

const MAX_RANURAS := 5

# -1 = partida nueva. Si es 1..5, el juego carga esa ranura al arrancar
var ranura_a_cargar := -1

func ruta(n: int) -> String:
	return "user://partida_%d.json" % n

func existe(n: int) -> bool:
	return FileAccess.file_exists(ruta(n))

func guardar(n: int, datos: Dictionary) -> bool:
	if n < 1 or n > MAX_RANURAS:
		return false
	var f := FileAccess.open(ruta(n), FileAccess.WRITE)
	if f == null:
		return false
	datos["fecha"] = Time.get_datetime_string_from_system(false, true)
	f.store_string(JSON.stringify(datos))
	return true

func cargar(n: int) -> Dictionary:
	if not existe(n):
		return {}
	var f := FileAccess.open(ruta(n), FileAccess.READ)
	var r = JSON.parse_string(f.get_as_text())
	return r if r is Dictionary else {}

func borrar(n: int) -> void:
	if existe(n):
		DirAccess.remove_absolute(ruta(n))
		
func hay_partidas() -> bool:
	for i in range(1, MAX_RANURAS + 1):
		if existe(i):
			return true
	return false
