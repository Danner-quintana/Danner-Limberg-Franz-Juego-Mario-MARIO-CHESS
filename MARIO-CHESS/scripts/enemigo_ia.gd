extends Node3D

@export var velocidad: float = 2.0
@export var distancia: float = 5.0

var direccion: int = 1
var posicion_inicial: Vector3

func _ready() -> void:
	posicion_inicial = position

func _process(delta: float) -> void:
	position.x += velocidad * direccion * delta

	if position.x >= posicion_inicial.x + distancia:
		direccion = -1

	if position.x <= posicion_inicial.x - distancia:
		direccion = 1
