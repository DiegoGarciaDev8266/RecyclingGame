extends Area2D

@export var tipo: int = 0
@export var variante: int = 0
var pickable := false
var dragging := false
var cayendo := true
var offset := Vector2.ZERO
var velocidad_caida := 150.0

const MATERIAL_BRILLO = preload("res://Shaders/brillo.tres")
const MATERIAL_SOMBRA = preload("res://Shaders/sombra.tres")

const TEXTURAS = {
	0: [
		"res://Assets/01-Egg.png",
		"res://Assets/02-BananaSkin.png",
		"res://Assets/03-Bone.png",
		"res://Assets/04-FishBone.png",
		"res://Assets/05-Apple.png"
	],
	1: [
		"res://Assets/11-Bottle.png",
		"res://Assets/16-Paper.png",
		"res://Assets/18-Box.png",
		"res://Assets/22-Glass.png",
		"res://Assets/10-Milk.png"
	],
	2: [
		"res://Assets/07-Styrofoam.png",
		"res://Assets/09-Snack.png",
		"res://Assets/20-Patchwork.png",
		"res://Assets/25-FilterCigarette.png",
		"res://Assets/12-Rope.png"
	]
}

func _ready():
	input_pickable = true
	# Sombra siempre activa
	$Sprite2D.material = MATERIAL_SOMBRA
	# Tamaño
	$Sprite2D.scale = Vector2(0.13, 0.13)
	var shape = $CollisionShape2D.shape
	if shape is RectangleShape2D:
		shape.size = Vector2(65, 65)
	# Textura
	var ruta = TEXTURAS[tipo][variante]
	if ResourceLoader.exists(ruta):
		$Sprite2D.texture = load(ruta)
	# Animación entrada
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BOUNCE)

func _process(delta):
	if dragging:
		global_position = get_global_mouse_position() + offset
	elif cayendo:
		global_position.y += velocidad_caida * delta

func iniciar_arrastre():
	dragging = true
	cayendo = false
	# Cambiar a shader de brillo
	$Sprite2D.material = MATERIAL_BRILLO

func soltar():
	dragging = false
	# Volver a sombra
	$Sprite2D.material = MATERIAL_SOMBRA

func emitir_particulas_acierto():
	if has_node("Particulas"):
		$Particulas.modulate = Color(0.2, 1.0, 0.2)
		$Particulas.emitting = true

func emitir_particulas_error():
	if has_node("Particulas"):
		$Particulas.modulate = Color(1.0, 0.2, 0.2)
		$Particulas.emitting = true
