extends Node2D

signal item_listo(item)

const BasuraItemScene = preload("res://Scenes/BasuraItem.tscn")

@export var velocidad: float = 120.0
@export var punto_recogida_x: float = 80.0

var item_en_banda: Node2D = null
var en_movimiento := false

const TEXTURAS = {
	0: {
		0: preload("res://Assets/carton_caja.svg"),
		1: preload("res://Assets/carton_periodico.svg"),
		2: preload("res://Assets/carton_rollo.svg")
	},
	1: {
		0: preload("res://Assets/vidrio_botella.svg"),
		1: preload("res://Assets/vidrio_frasco.svg"),
		2: preload("res://Assets/vidrio_vaso.svg")
	},
	2: {
		0: preload("res://Assets/plastico_botella.svg"),
		1: preload("res://Assets/plastico_vaso.svg"),
		2: preload("res://Assets/plastico_bolsa.svg")
	}
}

func spawn_siguiente(tipo: int, variante: int):
	if item_en_banda != null:
		return
	var item = BasuraItemScene.instantiate()
	item.tipo = tipo
	item.variante = variante
	item.get_node("Sprite2D").texture = TEXTURAS[tipo][variante]
	add_child(item)
	item.global_position = Vector2(
		$SpawnPoint.global_position.x + 100,
		$SpawnPoint.global_position.y
	)
	item.pickable = false  # ← se puede agarrar desde que aparece
	item_en_banda = item
	en_movimiento = true

func _process(delta):
	if not en_movimiento or item_en_banda == null:
		return
	item_en_banda.global_position.x -= velocidad * delta
	if item_en_banda.global_position.x <= punto_recogida_x:
		item_en_banda.global_position.x = punto_recogida_x
		en_movimiento = false
		item_en_banda.pickable = true
		emit_signal("item_listo", item_en_banda)

func liberar_banda():
	item_en_banda = null
	en_movimiento = false
