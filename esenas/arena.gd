extends Node3D

signal duelo_terminado(gana_equipo: int)

# Vida, daño y velocidad de cada tipo de pieza (ajústalos a tu gusto)
const DATOS := {
	"peon": {"vida": 30, "dano": 5, "velocidad": 4.0},
	"rey": {"vida": 70, "dano": 8, "velocidad": 3.5},
}

@onready var luchador1: Luchador = $Luchador1   # pieza del equipo 1
@onready var luchador2: Luchador = $Luchador2   # pieza del equipo 2

var tipo_equipo1: String = "peon"
var tipo_equipo2: String = "rey"
var terminado: bool = false

# Se llama antes de añadir la arena a la escena
func configurar(t1: String, t2: String) -> void:
	tipo_equipo1 = t1
	tipo_equipo2 = t2

func _ready() -> void:
	luchador1.oponente = luchador2
	luchador2.oponente = luchador1
	# Equipo 1: W A S D + F       Equipo 2: flechas + Enter
	luchador1.controles = {"izq": KEY_A, "der": KEY_D, "arriba": KEY_W, "abajo": KEY_S, "atacar": KEY_F}
	luchador2.controles = {"izq": KEY_LEFT, "der": KEY_RIGHT, "arriba": KEY_UP, "abajo": KEY_DOWN, "atacar": KEY_ENTER}
	luchador1.preparar(DATOS[tipo_equipo1])
	luchador2.preparar(DATOS[tipo_equipo2])
	luchador1.murio.connect(_on_murio)
	luchador2.murio.connect(_on_murio)
	$Camera3D.make_current()

func _on_murio(perdedor: Luchador) -> void:
	if terminado:
		return
	terminado = true
	var gana_equipo: int = 2 if perdedor == luchador1 else 1
	print("Gana el equipo ", gana_equipo)
	await get_tree().create_timer(1.0).timeout
	duelo_terminado.emit(gana_equipo)
