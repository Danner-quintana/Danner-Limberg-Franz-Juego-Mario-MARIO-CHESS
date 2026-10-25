class_name Luchador
extends CharacterBody3D

signal murio(luchador: Luchador)

var controles: Dictionary = {}   # teclas: izq, der, arriba, abajo, atacar
var oponente: Luchador
var vida_max: int = 30
var vida: int = 30
var dano: int = 5
var velocidad: float = 4.0
var alcance: float = 1.8
var espera: float = 0.0          # tiempo hasta poder volver a atacar
var activo: bool = true
var etiqueta: Label3D

@onready var malla: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	etiqueta = Label3D.new()
	etiqueta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	etiqueta.position = Vector3(0, 1.7, 0)
	etiqueta.font_size = 64
	add_child(etiqueta)
	actualizar_etiqueta()

func preparar(datos: Dictionary) -> void:
	vida_max = datos["vida"]
	vida = vida_max
	dano = datos["dano"]
	velocidad = datos["velocidad"]
	actualizar_etiqueta()

func actualizar_etiqueta() -> void:
	etiqueta.text = str(vida) + " / " + str(vida_max)

func _physics_process(delta: float) -> void:
	if not activo or controles.is_empty():
		return
	var dir := Vector3.ZERO
	if Input.is_key_pressed(controles["izq"]):
		dir.x -= 1.0
	if Input.is_key_pressed(controles["der"]):
		dir.x += 1.0
	if Input.is_key_pressed(controles["arriba"]):
		dir.z -= 1.0
	if Input.is_key_pressed(controles["abajo"]):
		dir.z += 1.0
	dir = dir.normalized()
	velocity.x = dir.x * velocidad
	velocity.z = dir.z * velocidad
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	move_and_slide()

	# Que no se salgan de la arena
	position.x = clampf(position.x, -6.5, 6.5)
	position.z = clampf(position.z, -6.5, 6.5)

	espera -= delta
	if Input.is_key_pressed(controles["atacar"]) and espera <= 0.0:
		atacar()

func atacar() -> void:
	espera = 0.5
	var t = create_tween()
	t.tween_property(malla, "scale", Vector3(1.3, 1.3, 1.3), 0.08)
	t.tween_property(malla, "scale", Vector3.ONE, 0.08)
	if oponente != null and oponente.activo:
		if global_position.distance_to(oponente.global_position) <= alcance:
			oponente.recibir_dano(dano)

func recibir_dano(cantidad: int) -> void:
	vida = maxi(vida - cantidad, 0)
	actualizar_etiqueta()
	var t = create_tween()
	t.tween_property(malla, "position:x", 0.15, 0.04)
	t.tween_property(malla, "position:x", -0.15, 0.04)
	t.tween_property(malla, "position:x", 0.0, 0.04)
	if vida <= 0:
		activo = false
		murio.emit(self)
